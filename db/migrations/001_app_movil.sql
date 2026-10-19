-- =============================================================================
-- Finanzas · migración para la app móvil (Neon Auth + Neon Data API)
--
-- Aditiva e idempotente sobre el esquema existente (movimientos, categorias).
-- Requisitos previos en Neon Console:
--   1. Auth habilitado (Managed Better Auth) con Google como proveedor.
--   2. Data API habilitada con Neon Auth como proveedor JWT. Esto crea el rol
--      `authenticated` y la función `auth.user_id()` (pg_session_jwt).
--
-- El rol dueño (el que usa el servidor MCP) no pasa por RLS, así que el
-- conector de Claude sigue funcionando igual.
-- =============================================================================

begin;

-- 1. Lista blanca: la app es de un solo usuario. Cualquiera puede registrarse
--    en Neon Auth con Google, pero solo los user_id aquí listados ven datos.
create table if not exists public.usuarios_permitidos (
  user_id   text primary key,
  creado_en timestamptz not null default now()
);

create or replace function public.es_usuario_permitido()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios_permitidos where user_id = auth.user_id()
  );
$$;

-- 2. Catálogos nuevos -------------------------------------------------------
alter table public.categorias
  add column if not exists presupuesto numeric(12, 2)
  check (presupuesto is null or presupuesto > 0);

create table if not exists public.cuentas (
  id        bigint generated always as identity primary key,
  nombre    text not null check (length(nombre) between 1 and 100),
  tipo      text not null check (tipo in ('debito', 'credito', 'efectivo')),
  moneda    text not null default 'MXN' check (moneda ~ '^[A-Z]{3}$'),
  color     text not null default '#0F5F4F' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  -- Solo últimos 4 dígitos; enlaza con movimientos.cuenta.
  ultimos4  text unique check (ultimos4 ~ '^[0-9]{4}$'),
  remitente text check (length(remitente) <= 200),
  creado_en timestamptz not null default now()
);

create table if not exists public.metas (
  id         bigint generated always as identity primary key,
  nombre     text not null check (length(nombre) between 1 and 100),
  objetivo   numeric(12, 2) not null check (objetivo > 0),
  ahorrado   numeric(12, 2) not null default 0 check (ahorrado >= 0),
  fecha_meta date,
  creado_en  timestamptz not null default now()
);

-- 3. Índices para los filtros/orden que usa la app ---------------------------
create index if not exists movimientos_fecha_id_idx
  on public.movimientos (fecha desc, id desc);
create index if not exists movimientos_categoria_fecha_idx
  on public.movimientos (categoria, fecha desc);
create index if not exists movimientos_tipo_fecha_idx
  on public.movimientos (tipo, fecha desc);
create index if not exists movimientos_cuenta_fecha_idx
  on public.movimientos (cuenta, fecha desc);
create index if not exists movimientos_origen_creado_idx
  on public.movimientos (origen, creado_en desc);

-- 4. RPC de agregados: cada pantalla obtiene sus totales en UNA consulta.
--    SECURITY INVOKER (por defecto) → aplican las políticas RLS.

-- Inicio: totales del periodo + gasto por categoría + pendientes de clasificar.
create or replace function public.app_resumen_periodo(
  p_desde  timestamptz,
  p_hasta  timestamptz,
  p_moneda text default 'MXN'
)
returns json
language sql stable
as $$
  with m as (
    select tipo, monto, categoria
    from public.movimientos
    where fecha >= p_desde and fecha < p_hasta and moneda = p_moneda
  ),
  por_categoria as (
    select categoria::text as nombre,
           sum(monto)      as total,
           count(*)        as movimientos
    from m
    where tipo = 'cargo'
    group by categoria
  )
  select json_build_object(
    'abonos',         coalesce(sum(monto) filter (where tipo = 'abono'), 0),
    'cargos',         coalesce(sum(monto) filter (where tipo = 'cargo'), 0),
    'por_clasificar', count(*) filter (where categoria = 'Otros'),
    'categorias',     coalesce(
                        (select json_agg(c order by c.total desc) from por_categoria c),
                        '[]'::json)
  )
  from m;
$$;

-- Categorías con total y conteo del periodo (LEFT JOIN + GROUP BY).
create or replace function public.app_categorias_con_totales(
  p_desde timestamptz,
  p_hasta timestamptz
)
returns table (
  nombre      text,
  es_ingreso  boolean,
  presupuesto numeric,
  total       numeric,
  movimientos bigint
)
language sql stable
as $$
  select c.nombre::text,
         c.es_ingreso,
         c.presupuesto::numeric,
         coalesce(t.total, 0)::numeric,
         coalesce(t.n, 0)::bigint
  from public.categorias c
  left join (
    select categoria, sum(monto) as total, count(*) as n
    from public.movimientos
    where fecha >= p_desde and fecha < p_hasta
    group by categoria
  ) t on t.categoria = c.nombre
  order by c.es_ingreso, coalesce(t.total, 0) desc, c.nombre;
$$;

-- Cuentas con número de movimientos del periodo.
create or replace function public.app_cuentas_con_conteo(
  p_desde timestamptz,
  p_hasta timestamptz
)
returns table (
  id          bigint,
  nombre      text,
  tipo        text,
  moneda      text,
  color       text,
  ultimos4    text,
  remitente   text,
  movimientos bigint
)
language sql stable
as $$
  select c.id, c.nombre, c.tipo, c.moneda, c.color, c.ultimos4, c.remitente,
         coalesce(t.n, 0)::bigint
  from public.cuentas c
  left join (
    select cuenta::text as cuenta, count(*) as n
    from public.movimientos
    where fecha >= p_desde and fecha < p_hasta and cuenta is not null
    group by cuenta
  ) t on t.cuenta = c.ultimos4
  order by c.id;
$$;

-- Metas: incremento atómico (sin leer-modificar-escribir en el cliente).
create or replace function public.app_aportar_meta(p_meta_id bigint, p_monto numeric)
returns public.metas
language plpgsql volatile
as $$
declare
  resultado public.metas;
begin
  if p_monto is null or p_monto <= 0 then
    raise exception 'El aporte debe ser mayor a cero' using errcode = '22023';
  end if;
  update public.metas
     set ahorrado = ahorrado + p_monto
   where id = p_meta_id
  returning * into resultado;
  if not found then
    raise exception 'Meta no encontrada' using errcode = 'P0002';
  end if;
  return resultado;
end;
$$;

-- 5. Regla de negocio: un movimiento de correo no cambia de tipo -------------
create or replace function public.app_proteger_movimiento_correo()
returns trigger
language plpgsql
as $$
begin
  if old.origen = 'correo' and new.tipo is distinct from old.tipo then
    raise exception 'No se puede cambiar el tipo de un movimiento registrado desde correo'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists app_proteger_movimiento_correo on public.movimientos;
create trigger app_proteger_movimiento_correo
  before update on public.movimientos
  for each row execute function public.app_proteger_movimiento_correo();

-- 6. Row Level Security ------------------------------------------------------
alter table public.movimientos         enable row level security;
alter table public.categorias          enable row level security;
alter table public.cuentas             enable row level security;
alter table public.metas               enable row level security;
alter table public.usuarios_permitidos enable row level security;

drop policy if exists app_movimientos_select on public.movimientos;
create policy app_movimientos_select on public.movimientos
  for select to authenticated using (public.es_usuario_permitido());

-- Desde la app solo se crean movimientos manuales.
drop policy if exists app_movimientos_insert on public.movimientos;
create policy app_movimientos_insert on public.movimientos
  for insert to authenticated
  with check (public.es_usuario_permitido() and origen = 'manual' and id_correo is null);

drop policy if exists app_movimientos_update on public.movimientos;
create policy app_movimientos_update on public.movimientos
  for update to authenticated
  using (public.es_usuario_permitido())
  with check (public.es_usuario_permitido());

do $$
declare t text;
begin
  foreach t in array array['categorias', 'cuentas', 'metas'] loop
    execute format('drop policy if exists app_%1$s_all on public.%1$I', t);
    execute format(
      'create policy app_%1$s_all on public.%1$I for all to authenticated
         using (public.es_usuario_permitido())
         with check (public.es_usuario_permitido())', t);
  end loop;
end $$;
-- usuarios_permitidos: sin políticas → invisible para `authenticated`.

-- 7. Privilegios mínimos para el rol de la Data API -------------------------
-- Al habilitarse, la Data API concede SELECT/INSERT/UPDATE/DELETE a
-- `authenticated` sobre todas las tablas (y por default privileges, también a
-- las nuevas). Se parte de cero y se concede solo lo necesario.
revoke all on all tables in schema public from authenticated, anonymous;
alter table if exists public._migraciones enable row level security;

grant usage on schema public to authenticated;

grant select on public.movimientos to authenticated;
grant insert (tipo, monto, moneda, fecha, concepto, categoria, cuenta, origen, notas)
  on public.movimientos to authenticated;
-- origen e id_correo no son actualizables desde la app.
grant update (tipo, monto, fecha, concepto, categoria, cuenta, notas)
  on public.movimientos to authenticated;

grant select, insert on public.categorias to authenticated;
grant select, insert, update on public.cuentas, public.metas to authenticated;
grant usage on all sequences in schema public to authenticated;

revoke all on public.usuarios_permitidos from authenticated;
revoke all on function public.es_usuario_permitido() from public;
grant execute on function public.es_usuario_permitido() to authenticated;

revoke all on function public.app_resumen_periodo(timestamptz, timestamptz, text) from public;
revoke all on function public.app_categorias_con_totales(timestamptz, timestamptz) from public;
revoke all on function public.app_cuentas_con_conteo(timestamptz, timestamptz) from public;
revoke all on function public.app_aportar_meta(bigint, numeric) from public;
grant execute on function public.app_resumen_periodo(timestamptz, timestamptz, text) to authenticated;
grant execute on function public.app_categorias_con_totales(timestamptz, timestamptz) to authenticated;
grant execute on function public.app_cuentas_con_conteo(timestamptz, timestamptz) to authenticated;
grant execute on function public.app_aportar_meta(bigint, numeric) to authenticated;

commit;

-- Después de iniciar sesión una vez con Google en la app, autoriza tu usuario:
--   insert into public.usuarios_permitidos (user_id)
--   select id::text from neon_auth."user" where email = '<tu correo>';

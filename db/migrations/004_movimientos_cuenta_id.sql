-- =============================================================================
-- 004 · movimientos.cuenta_id
--
-- `movimientos.cuenta` solo guarda últimos 4 dígitos (convención del MCP), así
-- que una cuenta de efectivo no podía asociarse a un movimiento. Se agrega una
-- FK opcional; `cuenta` se sigue llenando cuando la cuenta tiene dígitos.
-- =============================================================================

begin;

alter table public.movimientos
  add column if not exists cuenta_id bigint references public.cuentas(id) on delete set null;

create index if not exists movimientos_cuenta_id_fecha_idx
  on public.movimientos (cuenta_id, fecha desc);

-- Enlaza movimientos existentes por sus últimos 4 dígitos.
update public.movimientos m
   set cuenta_id = c.id
  from public.cuentas c
 where m.cuenta_id is null and m.cuenta is not null and m.cuenta = c.ultimos4;

grant insert (cuenta_id), update (cuenta_id) on public.movimientos to authenticated;

-- Conteo por cuenta: por FK, o por dígitos si el movimiento no tiene FK
-- (los que registra el MCP desde correo).
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
         count(m.id)::bigint
  from public.cuentas c
  left join public.movimientos m
    on m.fecha >= p_desde and m.fecha < p_hasta
   and (m.cuenta_id = c.id
        or (m.cuenta_id is null and c.ultimos4 is not null and m.cuenta = c.ultimos4))
  group by c.id
  order by c.id;
$$;

commit;

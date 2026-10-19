-- =============================================================================
-- 002 · Políticas RLS con auth.user_id() en línea
--
-- pg_session_jwt: si la PRIMERA llamada a auth.user_id() de la sesión ocurre
-- dentro de una función SECURITY DEFINER con `SET search_path`, devuelve NULL y
-- la sesión queda así. Con es_usuario_permitido() eso pasaba en las RPC (RLS
-- filtraba todo → totales en cero). Se sigue el patrón documentado por Neon:
-- llamar auth.user_id() directamente en la política, como `authenticated`.
-- =============================================================================

begin;

grant usage on schema auth to authenticated;

-- Cada usuario solo puede ver su propia fila de la lista blanca.
grant select on public.usuarios_permitidos to authenticated;
drop policy if exists app_usuarios_permitidos_self on public.usuarios_permitidos;
create policy app_usuarios_permitidos_self on public.usuarios_permitidos
  for select to authenticated using (user_id = auth.user_id());

-- Condición común (sin función intermedia).
--   exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id())

drop policy if exists app_movimientos_select on public.movimientos;
create policy app_movimientos_select on public.movimientos
  for select to authenticated
  using (exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id()));

drop policy if exists app_movimientos_insert on public.movimientos;
create policy app_movimientos_insert on public.movimientos
  for insert to authenticated
  with check (
    exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id())
    and origen = 'manual' and id_correo is null
  );

drop policy if exists app_movimientos_update on public.movimientos;
create policy app_movimientos_update on public.movimientos
  for update to authenticated
  using (exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id()))
  with check (exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id()));

do $$
declare t text;
begin
  foreach t in array array['categorias', 'cuentas', 'metas'] loop
    execute format('drop policy if exists app_%1$s_all on public.%1$I', t);
    execute format(
      'create policy app_%1$s_all on public.%1$I for all to authenticated
         using (exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id()))
         with check (exists (select 1 from public.usuarios_permitidos u where u.user_id = auth.user_id()))', t);
  end loop;
end $$;

drop function if exists public.es_usuario_permitido();

commit;

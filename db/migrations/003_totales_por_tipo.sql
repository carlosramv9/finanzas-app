-- =============================================================================
-- 003 · Totales de categoría según su tipo
--
-- app_categorias_con_totales sumaba cargos y abonos juntos: una categoría de
-- gasto como "Transferencia" mostraba depósitos recibidos como si fueran gasto.
-- Ahora: categorías de gasto suman cargos; de ingreso, abonos.
-- =============================================================================

begin;

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
    select categoria, tipo, sum(monto) as total, count(*) as n
    from public.movimientos
    where fecha >= p_desde and fecha < p_hasta
    group by categoria, tipo
  ) t on t.categoria = c.nombre
     and t.tipo = case when c.es_ingreso then 'abono' else 'cargo' end
  order by c.es_ingreso, coalesce(t.total, 0) desc, c.nombre;
$$;

commit;

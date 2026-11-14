-- PENDIENTE DE APLICAR en Supabase (proyecto ZITTANO). No borra ni modifica datos existentes.
-- 1) Crea la tabla de turnos (cada una ve lo suyo, Belén ve todo).
-- 2) Crea la copia de seguridad automática semanal (domingos), guardando las últimas 8 semanas.

-- TURNOS
create table public.turnos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  gestor text not null,
  cliente text not null,
  cliente_id text,
  consulado text,
  tipo text,
  fecha_pedido date default current_date,
  fecha_sacado date,
  fecha_turno date,
  precio_usd numeric,
  cobrado boolean not null default false,
  fecha_cobro date,
  costo_usd numeric,
  pagado_prog boolean not null default false,
  fecha_pago_prog date,
  cancelado boolean not null default false,
  nota text
);
alter table public.turnos enable row level security;
create policy zit_ver on public.turnos for select to authenticated using (zit_soy_admin() or zit_norm(gestor) = zit_norm(zit_mi_gestor()));
create policy zit_cargar on public.turnos for insert to authenticated with check (zit_soy_admin() or zit_norm(gestor) = zit_norm(zit_mi_gestor()));
create policy zit_editar on public.turnos for update to authenticated using (zit_soy_admin() or zit_norm(gestor) = zit_norm(zit_mi_gestor())) with check (zit_soy_admin() or zit_norm(gestor) = zit_norm(zit_mi_gestor()));
revoke all on public.turnos from anon;

-- RESPALDO SEMANAL
create schema if not exists respaldo;
revoke all on schema respaldo from anon, authenticated;
alter table public.ingresos_respaldo_20261114 set schema respaldo;
alter table respaldo.ingresos_respaldo_20261114 rename to ingresos_20261114;

create or replace function respaldo.hacer_copia() returns void
language plpgsql security definer set search_path = '' as $$
declare t text; sufijo text := to_char(now() at time zone 'America/Argentina/Buenos_Aires','YYYYMMDD'); viejo record;
begin
  foreach t in array array['clientes','ingresos','gastos','leads','planillas','turnos','actas_italia','notas_seguimiento','recibos','papelera'] loop
    if to_regclass('public.'||t) is not null and to_regclass('respaldo.'||t||'_'||sufijo) is null then
      execute format('create table respaldo.%I as select * from public.%I', t||'_'||sufijo, t);
    end if;
  end loop;
  -- se guardan las últimas 8 semanas de copias (solo se eliminan copias viejas, nunca datos del sistema)
  for viejo in select tablename from pg_catalog.pg_tables where schemaname='respaldo'
      and tablename ~ '_[0-9]{8}$' and to_date(right(tablename,8),'YYYYMMDD') < current_date - 56 loop
    execute format('drop table respaldo.%I', viejo.tablename);
  end loop;
end $$;
revoke all on function respaldo.hacer_copia() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.schedule('respaldo-semanal-zittano', '0 6 * * 0', 'select respaldo.hacer_copia()');
select respaldo.hacer_copia();

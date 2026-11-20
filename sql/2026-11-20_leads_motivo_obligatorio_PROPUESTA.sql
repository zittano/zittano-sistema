-- PROPUESTA — NO ESTÁ APLICADA. La aplica Belu (o quien ella diga) si la aprueba.
--
-- Qué hace: candado en la base para que ningún lead pueda quedar en "no_avanzo"
-- sin motivo, aunque alguien use una versión vieja del Sistema o edite la tabla a mano.
-- El Sistema ya lo exige en pantalla; esto es el cinturón de seguridad.
--
-- Es solo aditiva: no borra ni modifica ningún dato.
-- Al 20/11/2026 hay 0 leads en "no_avanzo", así que no choca con nada existente.
-- Para sacarla: alter table public.leads drop constraint leads_no_avanzo_con_motivo;

alter table public.leads
  add constraint leads_no_avanzo_con_motivo
  check (estado <> 'no_avanzo' or nullif(btrim(motivo), '') is not null);

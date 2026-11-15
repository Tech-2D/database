-- Apply after deploying the API that reads visit dates from visitas_aos_sites.
DELETE FROM tech2d.bloqueios_agenda WHERE tipo='ip';
ALTER TABLE tech2d.bloqueios_agenda
  DROP CONSTRAINT agenda_blocks_check,
  DROP CONSTRAINT agenda_blocks_kind_check,
  ADD CONSTRAINT bloqueios_agenda_apenas_email_check CHECK (tipo='email');
COMMENT ON TABLE tech2d.bloqueios_agenda IS 'Bloqueios de acesso à Agenda por e-mail, gerenciados por superadministradores.';
COMMENT ON COLUMN tech2d.bloqueios_agenda.tipo IS 'Tipo de bloqueio aceito pela API: email.';
COMMENT ON COLUMN tech2d.bloqueios_agenda.alvo IS 'E-mail normalizado da conta bloqueada.';

DROP TABLE tech2d.acessos_recentes;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:040_retirar_acessos_recentes';

-- Transfere referências e versões para as próprias entidades. Executar em uma transação.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
LOCK TABLE tech2d.registros_aplicacao IN ACCESS EXCLUSIVE MODE;
CREATE SEQUENCE tech2d.ids_entidades AS bigint;
SELECT setval('tech2d.ids_entidades', greatest(
  coalesce((SELECT max(id_registro) FROM tech2d.registros_aplicacao),0),
  coalesce(pg_sequence_last_value(pg_get_serial_sequence('tech2d.registros_aplicacao','id_registro')::regclass),0)
) + 1,false);
COMMENT ON SEQUENCE tech2d.ids_entidades IS 'Gera novos IDs numéricos sem reutilizar os IDs existentes.';
ALTER TABLE tech2d.horarios_aula RENAME COLUMN id_registro_aplicacao TO id_horario_interno;
COMMENT ON COLUMN tech2d.horarios_aula.id_horario_aula IS 'Identificador textual do horário preservado no contrato da API. id_horario_interno identifica o mesmo horário internamente.';

ALTER TABLE tech2d.atividades
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.atividades AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_atividade AND r.tipo='activities';
ALTER TABLE tech2d.atividades
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_atividade SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.atividades.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.atividades.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.atividades.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.atividades.id_atividade IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.perfis_administrativos
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.perfis_administrativos AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_perfil_administrativo AND r.tipo='admins';
ALTER TABLE tech2d.perfis_administrativos
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_perfil_administrativo SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.perfis_administrativos.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.perfis_administrativos.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.perfis_administrativos.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.perfis_administrativos.id_perfil_administrativo IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.regras_recorrencia
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.regras_recorrencia AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_regra_recorrencia AND r.tipo='recurringActivities';
ALTER TABLE tech2d.regras_recorrencia
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_regra_recorrencia SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.regras_recorrencia.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.regras_recorrencia.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.regras_recorrencia.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.regras_recorrencia.id_regra_recorrencia IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.regras_retencao
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.regras_retencao AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_regra_retencao AND r.tipo='activityRetention';
ALTER TABLE tech2d.regras_retencao
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_regra_retencao SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.regras_retencao.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.regras_retencao.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.regras_retencao.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.regras_retencao.id_regra_retencao IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.pedidos_agenda
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.pedidos_agenda AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_pedido_agenda AND r.tipo='agendaClassRequests';
ALTER TABLE tech2d.pedidos_agenda
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_pedido_agenda SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.pedidos_agenda.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.pedidos_agenda.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.pedidos_agenda.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.pedidos_agenda.id_pedido_agenda IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.turmas_agenda
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.turmas_agenda AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_turma_agenda AND r.tipo='agendaClasses';
ALTER TABLE tech2d.turmas_agenda
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_turma_agenda SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.turmas_agenda.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.turmas_agenda.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.turmas_agenda.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.turmas_agenda.id_turma_agenda IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.pedidos_representacao
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.pedidos_representacao AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_pedido_representacao AND r.tipo='representativeRequests';
ALTER TABLE tech2d.pedidos_representacao
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_pedido_representacao SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.pedidos_representacao.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.pedidos_representacao.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.pedidos_representacao.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.pedidos_representacao.id_pedido_representacao IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.sugestoes_atividade
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.sugestoes_atividade AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_sugestao_atividade AND r.tipo='suggestions';
ALTER TABLE tech2d.sugestoes_atividade
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_sugestao_atividade SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.sugestoes_atividade.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.sugestoes_atividade.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.sugestoes_atividade.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.sugestoes_atividade.id_sugestao_atividade IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.sugestoes_melhoria
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.sugestoes_melhoria AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_sugestao_melhoria AND r.tipo='feedback';
ALTER TABLE tech2d.sugestoes_melhoria
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_sugestao_melhoria SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.sugestoes_melhoria.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.sugestoes_melhoria.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.sugestoes_melhoria.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_sugestao_melhoria IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.mensagens_sugestao
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320),
  ADD COLUMN id_sugestao_melhoria bigint,
  ADD COLUMN referencia_sugestao varchar(320);
UPDATE tech2d.mensagens_sugestao AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia, id_sugestao_melhoria=r.id_registro_pai, referencia_sugestao=r.referencia_pai
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_mensagem_sugestao AND r.tipo='feedback/messages';
ALTER TABLE tech2d.mensagens_sugestao
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_mensagem_sugestao SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ALTER COLUMN referencia_sugestao SET NOT NULL,
  ADD UNIQUE (referencia_sugestao,referencia_api),
  ADD FOREIGN KEY (id_sugestao_melhoria) REFERENCES tech2d.sugestoes_melhoria(id_sugestao_melhoria) ON DELETE SET NULL;

COMMENT ON COLUMN tech2d.mensagens_sugestao.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.mensagens_sugestao.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.mensagens_sugestao.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.mensagens_sugestao.id_mensagem_sugestao IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.horarios_aula
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz;
UPDATE tech2d.horarios_aula AS e SET versao=r.versao, atualizado_em=r.atualizado_em
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_horario_interno AND r.tipo='schedules';
ALTER TABLE tech2d.horarios_aula
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_horario_interno SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN id_horario_interno SET NOT NULL;

COMMENT ON COLUMN tech2d.horarios_aula.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.horarios_aula.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.horarios_aula.id_horario_interno IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.perfis_comunidade
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.perfis_comunidade AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_perfil_comunidade AND r.tipo='userProfiles';
ALTER TABLE tech2d.perfis_comunidade
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_perfil_comunidade SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.perfis_comunidade.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.perfis_comunidade.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.perfis_comunidade.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.perfis_comunidade.id_perfil_comunidade IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.preferencias_resumo
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.preferencias_resumo AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_preferencia_resumo AND r.tipo='_agendaDigestPreferences';
ALTER TABLE tech2d.preferencias_resumo
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_preferencia_resumo SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.preferencias_resumo.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.preferencias_resumo.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.preferencias_resumo.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.preferencias_resumo.id_preferencia_resumo IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.espacos_kanban
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320),
  ADD COLUMN compartilhado boolean;
UPDATE tech2d.espacos_kanban AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia, compartilhado=(r.tipo='sharedKanban')
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_espaco_kanban AND r.tipo IN ('personalKanban','sharedKanban');
ALTER TABLE tech2d.espacos_kanban
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_espaco_kanban SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ALTER COLUMN compartilhado SET NOT NULL,
  ADD UNIQUE (compartilhado,referencia_api);

COMMENT ON COLUMN tech2d.espacos_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.espacos_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.espacos_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.espacos_kanban.id_espaco_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.participantes_kanban
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.participantes_kanban AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_participante_kanban AND r.tipo='kanbanMemberships';
ALTER TABLE tech2d.participantes_kanban
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_participante_kanban SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.participantes_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.participantes_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.participantes_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.participantes_kanban.id_participante_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.pedidos_kanban
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.pedidos_kanban AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_pedido_kanban AND r.tipo='kanbanRequests';
ALTER TABLE tech2d.pedidos_kanban
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_pedido_kanban SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.pedidos_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.pedidos_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.pedidos_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.pedidos_kanban.id_pedido_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

ALTER TABLE tech2d.limpeza_anexos_kanban
  ADD COLUMN versao bigint,
  ADD COLUMN atualizado_em timestamptz,
  ADD COLUMN referencia_api varchar(320);
UPDATE tech2d.limpeza_anexos_kanban AS e SET versao=r.versao, atualizado_em=r.atualizado_em, referencia_api=r.referencia
FROM tech2d.registros_aplicacao AS r WHERE r.id_registro=e.id_limpeza_anexo_kanban AND r.tipo='_kanbanFileCleanup';
ALTER TABLE tech2d.limpeza_anexos_kanban
  ALTER COLUMN versao SET NOT NULL,
  ALTER COLUMN atualizado_em SET NOT NULL,
  ADD CHECK (versao > 0),
  ALTER COLUMN id_limpeza_anexo_kanban SET DEFAULT nextval('tech2d.ids_entidades'),
  ALTER COLUMN referencia_api SET NOT NULL,
  ADD CHECK (referencia_api <> ''),
  ADD UNIQUE (referencia_api);

COMMENT ON COLUMN tech2d.limpeza_anexos_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

COMMENT ON COLUMN tech2d.limpeza_anexos_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

COMMENT ON COLUMN tech2d.limpeza_anexos_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

COMMENT ON COLUMN tech2d.limpeza_anexos_kanban.id_limpeza_anexo_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

CREATE INDEX mensagens_sugestao_sugestao_idx ON tech2d.mensagens_sugestao(id_sugestao_melhoria);
COMMENT ON COLUMN tech2d.mensagens_sugestao.id_sugestao_melhoria IS 'FK direta para a sugestão. Ao excluir a sugestão, a mensagem histórica fica desvinculada.';
COMMENT ON COLUMN tech2d.mensagens_sugestao.referencia_sugestao IS 'Referência externa usada no caminho da conversa, preservada após excluir a sugestão.';
COMMENT ON COLUMN tech2d.espacos_kanban.compartilhado IS 'Distingue espaços pessoais e compartilhados no contrato da API.';
CREATE FUNCTION tech2d.resolver_regra_recorrencia(valor text) RETURNS bigint
LANGUAGE plpgsql STABLE SET search_path=pg_catalog AS $fn$
DECLARE alvo bigint;
BEGIN
  IF valor IS NULL THEN RETURN NULL; END IF;
  SELECT id_regra_recorrencia INTO alvo FROM tech2d.regras_recorrencia WHERE referencia_api=valor;
  IF alvo IS NULL THEN RAISE EXCEPTION 'Regra de recorrência inexistente' USING ERRCODE='23503'; END IF;
  RETURN alvo;
END
$fn$;

CREATE OR REPLACE FUNCTION tech2d.gravar_atividades(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.atividades (versao,atualizado_em,referencia_api,id_atividade,titulo,descricao,tipo_atividade,id_disciplina,data_atividade,hora_atividade,id_turma,criado_por,email_criador,id_regra_recorrencia,criado_em,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'date')::date,(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',tech2d.resolver_regra_recorrencia(objeto->>'recurringId'),objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_atividade) DO UPDATE SET versao=atividades.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, id_regra_recorrencia=excluded.id_regra_recorrencia, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.anexos_atividade WHERE id_atividade=alvo;
  IF jsonb_typeof(objeto->'attachments')='array' THEN
    PERFORM tech2d.inserir_anexos_atividade(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'attachments') WITH ORDINALITY AS x(value,pos);
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_administrativos(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.perfis_administrativos (versao,atualizado_em,referencia_api,id_perfil_administrativo,papel,id_turma,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'role',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt')
  ON CONFLICT(id_perfil_administrativo) DO UPDATE SET versao=perfis_administrativos.versao+1, atualizado_em=excluded.atualizado_em, papel=excluded.papel, id_turma=excluded.id_turma, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_recorrencia(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.regras_recorrencia (versao,atualizado_em,referencia_api,id_regra_recorrencia,titulo,descricao,tipo_atividade,id_disciplina,hora_atividade,id_turma,criado_por,email_criador,criado_em,data_inicio,data_fim,ativa,excluida,intervalo_semanas,dias_semana) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'startDate')::date,(objeto->>'endDate')::date,(objeto->>'active')::boolean,(objeto->>'deleted')::boolean,(objeto->>'intervalWeeks')::smallint,CASE WHEN jsonb_typeof(objeto->'weekdays')='array' THEN ARRAY(SELECT value::smallint FROM jsonb_array_elements_text(objeto->'weekdays') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END)
  ON CONFLICT(id_regra_recorrencia) DO UPDATE SET versao=regras_recorrencia.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, data_inicio=excluded.data_inicio, data_fim=excluded.data_fim, ativa=excluded.ativa, excluida=excluded.excluida, intervalo_semanas=excluded.intervalo_semanas, dias_semana=excluded.dias_semana;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_retencao(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.regras_retencao (versao,atualizado_em,referencia_api,id_regra_retencao,id_turma,dias,ativa,alterado_por,alterado_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'days')::smallint,(objeto->>'enabled')::boolean,objeto->>'updatedBy',objeto->>'updatedAt')
  ON CONFLICT(id_regra_retencao) DO UPDATE SET versao=regras_retencao.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, dias=excluded.dias, ativa=excluded.ativa, alterado_por=excluded.alterado_por, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_agenda(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_agenda (versao,atualizado_em,referencia_api,id_pedido_agenda,nome_turma_solicitada,email,situacao,criado_em,revisado_em) VALUES (1,now(),chave_api,alvo,objeto->>'className',objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')
  ON CONFLICT(id_pedido_agenda) DO UPDATE SET versao=pedidos_agenda.versao+1, atualizado_em=excluded.atualizado_em, nome_turma_solicitada=excluded.nome_turma_solicitada, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_turmas_agenda(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.turmas_agenda (versao,atualizado_em,referencia_api,id_turma_agenda,id_turma,ativa,referencia_pedido,aprovada_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'name'),(objeto->>'active')::boolean,objeto->>'requestId',objeto->>'approvedAt')
  ON CONFLICT(id_turma_agenda) DO UPDATE SET versao=turmas_agenda.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, ativa=excluded.ativa, referencia_pedido=excluded.referencia_pedido, aprovada_em=excluded.aprovada_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_representacao(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_representacao (versao,atualizado_em,referencia_api,id_pedido_representacao,id_turma,email,situacao,criado_em,revisado_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')
  ON CONFLICT(id_pedido_representacao) DO UPDATE SET versao=pedidos_representacao.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_atividade(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.sugestoes_atividade (versao,atualizado_em,referencia_api,id_sugestao_atividade,titulo,descricao,tipo_atividade,id_disciplina,data_atividade,hora_atividade,id_turma,criado_em,alterado_em,situacao,resolucao,comentario_revisao,encerrada_em) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'date')::date,(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt',objeto->>'updatedAt',objeto->>'status',objeto->>'resolution',objeto->>'reviewComment',objeto->>'closedAt')
  ON CONFLICT(id_sugestao_atividade) DO UPDATE SET versao=sugestoes_atividade.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em, situacao=excluded.situacao, resolucao=excluded.resolucao, comentario_revisao=excluded.comentario_revisao, encerrada_em=excluded.encerrada_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_melhoria(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.sugestoes_melhoria (versao,atualizado_em,referencia_api,id_sugestao_melhoria,mensagem,id_turma,criado_por,email_criador,criado_em,credito_autorizado,nome_credito,situacao,concluida_em,concluida_por) VALUES (1,now(),chave_api,alvo,objeto->>'message',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'publicCreditAllowed')::boolean,objeto->>'publicCreditName',objeto->>'status',objeto->>'completedAt',objeto->>'completedBy')
  ON CONFLICT(id_sugestao_melhoria) DO UPDATE SET versao=sugestoes_melhoria.versao+1, atualizado_em=excluded.atualizado_em, mensagem=excluded.mensagem, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, credito_autorizado=excluded.credito_autorizado, nome_credito=excluded.nome_credito, situacao=excluded.situacao, concluida_em=excluded.concluida_em, concluida_por=excluded.concluida_por;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_mensagens_sugestao(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.mensagens_sugestao (versao,atualizado_em,referencia_api,referencia_sugestao,id_sugestao_melhoria,id_mensagem_sugestao,mensagem,remetente,criado_em) VALUES (1,now(),chave_api,pai_api,id_pai_api,alvo,objeto->>'text',objeto->>'senderId',objeto->>'createdAt')
  ON CONFLICT(id_mensagem_sugestao) DO UPDATE SET versao=mensagens_sugestao.versao+1, atualizado_em=excluded.atualizado_em, id_sugestao_melhoria=excluded.id_sugestao_melhoria, mensagem=excluded.mensagem, remetente=excluded.remetente, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_horarios_aula(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  inicio time;
  fim time;
  turma_catalogo bigint;
  disciplina_catalogo bigint;
BEGIN
  IF ((objeto->>'startTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'endTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'dayOfWeek') ~ '^[0-6]$'
    AND jsonb_typeof(objeto->'active')='boolean') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Invalid schedule projection' USING ERRCODE='check_violation';
  END IF;
  inicio := (objeto->>'startTime')::time;
  fim := (objeto->>'endTime')::time;
  INSERT INTO tech2d.professores(nome) VALUES(objeto->>'professor') ON CONFLICT(nome) DO NOTHING;
  disciplina_catalogo:=tech2d.resolver_disciplina(objeto->>'subject');
  turma_catalogo:=tech2d.resolver_turma(objeto->>'className',false);
  INSERT INTO tech2d.faixas_horario(hora_inicio,hora_fim) VALUES(inicio,fim) ON CONFLICT(hora_inicio,hora_fim) DO NOTHING;
  INSERT INTO tech2d.horarios_aula (versao,atualizado_em,id_horario_aula,id_horario_interno,id_professor,id_disciplina,id_turma,id_faixa_horario,dia_semana,ativo,andar,sala,criado_em,alterado_em)
  SELECT 1,now(),chave_api,alvo,p.id_professor,d.id_disciplina,t.id_turma,f.id_faixa_horario,(objeto->>'dayOfWeek')::smallint,(objeto->>'active')::boolean,
    objeto->>'floor',objeto->>'roomDescription',objeto->>'createdAt',objeto->>'updatedAt'
  FROM tech2d.professores p,tech2d.disciplinas d,tech2d.turmas t,tech2d.faixas_horario f
  WHERE p.nome=objeto->>'professor' AND d.id_disciplina=disciplina_catalogo AND t.id_turma=turma_catalogo
    AND f.hora_inicio=inicio AND f.hora_fim=fim
  ON CONFLICT(id_horario_aula) DO UPDATE SET versao=horarios_aula.versao+1, atualizado_em=excluded.atualizado_em, id_horario_interno=excluded.id_horario_interno,id_professor=excluded.id_professor,
    id_disciplina=excluded.id_disciplina,id_turma=excluded.id_turma,id_faixa_horario=excluded.id_faixa_horario,
    dia_semana=excluded.dia_semana,ativo=excluded.ativo,andar=excluded.andar,sala=excluded.sala,
    criado_em=excluded.criado_em,alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_comunidade(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.perfis_comunidade (versao,atualizado_em,referencia_api,id_perfil_comunidade,nome,empresa,turma_informada,sala,andar,url_foto,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')
  ON CONFLICT(id_perfil_comunidade) DO UPDATE SET versao=perfis_comunidade.versao+1, atualizado_em=excluded.atualizado_em, nome=excluded.nome, empresa=excluded.empresa, turma_informada=excluded.turma_informada, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_preferencias_resumo(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.preferencias_resumo (versao,atualizado_em,referencia_api,id_preferencia_resumo,ativo,id_turma,alterada_em_ms) VALUES (1,now(),chave_api,alvo,(objeto->>'enabled')::boolean,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'updatedAt')::bigint)
  ON CONFLICT(id_preferencia_resumo) DO UPDATE SET versao=preferencias_resumo.versao+1, atualizado_em=excluded.atualizado_em, ativo=excluded.ativo, id_turma=excluded.id_turma, alterada_em_ms=excluded.alterada_em_ms;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_espacos_kanban(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.espacos_kanban (versao,atualizado_em,referencia_api,compartilhado,id_espaco_kanban,id_proprietario,versao_formato,criado_em,alterado_em) VALUES (1,now(),chave_api,compartilhado_api,alvo,objeto->>'ownerId',(objeto->>'schemaVersion')::smallint,objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_espaco_kanban) DO UPDATE SET versao=espacos_kanban.versao+1, atualizado_em=excluded.atualizado_em, id_proprietario=excluded.id_proprietario, versao_formato=excluded.versao_formato, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.quadros_kanban WHERE id_espaco_kanban=alvo;
  IF jsonb_typeof(objeto->'boards')='array' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'boards') WITH ORDINALITY AS x(value,pos);
  END IF;
  IF jsonb_typeof(objeto->'board')='object' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,0,objeto->'board');
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_participantes_kanban(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.participantes_kanban (versao,atualizado_em,referencia_api,id_participante_kanban,referencia_quadro,id_usuario,email,nome,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt')
  ON CONFLICT(id_participante_kanban) DO UPDATE SET versao=participantes_kanban.versao+1, atualizado_em=excluded.atualizado_em, referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_kanban(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_kanban (versao,atualizado_em,referencia_api,id_pedido_kanban,referencia_quadro,id_usuario,email,nome,criado_em,situacao,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt',objeto->>'status',objeto->>'updatedAt')
  ON CONFLICT(id_pedido_kanban) DO UPDATE SET versao=pedidos_kanban.versao+1, atualizado_em=excluded.atualizado_em, referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em, situacao=excluded.situacao, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_limpeza_anexos_kanban(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.limpeza_anexos_kanban (versao,atualizado_em,referencia_api,id_limpeza_anexo_kanban,referencia_espaco,referencia_quadro,referencia_cartao) VALUES (1,now(),chave_api,alvo,objeto->>'path',objeto->>'board',objeto->>'task')
  ON CONFLICT(id_limpeza_anexo_kanban) DO UPDATE SET versao=limpeza_anexos_kanban.versao+1, atualizado_em=excluded.atualizado_em, referencia_espaco=excluded.referencia_espaco, referencia_quadro=excluded.referencia_quadro, referencia_cartao=excluded.referencia_cartao;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.ler_atividades(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo_atividade,
    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),
    'date', d.data_atividade,
    'time', to_char(d.hora_atividade,'HH24:MI'),
    'turmaId', tech2d.nome_turma_agenda(d.id_turma),
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'recurringId', (SELECT rr.referencia_api FROM tech2d.regras_recorrencia rr WHERE rr.id_regra_recorrencia=d.id_regra_recorrencia),
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'attachments', (SELECT coalesce(jsonb_agg(tech2d.ler_anexos_atividade(r.id_anexo_atividade) ORDER BY r.id_anexo_atividade),'[]'::jsonb) FROM tech2d.anexos_atividade r WHERE r.id_atividade=d.id_atividade)
  ))
  FROM tech2d.atividades d WHERE d.id_atividade=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_espacos_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'ownerId', d.id_proprietario,
    'schemaVersion', d.versao_formato,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'boards', CASE WHEN NOT d.compartilhado THEN (SELECT coalesce(jsonb_agg(tech2d.ler_quadros_kanban(r.id_quadro_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban) END,
    'board', CASE WHEN d.compartilhado THEN (SELECT tech2d.ler_quadros_kanban(r.id_quadro_kanban) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban AND r.ordem=0) END
  ))
  FROM tech2d.espacos_kanban d WHERE d.id_espaco_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_horarios_aula(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object('professor',p.nome,'subject',d.nome,'className',t.nome,
    'startTime',to_char(f.hora_inicio,'HH24:MI'),'endTime',to_char(f.hora_fim,'HH24:MI'),'dayOfWeek',h.dia_semana,
    'active',h.ativo,'floor',h.andar,'roomDescription',h.sala,'createdAt',h.criado_em,'updatedAt',h.alterado_em))
  FROM tech2d.horarios_aula h
  JOIN tech2d.professores p ON p.id_professor=h.id_professor JOIN tech2d.disciplinas d ON d.id_disciplina=h.id_disciplina
  JOIN tech2d.turmas t ON t.id_turma=h.id_turma JOIN tech2d.faixas_horario f ON f.id_faixa_horario=h.id_faixa_horario
  WHERE h.id_horario_interno=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro inválido' USING ERRCODE='check_violation';
  END IF;
  objeto := tech2d.padronizar_listas_registro(tipo,tech2d.remover_nulos_recursivo(objeto));
  CASE tipo
    WHEN 'activities' THEN PERFORM tech2d.gravar_atividades(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'admins' THEN PERFORM tech2d.gravar_perfis_administrativos(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'recurringActivities' THEN PERFORM tech2d.gravar_regras_recorrencia(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'activityRetention' THEN PERFORM tech2d.gravar_regras_retencao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'agendaClassRequests' THEN PERFORM tech2d.gravar_pedidos_agenda(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'agendaClasses' THEN PERFORM tech2d.gravar_turmas_agenda(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'representativeRequests' THEN PERFORM tech2d.gravar_pedidos_representacao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'suggestions' THEN PERFORM tech2d.gravar_sugestoes_atividade(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'feedback' THEN PERFORM tech2d.gravar_sugestoes_melhoria(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'feedback/messages' THEN PERFORM tech2d.gravar_mensagens_sugestao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'schedules' THEN PERFORM tech2d.gravar_horarios_aula(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'userProfiles' THEN PERFORM tech2d.gravar_perfis_comunidade(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_agendaDigestPreferences' THEN PERFORM tech2d.gravar_preferencias_resumo(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'personalKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'sharedKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanMemberships' THEN PERFORM tech2d.gravar_participantes_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanRequests' THEN PERFORM tech2d.gravar_pedidos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_kanbanFileCleanup' THEN PERFORM tech2d.gravar_limpeza_anexos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    ELSE RAISE EXCEPTION 'Tipo de registro desconhecido' USING ERRCODE='check_violation';
  END CASE;
  IF tech2d.ler_registro(alvo,tipo) IS DISTINCT FROM objeto THEN
    RAISE EXCEPTION 'Registro incompatível com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_registros(lote jsonb) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $fn$
DECLARE
  item record;
  partes text[];
  grupo varchar(40);
  pai varchar(320);
  chave varchar(320);
  tabela name;
  coluna_id name;
  alvo bigint;
  id_pai bigint;
  espaco_compartilhado boolean;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
  FOR item IN SELECT r.path,r.data FROM jsonb_to_recordset(lote) AS r(path text,data jsonb)
    ORDER BY (data IS NULL), CASE WHEN path LIKE 'recurringActivities/%' THEN 0 ELSE 1 END,length(path),path
  LOOP
    partes := string_to_array(item.path,'/');
    IF cardinality(partes) NOT IN (2,4) OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'Referência inválida' USING ERRCODE='23514';
    END IF;
    grupo := partes[1]; pai := ''; chave := partes[2]; id_pai := NULL;
    IF cardinality(partes)=4 THEN
      grupo := grupo || '/' || partes[3]; pai := partes[2]; chave := partes[4];
    END IF;
    CASE grupo
      WHEN 'activities' THEN tabela := 'atividades'; coluna_id := 'id_atividade';
      WHEN 'admins' THEN tabela := 'perfis_administrativos'; coluna_id := 'id_perfil_administrativo';
      WHEN 'recurringActivities' THEN tabela := 'regras_recorrencia'; coluna_id := 'id_regra_recorrencia';
      WHEN 'activityRetention' THEN tabela := 'regras_retencao'; coluna_id := 'id_regra_retencao';
      WHEN 'agendaClassRequests' THEN tabela := 'pedidos_agenda'; coluna_id := 'id_pedido_agenda';
      WHEN 'agendaClasses' THEN tabela := 'turmas_agenda'; coluna_id := 'id_turma_agenda';
      WHEN 'representativeRequests' THEN tabela := 'pedidos_representacao'; coluna_id := 'id_pedido_representacao';
      WHEN 'suggestions' THEN tabela := 'sugestoes_atividade'; coluna_id := 'id_sugestao_atividade';
      WHEN 'feedback' THEN tabela := 'sugestoes_melhoria'; coluna_id := 'id_sugestao_melhoria';
      WHEN 'feedback/messages' THEN tabela := 'mensagens_sugestao'; coluna_id := 'id_mensagem_sugestao';
      WHEN 'schedules' THEN tabela := 'horarios_aula'; coluna_id := 'id_horario_interno';
      WHEN 'userProfiles' THEN tabela := 'perfis_comunidade'; coluna_id := 'id_perfil_comunidade';
      WHEN '_agendaDigestPreferences' THEN tabela := 'preferencias_resumo'; coluna_id := 'id_preferencia_resumo';
      WHEN 'personalKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      WHEN 'kanbanMemberships' THEN tabela := 'participantes_kanban'; coluna_id := 'id_participante_kanban';
      WHEN 'kanbanRequests' THEN tabela := 'pedidos_kanban'; coluna_id := 'id_pedido_kanban';
      WHEN '_kanbanFileCleanup' THEN tabela := 'limpeza_anexos_kanban'; coluna_id := 'id_limpeza_anexo_kanban';
      WHEN 'sharedKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      ELSE RAISE EXCEPTION 'Recurso descontinuado ou desconhecido' USING ERRCODE='23514';
    END CASE;
    espaco_compartilhado := grupo='sharedKanban';
    IF grupo='feedback/messages' THEN
      SELECT id_sugestao_melhoria INTO id_pai FROM tech2d.sugestoes_melhoria WHERE referencia_api=pai;
      SELECT id_mensagem_sugestao INTO alvo FROM tech2d.mensagens_sugestao
      WHERE referencia_sugestao=pai AND referencia_api=chave;
    ELSIF tabela='espacos_kanban' THEN
      SELECT id_espaco_kanban INTO alvo FROM tech2d.espacos_kanban AS e
      WHERE e.compartilhado=espaco_compartilhado AND e.referencia_api=chave;
    ELSIF grupo='schedules' THEN
      SELECT id_horario_interno INTO alvo FROM tech2d.horarios_aula WHERE id_horario_aula=chave;
    ELSE
      EXECUTE format('SELECT %I FROM tech2d.%I WHERE referencia_api=$1',coluna_id,tabela) INTO alvo USING chave;
    END IF;
    IF item.data IS NULL THEN
      IF alvo IS NOT NULL THEN
        EXECUTE format('DELETE FROM tech2d.%I WHERE %I=$1',tabela,coluna_id) USING alvo;
      END IF;
    ELSE
      IF alvo IS NULL THEN alvo := nextval('tech2d.ids_entidades'); END IF;
      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data,chave,espaco_compartilhado,pai,id_pai);
      IF grupo='feedback' THEN
        UPDATE tech2d.mensagens_sugestao SET id_sugestao_melhoria=alvo
        WHERE referencia_sugestao=chave AND id_sugestao_melhoria IS NULL;
      END IF;
    END IF;
  END LOOP;
END
$fn$;

CREATE INDEX atividades_caminho_api_idx ON tech2d.atividades (tech2d.referencia_api('activities'::varchar,''::varchar,referencia_api));

CREATE INDEX perfis_administrativos_caminho_api_idx ON tech2d.perfis_administrativos (tech2d.referencia_api('admins'::varchar,''::varchar,referencia_api));

CREATE INDEX regras_recorrencia_caminho_api_idx ON tech2d.regras_recorrencia (tech2d.referencia_api('recurringActivities'::varchar,''::varchar,referencia_api));

CREATE INDEX regras_retencao_caminho_api_idx ON tech2d.regras_retencao (tech2d.referencia_api('activityRetention'::varchar,''::varchar,referencia_api));

CREATE INDEX pedidos_agenda_caminho_api_idx ON tech2d.pedidos_agenda (tech2d.referencia_api('agendaClassRequests'::varchar,''::varchar,referencia_api));

CREATE INDEX turmas_agenda_caminho_api_idx ON tech2d.turmas_agenda (tech2d.referencia_api('agendaClasses'::varchar,''::varchar,referencia_api));

CREATE INDEX pedidos_representacao_caminho_api_idx ON tech2d.pedidos_representacao (tech2d.referencia_api('representativeRequests'::varchar,''::varchar,referencia_api));

CREATE INDEX sugestoes_atividade_caminho_api_idx ON tech2d.sugestoes_atividade (tech2d.referencia_api('suggestions'::varchar,''::varchar,referencia_api));

CREATE INDEX sugestoes_melhoria_caminho_api_idx ON tech2d.sugestoes_melhoria (tech2d.referencia_api('feedback'::varchar,''::varchar,referencia_api));

CREATE INDEX mensagens_sugestao_caminho_api_idx ON tech2d.mensagens_sugestao (tech2d.referencia_api('feedback/messages'::varchar,referencia_sugestao,referencia_api));

CREATE INDEX horarios_aula_caminho_api_idx ON tech2d.horarios_aula (tech2d.referencia_api('schedules'::varchar,''::varchar,id_horario_aula));

CREATE INDEX perfis_comunidade_caminho_api_idx ON tech2d.perfis_comunidade (tech2d.referencia_api('userProfiles'::varchar,''::varchar,referencia_api));

CREATE INDEX preferencias_resumo_caminho_api_idx ON tech2d.preferencias_resumo (tech2d.referencia_api('_agendaDigestPreferences'::varchar,''::varchar,referencia_api));

CREATE INDEX espacos_kanban_personalkanban_caminho_api_idx ON tech2d.espacos_kanban (tech2d.referencia_api('personalKanban'::varchar,''::varchar,referencia_api)) WHERE NOT compartilhado;

CREATE INDEX participantes_kanban_caminho_api_idx ON tech2d.participantes_kanban (tech2d.referencia_api('kanbanMemberships'::varchar,''::varchar,referencia_api));

CREATE INDEX pedidos_kanban_caminho_api_idx ON tech2d.pedidos_kanban (tech2d.referencia_api('kanbanRequests'::varchar,''::varchar,referencia_api));

CREATE INDEX limpeza_anexos_kanban_caminho_api_idx ON tech2d.limpeza_anexos_kanban (tech2d.referencia_api('_kanbanFileCleanup'::varchar,''::varchar,referencia_api));

CREATE INDEX espacos_kanban_sharedkanban_caminho_api_idx ON tech2d.espacos_kanban (tech2d.referencia_api('sharedKanban'::varchar,''::varchar,referencia_api)) WHERE compartilhado;

CREATE OR REPLACE VIEW tech2d.visao_documentos_aplicacao AS
 SELECT tech2d.referencia_api('activities'::varchar,''::varchar,referencia_api) AS path, 'activities'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_atividade,'activities'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.atividades
UNION ALL
 SELECT tech2d.referencia_api('admins'::varchar,''::varchar,referencia_api) AS path, 'admins'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_perfil_administrativo,'admins'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.perfis_administrativos
UNION ALL
 SELECT tech2d.referencia_api('recurringActivities'::varchar,''::varchar,referencia_api) AS path, 'recurringActivities'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_regra_recorrencia,'recurringActivities'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.regras_recorrencia
UNION ALL
 SELECT tech2d.referencia_api('activityRetention'::varchar,''::varchar,referencia_api) AS path, 'activityRetention'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_regra_retencao,'activityRetention'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.regras_retencao
UNION ALL
 SELECT tech2d.referencia_api('agendaClassRequests'::varchar,''::varchar,referencia_api) AS path, 'agendaClassRequests'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_pedido_agenda,'agendaClassRequests'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.pedidos_agenda
UNION ALL
 SELECT tech2d.referencia_api('agendaClasses'::varchar,''::varchar,referencia_api) AS path, 'agendaClasses'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_turma_agenda,'agendaClasses'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.turmas_agenda
UNION ALL
 SELECT tech2d.referencia_api('representativeRequests'::varchar,''::varchar,referencia_api) AS path, 'representativeRequests'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_pedido_representacao,'representativeRequests'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.pedidos_representacao
UNION ALL
 SELECT tech2d.referencia_api('suggestions'::varchar,''::varchar,referencia_api) AS path, 'suggestions'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_sugestao_atividade,'suggestions'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.sugestoes_atividade
UNION ALL
 SELECT tech2d.referencia_api('feedback'::varchar,''::varchar,referencia_api) AS path, 'feedback'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_sugestao_melhoria,'feedback'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.sugestoes_melhoria
UNION ALL
 SELECT tech2d.referencia_api('feedback/messages'::varchar,referencia_sugestao,referencia_api) AS path, ('feedback/' || referencia_sugestao || '/messages') AS collection,
        referencia_api AS id, tech2d.ler_registro(id_mensagem_sugestao,'feedback/messages'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.mensagens_sugestao
UNION ALL
 SELECT tech2d.referencia_api('schedules'::varchar,''::varchar,id_horario_aula) AS path, 'schedules'::text AS collection,
        id_horario_aula AS id, tech2d.ler_registro(id_horario_interno,'schedules'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.horarios_aula
UNION ALL
 SELECT tech2d.referencia_api('userProfiles'::varchar,''::varchar,referencia_api) AS path, 'userProfiles'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_perfil_comunidade,'userProfiles'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.perfis_comunidade
UNION ALL
 SELECT tech2d.referencia_api('_agendaDigestPreferences'::varchar,''::varchar,referencia_api) AS path, '_agendaDigestPreferences'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_preferencia_resumo,'_agendaDigestPreferences'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.preferencias_resumo
UNION ALL
 SELECT tech2d.referencia_api('personalKanban'::varchar,''::varchar,referencia_api) AS path, 'personalKanban'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_espaco_kanban,'personalKanban'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.espacos_kanban WHERE NOT compartilhado
UNION ALL
 SELECT tech2d.referencia_api('kanbanMemberships'::varchar,''::varchar,referencia_api) AS path, 'kanbanMemberships'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_participante_kanban,'kanbanMemberships'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.participantes_kanban
UNION ALL
 SELECT tech2d.referencia_api('kanbanRequests'::varchar,''::varchar,referencia_api) AS path, 'kanbanRequests'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_pedido_kanban,'kanbanRequests'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.pedidos_kanban
UNION ALL
 SELECT tech2d.referencia_api('_kanbanFileCleanup'::varchar,''::varchar,referencia_api) AS path, '_kanbanFileCleanup'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_limpeza_anexo_kanban,'_kanbanFileCleanup'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.limpeza_anexos_kanban
UNION ALL
 SELECT tech2d.referencia_api('sharedKanban'::varchar,''::varchar,referencia_api) AS path, 'sharedKanban'::text AS collection,
        referencia_api AS id, tech2d.ler_registro(id_espaco_kanban,'sharedKanban'::varchar) AS data, versao AS version, atualizado_em AS updated_at
 FROM tech2d.espacos_kanban WHERE compartilhado;

CREATE OR REPLACE VIEW tech2d.visao_documentos_catalogo AS
 SELECT 'schedules'::varchar(40) AS collection, id_horario_aula AS id, tech2d.ler_registro(id_horario_interno,'schedules') AS data
 FROM tech2d.horarios_aula
 UNION ALL
 SELECT 'agendaClasses'::varchar(40), referencia_api, tech2d.ler_registro(id_turma_agenda,'agendaClasses')
 FROM tech2d.turmas_agenda;

CREATE OR REPLACE VIEW tech2d.visao_atividades AS
SELECT a.referencia_api AS id,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE rotulo_turma.id_turma = a.id_turma) AS turma_id,
    a.titulo AS title,
    COALESCE(a.descricao, ''::character varying) AS description,
    a.tipo_atividade AS type,
    (( SELECT COALESCE(( SELECT rotulo_nota.nome
                   FROM tech2d.visao_disciplinas_notas rotulo_nota
                  WHERE rotulo_nota.id = rotulo_disciplina.id_disciplina
                  ORDER BY rotulo_nota.ano_serie DESC
                 LIMIT 1), rotulo_disciplina.nome) AS "coalesce"
           FROM tech2d.disciplinas rotulo_disciplina
          WHERE rotulo_disciplina.id_disciplina = a.id_disciplina))::character varying(150) AS subject,
    a.data_atividade::character varying(10) AS date,
    to_char(a.hora_atividade::interval, 'HH24:MI'::text) AS "time",
    a.criado_por AS created_by,
    a.email_criador AS created_by_email,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia) AS recurring_id,
    COALESCE(( SELECT jsonb_agg(tech2d.ler_anexos_atividade(f.id_anexo_atividade) ORDER BY f.id_anexo_atividade) AS jsonb_agg
           FROM tech2d.anexos_atividade f
          WHERE f.id_atividade = a.id_atividade), '[]'::jsonb) AS attachments,
    a.criado_em::timestamp with time zone AS created_at,
    a.alterado_em::timestamp with time zone AS updated_at,
    a.versao AS version
   FROM tech2d.atividades a;

CREATE OR REPLACE VIEW tech2d.visao_atividades_automacao AS
SELECT a.referencia_api AS id,
    tech2d.referencia_api('activities','',a.referencia_api) AS caminho,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE rotulo_turma.id_turma = a.id_turma) AS turma,
    a.data_atividade AS data,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia) AS referencia_recorrencia,
    tech2d.ler_registro(a.id_atividade,'activities') AS conteudo
   FROM tech2d.atividades a;

CREATE OR REPLACE VIEW tech2d.visao_perfis_administrativos AS
SELECT p.referencia_api AS uid,
    p.papel AS role,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE rotulo_turma.id_turma = p.id_turma) AS turma_id,
    tech2d.ler_registro(p.id_perfil_administrativo,'admins') AS data
   FROM tech2d.perfis_administrativos p;

CREATE OR REPLACE FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean)
 RETURNS TABLE(activities jsonb, documents jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  WITH atividades_selecionadas AS (
    SELECT v.*
    FROM tech2d.atividades filtro
    JOIN tech2d.visao_atividades v ON v.id=filtro.referencia_api
    WHERE p_incluir_atividades
      AND (p_turma IS NULL OR filtro.id_turma = tech2d.buscar_id_turma(p_turma) OR filtro.id_turma IS NULL)
    ORDER BY date, time, id
    LIMIT 10001
  ), documentos_selecionados AS (
    SELECT collection, id, data
    FROM tech2d.visao_documentos_catalogo
    WHERE collection = 'agendaClasses'
    ORDER BY id
    LIMIT 10001
  )
  SELECT
    coalesce((SELECT jsonb_agg(
      to_jsonb(a) || jsonb_build_object('version', a.version::text)
      ORDER BY a.date, a.time, a.id
    ) FROM atividades_selecionadas a), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(
      to_jsonb(d) ORDER BY d.id
    ) FROM documentos_selecionados d), '[]'::jsonb);
$function$;

CREATE OR REPLACE FUNCTION tech2d.enfileirar_limpeza_kanban(lote jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  item jsonb;
  chave varchar(320);
BEGIN
  FOR item IN SELECT value FROM jsonb_array_elements(lote) LOOP
    chave := md5(item::text);
    IF NOT EXISTS (SELECT FROM tech2d.limpeza_anexos_kanban WHERE referencia_api=chave) THEN
      PERFORM tech2d.gravar_registros(jsonb_build_array(jsonb_build_object('path','_kanbanFileCleanup/'||chave,'data',item)));
    END IF;
  END LOOP;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.adiar_limpeza_kanban(chave text)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  UPDATE tech2d.limpeza_anexos_kanban SET atualizado_em=now()
  WHERE tech2d.referencia_api('_kanbanFileCleanup','',referencia_api)=chave;
$function$;

CREATE OR REPLACE FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE tipos varchar[]; revisao varchar(32);
BEGIN
 CASE catalogo
  WHEN 'agenda' THEN tipos:=ARRAY['activities','agendaClasses'];
  WHEN 'updates' THEN tipos:=ARRAY['agendaClasses'];
  WHEN 'schedules' THEN tipos:=ARRAY['schedules'];
  ELSE RAISE EXCEPTION 'Catálogo inválido' USING ERRCODE='22023';
 END CASE;
 SELECT md5(coalesce(string_agg(id_registro::text || ':' || versao::text, ',' ORDER BY id_registro),'')) INTO revisao
 FROM (
   SELECT id_atividade AS id_registro, versao FROM tech2d.atividades WHERE 'activities'=ANY(tipos)
   UNION ALL SELECT id_turma_agenda, versao FROM tech2d.turmas_agenda WHERE 'agendaClasses'=ANY(tipos)
   UNION ALL SELECT id_horario_interno, versao FROM tech2d.horarios_aula WHERE 'schedules'=ANY(tipos)
 ) entidades;
 SELECT md5(revisao||':'||coalesce((SELECT string_agg(id_disciplina::text||':'||nome,',' ORDER BY id_disciplina) FROM tech2d.disciplinas),'')
  ||':'||coalesce((SELECT string_agg(id_turma::text||':'||nome||':'||coalesce(referencia_agenda,''),',' ORDER BY id_turma) FROM tech2d.turmas),'')) INTO revisao;
 RETURN revisao;
END $function$;

DO $guard$
BEGIN
  IF EXISTS (
    SELECT tech2d.referencia_api(tipo,referencia_pai,referencia), versao, atualizado_em FROM tech2d.registros_aplicacao
    EXCEPT SELECT path,version,updated_at FROM tech2d.visao_documentos_aplicacao
  ) THEN
    RAISE EXCEPTION 'Há registros ou versões sem correspondência nas tabelas de destino';
  END IF;
END
$guard$;

ALTER TABLE tech2d.atividades DROP CONSTRAINT atividades_id_atividade_fkey;

ALTER TABLE tech2d.espacos_kanban DROP CONSTRAINT espacos_kanban_id_espaco_kanban_fkey;

ALTER TABLE tech2d.horarios_aula DROP CONSTRAINT horarios_aula_id_registro_aplicacao_fkey;

ALTER TABLE tech2d.limpeza_anexos_kanban DROP CONSTRAINT limpeza_anexos_kanban_id_limpeza_anexo_kanban_fkey;

ALTER TABLE tech2d.mensagens_sugestao DROP CONSTRAINT mensagens_sugestao_id_mensagem_sugestao_fkey;

ALTER TABLE tech2d.participantes_kanban DROP CONSTRAINT participantes_kanban_id_participante_kanban_fkey;

ALTER TABLE tech2d.pedidos_agenda DROP CONSTRAINT pedidos_agenda_id_pedido_agenda_fkey;

ALTER TABLE tech2d.pedidos_kanban DROP CONSTRAINT pedidos_kanban_id_pedido_kanban_fkey;

ALTER TABLE tech2d.pedidos_representacao DROP CONSTRAINT pedidos_representacao_id_pedido_representacao_fkey;

ALTER TABLE tech2d.perfis_administrativos DROP CONSTRAINT perfis_administrativos_id_perfil_administrativo_fkey;

ALTER TABLE tech2d.perfis_comunidade DROP CONSTRAINT perfis_comunidade_id_perfil_comunidade_fkey;

ALTER TABLE tech2d.preferencias_resumo DROP CONSTRAINT preferencias_resumo_id_preferencia_resumo_fkey;

ALTER TABLE tech2d.regras_recorrencia DROP CONSTRAINT regras_recorrencia_id_regra_recorrencia_fkey;

ALTER TABLE tech2d.regras_retencao DROP CONSTRAINT regras_retencao_id_regra_retencao_fkey;

ALTER TABLE tech2d.sugestoes_atividade DROP CONSTRAINT sugestoes_atividade_id_sugestao_atividade_fkey;

ALTER TABLE tech2d.sugestoes_melhoria DROP CONSTRAINT sugestoes_melhoria_id_sugestao_melhoria_fkey;

ALTER TABLE tech2d.turmas_agenda DROP CONSTRAINT turmas_agenda_id_turma_agenda_fkey;

DROP FUNCTION tech2d.gravar_atividades(bigint,jsonb);

DROP FUNCTION tech2d.gravar_perfis_administrativos(bigint,jsonb);

DROP FUNCTION tech2d.gravar_regras_recorrencia(bigint,jsonb);

DROP FUNCTION tech2d.gravar_regras_retencao(bigint,jsonb);

DROP FUNCTION tech2d.gravar_pedidos_agenda(bigint,jsonb);

DROP FUNCTION tech2d.gravar_turmas_agenda(bigint,jsonb);

DROP FUNCTION tech2d.gravar_pedidos_representacao(bigint,jsonb);

DROP FUNCTION tech2d.gravar_sugestoes_atividade(bigint,jsonb);

DROP FUNCTION tech2d.gravar_sugestoes_melhoria(bigint,jsonb);

DROP FUNCTION tech2d.gravar_mensagens_sugestao(bigint,jsonb);

DROP FUNCTION tech2d.gravar_horarios_aula(bigint,jsonb);

DROP FUNCTION tech2d.gravar_perfis_comunidade(bigint,jsonb);

DROP FUNCTION tech2d.gravar_preferencias_resumo(bigint,jsonb);

DROP FUNCTION tech2d.gravar_espacos_kanban(bigint,jsonb);

DROP FUNCTION tech2d.gravar_participantes_kanban(bigint,jsonb);

DROP FUNCTION tech2d.gravar_pedidos_kanban(bigint,jsonb);

DROP FUNCTION tech2d.gravar_limpeza_anexos_kanban(bigint,jsonb);

DROP FUNCTION tech2d.gravar_conteudo(bigint,varchar,jsonb);
DROP FUNCTION tech2d.resolver_referencia_entidade(varchar,text);
DROP FUNCTION tech2d.referencia_entidade(bigint);
DROP TABLE tech2d.registros_aplicacao;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:052_identidade_nas_entidades';

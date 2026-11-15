-- Executar em transação somente após copiar e verificar os registros no Redis.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));

CREATE OR REPLACE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro invÃƒÂ¡lido' USING ERRCODE='check_violation';
  END IF;
  objeto := tech2d.padronizar_listas_registro(tipo,tech2d.remover_nulos_recursivo(objeto));
  CASE tipo
    WHEN 'activities' THEN PERFORM tech2d.gravar_atividades(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'admins' THEN PERFORM tech2d.gravar_perfis_administrativos(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'recurringActivities' THEN PERFORM tech2d.gravar_regras_recorrencia(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'activityRetention' THEN PERFORM tech2d.gravar_regras_retencao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'agendaClasses' THEN PERFORM tech2d.gravar_turmas_agenda(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'representativeRequests' THEN PERFORM tech2d.gravar_pedidos_representacao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'feedback' THEN PERFORM tech2d.gravar_sugestoes_melhoria(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'schedules' THEN PERFORM tech2d.gravar_horarios_aula(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'userProfiles' THEN PERFORM tech2d.gravar_perfis(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_agendaDigestPreferences' THEN PERFORM tech2d.gravar_preferencias_resumo(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'personalKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'sharedKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanMemberships' THEN PERFORM tech2d.gravar_participantes_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanRequests' THEN PERFORM tech2d.gravar_pedidos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_kanbanFileCleanup' THEN PERFORM tech2d.gravar_limpeza_anexos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    ELSE RAISE EXCEPTION 'Tipo de registro desconhecido' USING ERRCODE='check_violation';
  END CASE;
  IF tech2d.ler_registro(alvo,tipo) IS DISTINCT FROM objeto THEN
    RAISE EXCEPTION 'Registro incompatÃƒÂ­vel com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_registros(lote jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
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
    IF cardinality(partes) <> 2 OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'ReferÃƒÂªncia invÃƒÂ¡lida' USING ERRCODE='23514';
    END IF;
    grupo := partes[1]; pai := ''; chave := partes[2]; id_pai := NULL;
    CASE grupo
      WHEN 'activities' THEN tabela := 'atividades'; coluna_id := 'id_atividade';
      WHEN 'admins' THEN tabela := 'perfis_administrativos'; coluna_id := 'id_perfil_administrativo';
      WHEN 'recurringActivities' THEN tabela := 'regras_recorrencia'; coluna_id := 'id_regra_recorrencia';
      WHEN 'activityRetention' THEN tabela := 'regras_retencao'; coluna_id := 'id_regra_retencao';
      WHEN 'agendaClasses' THEN tabela := 'turmas_agenda'; coluna_id := 'id_turma_agenda';
      WHEN 'representativeRequests' THEN tabela := 'pedidos_representacao'; coluna_id := 'id_pedido_representacao';
      WHEN 'feedback' THEN tabela := 'sugestoes_melhoria'; coluna_id := 'id_sugestao_melhoria';
      WHEN 'schedules' THEN tabela := 'horarios_aula'; coluna_id := 'id_horario_interno';
      WHEN 'userProfiles' THEN tabela := 'perfis'; coluna_id := 'id_perfil';
      WHEN '_agendaDigestPreferences' THEN tabela := 'preferencias_resumo'; coluna_id := 'id_preferencia_resumo';
      WHEN 'personalKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      WHEN 'kanbanMemberships' THEN tabela := 'participantes_kanban'; coluna_id := 'id_participante_kanban';
      WHEN 'kanbanRequests' THEN tabela := 'pedidos_kanban'; coluna_id := 'id_pedido_kanban';
      WHEN '_kanbanFileCleanup' THEN tabela := 'limpeza_anexos_kanban'; coluna_id := 'id_limpeza_anexo_kanban';
      WHEN 'sharedKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      ELSE RAISE EXCEPTION 'Recurso descontinuado ou desconhecido' USING ERRCODE='23514';
    END CASE;
    espaco_compartilhado := grupo='sharedKanban';
    IF tabela='espacos_kanban' THEN
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
    END IF;
  END LOOP;
END
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE tipo
    WHEN 'activities' THEN tech2d.ler_atividades(alvo)
    WHEN 'admins' THEN tech2d.ler_perfis_administrativos(alvo)
    WHEN 'recurringActivities' THEN tech2d.ler_regras_recorrencia(alvo)
    WHEN 'activityRetention' THEN tech2d.ler_regras_retencao(alvo)
    WHEN 'agendaClasses' THEN tech2d.ler_turmas_agenda(alvo)
    WHEN 'representativeRequests' THEN tech2d.ler_pedidos_representacao(alvo)
    WHEN 'feedback' THEN tech2d.ler_sugestoes_melhoria(alvo)
    WHEN 'schedules' THEN tech2d.ler_horarios_aula(alvo)
    WHEN 'userProfiles' THEN tech2d.ler_perfis(alvo)
    WHEN '_agendaDigestPreferences' THEN tech2d.ler_preferencias_resumo(alvo)
    WHEN 'personalKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'sharedKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'kanbanMemberships' THEN tech2d.ler_participantes_kanban(alvo)
    WHEN 'kanbanRequests' THEN tech2d.ler_pedidos_kanban(alvo)
    WHEN '_kanbanFileCleanup' THEN tech2d.ler_limpeza_anexos_kanban(alvo)
    ELSE NULL END;
$function$;

CREATE OR REPLACE VIEW tech2d.visao_documentos_aplicacao AS
SELECT tech2d.referencia_api('activities'::character varying, ''::character varying, atividades.referencia_api) AS path,
    'activities'::text AS collection,
    atividades.referencia_api AS id,
    tech2d.ler_registro(atividades.id_atividade, 'activities'::character varying) AS data,
    atividades.versao AS version,
    atividades.atualizado_em AS updated_at
   FROM tech2d.atividades
UNION ALL
SELECT tech2d.referencia_api('admins'::character varying, ''::character varying, perfis_administrativos.referencia_api) AS path,
    'admins'::text AS collection,
    perfis_administrativos.referencia_api AS id,
    tech2d.ler_registro(perfis_administrativos.id_perfil_administrativo, 'admins'::character varying) AS data,
    perfis_administrativos.versao AS version,
    perfis_administrativos.atualizado_em AS updated_at
   FROM tech2d.perfis_administrativos
UNION ALL
SELECT tech2d.referencia_api('recurringActivities'::character varying, ''::character varying, regras_recorrencia.referencia_api) AS path,
    'recurringActivities'::text AS collection,
    regras_recorrencia.referencia_api AS id,
    tech2d.ler_registro(regras_recorrencia.id_regra_recorrencia, 'recurringActivities'::character varying) AS data,
    regras_recorrencia.versao AS version,
    regras_recorrencia.atualizado_em AS updated_at
   FROM tech2d.regras_recorrencia
UNION ALL
SELECT tech2d.referencia_api('activityRetention'::character varying, ''::character varying, regras_retencao.referencia_api) AS path,
    'activityRetention'::text AS collection,
    regras_retencao.referencia_api AS id,
    tech2d.ler_registro(regras_retencao.id_regra_retencao, 'activityRetention'::character varying) AS data,
    regras_retencao.versao AS version,
    regras_retencao.atualizado_em AS updated_at
   FROM tech2d.regras_retencao
UNION ALL
SELECT tech2d.referencia_api('agendaClasses'::character varying, ''::character varying, turmas_agenda.referencia_api) AS path,
    'agendaClasses'::text AS collection,
    turmas_agenda.referencia_api AS id,
    tech2d.ler_registro(turmas_agenda.id_turma_agenda, 'agendaClasses'::character varying) AS data,
    turmas_agenda.versao AS version,
    turmas_agenda.atualizado_em AS updated_at
   FROM tech2d.turmas_agenda
UNION ALL
SELECT tech2d.referencia_api('representativeRequests'::character varying, ''::character varying, pedidos_representacao.referencia_api) AS path,
    'representativeRequests'::text AS collection,
    pedidos_representacao.referencia_api AS id,
    tech2d.ler_registro(pedidos_representacao.id_pedido_representacao, 'representativeRequests'::character varying) AS data,
    pedidos_representacao.versao AS version,
    pedidos_representacao.atualizado_em AS updated_at
   FROM tech2d.pedidos_representacao
UNION ALL
SELECT tech2d.referencia_api('feedback'::character varying, ''::character varying, sugestoes_melhoria.referencia_api) AS path,
    'feedback'::text AS collection,
    sugestoes_melhoria.referencia_api AS id,
    tech2d.ler_registro(sugestoes_melhoria.id_sugestao_melhoria, 'feedback'::character varying) AS data,
    sugestoes_melhoria.versao AS version,
    sugestoes_melhoria.atualizado_em AS updated_at
   FROM tech2d.sugestoes_melhoria
UNION ALL
SELECT tech2d.referencia_api('schedules'::character varying, ''::character varying, horarios_aula.id_horario_aula) AS path,
    'schedules'::text AS collection,
    horarios_aula.id_horario_aula AS id,
    tech2d.ler_registro(horarios_aula.id_horario_interno, 'schedules'::character varying) AS data,
    horarios_aula.versao AS version,
    horarios_aula.atualizado_em AS updated_at
   FROM tech2d.horarios_aula
UNION ALL
SELECT tech2d.referencia_api('userProfiles'::character varying, ''::character varying, perfis.referencia_api) AS path,
    'userProfiles'::text AS collection,
    perfis.referencia_api AS id,
    tech2d.ler_registro(perfis.id_perfil, 'userProfiles'::character varying) AS data,
    perfis.versao AS version,
    perfis.atualizado_em AS updated_at
   FROM tech2d.perfis
UNION ALL
SELECT tech2d.referencia_api('_agendaDigestPreferences'::character varying, ''::character varying, preferencias_resumo.referencia_api) AS path,
    '_agendaDigestPreferences'::text AS collection,
    preferencias_resumo.referencia_api AS id,
    tech2d.ler_registro(preferencias_resumo.id_preferencia_resumo, '_agendaDigestPreferences'::character varying) AS data,
    preferencias_resumo.versao AS version,
    preferencias_resumo.atualizado_em AS updated_at
   FROM tech2d.preferencias_resumo
UNION ALL
SELECT tech2d.referencia_api('personalKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'personalKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'personalKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE NOT espacos_kanban.compartilhado
UNION ALL
SELECT tech2d.referencia_api('kanbanMemberships'::character varying, ''::character varying, participantes_kanban.referencia_api) AS path,
    'kanbanMemberships'::text AS collection,
    participantes_kanban.referencia_api AS id,
    tech2d.ler_registro(participantes_kanban.id_participante_kanban, 'kanbanMemberships'::character varying) AS data,
    participantes_kanban.versao AS version,
    participantes_kanban.atualizado_em AS updated_at
   FROM tech2d.participantes_kanban
UNION ALL
SELECT tech2d.referencia_api('kanbanRequests'::character varying, ''::character varying, pedidos_kanban.referencia_api) AS path,
    'kanbanRequests'::text AS collection,
    pedidos_kanban.referencia_api AS id,
    tech2d.ler_registro(pedidos_kanban.id_pedido_kanban, 'kanbanRequests'::character varying) AS data,
    pedidos_kanban.versao AS version,
    pedidos_kanban.atualizado_em AS updated_at
   FROM tech2d.pedidos_kanban
UNION ALL
SELECT tech2d.referencia_api('_kanbanFileCleanup'::character varying, ''::character varying, limpeza_anexos_kanban.referencia_api) AS path,
    '_kanbanFileCleanup'::text AS collection,
    limpeza_anexos_kanban.referencia_api AS id,
    tech2d.ler_registro(limpeza_anexos_kanban.id_limpeza_anexo_kanban, '_kanbanFileCleanup'::character varying) AS data,
    limpeza_anexos_kanban.versao AS version,
    limpeza_anexos_kanban.atualizado_em AS updated_at
   FROM tech2d.limpeza_anexos_kanban
UNION ALL
SELECT tech2d.referencia_api('sharedKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'sharedKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'sharedKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE espacos_kanban.compartilhado;

DROP FUNCTION tech2d.ler_sugestoes_atividade(bigint);
DROP FUNCTION tech2d.gravar_sugestoes_atividade(bigint,jsonb,varchar,boolean,varchar,bigint);
DROP TABLE tech2d.sugestoes_atividade;

DROP FUNCTION tech2d.ler_pedidos_agenda(bigint);
DROP FUNCTION tech2d.gravar_pedidos_agenda(bigint,jsonb,varchar,boolean,varchar,bigint);
DROP TABLE tech2d.pedidos_agenda;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:055_pedidos_temporarios_redis';

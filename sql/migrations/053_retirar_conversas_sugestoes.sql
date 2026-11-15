-- Retira somente as conversas privadas de sugestões; as sugestões e seus créditos permanecem.
-- Executar em uma transação.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));

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
    WHEN 'agendaClassRequests' THEN tech2d.ler_pedidos_agenda(alvo)
    WHEN 'agendaClasses' THEN tech2d.ler_turmas_agenda(alvo)
    WHEN 'representativeRequests' THEN tech2d.ler_pedidos_representacao(alvo)
    WHEN 'suggestions' THEN tech2d.ler_sugestoes_atividade(alvo)
    WHEN 'feedback' THEN tech2d.ler_sugestoes_melhoria(alvo)
    WHEN 'schedules' THEN tech2d.ler_horarios_aula(alvo)
    WHEN 'userProfiles' THEN tech2d.ler_perfis_comunidade(alvo)
    WHEN '_agendaDigestPreferences' THEN tech2d.ler_preferencias_resumo(alvo)
    WHEN 'personalKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'sharedKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'kanbanMemberships' THEN tech2d.ler_participantes_kanban(alvo)
    WHEN 'kanbanRequests' THEN tech2d.ler_pedidos_kanban(alvo)
    WHEN '_kanbanFileCleanup' THEN tech2d.ler_limpeza_anexos_kanban(alvo)
    ELSE NULL END;
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
    IF cardinality(partes) <> 2 OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'Referência inválida' USING ERRCODE='23514';
    END IF;
    grupo := partes[1]; pai := ''; chave := partes[2]; id_pai := NULL;
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
$fn$;

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

DROP FUNCTION tech2d.ler_mensagens_sugestao(bigint);
DROP FUNCTION tech2d.gravar_mensagens_sugestao(bigint,jsonb,varchar,boolean,varchar,bigint);
DROP TABLE tech2d.mensagens_sugestao;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:053_retirar_conversas_sugestoes';

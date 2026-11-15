-- Padroniza o perfil do usuário preservando IDs, referências e permissões.
-- Executar em uma transação.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
ALTER TABLE tech2d.perfis_comunidade RENAME TO perfis;
ALTER TABLE tech2d.perfis RENAME COLUMN id_perfil_comunidade TO id_perfil;
ALTER FUNCTION tech2d.ler_perfis_comunidade(bigint) RENAME TO ler_perfis;
ALTER FUNCTION tech2d.gravar_perfis_comunidade(bigint,jsonb,varchar,boolean,varchar,bigint) RENAME TO gravar_perfis;
DO $rename$
DECLARE item record;
BEGIN
  FOR item IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.perfis'::regclass AND conname LIKE 'perfis_comunidade_%'
  LOOP
    EXECUTE format('ALTER TABLE tech2d.perfis RENAME CONSTRAINT %I TO %I',item.conname,replace(replace(item.conname,'perfis_comunidade_','perfis_'),'id_registro_','id_perfil_'));
  END LOOP;
END $rename$;
ALTER INDEX tech2d.perfis_comunidade_caminho_api_idx RENAME TO perfis_caminho_api_idx;
COMMENT ON TABLE tech2d.perfis IS 'Dados e configurações do perfil do usuário. Usada na edição do perfil e na apresentação dos dados que a pessoa escolheu publicar na Agenda e no Cadê o professor.';
COMMENT ON COLUMN tech2d.perfis.id_perfil IS 'Identificador numérico do perfil do usuário. Chave primária gerada pela sequência ids_entidades.';

CREATE OR REPLACE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro invÃ¡lido' USING ERRCODE='check_violation';
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
    RAISE EXCEPTION 'Registro incompatÃ­vel com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.perfis (versao,atualizado_em,referencia_api,id_perfil,nome,empresa,turma_informada,sala,andar,url_foto,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')
  ON CONFLICT(id_perfil) DO UPDATE SET versao=perfis.versao+1, atualizado_em=excluded.atualizado_em, nome=excluded.nome, empresa=excluded.empresa, turma_informada=excluded.turma_informada, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;
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
      RAISE EXCEPTION 'ReferÃªncia invÃ¡lida' USING ERRCODE='23514';
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

CREATE OR REPLACE FUNCTION tech2d.ler_perfis(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'displayName', d.nome,

    'company', d.empresa,

    'className', d.turma_informada,

    'room', d.sala,

    'floor', d.andar,

    'photoUrl', d.url_foto,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.perfis d WHERE d.id_perfil=alvo;

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
    WHEN 'agendaClassRequests' THEN tech2d.ler_pedidos_agenda(alvo)
    WHEN 'agendaClasses' THEN tech2d.ler_turmas_agenda(alvo)
    WHEN 'representativeRequests' THEN tech2d.ler_pedidos_representacao(alvo)
    WHEN 'suggestions' THEN tech2d.ler_sugestoes_atividade(alvo)
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

COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:054_perfis_usuarios';

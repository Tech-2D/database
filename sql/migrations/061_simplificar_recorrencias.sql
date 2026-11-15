-- Remoção física das séries já encerradas. Ocorrências anteriores são preservadas.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
DO $guard$
BEGIN
 IF EXISTS(SELECT 1 FROM tech2d.atividades a JOIN tech2d.regras_recorrencia r USING(id_regra_recorrencia)
   WHERE r.excluida AND a.data_atividade >= (now() AT TIME ZONE 'America/Sao_Paulo')::date) THEN
  RAISE EXCEPTION 'Há ocorrências futuras vinculadas a uma série excluída. Conclua a limpeza antes de migrar.';
 END IF;
END $guard$;
DELETE FROM tech2d.regras_recorrencia WHERE excluida;

CREATE OR REPLACE FUNCTION tech2d.ler_regras_recorrencia(alvo bigint)
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

    'time', to_char(d.hora_atividade,'HH24:MI'),

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdAt', d.criado_em,

    'startDate', d.data_inicio,

    'endDate', d.data_fim,

    'active', d.ativa,

    'intervalWeeks', d.intervalo_semanas,

    'weekdays', d.dias_semana

  ))

  FROM tech2d.regras_recorrencia d WHERE d.id_regra_recorrencia=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_recorrencia(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.regras_recorrencia (versao,atualizado_em,referencia_api,id_regra_recorrencia,titulo,descricao,tipo_atividade,id_disciplina,hora_atividade,id_turma,criado_por,criado_em,data_inicio,data_fim,ativa,intervalo_semanas,dias_semana) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdAt',(objeto->>'startDate')::date,(objeto->>'endDate')::date,(objeto->>'active')::boolean,(objeto->>'intervalWeeks')::smallint,CASE WHEN jsonb_typeof(objeto->'weekdays')='array' THEN ARRAY(SELECT value::smallint FROM jsonb_array_elements_text(objeto->'weekdays') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END)
  ON CONFLICT(id_regra_recorrencia) DO UPDATE SET versao=regras_recorrencia.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, criado_em=excluded.criado_em, data_inicio=excluded.data_inicio, data_fim=excluded.data_fim, ativa=excluded.ativa, intervalo_semanas=excluded.intervalo_semanas, dias_semana=excluded.dias_semana;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro inválido' USING ERRCODE='check_violation';
  END IF;
  objeto := tech2d.padronizar_listas_registro(tipo,tech2d.remover_nulos_recursivo(objeto));
  IF tipo='recurringActivities' THEN
    objeto := objeto - 'createdByEmail' - 'deleted';
  END IF;
  CASE tipo
    WHEN 'activities' THEN PERFORM tech2d.gravar_atividades(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'admins' THEN PERFORM tech2d.gravar_perfis_administrativos(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'recurringActivities' THEN PERFORM tech2d.gravar_regras_recorrencia(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'activityRetention' THEN PERFORM tech2d.gravar_regras_retencao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'agendaClasses' THEN PERFORM tech2d.gravar_turmas_agenda(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'feedback' THEN PERFORM tech2d.gravar_sugestoes_melhoria(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'schedules' THEN PERFORM tech2d.gravar_horarios_aula(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'userProfiles' THEN PERFORM tech2d.gravar_perfis(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_agendaDigestPreferences' THEN PERFORM tech2d.gravar_resumo_perfil(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'personalKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'sharedKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanMemberships' THEN PERFORM tech2d.gravar_participantes_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    ELSE RAISE EXCEPTION 'Tipo de registro desconhecido' USING ERRCODE='check_violation';
  END CASE;
  IF tech2d.ler_registro(alvo,tipo) IS DISTINCT FROM objeto THEN
    RAISE EXCEPTION 'Registro incompatÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­vel com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $function$;

ALTER TABLE tech2d.regras_recorrencia DROP COLUMN excluida, DROP COLUMN email_criador;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:061_simplificar_recorrencias';

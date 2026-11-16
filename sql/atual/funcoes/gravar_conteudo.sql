-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_conteudo(bigint, character varying, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
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
END $$;

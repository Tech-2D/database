-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_atividades(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_atividades(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
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
$$;

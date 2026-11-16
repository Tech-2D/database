-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_regras_recorrencia(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_regras_recorrencia(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

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

$$;

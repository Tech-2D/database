-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_sugestoes_melhoria(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'message', d.mensagem,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdByEmail', d.email_criador,

    'createdAt', d.criado_em,

    'publicCreditAllowed', d.credito_autorizado,

    'publicCreditName', d.nome_credito,

    'status', d.situacao,

    'completedAt', d.concluida_em,

    'completedBy', d.concluida_por

  ))

  FROM tech2d.sugestoes_melhoria d WHERE d.id_sugestao_melhoria=alvo;

$$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_turmas_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_turmas_agenda(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'name', tech2d.nome_turma_agenda(d.id_turma),

    'active', d.ativa,

    'requestId', d.referencia_pedido,

    'approvedAt', d.aprovada_em

  ))

  FROM tech2d.turmas_agenda d WHERE d.id_turma_agenda=alvo;

$$;

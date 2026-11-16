-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_regras_retencao(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_regras_retencao(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'days', d.dias,

    'enabled', d.ativa,

    'updatedBy', d.alterado_por,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.regras_retencao d WHERE d.id_regra_retencao=alvo;

$$;

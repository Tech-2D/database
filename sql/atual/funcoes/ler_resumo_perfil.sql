-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_resumo_perfil(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_resumo_perfil(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'enabled', d.resumo_semanal_ativo,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma_resumo),

    'updatedAt', d.resumo_alterado_em_ms

  ))

  FROM tech2d.perfis d WHERE d.id_perfil=alvo AND d.resumo_versao IS NOT NULL;

$$;

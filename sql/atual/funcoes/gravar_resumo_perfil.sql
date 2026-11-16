-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_resumo_perfil(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_resumo_perfil(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
 INSERT INTO tech2d.perfis(id_perfil,referencia_api,resumo_semanal_ativo,id_turma_resumo,resumo_alterado_em_ms,resumo_versao,resumo_atualizado_em)
 VALUES(alvo,chave_api,(objeto->>'enabled')::boolean,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'updatedAt')::bigint,1,now())
 ON CONFLICT(id_perfil) DO UPDATE SET resumo_semanal_ativo=excluded.resumo_semanal_ativo,id_turma_resumo=excluded.id_turma_resumo,resumo_alterado_em_ms=excluded.resumo_alterado_em_ms,resumo_versao=coalesce(perfis.resumo_versao,0)+1,resumo_atualizado_em=excluded.resumo_atualizado_em;
END $$;

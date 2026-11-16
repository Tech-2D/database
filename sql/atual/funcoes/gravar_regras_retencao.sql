-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_regras_retencao(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_regras_retencao(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.regras_retencao (versao,atualizado_em,referencia_api,id_regra_retencao,id_turma,dias,ativa,alterado_por,alterado_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'days')::smallint,(objeto->>'enabled')::boolean,objeto->>'updatedBy',objeto->>'updatedAt')
  ON CONFLICT(id_regra_retencao) DO UPDATE SET versao=regras_retencao.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, dias=excluded.dias, ativa=excluded.ativa, alterado_por=excluded.alterado_por, alterado_em=excluded.alterado_em;
END $$;

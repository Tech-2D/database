-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_perfis_administrativos(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_perfis_administrativos(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.perfis_administrativos (versao,atualizado_em,referencia_api,id_perfil_administrativo,papel,id_turma,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'role',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt')
  ON CONFLICT(id_perfil_administrativo) DO UPDATE SET versao=perfis_administrativos.versao+1, atualizado_em=excluded.atualizado_em, papel=excluded.papel, id_turma=excluded.id_turma, criado_em=excluded.criado_em;
END $$;

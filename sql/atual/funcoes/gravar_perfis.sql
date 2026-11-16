-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_perfis(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_perfis(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.perfis (versao,atualizado_em,referencia_api,id_perfil,nome,empresa,turma_informada,sala,andar,url_foto,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')
  ON CONFLICT(id_perfil) DO UPDATE SET versao=coalesce(perfis.versao,0)+1, atualizado_em=excluded.atualizado_em, nome=excluded.nome, empresa=excluded.empresa, turma_informada=excluded.turma_informada, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;
END $$;

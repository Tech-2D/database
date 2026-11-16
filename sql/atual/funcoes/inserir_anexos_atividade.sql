-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: inserir_anexos_atividade(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.anexos_atividade (id_atividade,referencia,nome,tipo_mime,tamanho_bytes,chave_arquivo,enviado_em,enviado_por) VALUES (pai,objeto->>'id',objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'storagePath',objeto->>'uploadedAt',objeto->>'uploadedBy') RETURNING id_anexo_atividade INTO alvo;
END $$;

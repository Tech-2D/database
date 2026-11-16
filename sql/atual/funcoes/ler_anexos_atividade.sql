-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_anexos_atividade(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_anexos_atividade(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'contentType', d.tipo_mime,
    'size', d.tamanho_bytes,
    'storagePath', d.chave_arquivo,
    'uploadedAt', d.enviado_em,
    'uploadedBy', d.enviado_por
  ))
  FROM tech2d.anexos_atividade d WHERE d.id_anexo_atividade=alvo;
$$;

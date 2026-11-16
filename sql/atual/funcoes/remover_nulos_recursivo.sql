-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: remover_nulos_recursivo(jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.remover_nulos_recursivo(valor jsonb) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE resultado jsonb;
BEGIN
  IF valor IS NULL THEN RETURN NULL; END IF;
  CASE jsonb_typeof(valor)
    WHEN 'object' THEN
      SELECT coalesce(jsonb_object_agg(chave, tech2d.remover_nulos_recursivo(conteudo)), '{}'::jsonb)
        INTO resultado FROM jsonb_each(valor) AS item(chave, conteudo)
        WHERE conteudo <> 'null'::jsonb;
      RETURN resultado;
    WHEN 'array' THEN
      SELECT coalesce(jsonb_agg(tech2d.remover_nulos_recursivo(conteudo) ORDER BY ordem), '[]'::jsonb)
        INTO resultado FROM jsonb_array_elements(valor) WITH ORDINALITY AS item(conteudo, ordem);
      RETURN resultado;
    ELSE RETURN valor;
  END CASE;
END $$;

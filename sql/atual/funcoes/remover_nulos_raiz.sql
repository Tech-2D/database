-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: remover_nulos_raiz(jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT coalesce(jsonb_object_agg(key,value),'{}'::jsonb)
  FROM jsonb_each(objeto) WHERE value <> 'null'::jsonb;
$$;

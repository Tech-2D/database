-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: referencia_api(character varying, character varying, character varying); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT CASE WHEN pai='' THEN tipo || '/' || referencia
    ELSE split_part(tipo,'/',1) || '/' || pai || '/' || split_part(tipo,'/',2) || '/' || referencia END;
$$;

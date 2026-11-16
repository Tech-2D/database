-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: normalizar_rotulo(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.normalizar_rotulo(valor text) RETURNS character varying
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT regexp_replace(translate(lower(btrim(valor)),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc'),'[^a-z0-9]','','g')::varchar;
$$;

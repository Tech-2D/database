-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: chave_turma(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.chave_turma(valor text) RETURNS character varying
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT tech2d.normalizar_rotulo(regexp_replace(replace(upper(valor),'TECH','TEC'),'\mANO\M','','g'));
$$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: buscar_id_turma(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.buscar_id_turma(valor text) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT id_turma FROM tech2d.turmas WHERE referencia_agenda=valor OR nome=valor
 ORDER BY (referencia_agenda=valor) DESC NULLS LAST LIMIT 1;
$$;

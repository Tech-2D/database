-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: nome_turma_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.nome_turma_agenda(alvo bigint) RETURNS character varying
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT coalesce(referencia_agenda,nome)::varchar FROM tech2d.turmas WHERE id_turma=alvo;
$$;

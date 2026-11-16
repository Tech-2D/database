-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: nome_disciplina_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.nome_disciplina_agenda(alvo bigint) RETURNS character varying
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT coalesce((SELECT v.nome FROM tech2d.visao_disciplinas_notas v WHERE v.id=d.id_disciplina ORDER BY v.ano_serie DESC LIMIT 1),d.nome)::varchar
 FROM tech2d.disciplinas d WHERE d.id_disciplina=alvo;
$$;

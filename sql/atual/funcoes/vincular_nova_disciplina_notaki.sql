-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vincular_nova_disciplina_notaki(); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.vincular_nova_disciplina_notaki() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  PERFORM tech2d.vincular_disciplina_notaki(NEW.id_turma, NEW.id_disciplina);
  RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

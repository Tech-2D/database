-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: travar_gravacao(text[]); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.travar_gravacao(caminhos text[]) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  inclui_kanban boolean;
  inclui_agenda boolean;
BEGIN
  SELECT coalesce(bool_or(kanban), false), coalesce(bool_or(NOT kanban), true)
  INTO inclui_kanban, inclui_agenda
  FROM (
    SELECT coalesce(split_part(caminho,'/',1) IN
      ('personalKanban','sharedKanban','kanbanMemberships','kanbanRequests'), false) AS kanban
    FROM unnest(caminhos) AS caminho
  ) escopos;
  IF inclui_agenda THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
  END IF;
  IF inclui_kanban THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-kanban-commit'));
  END IF;
END
$$;

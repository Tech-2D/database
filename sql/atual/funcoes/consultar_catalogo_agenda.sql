-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: consultar_catalogo_agenda(text, boolean); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) RETURNS TABLE(activities jsonb, documents jsonb)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  WITH atividades_selecionadas AS (
    SELECT v.*
    FROM tech2d.atividades filtro
    JOIN tech2d.visao_atividades v ON v.id=filtro.referencia_api
    WHERE p_incluir_atividades
      AND (p_turma IS NULL OR filtro.id_turma = tech2d.buscar_id_turma(p_turma) OR filtro.id_turma IS NULL)
    ORDER BY date, time, id
    LIMIT 10001
  ), documentos_selecionados AS (
    SELECT collection, id, data
    FROM tech2d.visao_documentos_catalogo
    WHERE collection = 'agendaClasses'
    ORDER BY id
    LIMIT 10001
  )
  SELECT
    coalesce((SELECT jsonb_agg(
      to_jsonb(a) || jsonb_build_object('version', a.version::text)
      ORDER BY a.date, a.time, a.id
    ) FROM atividades_selecionadas a), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(
      to_jsonb(d) ORDER BY d.id
    ) FROM documentos_selecionados d), '[]'::jsonb);
$$;

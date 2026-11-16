-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_espacos_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_espacos_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'ownerId', d.id_proprietario,
    'schemaVersion', d.versao_formato,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'boards', CASE WHEN NOT d.compartilhado THEN (SELECT coalesce(jsonb_agg(tech2d.ler_quadros_kanban(r.id_quadro_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban) END,
    'board', CASE WHEN d.compartilhado THEN (SELECT tech2d.ler_quadros_kanban(r.id_quadro_kanban) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban AND r.ordem=0) END
  ))
  FROM tech2d.espacos_kanban d WHERE d.id_espaco_kanban=alvo;
$$;

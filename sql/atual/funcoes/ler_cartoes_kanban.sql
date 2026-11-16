-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_cartoes_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_cartoes_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'columnId', d.referencia_coluna,
    'title', d.titulo,
    'description', d.descricao,
    'priority', d.prioridade,
    'dueDate', d.prazo,
    'assigneeId', d.id_responsavel,
    'labels', d.etiquetas,
    'activityIds', d.referencias_atividades,
    'checklist', (SELECT coalesce(jsonb_agg(tech2d.ler_itens_checklist(r.id_item_checklist) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.itens_checklist r WHERE r.id_cartao_kanban=d.id_cartao_kanban)
  ))
  FROM tech2d.cartoes_kanban d WHERE d.id_cartao_kanban=alvo;
$$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_quadros_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_quadros_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'compact', d.compacto,
    'columns', (SELECT coalesce(jsonb_agg(tech2d.ler_colunas_kanban(r.id_coluna_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.colunas_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban),
    'tasks', (SELECT coalesce(jsonb_agg(tech2d.ler_cartoes_kanban(r.id_cartao_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.cartoes_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban)
  ))
  FROM tech2d.quadros_kanban d WHERE d.id_quadro_kanban=alvo;
$$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_colunas_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_colunas_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'done', d.concluida
  ))
  FROM tech2d.colunas_kanban d WHERE d.id_coluna_kanban=alvo;
$$;

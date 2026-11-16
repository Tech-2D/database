-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_itens_checklist(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_itens_checklist(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'text', d.descricao,
    'done', d.concluido
  ))
  FROM tech2d.itens_checklist d WHERE d.id_item_checklist=alvo;
$$;

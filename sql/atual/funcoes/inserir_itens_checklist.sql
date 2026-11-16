-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: inserir_itens_checklist(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.itens_checklist (id_cartao_kanban,ordem,referencia,descricao,concluido) VALUES (pai,posicao,objeto->>'id',objeto->>'text',(objeto->>'done')::boolean) RETURNING id_item_checklist INTO alvo;
END $$;

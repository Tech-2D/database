-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: inserir_colunas_kanban(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.colunas_kanban (id_quadro_kanban,ordem,referencia,nome,cor,concluida) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'done')::boolean) RETURNING id_coluna_kanban INTO alvo;
END $$;

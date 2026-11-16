-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: inserir_quadros_kanban(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.quadros_kanban (id_espaco_kanban,ordem,referencia,nome,cor,compacto) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'compact')::boolean) RETURNING id_quadro_kanban INTO alvo;
  DELETE FROM tech2d.colunas_kanban WHERE id_quadro_kanban=alvo;
  IF jsonb_typeof(objeto->'columns')='array' THEN
    PERFORM tech2d.inserir_colunas_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'columns') WITH ORDINALITY AS x(value,pos);
  END IF;
  DELETE FROM tech2d.cartoes_kanban WHERE id_quadro_kanban=alvo;
  IF jsonb_typeof(objeto->'tasks')='array' THEN
    PERFORM tech2d.inserir_cartoes_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'tasks') WITH ORDINALITY AS x(value,pos);
  END IF;
END $$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: inserir_cartoes_kanban(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.cartoes_kanban (id_quadro_kanban,ordem,referencia,referencia_coluna,titulo,descricao,prioridade,prazo,id_responsavel,etiquetas,referencias_atividades) VALUES (pai,posicao,objeto->>'id',objeto->>'columnId',objeto->>'title',objeto->>'description',objeto->>'priority',(objeto->>'dueDate')::date,objeto->>'assigneeId',CASE WHEN jsonb_typeof(objeto->'labels')='array' THEN ARRAY(SELECT value::varchar(30) FROM jsonb_array_elements_text(objeto->'labels') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END,CASE WHEN jsonb_typeof(objeto->'activityIds')='array' THEN ARRAY(SELECT value::varchar(128) FROM jsonb_array_elements_text(objeto->'activityIds') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END) RETURNING id_cartao_kanban INTO alvo;
  DELETE FROM tech2d.itens_checklist WHERE id_cartao_kanban=alvo;
  IF jsonb_typeof(objeto->'checklist')='array' THEN
    PERFORM tech2d.inserir_itens_checklist(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'checklist') WITH ORDINALITY AS x(value,pos);
  END IF;
END $$;

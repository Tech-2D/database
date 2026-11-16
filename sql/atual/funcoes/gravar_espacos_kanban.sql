-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_espacos_kanban(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_espacos_kanban(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.espacos_kanban (versao,atualizado_em,referencia_api,compartilhado,id_espaco_kanban,id_proprietario,versao_formato,criado_em,alterado_em) VALUES (1,now(),chave_api,compartilhado_api,alvo,objeto->>'ownerId',(objeto->>'schemaVersion')::smallint,objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_espaco_kanban) DO UPDATE SET versao=espacos_kanban.versao+1, atualizado_em=excluded.atualizado_em, id_proprietario=excluded.id_proprietario, versao_formato=excluded.versao_formato, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.quadros_kanban WHERE id_espaco_kanban=alvo;
  IF jsonb_typeof(objeto->'boards')='array' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'boards') WITH ORDINALITY AS x(value,pos);
  END IF;
  IF jsonb_typeof(objeto->'board')='object' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,0,objeto->'board');
  END IF;
END $$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: padronizar_listas_registro(character varying, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.padronizar_listas_registro(tipo character varying, objeto jsonb) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE lista jsonb; chave varchar;
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN RETURN objeto; END IF;
  CASE tipo
    WHEN 'activities' THEN objeto := jsonb_build_object('attachments','[]'::jsonb) || objeto;
    WHEN 'task' THEN objeto := jsonb_build_object('checklist','[]'::jsonb) || objeto;
    WHEN 'sharedKanban' THEN
      IF objeto ? 'board' THEN objeto := jsonb_set(objeto,'{board}',tech2d.padronizar_listas_registro('board',objeto->'board')); END IF;
    WHEN 'personalKanban', 'board' THEN
      IF tipo='board' THEN
        objeto := jsonb_build_object('columns','[]'::jsonb,'tasks','[]'::jsonb) || objeto;
        chave := 'tasks';
      ELSE
        objeto := jsonb_build_object('boards','[]'::jsonb) || objeto;
        chave := 'boards';
      END IF;
      IF jsonb_typeof(objeto->chave)='array' THEN
        SELECT coalesce(jsonb_agg(tech2d.padronizar_listas_registro(CASE WHEN chave='tasks' THEN 'task' ELSE 'board' END,v) ORDER BY n),'[]'::jsonb)
        INTO lista FROM jsonb_array_elements(objeto->chave) WITH ORDINALITY AS item(v,n);
        objeto := jsonb_set(objeto,ARRAY[chave]::text[],lista);
      END IF;
    ELSE NULL;
  END CASE;
  RETURN objeto;
END $$;

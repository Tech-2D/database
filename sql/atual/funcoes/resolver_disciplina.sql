-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: resolver_disciplina(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.resolver_disciplina(valor text) RETURNS bigint
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint; ids bigint[];
BEGIN
 IF valor IS NULL THEN RETURN NULL; END IF;
 IF btrim(valor)='' OR length(valor)>150 THEN RAISE EXCEPTION 'Disciplina inválida' USING ERRCODE='23514'; END IF;
 SELECT id_disciplina INTO alvo FROM tech2d.disciplinas WHERE nome=valor;
 IF alvo IS NULL THEN SELECT id INTO alvo FROM tech2d.visao_disciplinas_notas WHERE nome=valor ORDER BY ano_serie DESC LIMIT 1; END IF;
 IF alvo IS NULL THEN
  SELECT array_agg(id_disciplina) INTO ids FROM tech2d.disciplinas WHERE tech2d.normalizar_rotulo(nome)=tech2d.normalizar_rotulo(valor);
  IF cardinality(ids)>1 THEN RAISE EXCEPTION 'Disciplina ambígua no catálogo' USING ERRCODE='23514'; END IF;
  alvo:=ids[1];
 END IF;
 IF alvo IS NULL THEN INSERT INTO tech2d.disciplinas(nome) VALUES(valor) ON CONFLICT(nome) DO UPDATE SET nome=excluded.nome RETURNING id_disciplina INTO alvo; END IF;
 RETURN alvo;
END $$;

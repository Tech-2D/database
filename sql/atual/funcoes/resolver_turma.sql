-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: resolver_turma(text, boolean); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.resolver_turma(valor text, agenda boolean DEFAULT true) RETURNS bigint
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint; ids bigint[]; canonico varchar(150);
BEGIN
 IF valor IS NULL THEN RETURN NULL; END IF;
 IF btrim(valor)='' OR length(valor)>150 THEN RAISE EXCEPTION 'Turma inválida' USING ERRCODE='23514'; END IF;
 alvo:=tech2d.buscar_id_turma(valor);
 IF alvo IS NULL THEN
  SELECT array_agg(id_turma) INTO ids FROM tech2d.turmas WHERE tech2d.chave_turma(nome)=tech2d.chave_turma(valor);
  IF cardinality(ids)>1 THEN RAISE EXCEPTION 'Turma ambígua no catálogo' USING ERRCODE='23514'; END IF;
  alvo:=ids[1];
 END IF;
 IF alvo IS NULL THEN
  canonico:=valor;
  IF upper(valor) ~ '^[123][°º] TECH ' THEN canonico:=regexp_replace(valor,'^([123])[°º] TECH ','\1º Tec ','i'); END IF;
  INSERT INTO tech2d.turmas(nome) VALUES(canonico) ON CONFLICT(nome) DO UPDATE SET nome=excluded.nome RETURNING id_turma INTO alvo;
 END IF;
 IF agenda THEN UPDATE tech2d.turmas SET referencia_agenda=valor WHERE id_turma=alvo AND referencia_agenda IS NULL; END IF;
 RETURN alvo;
END $$;

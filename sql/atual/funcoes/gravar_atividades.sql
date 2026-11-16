-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_atividades(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_atividades(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.atividades (versao,atualizado_em,referencia_api,id_atividade,titulo,descricao,tipo_atividade,id_disciplina,data_atividade,hora_atividade,id_turma,criado_por,email_criador,id_regra_recorrencia,criado_em,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'date')::date,(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',tech2d.resolver_regra_recorrencia(objeto->>'recurringId'),objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_atividade) DO UPDATE SET versao=atividades.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, id_regra_recorrencia=excluded.id_regra_recorrencia, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.anexos_atividade WHERE id_atividade=alvo;
  IF jsonb_typeof(objeto->'attachments')='array' THEN
    PERFORM tech2d.inserir_anexos_atividade(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'attachments') WITH ORDINALITY AS x(value,pos);
  END IF;
END $$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_regras_recorrencia(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_regras_recorrencia(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.regras_recorrencia (versao,atualizado_em,referencia_api,id_regra_recorrencia,titulo,descricao,tipo_atividade,id_disciplina,hora_atividade,id_turma,criado_por,criado_em,data_inicio,data_fim,ativa,intervalo_semanas,dias_semana) VALUES (1,now(),chave_api,alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdAt',(objeto->>'startDate')::date,(objeto->>'endDate')::date,(objeto->>'active')::boolean,(objeto->>'intervalWeeks')::smallint,CASE WHEN jsonb_typeof(objeto->'weekdays')='array' THEN ARRAY(SELECT value::smallint FROM jsonb_array_elements_text(objeto->'weekdays') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END)
  ON CONFLICT(id_regra_recorrencia) DO UPDATE SET versao=regras_recorrencia.versao+1, atualizado_em=excluded.atualizado_em, titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, criado_em=excluded.criado_em, data_inicio=excluded.data_inicio, data_fim=excluded.data_fim, ativa=excluded.ativa, intervalo_semanas=excluded.intervalo_semanas, dias_semana=excluded.dias_semana;
END $$;

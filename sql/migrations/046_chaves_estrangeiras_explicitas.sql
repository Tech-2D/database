-- Torna explícito o destino de cada FK antes chamada id_pai.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
ALTER TABLE tech2d.anexos_atividade RENAME COLUMN id_pai TO id_atividade;
ALTER TABLE tech2d.quadros_kanban RENAME COLUMN id_pai TO id_espaco_kanban;
ALTER TABLE tech2d.colunas_kanban RENAME COLUMN id_pai TO id_quadro_kanban;
ALTER TABLE tech2d.cartoes_kanban RENAME COLUMN id_pai TO id_quadro_kanban;
ALTER TABLE tech2d.itens_checklist RENAME COLUMN id_pai TO id_cartao_kanban;
ALTER TABLE tech2d.registros_aplicacao RENAME COLUMN id_pai TO id_registro_pai;
CREATE OR REPLACE VIEW tech2d.visao_atividades AS
 SELECT r.referencia AS id,
    a.turma AS turma_id,
    a.titulo AS title,
    COALESCE(a.descricao, ''::character varying) AS description,
    a.tipo AS type,
    a.disciplina AS subject,
    a.data::character varying(10) AS date,
    to_char(a.hora::interval, 'HH24:MI'::text) AS "time",
    a.criado_por AS created_by,
    a.email_criador AS created_by_email,
    a.referencia_recorrencia AS recurring_id,
    COALESCE(( SELECT jsonb_agg(tech2d.ler_anexos_atividade(f.id) ORDER BY f.id) AS jsonb_agg
           FROM tech2d.anexos_atividade f
          WHERE f.id_atividade = r.id), '[]'::jsonb) AS attachments,
    a.criado_em::timestamp with time zone AS created_at,
    a.alterado_em::timestamp with time zone AS updated_at,
    r.versao AS version
   FROM tech2d.atividades a
     JOIN tech2d.registros_aplicacao r ON r.id = a.id_registro;
ALTER TABLE tech2d.anexos_atividade DROP COLUMN ordem;

CREATE OR REPLACE FUNCTION tech2d.gravar_atividades(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.atividades (id_registro,titulo,descricao,tipo,disciplina,data,hora,turma,criado_por,email_criador,referencia_recorrencia,criado_em,alterado_em) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',objeto->>'subject',(objeto->>'date')::date,(objeto->>'time')::time,objeto->>'turmaId',objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'recurringId',objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_registro) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo=excluded.tipo, disciplina=excluded.disciplina, data=excluded.data, hora=excluded.hora, turma=excluded.turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, referencia_recorrencia=excluded.referencia_recorrencia, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.anexos_atividade WHERE id_atividade=alvo;
  IF jsonb_typeof(objeto->'attachments')='array' THEN
    PERFORM tech2d.inserir_anexos_atividade(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'attachments') WITH ORDINALITY AS x(value,pos);
  END IF;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_espacos_kanban(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.espacos_kanban (id_registro,id_proprietario,versao_formato,criado_em,alterado_em) VALUES (alvo,objeto->>'ownerId',(objeto->>'schemaVersion')::smallint,objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_registro) DO UPDATE SET id_proprietario=excluded.id_proprietario, versao_formato=excluded.versao_formato, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.quadros_kanban WHERE id_espaco_kanban=alvo;
  IF jsonb_typeof(objeto->'boards')='array' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'boards') WITH ORDINALITY AS x(value,pos);
  END IF;
  IF jsonb_typeof(objeto->'board')='object' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,0,objeto->'board');
  END IF;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_registros(lote jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  item record;
  partes text[];
  grupo varchar(40);
  pai varchar(320);
  chave varchar(320);
  alvo bigint;
BEGIN
  FOR item IN SELECT r.path,r.data FROM jsonb_to_recordset(lote) r(path text,data jsonb)
    ORDER BY (data IS NULL),length(path),path
  LOOP
    partes := string_to_array(item.path,'/');
    IF cardinality(partes) NOT IN (2,4) OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'Referência inválida' USING ERRCODE='check_violation';
    END IF;
    grupo := partes[1];
    pai := '';
    chave := partes[2];
    IF cardinality(partes)=4 THEN
      grupo := grupo || '/' || partes[3];
      pai := partes[2];
      chave := partes[4];
    END IF;
    IF grupo IN ('polls','polls/votes','pollVoterAccess','notebookNotes','announcement','purgedActivities','agendaUpdates','boardNotices','representativeChat','representativeInvites') THEN
      RAISE EXCEPTION 'Recurso descontinuado' USING ERRCODE='check_violation';
    END IF;
    IF item.data IS NULL THEN
      DELETE FROM tech2d.registros_aplicacao WHERE tipo=grupo AND referencia_pai=pai AND referencia=chave;
    ELSE
      INSERT INTO tech2d.registros_aplicacao(tipo,referencia_pai,referencia,id_registro_pai)
      VALUES(grupo,pai,chave,(SELECT id FROM tech2d.registros_aplicacao
        WHERE tipo=partes[1] AND referencia_pai='' AND referencia=pai AND pai<>''))
      ON CONFLICT(tipo,referencia_pai,referencia) DO UPDATE
      SET versao=registros_aplicacao.versao+1,atualizado_em=now(),id_registro_pai=excluded.id_registro_pai
      RETURNING id INTO alvo;
      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data);
      IF pai='' AND grupo='feedback' THEN
        UPDATE tech2d.registros_aplicacao SET id_registro_pai=alvo
        WHERE tipo='feedback/messages'
          AND referencia_pai=chave AND id_registro_pai IS NULL;
      END IF;
    END IF;
  END LOOP;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.anexos_atividade (id_atividade,referencia,nome,tipo_mime,tamanho_bytes,chave_arquivo,enviado_em,enviado_por) VALUES (pai,objeto->>'id',objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'storagePath',objeto->>'uploadedAt',objeto->>'uploadedBy') RETURNING id INTO alvo;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.cartoes_kanban (id_quadro_kanban,ordem,referencia,referencia_coluna,titulo,descricao,prioridade,prazo,id_responsavel,etiquetas,referencias_atividades) VALUES (pai,posicao,objeto->>'id',objeto->>'columnId',objeto->>'title',objeto->>'description',objeto->>'priority',(objeto->>'dueDate')::date,objeto->>'assigneeId',CASE WHEN jsonb_typeof(objeto->'labels')='array' THEN ARRAY(SELECT value::varchar(30) FROM jsonb_array_elements_text(objeto->'labels') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END,CASE WHEN jsonb_typeof(objeto->'activityIds')='array' THEN ARRAY(SELECT value::varchar(128) FROM jsonb_array_elements_text(objeto->'activityIds') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END) RETURNING id INTO alvo;
  DELETE FROM tech2d.itens_checklist WHERE id_cartao_kanban=alvo;
  IF jsonb_typeof(objeto->'checklist')='array' THEN
    PERFORM tech2d.inserir_itens_checklist(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'checklist') WITH ORDINALITY AS x(value,pos);
  END IF;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.colunas_kanban (id_quadro_kanban,ordem,referencia,nome,cor,concluida) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'done')::boolean) RETURNING id INTO alvo;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.itens_checklist (id_cartao_kanban,ordem,referencia,descricao,concluido) VALUES (pai,posicao,objeto->>'id',objeto->>'text',(objeto->>'done')::boolean) RETURNING id INTO alvo;
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.quadros_kanban (id_espaco_kanban,ordem,referencia,nome,cor,compacto) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'compact')::boolean) RETURNING id INTO alvo;
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
END $function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_atividades(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo,
    'subject', d.disciplina,
    'date', d.data,
    'time', to_char(d.hora,'HH24:MI'),
    'turmaId', d.turma,
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'recurringId', d.referencia_recorrencia,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'attachments', (SELECT coalesce(jsonb_agg(tech2d.ler_anexos_atividade(r.id) ORDER BY r.id),'[]'::jsonb) FROM tech2d.anexos_atividade r WHERE r.id_atividade=d.id_registro)
  ))
  FROM tech2d.atividades d WHERE d.id_registro=alvo;
$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_cartoes_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'columnId', d.referencia_coluna,
    'title', d.titulo,
    'description', d.descricao,
    'priority', d.prioridade,
    'dueDate', d.prazo,
    'assigneeId', d.id_responsavel,
    'labels', d.etiquetas,
    'activityIds', d.referencias_atividades,
    'checklist', (SELECT coalesce(jsonb_agg(tech2d.ler_itens_checklist(r.id) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.itens_checklist r WHERE r.id_cartao_kanban=d.id)
  ))
  FROM tech2d.cartoes_kanban d WHERE d.id=alvo;
$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_espacos_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'ownerId', d.id_proprietario,
    'schemaVersion', d.versao_formato,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'boards', CASE WHEN r.tipo='personalKanban' THEN (SELECT coalesce(jsonb_agg(tech2d.ler_quadros_kanban(r.id) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_registro) END,
    'board', CASE WHEN r.tipo='sharedKanban' THEN (SELECT tech2d.ler_quadros_kanban(r.id) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_registro AND r.ordem=0) END
  ))
  FROM tech2d.espacos_kanban d JOIN tech2d.registros_aplicacao r ON r.id=d.id_registro WHERE d.id_registro=alvo;
$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_quadros_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'compact', d.compacto,
    'columns', (SELECT coalesce(jsonb_agg(tech2d.ler_colunas_kanban(r.id) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.colunas_kanban r WHERE r.id_quadro_kanban=d.id),
    'tasks', (SELECT coalesce(jsonb_agg(tech2d.ler_cartoes_kanban(r.id) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.cartoes_kanban r WHERE r.id_quadro_kanban=d.id)
  ))
  FROM tech2d.quadros_kanban d WHERE d.id=alvo;
$function$
;

DO $names$
DECLARE obj record; novo varchar(128);
BEGIN
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.anexos_atividade'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_atividade');
    EXECUTE format('ALTER TABLE tech2d.anexos_atividade RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.quadros_kanban'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_espaco_kanban');
    EXECUTE format('ALTER TABLE tech2d.quadros_kanban RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.colunas_kanban'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_quadro_kanban');
    EXECUTE format('ALTER TABLE tech2d.colunas_kanban RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.cartoes_kanban'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_quadro_kanban');
    EXECUTE format('ALTER TABLE tech2d.cartoes_kanban RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.itens_checklist'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_cartao_kanban');
    EXECUTE format('ALTER TABLE tech2d.itens_checklist RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT conname FROM pg_constraint WHERE conrelid='tech2d.registros_aplicacao'::regclass AND conname LIKE '%id_pai%' LOOP
    novo:=replace(obj.conname,'id_pai','id_registro_pai');
    EXECUTE format('ALTER TABLE tech2d.registros_aplicacao RENAME CONSTRAINT %I TO %I',obj.conname,novo);
  END LOOP;
END
$names$;
ALTER INDEX tech2d.registros_aplicacao_pai RENAME TO registros_aplicacao_registro_pai;
COMMENT ON COLUMN tech2d.anexos_atividade.id_atividade IS 'Atividade que contém o anexo. Referencia atividades.id_registro; a exclusão da atividade remove os metadados de seus anexos.';
COMMENT ON COLUMN tech2d.quadros_kanban.id_espaco_kanban IS 'Espaço pessoal ou compartilhado que contém o quadro. Referencia espacos_kanban.id_registro.';
COMMENT ON COLUMN tech2d.colunas_kanban.id_quadro_kanban IS 'Quadro ao qual a coluna pertence. Referencia quadros_kanban.id.';
COMMENT ON COLUMN tech2d.cartoes_kanban.id_quadro_kanban IS 'Quadro ao qual o cartão pertence. Referencia quadros_kanban.id; junto com referencia_coluna, exige uma coluna desse mesmo quadro.';
COMMENT ON COLUMN tech2d.itens_checklist.id_cartao_kanban IS 'Cartão que contém o item de checklist. Referencia cartoes_kanban.id.';
COMMENT ON COLUMN tech2d.registros_aplicacao.id_registro_pai IS 'Registro da aplicação ao qual este registro está vinculado. Referencia registros_aplicacao.id; nas mensagens de sugestão, identifica o registro da sugestão.';
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:046_chaves_estrangeiras_explicitas';

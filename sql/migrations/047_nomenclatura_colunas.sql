-- Padroniza PKs e campos por entidade; preserva aliases públicos das views.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
ALTER TABLE tech2d.anexos_atividade RENAME COLUMN id TO id_anexo_atividade;
ALTER TABLE tech2d.atividades RENAME COLUMN id_registro TO id_atividade;
ALTER TABLE tech2d.atividades RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.atividades RENAME COLUMN disciplina TO nome_disciplina;
ALTER TABLE tech2d.atividades RENAME COLUMN data TO data_atividade;
ALTER TABLE tech2d.atividades RENAME COLUMN hora TO hora_atividade;
ALTER TABLE tech2d.atividades RENAME COLUMN tipo TO tipo_atividade;
ALTER TABLE tech2d.cartoes_kanban RENAME COLUMN id TO id_cartao_kanban;
ALTER TABLE tech2d.colunas_kanban RENAME COLUMN id TO id_coluna_kanban;
ALTER TABLE tech2d.disciplinas RENAME COLUMN id TO id_disciplina;
ALTER TABLE tech2d.entregas_resumo RENAME COLUMN id_registro TO id_entrega_resumo;
ALTER TABLE tech2d.envios_anexos RENAME COLUMN id_registro TO id_envio_anexo;
ALTER TABLE tech2d.espacos_kanban RENAME COLUMN id_registro TO id_espaco_kanban;
ALTER TABLE tech2d.faixas_horario RENAME COLUMN id TO id_faixa_horario;
ALTER TABLE tech2d.horarios_aula RENAME COLUMN id TO id_horario_aula;
ALTER TABLE tech2d.horarios_aula RENAME COLUMN id_registro TO id_registro_aplicacao;
ALTER TABLE tech2d.itens_checklist RENAME COLUMN id TO id_item_checklist;
ALTER TABLE tech2d.limites_servico RENAME COLUMN id_registro TO id_limite_servico;
ALTER TABLE tech2d.limpeza_anexos_kanban RENAME COLUMN id_registro TO id_limpeza_anexo_kanban;
ALTER TABLE tech2d.mensagens_sugestao RENAME COLUMN id_registro TO id_mensagem_sugestao;
ALTER TABLE tech2d.participantes_kanban RENAME COLUMN id_registro TO id_participante_kanban;
ALTER TABLE tech2d.pedidos_agenda RENAME COLUMN id_registro TO id_pedido_agenda;
ALTER TABLE tech2d.pedidos_kanban RENAME COLUMN id_registro TO id_pedido_kanban;
ALTER TABLE tech2d.pedidos_representacao RENAME COLUMN id_registro TO id_pedido_representacao;
ALTER TABLE tech2d.pedidos_representacao RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.perfis_administrativos RENAME COLUMN id_registro TO id_perfil_administrativo;
ALTER TABLE tech2d.perfis_administrativos RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.perfis_comunidade RENAME COLUMN id_registro TO id_perfil_comunidade;
ALTER TABLE tech2d.perfis_comunidade RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.preferencias_resumo RENAME COLUMN id_registro TO id_preferencia_resumo;
ALTER TABLE tech2d.preferencias_resumo RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.professores RENAME COLUMN id TO id_professor;
ALTER TABLE tech2d.quadros_kanban RENAME COLUMN id TO id_quadro_kanban;
ALTER TABLE tech2d.recibos_gravacao RENAME COLUMN id TO id_recibo_gravacao;
ALTER TABLE tech2d.registros_aplicacao RENAME COLUMN id TO id_registro;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN id_registro TO id_regra_recorrencia;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN disciplina TO nome_disciplina;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN hora TO hora_atividade;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN tipo TO tipo_atividade;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN inicio TO data_inicio;
ALTER TABLE tech2d.regras_recorrencia RENAME COLUMN fim TO data_fim;
ALTER TABLE tech2d.regras_retencao RENAME COLUMN id_registro TO id_regra_retencao;
ALTER TABLE tech2d.regras_retencao RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN id_registro TO id_sugestao_atividade;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN disciplina TO nome_disciplina;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN data TO data_atividade;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN hora TO hora_atividade;
ALTER TABLE tech2d.sugestoes_atividade RENAME COLUMN tipo TO tipo_atividade;
ALTER TABLE tech2d.sugestoes_melhoria RENAME COLUMN id_registro TO id_sugestao_melhoria;
ALTER TABLE tech2d.sugestoes_melhoria RENAME COLUMN turma TO nome_turma;
ALTER TABLE tech2d.turmas RENAME COLUMN id TO id_turma;
ALTER TABLE tech2d.turmas_agenda RENAME COLUMN id_registro TO id_turma_agenda;

CREATE OR REPLACE FUNCTION tech2d.adiar_limpeza_kanban(chave text)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  UPDATE tech2d.registros_aplicacao SET atualizado_em=now()
  WHERE tipo='_kanbanFileCleanup' AND referencia_pai='' AND tech2d.referencia_api(tipo,referencia_pai,referencia)=chave;
$function$;

CREATE OR REPLACE FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean)
 RETURNS TABLE(activities jsonb, documents jsonb)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  WITH atividades_selecionadas AS (
    SELECT *
    FROM tech2d.visao_atividades
    WHERE p_incluir_atividades
      AND (p_turma IS NULL OR turma_id = p_turma OR turma_id IS NULL)
    ORDER BY date, time, id
    LIMIT 10001
  ), documentos_selecionados AS (
    SELECT collection, id, data
    FROM tech2d.visao_documentos_catalogo
    WHERE collection = 'agendaClasses'
    ORDER BY id
    LIMIT 10001
  )
  SELECT
    coalesce((SELECT jsonb_agg(
      to_jsonb(a) || jsonb_build_object('version', a.version::text)
      ORDER BY a.date, a.time, a.id
    ) FROM atividades_selecionadas a), '[]'::jsonb),
    coalesce((SELECT jsonb_agg(
      to_jsonb(d) ORDER BY d.id
    ) FROM documentos_selecionados d), '[]'::jsonb);
$function$;

CREATE OR REPLACE FUNCTION tech2d.enfileirar_limpeza_kanban(lote jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  item jsonb;
  chave varchar(320);
BEGIN
  FOR item IN SELECT value FROM jsonb_array_elements(lote) LOOP
    chave := md5(item::text);
    IF NOT EXISTS (SELECT FROM tech2d.registros_aplicacao WHERE tipo='_kanbanFileCleanup' AND referencia=chave AND referencia_pai='') THEN
      PERFORM tech2d.gravar_registros(jsonb_build_array(jsonb_build_object('path','_kanbanFileCleanup/'||chave,'data',item)));
    END IF;
  END LOOP;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_atividades(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.atividades (id_atividade,titulo,descricao,tipo_atividade,nome_disciplina,data_atividade,hora_atividade,nome_turma,criado_por,email_criador,referencia_recorrencia,criado_em,alterado_em) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',objeto->>'subject',(objeto->>'date')::date,(objeto->>'time')::time,objeto->>'turmaId',objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'recurringId',objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_atividade) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, nome_disciplina=excluded.nome_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, nome_turma=excluded.nome_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, referencia_recorrencia=excluded.referencia_recorrencia, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.anexos_atividade WHERE id_atividade=alvo;
  IF jsonb_typeof(objeto->'attachments')='array' THEN
    PERFORM tech2d.inserir_anexos_atividade(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'attachments') WITH ORDINALITY AS x(value,pos);
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro inválido' USING ERRCODE='check_violation';
  END IF;
  objeto := tech2d.padronizar_listas_registro(tipo,tech2d.remover_nulos_recursivo(objeto));
  CASE tipo
    WHEN 'activities' THEN PERFORM tech2d.gravar_atividades(alvo,objeto);
    WHEN 'admins' THEN PERFORM tech2d.gravar_perfis_administrativos(alvo,objeto);
    WHEN 'recurringActivities' THEN PERFORM tech2d.gravar_regras_recorrencia(alvo,objeto);
    WHEN 'activityRetention' THEN PERFORM tech2d.gravar_regras_retencao(alvo,objeto);
    WHEN 'agendaClassRequests' THEN PERFORM tech2d.gravar_pedidos_agenda(alvo,objeto);
    WHEN 'agendaClasses' THEN PERFORM tech2d.gravar_turmas_agenda(alvo,objeto);
    WHEN 'representativeRequests' THEN PERFORM tech2d.gravar_pedidos_representacao(alvo,objeto);
    WHEN 'suggestions' THEN PERFORM tech2d.gravar_sugestoes_atividade(alvo,objeto);
    WHEN 'feedback' THEN PERFORM tech2d.gravar_sugestoes_melhoria(alvo,objeto);
    WHEN 'feedback/messages' THEN PERFORM tech2d.gravar_mensagens_sugestao(alvo,objeto);
    WHEN 'schedules' THEN PERFORM tech2d.gravar_horarios_aula(alvo,objeto);
    WHEN 'userProfiles' THEN PERFORM tech2d.gravar_perfis_comunidade(alvo,objeto);
    WHEN '_agendaDigestPreferences' THEN PERFORM tech2d.gravar_preferencias_resumo(alvo,objeto);
    WHEN '_agendaDigestDeliveries' THEN PERFORM tech2d.gravar_entregas_resumo(alvo,objeto);
    WHEN '_agendaUploads' THEN PERFORM tech2d.gravar_envios_anexos(alvo,objeto);
    WHEN '_passwordResetLimits' THEN PERFORM tech2d.gravar_limites_servico(alvo,objeto);
    WHEN '_r2UploadLimits' THEN PERFORM tech2d.gravar_limites_servico(alvo,objeto);
    WHEN '_profilePhotoLimits' THEN PERFORM tech2d.gravar_limites_servico(alvo,objeto);
    WHEN 'personalKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto);
    WHEN 'sharedKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto);
    WHEN 'kanbanMemberships' THEN PERFORM tech2d.gravar_participantes_kanban(alvo,objeto);
    WHEN 'kanbanRequests' THEN PERFORM tech2d.gravar_pedidos_kanban(alvo,objeto);
    WHEN '_kanbanFileCleanup' THEN PERFORM tech2d.gravar_limpeza_anexos_kanban(alvo,objeto);
    ELSE RAISE EXCEPTION 'Tipo de registro desconhecido' USING ERRCODE='check_violation';
  END CASE;
  IF tech2d.ler_registro(alvo,tipo) IS DISTINCT FROM objeto THEN
    RAISE EXCEPTION 'Registro incompatível com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_entregas_resumo(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.entregas_resumo (id_entrega_resumo,situacao,inicio_semana,criada_em_ms,concluida_em_ms) VALUES (alvo,objeto->>'status',(objeto->>'weekStart')::date,(objeto->>'createdAt')::bigint,(objeto->>'completedAt')::bigint)
  ON CONFLICT(id_entrega_resumo) DO UPDATE SET situacao=excluded.situacao, inicio_semana=excluded.inicio_semana, criada_em_ms=excluded.criada_em_ms, concluida_em_ms=excluded.concluida_em_ms;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_envios_anexos(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.envios_anexos (id_envio_anexo,referencia_atividade,nome,tipo_mime,tamanho_bytes,chave_arquivo,id_usuario,criado_em_ms) VALUES (alvo,objeto->>'activityId',objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'key',objeto->>'uid',(objeto->>'createdAt')::bigint)
  ON CONFLICT(id_envio_anexo) DO UPDATE SET referencia_atividade=excluded.referencia_atividade, nome=excluded.nome, tipo_mime=excluded.tipo_mime, tamanho_bytes=excluded.tamanho_bytes, chave_arquivo=excluded.chave_arquivo, id_usuario=excluded.id_usuario, criado_em_ms=excluded.criado_em_ms;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_espacos_kanban(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.espacos_kanban (id_espaco_kanban,id_proprietario,versao_formato,criado_em,alterado_em) VALUES (alvo,objeto->>'ownerId',(objeto->>'schemaVersion')::smallint,objeto->>'createdAt',objeto->>'updatedAt')
  ON CONFLICT(id_espaco_kanban) DO UPDATE SET id_proprietario=excluded.id_proprietario, versao_formato=excluded.versao_formato, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;
  DELETE FROM tech2d.quadros_kanban WHERE id_espaco_kanban=alvo;
  IF jsonb_typeof(objeto->'boards')='array' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'boards') WITH ORDINALITY AS x(value,pos);
  END IF;
  IF jsonb_typeof(objeto->'board')='object' THEN
    PERFORM tech2d.inserir_quadros_kanban(alvo,0,objeto->'board');
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_horarios_aula(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  chave varchar(320);
  inicio time;
  fim time;
BEGIN
  SELECT referencia INTO STRICT chave FROM tech2d.registros_aplicacao WHERE id_registro=alvo;
  IF ((objeto->>'startTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'endTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'dayOfWeek') ~ '^[0-6]$'
    AND jsonb_typeof(objeto->'active')='boolean') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Invalid schedule projection' USING ERRCODE='check_violation';
  END IF;
  inicio := (objeto->>'startTime')::time;
  fim := (objeto->>'endTime')::time;
  INSERT INTO tech2d.professores(nome) VALUES(objeto->>'professor') ON CONFLICT(nome) DO NOTHING;
  INSERT INTO tech2d.disciplinas(nome) VALUES(objeto->>'subject') ON CONFLICT(nome) DO NOTHING;
  INSERT INTO tech2d.turmas(nome) VALUES(objeto->>'className') ON CONFLICT(nome) DO NOTHING;
  INSERT INTO tech2d.faixas_horario(hora_inicio,hora_fim) VALUES(inicio,fim) ON CONFLICT(hora_inicio,hora_fim) DO NOTHING;

  INSERT INTO tech2d.horarios_aula(id_horario_aula,id_registro_aplicacao,id_professor,id_disciplina,id_turma,id_faixa_horario,dia_semana,ativo,andar,sala,criado_em,alterado_em)
  SELECT chave,alvo,p.id_professor,d.id_disciplina,t.id_turma,f.id_faixa_horario,(objeto->>'dayOfWeek')::smallint,(objeto->>'active')::boolean,
    objeto->>'floor',objeto->>'roomDescription',objeto->>'createdAt',objeto->>'updatedAt'
  FROM tech2d.professores p,tech2d.disciplinas d,tech2d.turmas t,tech2d.faixas_horario f
  WHERE p.nome=objeto->>'professor' AND d.nome=objeto->>'subject' AND t.nome=objeto->>'className'
    AND f.hora_inicio=inicio AND f.hora_fim=fim
  ON CONFLICT(id_horario_aula) DO UPDATE SET id_registro_aplicacao=excluded.id_registro_aplicacao,id_professor=excluded.id_professor,
    id_disciplina=excluded.id_disciplina,id_turma=excluded.id_turma,id_faixa_horario=excluded.id_faixa_horario,
    dia_semana=excluded.dia_semana,ativo=excluded.ativo,andar=excluded.andar,sala=excluded.sala,
    criado_em=excluded.criado_em,alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_limites_servico(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.limites_servico (id_limite_servico,quantidade,expira_em_ms) VALUES (alvo,(objeto->>'count')::integer,(objeto->>'resetAt')::bigint)
  ON CONFLICT(id_limite_servico) DO UPDATE SET quantidade=excluded.quantidade, expira_em_ms=excluded.expira_em_ms;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_limpeza_anexos_kanban(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.limpeza_anexos_kanban (id_limpeza_anexo_kanban,referencia_espaco,referencia_quadro,referencia_cartao) VALUES (alvo,objeto->>'path',objeto->>'board',objeto->>'task')
  ON CONFLICT(id_limpeza_anexo_kanban) DO UPDATE SET referencia_espaco=excluded.referencia_espaco, referencia_quadro=excluded.referencia_quadro, referencia_cartao=excluded.referencia_cartao;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_mensagens_sugestao(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.mensagens_sugestao (id_mensagem_sugestao,mensagem,remetente,criado_em) VALUES (alvo,objeto->>'text',objeto->>'senderId',objeto->>'createdAt')
  ON CONFLICT(id_mensagem_sugestao) DO UPDATE SET mensagem=excluded.mensagem, remetente=excluded.remetente, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_participantes_kanban(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.participantes_kanban (id_participante_kanban,referencia_quadro,id_usuario,email,nome,criado_em) VALUES (alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt')
  ON CONFLICT(id_participante_kanban) DO UPDATE SET referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_agenda(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_agenda (id_pedido_agenda,nome_turma,email,situacao,criado_em,revisado_em) VALUES (alvo,objeto->>'className',objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')
  ON CONFLICT(id_pedido_agenda) DO UPDATE SET nome_turma=excluded.nome_turma, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_kanban(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_kanban (id_pedido_kanban,referencia_quadro,id_usuario,email,nome,criado_em,situacao,alterado_em) VALUES (alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt',objeto->>'status',objeto->>'updatedAt')
  ON CONFLICT(id_pedido_kanban) DO UPDATE SET referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em, situacao=excluded.situacao, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_representacao(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.pedidos_representacao (id_pedido_representacao,nome_turma,email,situacao,criado_em,revisado_em) VALUES (alvo,objeto->>'turmaId',objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')
  ON CONFLICT(id_pedido_representacao) DO UPDATE SET nome_turma=excluded.nome_turma, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_administrativos(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.perfis_administrativos (id_perfil_administrativo,papel,nome_turma,criado_em) VALUES (alvo,objeto->>'role',objeto->>'turmaId',objeto->>'createdAt')
  ON CONFLICT(id_perfil_administrativo) DO UPDATE SET papel=excluded.papel, nome_turma=excluded.nome_turma, criado_em=excluded.criado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_comunidade(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.perfis_comunidade (id_perfil_comunidade,nome,empresa,nome_turma,sala,andar,url_foto,alterado_em) VALUES (alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')
  ON CONFLICT(id_perfil_comunidade) DO UPDATE SET nome=excluded.nome, empresa=excluded.empresa, nome_turma=excluded.nome_turma, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_preferencias_resumo(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.preferencias_resumo (id_preferencia_resumo,ativo,nome_turma,alterada_em_ms) VALUES (alvo,(objeto->>'enabled')::boolean,objeto->>'turmaId',(objeto->>'updatedAt')::bigint)
  ON CONFLICT(id_preferencia_resumo) DO UPDATE SET ativo=excluded.ativo, nome_turma=excluded.nome_turma, alterada_em_ms=excluded.alterada_em_ms;
END $function$;

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
      VALUES(grupo,pai,chave,(SELECT id_registro FROM tech2d.registros_aplicacao
        WHERE tipo=partes[1] AND referencia_pai='' AND referencia=pai AND pai<>''))
      ON CONFLICT(tipo,referencia_pai,referencia) DO UPDATE
      SET versao=registros_aplicacao.versao+1,atualizado_em=now(),id_registro_pai=excluded.id_registro_pai
      RETURNING id_registro INTO alvo;
      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data);
      IF pai='' AND grupo='feedback' THEN
        UPDATE tech2d.registros_aplicacao SET id_registro_pai=alvo
        WHERE tipo='feedback/messages'
          AND referencia_pai=chave AND id_registro_pai IS NULL;
      END IF;
    END IF;
  END LOOP;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_recorrencia(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.regras_recorrencia (id_regra_recorrencia,titulo,descricao,tipo_atividade,nome_disciplina,hora_atividade,nome_turma,criado_por,email_criador,criado_em,data_inicio,data_fim,ativa,excluida,intervalo_semanas,dias_semana) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',objeto->>'subject',(objeto->>'time')::time,objeto->>'turmaId',objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'startDate')::date,(objeto->>'endDate')::date,(objeto->>'active')::boolean,(objeto->>'deleted')::boolean,(objeto->>'intervalWeeks')::smallint,CASE WHEN jsonb_typeof(objeto->'weekdays')='array' THEN ARRAY(SELECT value::smallint FROM jsonb_array_elements_text(objeto->'weekdays') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END)
  ON CONFLICT(id_regra_recorrencia) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, nome_disciplina=excluded.nome_disciplina, hora_atividade=excluded.hora_atividade, nome_turma=excluded.nome_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, data_inicio=excluded.data_inicio, data_fim=excluded.data_fim, ativa=excluded.ativa, excluida=excluded.excluida, intervalo_semanas=excluded.intervalo_semanas, dias_semana=excluded.dias_semana;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_retencao(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.regras_retencao (id_regra_retencao,nome_turma,dias,ativa,alterado_por,alterado_em) VALUES (alvo,objeto->>'turmaId',(objeto->>'days')::smallint,(objeto->>'enabled')::boolean,objeto->>'updatedBy',objeto->>'updatedAt')
  ON CONFLICT(id_regra_retencao) DO UPDATE SET nome_turma=excluded.nome_turma, dias=excluded.dias, ativa=excluded.ativa, alterado_por=excluded.alterado_por, alterado_em=excluded.alterado_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_atividade(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.sugestoes_atividade (id_sugestao_atividade,titulo,descricao,tipo_atividade,nome_disciplina,data_atividade,hora_atividade,nome_turma,criado_em,alterado_em,situacao,resolucao,comentario_revisao,encerrada_em) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',objeto->>'subject',(objeto->>'date')::date,(objeto->>'time')::time,objeto->>'turmaId',objeto->>'createdAt',objeto->>'updatedAt',objeto->>'status',objeto->>'resolution',objeto->>'reviewComment',objeto->>'closedAt')
  ON CONFLICT(id_sugestao_atividade) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, nome_disciplina=excluded.nome_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, nome_turma=excluded.nome_turma, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em, situacao=excluded.situacao, resolucao=excluded.resolucao, comentario_revisao=excluded.comentario_revisao, encerrada_em=excluded.encerrada_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_melhoria(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.sugestoes_melhoria (id_sugestao_melhoria,mensagem,nome_turma,criado_por,email_criador,criado_em,credito_autorizado,nome_credito,situacao,concluida_em,concluida_por) VALUES (alvo,objeto->>'message',objeto->>'turmaId',objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'publicCreditAllowed')::boolean,objeto->>'publicCreditName',objeto->>'status',objeto->>'completedAt',objeto->>'completedBy')
  ON CONFLICT(id_sugestao_melhoria) DO UPDATE SET mensagem=excluded.mensagem, nome_turma=excluded.nome_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, credito_autorizado=excluded.credito_autorizado, nome_credito=excluded.nome_credito, situacao=excluded.situacao, concluida_em=excluded.concluida_em, concluida_por=excluded.concluida_por;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.gravar_turmas_agenda(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  INSERT INTO tech2d.turmas_agenda (id_turma_agenda,nome,ativa,referencia_pedido,aprovada_em) VALUES (alvo,objeto->>'name',(objeto->>'active')::boolean,objeto->>'requestId',objeto->>'approvedAt')
  ON CONFLICT(id_turma_agenda) DO UPDATE SET nome=excluded.nome, ativa=excluded.ativa, referencia_pedido=excluded.referencia_pedido, aprovada_em=excluded.aprovada_em;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.anexos_atividade (id_atividade,referencia,nome,tipo_mime,tamanho_bytes,chave_arquivo,enviado_em,enviado_por) VALUES (pai,objeto->>'id',objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'storagePath',objeto->>'uploadedAt',objeto->>'uploadedBy') RETURNING id_anexo_atividade INTO alvo;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.cartoes_kanban (id_quadro_kanban,ordem,referencia,referencia_coluna,titulo,descricao,prioridade,prazo,id_responsavel,etiquetas,referencias_atividades) VALUES (pai,posicao,objeto->>'id',objeto->>'columnId',objeto->>'title',objeto->>'description',objeto->>'priority',(objeto->>'dueDate')::date,objeto->>'assigneeId',CASE WHEN jsonb_typeof(objeto->'labels')='array' THEN ARRAY(SELECT value::varchar(30) FROM jsonb_array_elements_text(objeto->'labels') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END,CASE WHEN jsonb_typeof(objeto->'activityIds')='array' THEN ARRAY(SELECT value::varchar(128) FROM jsonb_array_elements_text(objeto->'activityIds') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END) RETURNING id_cartao_kanban INTO alvo;
  DELETE FROM tech2d.itens_checklist WHERE id_cartao_kanban=alvo;
  IF jsonb_typeof(objeto->'checklist')='array' THEN
    PERFORM tech2d.inserir_itens_checklist(alvo,(pos-1)::integer,value)
    FROM jsonb_array_elements(objeto->'checklist') WITH ORDINALITY AS x(value,pos);
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.colunas_kanban (id_quadro_kanban,ordem,referencia,nome,cor,concluida) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'done')::boolean) RETURNING id_coluna_kanban INTO alvo;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.itens_checklist (id_cartao_kanban,ordem,referencia,descricao,concluido) VALUES (pai,posicao,objeto->>'id',objeto->>'text',(objeto->>'done')::boolean) RETURNING id_item_checklist INTO alvo;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
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
END $function$;

CREATE OR REPLACE FUNCTION tech2d.ler_anexos_atividade(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'contentType', d.tipo_mime,
    'size', d.tamanho_bytes,
    'storagePath', d.chave_arquivo,
    'uploadedAt', d.enviado_em,
    'uploadedBy', d.enviado_por
  ))
  FROM tech2d.anexos_atividade d WHERE d.id_anexo_atividade=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_atividades(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo_atividade,
    'subject', d.nome_disciplina,
    'date', d.data_atividade,
    'time', to_char(d.hora_atividade,'HH24:MI'),
    'turmaId', d.nome_turma,
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'recurringId', d.referencia_recorrencia,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'attachments', (SELECT coalesce(jsonb_agg(tech2d.ler_anexos_atividade(r.id_anexo_atividade) ORDER BY r.id_anexo_atividade),'[]'::jsonb) FROM tech2d.anexos_atividade r WHERE r.id_atividade=d.id_atividade)
  ))
  FROM tech2d.atividades d WHERE d.id_atividade=alvo;
$function$;

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
    'checklist', (SELECT coalesce(jsonb_agg(tech2d.ler_itens_checklist(r.id_item_checklist) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.itens_checklist r WHERE r.id_cartao_kanban=d.id_cartao_kanban)
  ))
  FROM tech2d.cartoes_kanban d WHERE d.id_cartao_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_colunas_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'done', d.concluida
  ))
  FROM tech2d.colunas_kanban d WHERE d.id_coluna_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_entregas_resumo(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'status', d.situacao,
    'weekStart', d.inicio_semana,
    'createdAt', d.criada_em_ms,
    'completedAt', d.concluida_em_ms
  ))
  FROM tech2d.entregas_resumo d WHERE d.id_entrega_resumo=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_envios_anexos(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'activityId', d.referencia_atividade,
    'name', d.nome,
    'contentType', d.tipo_mime,
    'size', d.tamanho_bytes,
    'key', d.chave_arquivo,
    'uid', d.id_usuario,
    'createdAt', d.criado_em_ms
  ))
  FROM tech2d.envios_anexos d WHERE d.id_envio_anexo=alvo;
$function$;

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
    'boards', CASE WHEN r.tipo='personalKanban' THEN (SELECT coalesce(jsonb_agg(tech2d.ler_quadros_kanban(r.id_quadro_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban) END,
    'board', CASE WHEN r.tipo='sharedKanban' THEN (SELECT tech2d.ler_quadros_kanban(r.id_quadro_kanban) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban AND r.ordem=0) END
  ))
  FROM tech2d.espacos_kanban d JOIN tech2d.registros_aplicacao r ON r.id_registro=d.id_espaco_kanban WHERE d.id_espaco_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_horarios_aula(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object('professor',p.nome,'subject',d.nome,'className',t.nome,
    'startTime',to_char(f.hora_inicio,'HH24:MI'),'endTime',to_char(f.hora_fim,'HH24:MI'),'dayOfWeek',h.dia_semana,
    'active',h.ativo,'floor',h.andar,'roomDescription',h.sala,'createdAt',h.criado_em,'updatedAt',h.alterado_em))
  FROM tech2d.horarios_aula h
  JOIN tech2d.professores p ON p.id_professor=h.id_professor JOIN tech2d.disciplinas d ON d.id_disciplina=h.id_disciplina
  JOIN tech2d.turmas t ON t.id_turma=h.id_turma JOIN tech2d.faixas_horario f ON f.id_faixa_horario=h.id_faixa_horario
  WHERE h.id_registro_aplicacao=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_itens_checklist(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'text', d.descricao,
    'done', d.concluido
  ))
  FROM tech2d.itens_checklist d WHERE d.id_item_checklist=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_limites_servico(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'count', d.quantidade,
    'resetAt', d.expira_em_ms
  ))
  FROM tech2d.limites_servico d WHERE d.id_limite_servico=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_limpeza_anexos_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'path', d.referencia_espaco,
    'board', d.referencia_quadro,
    'task', d.referencia_cartao
  ))
  FROM tech2d.limpeza_anexos_kanban d WHERE d.id_limpeza_anexo_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_mensagens_sugestao(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'text', d.mensagem,
    'senderId', d.remetente,
    'createdAt', d.criado_em
  ))
  FROM tech2d.mensagens_sugestao d WHERE d.id_mensagem_sugestao=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_participantes_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'boardId', d.referencia_quadro,
    'userId', d.id_usuario,
    'userEmail', d.email,
    'name', d.nome,
    'createdAt', d.criado_em
  ))
  FROM tech2d.participantes_kanban d WHERE d.id_participante_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_pedidos_agenda(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'className', d.nome_turma,
    'email', d.email,
    'status', d.situacao,
    'createdAt', d.criado_em,
    'reviewedAt', d.revisado_em
  ))
  FROM tech2d.pedidos_agenda d WHERE d.id_pedido_agenda=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_pedidos_kanban(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'boardId', d.referencia_quadro,
    'userId', d.id_usuario,
    'userEmail', d.email,
    'name', d.nome,
    'createdAt', d.criado_em,
    'status', d.situacao,
    'updatedAt', d.alterado_em
  ))
  FROM tech2d.pedidos_kanban d WHERE d.id_pedido_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_pedidos_representacao(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'turmaId', d.nome_turma,
    'email', d.email,
    'status', d.situacao,
    'createdAt', d.criado_em,
    'reviewedAt', d.revisado_em
  ))
  FROM tech2d.pedidos_representacao d WHERE d.id_pedido_representacao=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_perfis_administrativos(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'role', d.papel,
    'turmaId', d.nome_turma,
    'createdAt', d.criado_em
  ))
  FROM tech2d.perfis_administrativos d WHERE d.id_perfil_administrativo=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_perfis_comunidade(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'displayName', d.nome,
    'company', d.empresa,
    'className', d.nome_turma,
    'room', d.sala,
    'floor', d.andar,
    'photoUrl', d.url_foto,
    'updatedAt', d.alterado_em
  ))
  FROM tech2d.perfis_comunidade d WHERE d.id_perfil_comunidade=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_preferencias_resumo(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'enabled', d.ativo,
    'turmaId', d.nome_turma,
    'updatedAt', d.alterada_em_ms
  ))
  FROM tech2d.preferencias_resumo d WHERE d.id_preferencia_resumo=alvo;
$function$;

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
    'columns', (SELECT coalesce(jsonb_agg(tech2d.ler_colunas_kanban(r.id_coluna_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.colunas_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban),
    'tasks', (SELECT coalesce(jsonb_agg(tech2d.ler_cartoes_kanban(r.id_cartao_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.cartoes_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban)
  ))
  FROM tech2d.quadros_kanban d WHERE d.id_quadro_kanban=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE tipo
    WHEN 'activities' THEN tech2d.ler_atividades(alvo)
    WHEN 'admins' THEN tech2d.ler_perfis_administrativos(alvo)
    WHEN 'recurringActivities' THEN tech2d.ler_regras_recorrencia(alvo)
    WHEN 'activityRetention' THEN tech2d.ler_regras_retencao(alvo)
    WHEN 'agendaClassRequests' THEN tech2d.ler_pedidos_agenda(alvo)
    WHEN 'agendaClasses' THEN tech2d.ler_turmas_agenda(alvo)
    WHEN 'representativeRequests' THEN tech2d.ler_pedidos_representacao(alvo)
    WHEN 'suggestions' THEN tech2d.ler_sugestoes_atividade(alvo)
    WHEN 'feedback' THEN tech2d.ler_sugestoes_melhoria(alvo)
    WHEN 'feedback/messages' THEN tech2d.ler_mensagens_sugestao(alvo)
    WHEN 'schedules' THEN tech2d.ler_horarios_aula(alvo)
    WHEN 'userProfiles' THEN tech2d.ler_perfis_comunidade(alvo)
    WHEN '_agendaDigestPreferences' THEN tech2d.ler_preferencias_resumo(alvo)
    WHEN '_agendaDigestDeliveries' THEN tech2d.ler_entregas_resumo(alvo)
    WHEN '_agendaUploads' THEN tech2d.ler_envios_anexos(alvo)
    WHEN '_passwordResetLimits' THEN tech2d.ler_limites_servico(alvo)
    WHEN '_r2UploadLimits' THEN tech2d.ler_limites_servico(alvo)
    WHEN '_profilePhotoLimits' THEN tech2d.ler_limites_servico(alvo)
    WHEN 'personalKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'sharedKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'kanbanMemberships' THEN tech2d.ler_participantes_kanban(alvo)
    WHEN 'kanbanRequests' THEN tech2d.ler_pedidos_kanban(alvo)
    WHEN '_kanbanFileCleanup' THEN tech2d.ler_limpeza_anexos_kanban(alvo)
    ELSE NULL END;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_regras_recorrencia(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo_atividade,
    'subject', d.nome_disciplina,
    'time', to_char(d.hora_atividade,'HH24:MI'),
    'turmaId', d.nome_turma,
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'createdAt', d.criado_em,
    'startDate', d.data_inicio,
    'endDate', d.data_fim,
    'active', d.ativa,
    'deleted', d.excluida,
    'intervalWeeks', d.intervalo_semanas,
    'weekdays', d.dias_semana
  ))
  FROM tech2d.regras_recorrencia d WHERE d.id_regra_recorrencia=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_regras_retencao(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'turmaId', d.nome_turma,
    'days', d.dias,
    'enabled', d.ativa,
    'updatedBy', d.alterado_por,
    'updatedAt', d.alterado_em
  ))
  FROM tech2d.regras_retencao d WHERE d.id_regra_retencao=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_sugestoes_atividade(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo_atividade,
    'subject', d.nome_disciplina,
    'date', d.data_atividade,
    'time', to_char(d.hora_atividade,'HH24:MI'),
    'turmaId', d.nome_turma,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'status', d.situacao,
    'resolution', d.resolucao,
    'reviewComment', d.comentario_revisao,
    'closedAt', d.encerrada_em
  ))
  FROM tech2d.sugestoes_atividade d WHERE d.id_sugestao_atividade=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'message', d.mensagem,
    'turmaId', d.nome_turma,
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'createdAt', d.criado_em,
    'publicCreditAllowed', d.credito_autorizado,
    'publicCreditName', d.nome_credito,
    'status', d.situacao,
    'completedAt', d.concluida_em,
    'completedBy', d.concluida_por
  ))
  FROM tech2d.sugestoes_melhoria d WHERE d.id_sugestao_melhoria=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.ler_turmas_agenda(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'name', d.nome,
    'active', d.ativa,
    'requestId', d.referencia_pedido,
    'approvedAt', d.aprovada_em
  ))
  FROM tech2d.turmas_agenda d WHERE d.id_turma_agenda=alvo;
$function$;

CREATE OR REPLACE FUNCTION tech2d.padronizar_listas_registro(tipo character varying, objeto jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'pg_catalog'
AS $function$
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
END $function$;

CREATE OR REPLACE FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE WHEN pai='' THEN tipo || '/' || referencia
    ELSE split_part(tipo,'/',1) || '/' || pai || '/' || split_part(tipo,'/',2) || '/' || referencia END;
$function$;

CREATE OR REPLACE FUNCTION tech2d.remover_nulos_raiz(objeto jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog'
AS $function$
  SELECT coalesce(jsonb_object_agg(key,value),'{}'::jsonb)
  FROM jsonb_each(objeto) WHERE value <> 'null'::jsonb;
$function$;

CREATE OR REPLACE FUNCTION tech2d.remover_nulos_recursivo(valor jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE resultado jsonb;
BEGIN
  IF valor IS NULL THEN RETURN NULL; END IF;
  CASE jsonb_typeof(valor)
    WHEN 'object' THEN
      SELECT coalesce(jsonb_object_agg(chave, tech2d.remover_nulos_recursivo(conteudo)), '{}'::jsonb)
        INTO resultado FROM jsonb_each(valor) AS item(chave, conteudo)
        WHERE conteudo <> 'null'::jsonb;
      RETURN resultado;
    WHEN 'array' THEN
      SELECT coalesce(jsonb_agg(tech2d.remover_nulos_recursivo(conteudo) ORDER BY ordem), '[]'::jsonb)
        INTO resultado FROM jsonb_array_elements(valor) WITH ORDINALITY AS item(conteudo, ordem);
      RETURN resultado;
    ELSE RETURN valor;
  END CASE;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE tipos varchar[]; revisao varchar(32);
BEGIN
 CASE catalogo
  WHEN 'agenda' THEN tipos:=ARRAY['activities','agendaClasses'];
  WHEN 'updates' THEN tipos:=ARRAY['agendaClasses'];
  WHEN 'schedules' THEN tipos:=ARRAY['schedules'];
  ELSE RAISE EXCEPTION 'Catálogo inválido' USING ERRCODE='22023';
 END CASE;
 SELECT md5(coalesce(string_agg(id_registro::text || ':' || versao::text, ',' ORDER BY id_registro),'')) INTO revisao
 FROM tech2d.registros_aplicacao WHERE tipo=ANY(tipos);
 RETURN revisao;
END $function$;

CREATE OR REPLACE FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'pg_catalog'
AS $function$
  INSERT INTO tech2d.disciplinas_series (id_disciplina, ano_serie)
  SELECT COALESCE(canonica.id_disciplina, disciplina.id_disciplina), left(turma.nome, 1)::smallint
  FROM tech2d.turmas turma
  JOIN tech2d.disciplinas disciplina ON disciplina.id_disciplina = disciplina_id
  LEFT JOIN tech2d.disciplinas canonica ON canonica.nome = CASE disciplina.nome
    WHEN 'Desenvolvimento Aplicação Dinâmica' THEN 'Desenvolvimento de Aplicação Dinâmica'
    WHEN 'Engenharia e Qualidade de Software' THEN 'Engenharia e Qualidae de Software'
    WHEN 'Língua Portuguesa e suas Literaturas' THEN 'Língua Portuguesa e Suas Literaturas'
    WHEN 'Matemática 9-Banco de Dados' THEN 'Matemática 9-Banco de dados'
    WHEN 'Língua Inglesa' THEN 'Lingua inglesa'
    WHEN 'Lingua Inglêsa' THEN 'Lingua inglesa'
    WHEN 'Biologia 2-ESG-Environment, Social and Governance' THEN 'Biologia 2 - ESG'
    WHEN 'Matemática 14 - Inteligência Artificial' THEN 'Matemática 14-Inteligência Artificial'
    ELSE disciplina.nome
  END
  WHERE turma.id_turma = turma_id AND turma.nome ~ '^[123]º Tec '
  ON CONFLICT DO NOTHING;
$function$;

CREATE OR REPLACE FUNCTION tech2d.vincular_nova_disciplina_notaki()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  PERFORM tech2d.vincular_disciplina_notaki(NEW.id_turma, NEW.id_disciplina);
  RETURN NEW;
END;
$function$;

-- Os nomes das constraints são derivados das colunas reais, sem substituir partes de outras FKs.
DO $names$
DECLARE obj record; novo varchar(128);
BEGIN
 FOR obj IN
  SELECT c.oid,c.conrelid,c.conname,c.contype,r.relname,
    (SELECT string_agg(a.attname,'_' ORDER BY k.pos) FROM unnest(c.conkey) WITH ORDINALITY k(num,pos) JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.num) AS colunas
  FROM pg_constraint c JOIN pg_class r ON r.oid=c.conrelid JOIN pg_namespace n ON n.oid=r.relnamespace
  WHERE n.nspname='tech2d' AND c.contype IN ('f','u','c') AND (
(r.relname='anexos_atividade' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_anexo_atividade')))
 OR (r.relname='atividades' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_atividade','nome_turma','nome_disciplina','data_atividade','hora_atividade','tipo_atividade')))
 OR (r.relname='cartoes_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_cartao_kanban')))
 OR (r.relname='colunas_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_coluna_kanban')))
 OR (r.relname='disciplinas' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_disciplina')))
 OR (r.relname='entregas_resumo' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_entrega_resumo')))
 OR (r.relname='envios_anexos' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_envio_anexo')))
 OR (r.relname='espacos_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_espaco_kanban')))
 OR (r.relname='faixas_horario' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_faixa_horario')))
 OR (r.relname='horarios_aula' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_horario_aula','id_registro_aplicacao')))
 OR (r.relname='itens_checklist' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_item_checklist')))
 OR (r.relname='limites_servico' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_limite_servico')))
 OR (r.relname='limpeza_anexos_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_limpeza_anexo_kanban')))
 OR (r.relname='mensagens_sugestao' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_mensagem_sugestao')))
 OR (r.relname='participantes_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_participante_kanban')))
 OR (r.relname='pedidos_agenda' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_pedido_agenda')))
 OR (r.relname='pedidos_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_pedido_kanban')))
 OR (r.relname='pedidos_representacao' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_pedido_representacao','nome_turma')))
 OR (r.relname='perfis_administrativos' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_perfil_administrativo','nome_turma')))
 OR (r.relname='perfis_comunidade' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_perfil_comunidade','nome_turma')))
 OR (r.relname='preferencias_resumo' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_preferencia_resumo','nome_turma')))
 OR (r.relname='professores' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_professor')))
 OR (r.relname='quadros_kanban' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_quadro_kanban')))
 OR (r.relname='recibos_gravacao' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_recibo_gravacao')))
 OR (r.relname='registros_aplicacao' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_registro')))
 OR (r.relname='regras_recorrencia' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_regra_recorrencia','nome_turma','nome_disciplina','hora_atividade','tipo_atividade','data_inicio','data_fim')))
 OR (r.relname='regras_retencao' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_regra_retencao','nome_turma')))
 OR (r.relname='sugestoes_atividade' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_sugestao_atividade','nome_turma','nome_disciplina','data_atividade','hora_atividade','tipo_atividade')))
 OR (r.relname='sugestoes_melhoria' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_sugestao_melhoria','nome_turma')))
 OR (r.relname='turmas' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_turma')))
 OR (r.relname='turmas_agenda' AND EXISTS(SELECT FROM pg_attribute z WHERE z.attrelid=c.conrelid AND z.attnum=ANY(c.conkey) AND z.attname IN ('id_turma_agenda'))))
 LOOP
  novo:=obj.relname||'_'||obj.colunas||'_'||CASE obj.contype WHEN 'f' THEN 'fkey' WHEN 'u' THEN 'key' ELSE 'check' END;
  IF length(novo)>63 THEN novo:=left(novo,54)||'_'||left(md5(obj.conname),8); END IF;
  IF EXISTS(SELECT FROM pg_constraint c WHERE c.conrelid=obj.conrelid AND c.conname=novo AND c.oid<>obj.oid) THEN novo:=left(novo,54)||'_'||left(md5(obj.conname),8); END IF;
  IF novo<>obj.conname THEN EXECUTE format('ALTER TABLE tech2d.%I RENAME CONSTRAINT %I TO %I',obj.relname,obj.conname,novo); END IF;
 END LOOP;
END
$names$;
COMMENT ON COLUMN tech2d.anexos_atividade.id_anexo_atividade IS 'Identificador numérico de anexos_atividade. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.atividades.id_atividade IS 'Identificador de atividades, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.cartoes_kanban.id_cartao_kanban IS 'Identificador numérico de cartoes_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.colunas_kanban.id_coluna_kanban IS 'Identificador numérico de colunas_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.disciplinas.id_disciplina IS 'Identificador numérico de disciplinas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.entregas_resumo.id_entrega_resumo IS 'Identificador de entregas_resumo, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.envios_anexos.id_envio_anexo IS 'Identificador de envios_anexos, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.espacos_kanban.id_espaco_kanban IS 'Identificador de espacos_kanban, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.faixas_horario.id_faixa_horario IS 'Identificador numérico de faixas_horario. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.horarios_aula.id_horario_aula IS 'Identificador textual do horário de aula, preservado nos links e no contrato da API. id_registro_aplicacao identifica separadamente o registro interno.';
COMMENT ON COLUMN tech2d.itens_checklist.id_item_checklist IS 'Identificador numérico de itens_checklist. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.limites_servico.id_limite_servico IS 'Identificador de limites_servico, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.limpeza_anexos_kanban.id_limpeza_anexo_kanban IS 'Identificador de limpeza_anexos_kanban, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.mensagens_sugestao.id_mensagem_sugestao IS 'Identificador de mensagens_sugestao, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.participantes_kanban.id_participante_kanban IS 'Identificador de participantes_kanban, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.pedidos_agenda.id_pedido_agenda IS 'Identificador de pedidos_agenda, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.pedidos_kanban.id_pedido_kanban IS 'Identificador de pedidos_kanban, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.pedidos_representacao.id_pedido_representacao IS 'Identificador de pedidos_representacao, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.perfis_administrativos.id_perfil_administrativo IS 'Identificador de perfis_administrativos, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.perfis_comunidade.id_perfil_comunidade IS 'Identificador de perfis_comunidade, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.preferencias_resumo.id_preferencia_resumo IS 'Identificador de preferencias_resumo, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.professores.id_professor IS 'Identificador numérico de professores. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.quadros_kanban.id_quadro_kanban IS 'Identificador numérico de quadros_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.recibos_gravacao.id_recibo_gravacao IS 'Identificador externo do lote confirmado, recebido em commit.id. O valor continua estável nos reenvios e é exposto como id pela view de recibos.';
COMMENT ON COLUMN tech2d.registros_aplicacao.id_registro IS 'Identificador numérico do registro da aplicação. As tabelas de negócio referenciam esta chave usando nomes específicos de cada entidade.';
COMMENT ON COLUMN tech2d.regras_recorrencia.id_regra_recorrencia IS 'Identificador de regras_recorrencia, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.regras_retencao.id_regra_retencao IS 'Identificador de regras_retencao, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.sugestoes_atividade.id_sugestao_atividade IS 'Identificador de sugestoes_atividade, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_sugestao_melhoria IS 'Identificador de sugestoes_melhoria, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
COMMENT ON COLUMN tech2d.turmas.id_turma IS 'Identificador numérico de turmas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';
COMMENT ON COLUMN tech2d.turmas_agenda.id_turma_agenda IS 'Identificador de turmas_agenda, simultaneamente PK e FK para registros_aplicacao.id_registro. Compartilha o valor do registro da aplicação; a referência pública usada pelos links permanece separada.';
DO $comments$
DECLARE obj record; texto varchar(4000);
BEGIN
 FOR obj IN SELECT c.relname,a.attname,col_description(c.oid,a.attnum) AS descricao FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid WHERE n.nspname='tech2d' AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped AND col_description(c.oid,a.attnum) IS NOT NULL LOOP
  texto:=obj.descricao;
  texto:=regexp_replace(texto,'anexos_atividade\.id\M','anexos_atividade.id_anexo_atividade','g');
  texto:=regexp_replace(texto,'atividades\.id_registro\M','atividades.id_atividade','g');
  texto:=regexp_replace(texto,'atividades\.turma\M','atividades.nome_turma','g');
  texto:=regexp_replace(texto,'atividades\.disciplina\M','atividades.nome_disciplina','g');
  texto:=regexp_replace(texto,'atividades\.data\M','atividades.data_atividade','g');
  texto:=regexp_replace(texto,'atividades\.hora\M','atividades.hora_atividade','g');
  texto:=regexp_replace(texto,'atividades\.tipo\M','atividades.tipo_atividade','g');
  texto:=regexp_replace(texto,'cartoes_kanban\.id\M','cartoes_kanban.id_cartao_kanban','g');
  texto:=regexp_replace(texto,'colunas_kanban\.id\M','colunas_kanban.id_coluna_kanban','g');
  texto:=regexp_replace(texto,'disciplinas\.id\M','disciplinas.id_disciplina','g');
  texto:=regexp_replace(texto,'entregas_resumo\.id_registro\M','entregas_resumo.id_entrega_resumo','g');
  texto:=regexp_replace(texto,'envios_anexos\.id_registro\M','envios_anexos.id_envio_anexo','g');
  texto:=regexp_replace(texto,'espacos_kanban\.id_registro\M','espacos_kanban.id_espaco_kanban','g');
  texto:=regexp_replace(texto,'faixas_horario\.id\M','faixas_horario.id_faixa_horario','g');
  texto:=regexp_replace(texto,'horarios_aula\.id\M','horarios_aula.id_horario_aula','g');
  texto:=regexp_replace(texto,'horarios_aula\.id_registro\M','horarios_aula.id_registro_aplicacao','g');
  texto:=regexp_replace(texto,'itens_checklist\.id\M','itens_checklist.id_item_checklist','g');
  texto:=regexp_replace(texto,'limites_servico\.id_registro\M','limites_servico.id_limite_servico','g');
  texto:=regexp_replace(texto,'limpeza_anexos_kanban\.id_registro\M','limpeza_anexos_kanban.id_limpeza_anexo_kanban','g');
  texto:=regexp_replace(texto,'mensagens_sugestao\.id_registro\M','mensagens_sugestao.id_mensagem_sugestao','g');
  texto:=regexp_replace(texto,'participantes_kanban\.id_registro\M','participantes_kanban.id_participante_kanban','g');
  texto:=regexp_replace(texto,'pedidos_agenda\.id_registro\M','pedidos_agenda.id_pedido_agenda','g');
  texto:=regexp_replace(texto,'pedidos_kanban\.id_registro\M','pedidos_kanban.id_pedido_kanban','g');
  texto:=regexp_replace(texto,'pedidos_representacao\.id_registro\M','pedidos_representacao.id_pedido_representacao','g');
  texto:=regexp_replace(texto,'pedidos_representacao\.turma\M','pedidos_representacao.nome_turma','g');
  texto:=regexp_replace(texto,'perfis_administrativos\.id_registro\M','perfis_administrativos.id_perfil_administrativo','g');
  texto:=regexp_replace(texto,'perfis_administrativos\.turma\M','perfis_administrativos.nome_turma','g');
  texto:=regexp_replace(texto,'perfis_comunidade\.id_registro\M','perfis_comunidade.id_perfil_comunidade','g');
  texto:=regexp_replace(texto,'perfis_comunidade\.turma\M','perfis_comunidade.nome_turma','g');
  texto:=regexp_replace(texto,'preferencias_resumo\.id_registro\M','preferencias_resumo.id_preferencia_resumo','g');
  texto:=regexp_replace(texto,'preferencias_resumo\.turma\M','preferencias_resumo.nome_turma','g');
  texto:=regexp_replace(texto,'professores\.id\M','professores.id_professor','g');
  texto:=regexp_replace(texto,'quadros_kanban\.id\M','quadros_kanban.id_quadro_kanban','g');
  texto:=regexp_replace(texto,'recibos_gravacao\.id\M','recibos_gravacao.id_recibo_gravacao','g');
  texto:=regexp_replace(texto,'registros_aplicacao\.id\M','registros_aplicacao.id_registro','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.id_registro\M','regras_recorrencia.id_regra_recorrencia','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.turma\M','regras_recorrencia.nome_turma','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.disciplina\M','regras_recorrencia.nome_disciplina','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.hora\M','regras_recorrencia.hora_atividade','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.tipo\M','regras_recorrencia.tipo_atividade','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.inicio\M','regras_recorrencia.data_inicio','g');
  texto:=regexp_replace(texto,'regras_recorrencia\.fim\M','regras_recorrencia.data_fim','g');
  texto:=regexp_replace(texto,'regras_retencao\.id_registro\M','regras_retencao.id_regra_retencao','g');
  texto:=regexp_replace(texto,'regras_retencao\.turma\M','regras_retencao.nome_turma','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.id_registro\M','sugestoes_atividade.id_sugestao_atividade','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.turma\M','sugestoes_atividade.nome_turma','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.disciplina\M','sugestoes_atividade.nome_disciplina','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.data\M','sugestoes_atividade.data_atividade','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.hora\M','sugestoes_atividade.hora_atividade','g');
  texto:=regexp_replace(texto,'sugestoes_atividade\.tipo\M','sugestoes_atividade.tipo_atividade','g');
  texto:=regexp_replace(texto,'sugestoes_melhoria\.id_registro\M','sugestoes_melhoria.id_sugestao_melhoria','g');
  texto:=regexp_replace(texto,'sugestoes_melhoria\.turma\M','sugestoes_melhoria.nome_turma','g');
  texto:=regexp_replace(texto,'turmas\.id\M','turmas.id_turma','g');
  texto:=regexp_replace(texto,'turmas_agenda\.id_registro\M','turmas_agenda.id_turma_agenda','g');
  IF texto<>obj.descricao THEN EXECUTE format('COMMENT ON COLUMN tech2d.%I.%I IS %L',obj.relname,obj.attname,texto); END IF;
 END LOOP;
END
$comments$;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:047_nomenclatura_colunas';

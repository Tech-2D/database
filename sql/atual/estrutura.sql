--
-- PostgreSQL database dump
--

\restrict Tech2dSchemaExport

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tech2d; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tech2d;


--
-- Name: SCHEMA tech2d; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:078_classificar_provas_recuperacao';


--
-- Name: buscar_id_turma(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.buscar_id_turma(valor text) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT id_turma FROM tech2d.turmas WHERE referencia_agenda=valor OR nome=valor
 ORDER BY (referencia_agenda=valor) DESC NULLS LAST LIMIT 1;
$$;


--
-- Name: FUNCTION buscar_id_turma(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.buscar_id_turma(valor text) IS 'Busca sem gravar o ID de uma turma por referência estável da Agenda ou nome do catálogo. Usada nas consultas indexadas do calendário.';


--
-- Name: chave_turma(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.chave_turma(valor text) RETURNS character varying
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT tech2d.normalizar_rotulo(regexp_replace(replace(upper(valor),'TECH','TEC'),'\mANO\M','','g'));
$$;


--
-- Name: FUNCTION chave_turma(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.chave_turma(valor text) IS 'Permite comparar rótulos da mesma turma, como 2° TECH D e 2º Tec D, sem criar outra turma.';


--
-- Name: consultar_catalogo_agenda(text, boolean); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) RETURNS TABLE(activities jsonb, documents jsonb)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  WITH atividades_selecionadas AS (
    SELECT v.*
    FROM tech2d.atividades filtro
    JOIN tech2d.visao_atividades v ON v.id=filtro.referencia_api
    WHERE p_incluir_atividades
      AND (p_turma IS NULL OR filtro.id_turma = tech2d.buscar_id_turma(p_turma) OR filtro.id_turma IS NULL)
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
$$;


--
-- Name: FUNCTION consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) IS 'Seleciona atividades gerais e da turma e reúne os documentos do catálogo em uma consulta limitada.';


--
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


--
-- Name: gravar_conteudo(bigint, character varying, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_conteudo(alvo bigint, tipo character varying, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  turma_vinculada text;
BEGIN
  IF jsonb_typeof(objeto) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Objeto de registro invÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡lido' USING ERRCODE='check_violation';
  END IF;
  objeto := tech2d.padronizar_listas_registro(tipo,tech2d.remover_nulos_recursivo(objeto));
  IF tipo='recurringActivities' THEN
    objeto := objeto - 'createdByEmail' - 'deleted';
  ELSIF tipo='userProfiles' THEN
    SELECT turma INTO turma_vinculada FROM tech2d.vinculos_turma_perfil WHERE firebase_uid=chave_api;
    IF FOUND THEN
      objeto := jsonb_set(objeto, '{className}', to_jsonb(turma_vinculada));
    END IF;
  END IF;
  CASE tipo
    WHEN 'activities' THEN PERFORM tech2d.gravar_atividades(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'admins' THEN PERFORM tech2d.gravar_perfis_administrativos(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'recurringActivities' THEN PERFORM tech2d.gravar_regras_recorrencia(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'activityRetention' THEN PERFORM tech2d.gravar_regras_retencao(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'agendaClasses' THEN PERFORM tech2d.gravar_turmas_agenda(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'feedback' THEN PERFORM tech2d.gravar_sugestoes_melhoria(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'schedules' THEN PERFORM tech2d.gravar_horarios_aula(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'userProfiles' THEN PERFORM tech2d.gravar_perfis(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN '_agendaDigestPreferences' THEN PERFORM tech2d.gravar_resumo_perfil(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'personalKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'sharedKanban' THEN PERFORM tech2d.gravar_espacos_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    WHEN 'kanbanMemberships' THEN PERFORM tech2d.gravar_participantes_kanban(alvo,objeto,chave_api,compartilhado_api,pai_api,id_pai_api);
    ELSE RAISE EXCEPTION 'Tipo de registro desconhecido' USING ERRCODE='check_violation';
  END CASE;
  IF tech2d.ler_registro(alvo,tipo) IS DISTINCT FROM objeto THEN
    RAISE EXCEPTION 'Registro incompatÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­vel com as colunas de %',tipo USING ERRCODE='check_violation';
  END IF;
END $$;


--
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


--
-- Name: gravar_horarios_aula(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_horarios_aula(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  inicio time;
  fim time;
  turma_catalogo bigint;
  disciplina_catalogo bigint;
  professor_catalogo bigint;
  nome_professor text;
  chave_professor text;
BEGIN
  IF ((objeto->>'startTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'endTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'dayOfWeek') ~ '^[0-6]$'
    AND jsonb_typeof(objeto->'active')='boolean') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Invalid schedule projection' USING ERRCODE='check_violation';
  END IF;
  inicio := (objeto->>'startTime')::time;
  fim := (objeto->>'endTime')::time;
  nome_professor := btrim(regexp_replace(objeto->>'professor', '[[:space:]]+', ' ', 'g'));
  chave_professor := lower(nome_professor);
  PERFORM pg_advisory_xact_lock(hashtext('tech2d-professor'), hashtext(chave_professor));
  SELECT id_professor INTO professor_catalogo
  FROM tech2d.professores
  WHERE lower(btrim(regexp_replace(nome, '[[:space:]]+', ' ', 'g'))) = chave_professor
  ORDER BY (nome = nome_professor) DESC, id_professor
  LIMIT 1;
  IF professor_catalogo IS NULL THEN
    INSERT INTO tech2d.professores(nome) VALUES (nome_professor)
    ON CONFLICT(nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id_professor INTO professor_catalogo;
  END IF;
  disciplina_catalogo:=tech2d.resolver_disciplina(objeto->>'subject');
  turma_catalogo:=tech2d.resolver_turma(objeto->>'className',false);
  INSERT INTO tech2d.faixas_horario(hora_inicio,hora_fim) VALUES(inicio,fim) ON CONFLICT(hora_inicio,hora_fim) DO NOTHING;
  INSERT INTO tech2d.horarios_aula (versao,atualizado_em,id_horario_aula,id_horario_interno,id_professor,id_disciplina,id_turma,id_faixa_horario,dia_semana,ativo,andar,sala,criado_em,alterado_em)
  SELECT 1,now(),chave_api,alvo,professor_catalogo,d.id_disciplina,t.id_turma,f.id_faixa_horario,(objeto->>'dayOfWeek')::smallint,(objeto->>'active')::boolean,
    objeto->>'floor',objeto->>'roomDescription',objeto->>'createdAt',objeto->>'updatedAt'
  FROM tech2d.disciplinas d,tech2d.turmas t,tech2d.faixas_horario f
  WHERE d.id_disciplina=disciplina_catalogo AND t.id_turma=turma_catalogo
    AND f.hora_inicio=inicio AND f.hora_fim=fim
  ON CONFLICT(id_horario_aula) DO UPDATE SET versao=horarios_aula.versao+1, atualizado_em=excluded.atualizado_em, id_horario_interno=excluded.id_horario_interno,id_professor=excluded.id_professor,
    id_disciplina=excluded.id_disciplina,id_turma=excluded.id_turma,id_faixa_horario=excluded.id_faixa_horario,
    dia_semana=excluded.dia_semana,ativo=excluded.ativo,andar=excluded.andar,sala=excluded.sala,
    criado_em=excluded.criado_em,alterado_em=excluded.alterado_em;
END $_$;


--
-- Name: gravar_participantes_kanban(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_participantes_kanban(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.participantes_kanban (versao,atualizado_em,referencia_api,id_participante_kanban,referencia_quadro,id_usuario,email,nome,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt')
  ON CONFLICT(id_participante_kanban) DO UPDATE SET versao=participantes_kanban.versao+1, atualizado_em=excluded.atualizado_em, referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em;
END $$;


--
-- Name: gravar_perfis(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_perfis(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.perfis (versao,atualizado_em,referencia_api,id_perfil,nome,empresa,turma_informada,sala,andar,url_foto,alterado_em) VALUES (1,now(),chave_api,alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')
  ON CONFLICT(id_perfil) DO UPDATE SET versao=coalesce(perfis.versao,0)+1, atualizado_em=excluded.atualizado_em, nome=excluded.nome, empresa=excluded.empresa, turma_informada=excluded.turma_informada, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;
END $$;


--
-- Name: gravar_perfis_administrativos(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_perfis_administrativos(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.perfis_administrativos (versao,atualizado_em,referencia_api,id_perfil_administrativo,papel,id_turma,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'role',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt')
  ON CONFLICT(id_perfil_administrativo) DO UPDATE SET versao=perfis_administrativos.versao+1, atualizado_em=excluded.atualizado_em, papel=excluded.papel, id_turma=excluded.id_turma, criado_em=excluded.criado_em;
END $$;


--
-- Name: gravar_registros(jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_registros(lote jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  item record;
  partes text[];
  grupo varchar(40);
  pai varchar(320);
  chave varchar(320);
  tabela name;
  coluna_id name;
  alvo bigint;
  id_pai bigint;
  espaco_compartilhado boolean;
BEGIN
  PERFORM tech2d.travar_gravacao(ARRAY(SELECT item_lote->>'path' FROM jsonb_array_elements(lote) AS item_lote));
  FOR item IN SELECT r.path,r.data FROM jsonb_to_recordset(lote) AS r(path text,data jsonb)
    ORDER BY (data IS NULL), CASE WHEN path LIKE 'recurringActivities/%' THEN 0 ELSE 1 END,length(path),path
  LOOP
    partes := string_to_array(item.path,'/');
    IF cardinality(partes) <> 2 OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'ReferÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âªncia invÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡lida' USING ERRCODE='23514';
    END IF;
    grupo := partes[1]; pai := ''; chave := partes[2]; id_pai := NULL;
    CASE grupo
      WHEN 'activities' THEN tabela := 'atividades'; coluna_id := 'id_atividade';
      WHEN 'admins' THEN tabela := 'perfis_administrativos'; coluna_id := 'id_perfil_administrativo';
      WHEN 'recurringActivities' THEN tabela := 'regras_recorrencia'; coluna_id := 'id_regra_recorrencia';
      WHEN 'activityRetention' THEN tabela := 'regras_retencao'; coluna_id := 'id_regra_retencao';
      WHEN 'agendaClasses' THEN tabela := 'turmas_agenda'; coluna_id := 'id_turma_agenda';
      WHEN 'feedback' THEN tabela := 'sugestoes_melhoria'; coluna_id := 'id_sugestao_melhoria';
      WHEN 'schedules' THEN tabela := 'horarios_aula'; coluna_id := 'id_horario_interno';
      WHEN 'userProfiles' THEN tabela := 'perfis'; coluna_id := 'id_perfil';
      WHEN '_agendaDigestPreferences' THEN tabela := 'perfis'; coluna_id := 'id_perfil';
      WHEN 'personalKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      WHEN 'kanbanMemberships' THEN tabela := 'participantes_kanban'; coluna_id := 'id_participante_kanban';
      WHEN 'sharedKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      ELSE RAISE EXCEPTION 'Recurso descontinuado ou desconhecido' USING ERRCODE='23514';
    END CASE;
    espaco_compartilhado := grupo='sharedKanban';
    IF tabela='espacos_kanban' THEN
      SELECT id_espaco_kanban INTO alvo FROM tech2d.espacos_kanban AS e
      WHERE e.compartilhado=espaco_compartilhado AND e.referencia_api=chave;
    ELSIF grupo='schedules' THEN
      SELECT id_horario_interno INTO alvo FROM tech2d.horarios_aula WHERE id_horario_aula=chave;
    ELSE
      EXECUTE format('SELECT %I FROM tech2d.%I WHERE referencia_api=$1',coluna_id,tabela) INTO alvo USING chave;
    END IF;
    IF item.data IS NULL THEN
      IF alvo IS NOT NULL THEN
        IF grupo='userProfiles' AND EXISTS(SELECT 1 FROM tech2d.perfis WHERE id_perfil=alvo AND resumo_versao IS NOT NULL) THEN
          UPDATE tech2d.perfis SET nome=NULL,empresa=NULL,turma_informada=NULL,sala=NULL,andar=NULL,url_foto=NULL,alterado_em=NULL,versao=NULL,atualizado_em=NULL WHERE id_perfil=alvo;
        ELSIF grupo='_agendaDigestPreferences' AND EXISTS(SELECT 1 FROM tech2d.perfis WHERE id_perfil=alvo AND versao IS NOT NULL) THEN
          UPDATE tech2d.perfis SET resumo_semanal_ativo=NULL,id_turma_resumo=NULL,resumo_alterado_em_ms=NULL,resumo_versao=NULL,resumo_atualizado_em=NULL WHERE id_perfil=alvo;
        ELSE
          EXECUTE format('DELETE FROM tech2d.%I WHERE %I=$1',tabela,coluna_id) USING alvo;
        END IF;
      END IF;
    ELSE
      IF alvo IS NULL THEN alvo := nextval('tech2d.ids_entidades'); END IF;
      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data,chave,espaco_compartilhado,pai,id_pai);
    END IF;
  END LOOP;
END
$_$;


--
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


--
-- Name: gravar_regras_retencao(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_regras_retencao(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.regras_retencao (versao,atualizado_em,referencia_api,id_regra_retencao,id_turma,dias,ativa,alterado_por,alterado_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'days')::smallint,(objeto->>'enabled')::boolean,objeto->>'updatedBy',objeto->>'updatedAt')
  ON CONFLICT(id_regra_retencao) DO UPDATE SET versao=regras_retencao.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, dias=excluded.dias, ativa=excluded.ativa, alterado_por=excluded.alterado_por, alterado_em=excluded.alterado_em;
END $$;


--
-- Name: gravar_resumo_perfil(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_resumo_perfil(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
 INSERT INTO tech2d.perfis(id_perfil,referencia_api,resumo_semanal_ativo,id_turma_resumo,resumo_alterado_em_ms,resumo_versao,resumo_atualizado_em)
 VALUES(alvo,chave_api,(objeto->>'enabled')::boolean,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'updatedAt')::bigint,1,now())
 ON CONFLICT(id_perfil) DO UPDATE SET resumo_semanal_ativo=excluded.resumo_semanal_ativo,id_turma_resumo=excluded.id_turma_resumo,resumo_alterado_em_ms=excluded.resumo_alterado_em_ms,resumo_versao=coalesce(perfis.resumo_versao,0)+1,resumo_atualizado_em=excluded.resumo_atualizado_em;
END $$;


--
-- Name: gravar_sugestoes_melhoria(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_sugestoes_melhoria(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.sugestoes_melhoria (versao,atualizado_em,referencia_api,id_sugestao_melhoria,mensagem,id_turma,criado_por,email_criador,criado_em,credito_autorizado,nome_credito,situacao,concluida_em,concluida_por) VALUES (1,now(),chave_api,alvo,objeto->>'message',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'publicCreditAllowed')::boolean,objeto->>'publicCreditName',objeto->>'status',objeto->>'completedAt',objeto->>'completedBy')
  ON CONFLICT(id_sugestao_melhoria) DO UPDATE SET versao=sugestoes_melhoria.versao+1, atualizado_em=excluded.atualizado_em, mensagem=excluded.mensagem, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, credito_autorizado=excluded.credito_autorizado, nome_credito=excluded.nome_credito, situacao=excluded.situacao, concluida_em=excluded.concluida_em, concluida_por=excluded.concluida_por;
END $$;


--
-- Name: gravar_turmas_agenda(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_turmas_agenda(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.turmas_agenda (versao,atualizado_em,referencia_api,id_turma_agenda,id_turma,ativa,referencia_pedido,aprovada_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'name'),(objeto->>'active')::boolean,objeto->>'requestId',objeto->>'approvedAt')
  ON CONFLICT(id_turma_agenda) DO UPDATE SET versao=turmas_agenda.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, ativa=excluded.ativa, referencia_pedido=excluded.referencia_pedido, aprovada_em=excluded.aprovada_em;
END $$;


--
-- Name: inserir_anexos_atividade(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.anexos_atividade (id_atividade,referencia,nome,tipo_mime,tamanho_bytes,chave_arquivo,enviado_em,enviado_por) VALUES (pai,objeto->>'id',objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'storagePath',objeto->>'uploadedAt',objeto->>'uploadedBy') RETURNING id_anexo_atividade INTO alvo;
END $$;


--
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


--
-- Name: inserir_colunas_kanban(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.colunas_kanban (id_quadro_kanban,ordem,referencia,nome,cor,concluida) VALUES (pai,posicao,objeto->>'id',objeto->>'name',objeto->>'color',(objeto->>'done')::boolean) RETURNING id_coluna_kanban INTO alvo;
END $$;


--
-- Name: inserir_itens_checklist(bigint, integer, jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  INSERT INTO tech2d.itens_checklist (id_cartao_kanban,ordem,referencia,descricao,concluido) VALUES (pai,posicao,objeto->>'id',objeto->>'text',(objeto->>'done')::boolean) RETURNING id_item_checklist INTO alvo;
END $$;


--
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


--
-- Name: ler_anexos_atividade(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_anexos_atividade(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
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
$$;


--
-- Name: ler_atividades(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_atividades(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'title', d.titulo,
    'description', d.descricao,
    'type', d.tipo_atividade,
    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),
    'date', d.data_atividade,
    'time', to_char(d.hora_atividade,'HH24:MI'),
    'turmaId', tech2d.nome_turma_agenda(d.id_turma),
    'createdBy', d.criado_por,
    'createdByEmail', d.email_criador,
    'recurringId', (SELECT rr.referencia_api FROM tech2d.regras_recorrencia rr WHERE rr.id_regra_recorrencia=d.id_regra_recorrencia),
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'attachments', (SELECT coalesce(jsonb_agg(tech2d.ler_anexos_atividade(r.id_anexo_atividade) ORDER BY r.id_anexo_atividade),'[]'::jsonb) FROM tech2d.anexos_atividade r WHERE r.id_atividade=d.id_atividade)
  ))
  FROM tech2d.atividades d WHERE d.id_atividade=alvo;
$$;


--
-- Name: ler_cartoes_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_cartoes_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
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
$$;


--
-- Name: ler_colunas_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_colunas_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'done', d.concluida
  ))
  FROM tech2d.colunas_kanban d WHERE d.id_coluna_kanban=alvo;
$$;


--
-- Name: ler_espacos_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_espacos_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'ownerId', d.id_proprietario,
    'schemaVersion', d.versao_formato,
    'createdAt', d.criado_em,
    'updatedAt', d.alterado_em,
    'boards', CASE WHEN NOT d.compartilhado THEN (SELECT coalesce(jsonb_agg(tech2d.ler_quadros_kanban(r.id_quadro_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban) END,
    'board', CASE WHEN d.compartilhado THEN (SELECT tech2d.ler_quadros_kanban(r.id_quadro_kanban) FROM tech2d.quadros_kanban r WHERE r.id_espaco_kanban=d.id_espaco_kanban AND r.ordem=0) END
  ))
  FROM tech2d.espacos_kanban d WHERE d.id_espaco_kanban=alvo;
$$;


--
-- Name: ler_horarios_aula(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_horarios_aula(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object('professor',p.nome,'subject',d.nome,'className',t.nome,
    'startTime',to_char(f.hora_inicio,'HH24:MI'),'endTime',to_char(f.hora_fim,'HH24:MI'),'dayOfWeek',h.dia_semana,
    'active',h.ativo,'floor',h.andar,'roomDescription',h.sala,'createdAt',h.criado_em,'updatedAt',h.alterado_em))
  FROM tech2d.horarios_aula h
  JOIN tech2d.professores p ON p.id_professor=h.id_professor JOIN tech2d.disciplinas d ON d.id_disciplina=h.id_disciplina
  JOIN tech2d.turmas t ON t.id_turma=h.id_turma JOIN tech2d.faixas_horario f ON f.id_faixa_horario=h.id_faixa_horario
  WHERE h.id_horario_interno=alvo;
$$;


--
-- Name: ler_itens_checklist(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_itens_checklist(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'text', d.descricao,
    'done', d.concluido
  ))
  FROM tech2d.itens_checklist d WHERE d.id_item_checklist=alvo;
$$;


--
-- Name: ler_participantes_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_participantes_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'boardId', d.referencia_quadro,
    'userId', d.id_usuario,
    'userEmail', d.email,
    'name', d.nome,
    'createdAt', d.criado_em
  ))
  FROM tech2d.participantes_kanban d WHERE d.id_participante_kanban=alvo;
$$;


--
-- Name: ler_perfis(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_perfis(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'displayName', d.nome,

    'company', d.empresa,

    'className', d.turma_informada,

    'room', d.sala,

    'floor', d.andar,

    'photoUrl', d.url_foto,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.perfis d WHERE d.id_perfil=alvo AND d.versao IS NOT NULL;

$$;


--
-- Name: ler_perfis_administrativos(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_perfis_administrativos(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'role', d.papel,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdAt', d.criado_em

  ))

  FROM tech2d.perfis_administrativos d WHERE d.id_perfil_administrativo=alvo;

$$;


--
-- Name: ler_quadros_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_quadros_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'id', d.referencia,
    'name', d.nome,
    'color', d.cor,
    'compact', d.compacto,
    'columns', (SELECT coalesce(jsonb_agg(tech2d.ler_colunas_kanban(r.id_coluna_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.colunas_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban),
    'tasks', (SELECT coalesce(jsonb_agg(tech2d.ler_cartoes_kanban(r.id_cartao_kanban) ORDER BY r.ordem),'[]'::jsonb) FROM tech2d.cartoes_kanban r WHERE r.id_quadro_kanban=d.id_quadro_kanban)
  ))
  FROM tech2d.quadros_kanban d WHERE d.id_quadro_kanban=alvo;
$$;


--
-- Name: ler_registro(bigint, character varying); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT CASE tipo
    WHEN 'activities' THEN tech2d.ler_atividades(alvo)
    WHEN 'admins' THEN tech2d.ler_perfis_administrativos(alvo)
    WHEN 'recurringActivities' THEN tech2d.ler_regras_recorrencia(alvo)
    WHEN 'activityRetention' THEN tech2d.ler_regras_retencao(alvo)
    WHEN 'agendaClasses' THEN tech2d.ler_turmas_agenda(alvo)
    WHEN 'feedback' THEN tech2d.ler_sugestoes_melhoria(alvo)
    WHEN 'schedules' THEN tech2d.ler_horarios_aula(alvo)
    WHEN 'userProfiles' THEN tech2d.ler_perfis(alvo)
    WHEN '_agendaDigestPreferences' THEN tech2d.ler_resumo_perfil(alvo)
    WHEN 'personalKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'sharedKanban' THEN tech2d.ler_espacos_kanban(alvo)
    WHEN 'kanbanMemberships' THEN tech2d.ler_participantes_kanban(alvo)
    ELSE NULL END;
$$;


--
-- Name: ler_regras_recorrencia(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_regras_recorrencia(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'title', d.titulo,

    'description', d.descricao,

    'type', d.tipo_atividade,

    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),

    'time', to_char(d.hora_atividade,'HH24:MI'),

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdAt', d.criado_em,

    'startDate', d.data_inicio,

    'endDate', d.data_fim,

    'active', d.ativa,

    'intervalWeeks', d.intervalo_semanas,

    'weekdays', d.dias_semana

  ))

  FROM tech2d.regras_recorrencia d WHERE d.id_regra_recorrencia=alvo;

$$;


--
-- Name: ler_regras_retencao(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_regras_retencao(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'days', d.dias,

    'enabled', d.ativa,

    'updatedBy', d.alterado_por,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.regras_retencao d WHERE d.id_regra_retencao=alvo;

$$;


--
-- Name: ler_resumo_perfil(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_resumo_perfil(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'enabled', d.resumo_semanal_ativo,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma_resumo),

    'updatedAt', d.resumo_alterado_em_ms

  ))

  FROM tech2d.perfis d WHERE d.id_perfil=alvo AND d.resumo_versao IS NOT NULL;

$$;


--
-- Name: ler_sugestoes_melhoria(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'message', d.mensagem,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

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

$$;


--
-- Name: ler_turmas_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_turmas_agenda(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'name', tech2d.nome_turma_agenda(d.id_turma),

    'active', d.ativa,

    'requestId', d.referencia_pedido,

    'approvedAt', d.aprovada_em

  ))

  FROM tech2d.turmas_agenda d WHERE d.id_turma_agenda=alvo;

$$;


--
-- Name: nome_disciplina_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.nome_disciplina_agenda(alvo bigint) RETURNS character varying
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT coalesce((SELECT v.nome FROM tech2d.visao_disciplinas_notas v WHERE v.id=d.id_disciplina ORDER BY v.ano_serie DESC LIMIT 1),d.nome)::varchar
 FROM tech2d.disciplinas d WHERE d.id_disciplina=alvo;
$$;


--
-- Name: FUNCTION nome_disciplina_agenda(alvo bigint); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.nome_disciplina_agenda(alvo bigint) IS 'Reconstrói o rótulo da disciplina usando a convenção já compartilhada com Notas, sem duplicar disciplinas para diferenças de exibição.';


--
-- Name: nome_turma_agenda(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.nome_turma_agenda(alvo bigint) RETURNS character varying
    LANGUAGE sql STABLE STRICT
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT coalesce(referencia_agenda,nome)::varchar FROM tech2d.turmas WHERE id_turma=alvo;
$$;


--
-- Name: FUNCTION nome_turma_agenda(alvo bigint); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.nome_turma_agenda(alvo bigint) IS 'Reconstrói o identificador textual esperado pela Agenda a partir do ID escolar, mantendo as permissões e os links existentes.';


--
-- Name: normalizar_rotulo(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.normalizar_rotulo(valor text) RETURNS character varying
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
 SELECT regexp_replace(translate(lower(btrim(valor)),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc'),'[^a-z0-9]','','g')::varchar;
$$;


--
-- Name: FUNCTION normalizar_rotulo(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.normalizar_rotulo(valor text) IS 'Normaliza somente para localizar um rótulo existente, ignorando caixa, acentos e pontuação; não substitui os nomes guardados no catálogo.';


--
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


--
-- Name: referencia_api(character varying, character varying, character varying); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT CASE WHEN pai='' THEN tipo || '/' || referencia
    ELSE split_part(tipo,'/',1) || '/' || pai || '/' || split_part(tipo,'/',2) || '/' || referencia END;
$$;


--
-- Name: remover_nulos_raiz(jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT coalesce(jsonb_object_agg(key,value),'{}'::jsonb)
  FROM jsonb_each(objeto) WHERE value <> 'null'::jsonb;
$$;


--
-- Name: remover_nulos_recursivo(jsonb); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.remover_nulos_recursivo(valor jsonb) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
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
END $$;


--
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


--
-- Name: FUNCTION resolver_disciplina(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.resolver_disciplina(valor text) IS 'Reutiliza disciplinas por nome exato, rótulo de Notas ou correspondência única normalizada. Rejeita ambiguidades; cadastra uma matéria apenas quando ela ainda não existe. Não concede autorização.';


--
-- Name: resolver_regra_recorrencia(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.resolver_regra_recorrencia(valor text) RETURNS bigint
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  IF valor IS NULL THEN RETURN NULL; END IF;
  SELECT id_regra_recorrencia INTO alvo FROM tech2d.regras_recorrencia WHERE referencia_api=valor;
  IF alvo IS NULL THEN RAISE EXCEPTION 'Regra de recorrência inexistente' USING ERRCODE='23503'; END IF;
  RETURN alvo;
END
$$;


--
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


--
-- Name: FUNCTION resolver_turma(valor text, agenda boolean); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.resolver_turma(valor text, agenda boolean) IS 'Reutiliza a turma existente por referência, nome ou correspondência única normalizada. Cadastra somente nomes novos e registra uma vez a referência da Agenda, quando solicitado. Não concede autorização.';


--
-- Name: revisao_catalogo_publico(character varying); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) RETURNS character varying
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE tipos varchar[]; revisao varchar(32);
BEGIN
 CASE catalogo
  WHEN 'agenda' THEN tipos:=ARRAY['activities','agendaClasses'];
  WHEN 'updates' THEN tipos:=ARRAY['agendaClasses'];
  WHEN 'schedules' THEN tipos:=ARRAY['schedules'];
  ELSE RAISE EXCEPTION 'Catálogo inválido' USING ERRCODE='22023';
 END CASE;
 SELECT md5(coalesce(string_agg(id_registro::text || ':' || versao::text, ',' ORDER BY id_registro),'')) INTO revisao
 FROM (
   SELECT id_atividade AS id_registro, versao FROM tech2d.atividades WHERE 'activities'=ANY(tipos)
   UNION ALL SELECT id_turma_agenda, versao FROM tech2d.turmas_agenda WHERE 'agendaClasses'=ANY(tipos)
   UNION ALL SELECT id_horario_interno, versao FROM tech2d.horarios_aula WHERE 'schedules'=ANY(tipos)
 ) entidades;
 SELECT md5(revisao||':'||coalesce((SELECT string_agg(id_disciplina::text||':'||nome,',' ORDER BY id_disciplina) FROM tech2d.disciplinas),'')
  ||':'||coalesce((SELECT string_agg(id_turma::text||':'||nome||':'||coalesce(referencia_agenda,''),',' ORDER BY id_turma) FROM tech2d.turmas),'')) INTO revisao;
 RETURN revisao;
END $$;


--
-- Name: FUNCTION revisao_catalogo_publico(catalogo character varying); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) IS 'Calcula a revisão do catálogo com as versões dos registros e os nomes/referências de disciplinas e turmas; alterações nesses catálogos também invalidam o cache Redis.';


--
-- Name: travar_gravacao(text[]); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.travar_gravacao(caminhos text[]) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  inclui_kanban boolean;
  inclui_agenda boolean;
BEGIN
  SELECT coalesce(bool_or(kanban), false), coalesce(bool_or(NOT kanban), true)
  INTO inclui_kanban, inclui_agenda
  FROM (
    SELECT coalesce(split_part(caminho,'/',1) IN
      ('personalKanban','sharedKanban','kanbanMemberships','kanbanRequests'), false) AS kanban
    FROM unnest(caminhos) AS caminho
  ) escopos;
  IF inclui_agenda THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
  END IF;
  IF inclui_kanban THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-kanban-commit'));
  END IF;
END
$$;


--
-- Name: vincular_disciplina_notaki(bigint, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint) RETURNS void
    LANGUAGE sql
    SET search_path TO 'pg_catalog'
    AS $$
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
$$;


--
-- Name: vincular_nova_disciplina_notaki(); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.vincular_nova_disciplina_notaki() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  PERFORM tech2d.vincular_disciplina_notaki(NEW.id_turma, NEW.id_disciplina);
  RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

--
-- Name: anexos_atividade; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.anexos_atividade (
    id_anexo_atividade bigint CONSTRAINT anexos_atividade_id_not_null NOT NULL,
    id_atividade bigint NOT NULL,
    referencia character varying(180),
    nome character varying(500),
    tipo_mime character varying(150),
    tamanho_bytes bigint,
    chave_arquivo character varying(1024),
    enviado_em character varying(40),
    enviado_por character varying(128)
);


--
-- Name: TABLE anexos_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.anexos_atividade IS 'Metadados dos arquivos anexados às atividades';


--
-- Name: COLUMN anexos_atividade.id_anexo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.id_anexo_atividade IS 'Identificador numérico de anexos_atividade. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN anexos_atividade.id_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.id_atividade IS 'Atividade que contém o anexo. Referencia atividades.id_atividade; a exclusão da atividade remove os metadados de seus anexos.';


--
-- Name: COLUMN anexos_atividade.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.referencia IS 'Campo id no contrato da API.';


--
-- Name: COLUMN anexos_atividade.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.nome IS 'Campo name no contrato da API.';


--
-- Name: COLUMN anexos_atividade.tipo_mime; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.tipo_mime IS 'Campo contentType no contrato da API.';


--
-- Name: COLUMN anexos_atividade.tamanho_bytes; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.tamanho_bytes IS 'Campo size no contrato da API.';


--
-- Name: COLUMN anexos_atividade.chave_arquivo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.chave_arquivo IS 'Campo storagePath no contrato da API.';


--
-- Name: COLUMN anexos_atividade.enviado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.enviado_em IS 'Campo uploadedAt no contrato da API.';


--
-- Name: COLUMN anexos_atividade.enviado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.enviado_por IS 'Campo uploadedBy no contrato da API.';


--
-- Name: anexos_atividade_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.anexos_atividade ALTER COLUMN id_anexo_atividade ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.anexos_atividade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: apelidos_disciplinas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.apelidos_disciplinas (
    id bigint NOT NULL,
    id_disciplina bigint NOT NULL,
    apelido text NOT NULL,
    chave_normalizada text NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apelidos_disciplinas_apelido_check CHECK ((btrim(apelido) <> ''::text)),
    CONSTRAINT apelidos_disciplinas_chave_normalizada_check CHECK ((btrim(chave_normalizada) <> ''::text))
);


--
-- Name: TABLE apelidos_disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.apelidos_disciplinas IS 'Apelidos aprovados usados pela IA para identificar disciplinas.';


--
-- Name: apelidos_disciplinas_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.apelidos_disciplinas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.apelidos_disciplinas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: apelidos_professores; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.apelidos_professores (
    id bigint NOT NULL,
    id_professor bigint NOT NULL,
    apelido text NOT NULL,
    chave_normalizada text NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apelidos_professores_apelido_check CHECK ((btrim(apelido) <> ''::text)),
    CONSTRAINT apelidos_professores_chave_normalizada_check CHECK ((btrim(chave_normalizada) <> ''::text))
);


--
-- Name: TABLE apelidos_professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.apelidos_professores IS 'Apelidos aprovados usados pela IA para identificar professores.';


--
-- Name: apelidos_professores_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.apelidos_professores ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.apelidos_professores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ids_entidades; Type: SEQUENCE; Schema: tech2d; Owner: -
--

CREATE SEQUENCE tech2d.ids_entidades
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: SEQUENCE ids_entidades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON SEQUENCE tech2d.ids_entidades IS 'Gera novos IDs numéricos sem reutilizar os IDs existentes.';


--
-- Name: turmas_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.turmas_agenda (
    id_turma_agenda bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT turmas_agenda_id_registro_not_null NOT NULL,
    ativa boolean,
    referencia_pedido character varying(180),
    aprovada_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT turmas_agenda_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT turmas_agenda_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE turmas_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.turmas_agenda IS 'Turmas habilitadas na Agenda';


--
-- Name: COLUMN turmas_agenda.id_turma_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.id_turma_agenda IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN turmas_agenda.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.ativa IS 'Campo active no contrato da API.';


--
-- Name: COLUMN turmas_agenda.referencia_pedido; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.referencia_pedido IS 'Campo requestId no contrato da API.';


--
-- Name: COLUMN turmas_agenda.aprovada_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.aprovada_em IS 'Campo approvedAt no contrato da API.';


--
-- Name: COLUMN turmas_agenda.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN turmas_agenda.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN turmas_agenda.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN turmas_agenda.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: assistant_class_catalog; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.assistant_class_catalog AS
 SELECT (referencia_api)::text AS id
   FROM tech2d.turmas_agenda a
  WHERE ativa;


--
-- Name: disciplinas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.disciplinas (
    id_disciplina bigint CONSTRAINT school_subjects_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_subjects_name_not_null NOT NULL,
    CONSTRAINT school_subjects_name_check CHECK ((btrim((nome)::text) <> ''::text))
);


--
-- Name: TABLE disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.disciplinas IS 'Nomes das disciplinas reutilizadas pelos horários.';


--
-- Name: COLUMN disciplinas.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas.id_disciplina IS 'Identificador numérico de disciplinas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: regras_recorrencia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.regras_recorrencia (
    id_regra_recorrencia bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT regras_recorrencia_id_registro_not_null NOT NULL,
    titulo character varying(120),
    descricao character varying(2000),
    tipo_atividade character varying(32),
    hora_atividade time without time zone,
    criado_por character varying(128),
    criado_em character varying(40),
    data_inicio date,
    data_fim date,
    ativa boolean,
    intervalo_semanas smallint,
    dias_semana smallint[],
    id_disciplina bigint,
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT regras_recorrencia_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT regras_recorrencia_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE regras_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.regras_recorrencia IS 'Regras de repetição';


--
-- Name: COLUMN regras_recorrencia.id_regra_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_regra_recorrencia IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN regras_recorrencia.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.titulo IS 'Campo title no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.descricao IS 'Campo description no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.tipo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.tipo_atividade IS 'Campo type no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.hora_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.hora_atividade IS 'Campo time no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.criado_por IS 'Campo createdBy no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.data_inicio; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.data_inicio IS 'Campo startDate no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.data_fim; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.data_fim IS 'Campo endDate no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.ativa IS 'Campo active no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.intervalo_semanas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.intervalo_semanas IS 'Campo intervalWeeks no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.dias_semana; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.dias_semana IS 'Campo weekdays no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';


--
-- Name: COLUMN regras_recorrencia.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN regras_recorrencia.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN regras_recorrencia.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN regras_recorrencia.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: turmas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.turmas (
    id_turma bigint CONSTRAINT school_classes_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_classes_name_not_null NOT NULL,
    referencia_agenda character varying(150),
    CONSTRAINT school_classes_name_check CHECK ((btrim((nome)::text) <> ''::text))
);


--
-- Name: TABLE turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.turmas IS 'Nomes das turmas do catálogo de horários.';


--
-- Name: COLUMN turmas.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas.id_turma IS 'Identificador numérico de turmas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN turmas.referencia_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas.referencia_agenda IS 'Identificador textual estável da turma na Agenda, como 2° TECH D. É guardado uma única vez; os vínculos das tabelas usam id_turma.';


--
-- Name: assistant_recurring_activities; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.assistant_recurring_activities AS
 SELECT r.referencia_api AS id,
    jsonb_strip_nulls(jsonb_build_object('turmaId', COALESCE(t.referencia_agenda, t.nome), 'subject', d.nome, 'active', r.ativa, 'type', r.tipo_atividade, 'startDate', r.data_inicio, 'endDate', r.data_fim, 'weekdays', r.dias_semana, 'intervalWeeks', r.intervalo_semanas, 'time', to_char((r.hora_atividade)::interval, 'HH24:MI'::text), 'title', r.titulo)) AS data
   FROM ((tech2d.regras_recorrencia r
     LEFT JOIN tech2d.turmas t USING (id_turma))
     LEFT JOIN tech2d.disciplinas d USING (id_disciplina));


--
-- Name: faixas_horario; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.faixas_horario (
    id_faixa_horario bigint CONSTRAINT school_time_slots_id_not_null NOT NULL,
    hora_inicio time(0) without time zone CONSTRAINT school_time_slots_start_time_not_null NOT NULL,
    hora_fim time(0) without time zone CONSTRAINT school_time_slots_end_time_not_null NOT NULL,
    CONSTRAINT school_time_slots_check CHECK ((hora_inicio < hora_fim))
);


--
-- Name: TABLE faixas_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.faixas_horario IS 'Pares de horário de início e fim reutilizados pelas aulas.';


--
-- Name: COLUMN faixas_horario.id_faixa_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.faixas_horario.id_faixa_horario IS 'Identificador numérico de faixas_horario. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: horarios_aula; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.horarios_aula (
    id_horario_aula character varying(320) CONSTRAINT school_schedules_id_not_null NOT NULL,
    id_professor bigint CONSTRAINT school_schedules_teacher_id_not_null NOT NULL,
    id_disciplina bigint CONSTRAINT school_schedules_subject_id_not_null NOT NULL,
    id_turma bigint CONSTRAINT school_schedules_class_id_not_null NOT NULL,
    id_faixa_horario bigint CONSTRAINT school_schedules_time_slot_id_not_null NOT NULL,
    dia_semana smallint CONSTRAINT school_schedules_day_of_week_not_null NOT NULL,
    ativo boolean CONSTRAINT school_schedules_active_not_null NOT NULL,
    id_horario_interno bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT horarios_aula_id_registro_not_null NOT NULL,
    andar character varying(80),
    sala character varying(500),
    criado_em character varying(40),
    alterado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    CONSTRAINT horarios_aula_versao_check CHECK ((versao > 0)),
    CONSTRAINT school_schedules_day_of_week_check CHECK (((dia_semana >= 0) AND (dia_semana <= 6)))
);


--
-- Name: TABLE horarios_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.horarios_aula IS 'Liga professor, disciplina, turma e faixa de horário a um dia da semana.';


--
-- Name: COLUMN horarios_aula.id_horario_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.id_horario_aula IS 'Identificador textual do horário preservado no contrato da API. id_horario_interno identifica o mesmo horário internamente.';


--
-- Name: COLUMN horarios_aula.id_horario_interno; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.id_horario_interno IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN horarios_aula.andar; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.andar IS 'Andar informado para a aula.';


--
-- Name: COLUMN horarios_aula.sala; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.sala IS 'Descrição da sala ou localização da aula.';


--
-- Name: COLUMN horarios_aula.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN horarios_aula.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: assistant_teacher_schedule; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.assistant_teacher_schedule AS
 SELECT h.id_professor,
    h.dia_semana,
    f.hora_inicio,
    f.hora_fim,
    d.nome AS disciplina,
    t.nome AS turma,
    h.andar,
    h.sala
   FROM (((tech2d.horarios_aula h
     JOIN tech2d.faixas_horario f USING (id_faixa_horario))
     JOIN tech2d.disciplinas d USING (id_disciplina))
     JOIN tech2d.turmas t USING (id_turma))
  WHERE h.ativo;


--
-- Name: atividades; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.atividades (
    id_atividade bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT atividades_id_registro_not_null NOT NULL,
    titulo character varying(120),
    descricao character varying(2000),
    tipo_atividade character varying(32),
    data_atividade date,
    hora_atividade time without time zone,
    criado_por character varying(128),
    email_criador character varying(320),
    criado_em character varying(40),
    alterado_em character varying(40),
    id_disciplina bigint,
    id_turma bigint,
    id_regra_recorrencia bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT atividades_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT atividades_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.atividades IS 'Atividades da Agenda';


--
-- Name: COLUMN atividades.id_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_atividade IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN atividades.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.titulo IS 'Campo title no contrato da API.';


--
-- Name: COLUMN atividades.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.descricao IS 'Campo description no contrato da API.';


--
-- Name: COLUMN atividades.tipo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.tipo_atividade IS 'Campo type no contrato da API.';


--
-- Name: COLUMN atividades.data_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.data_atividade IS 'Campo date no contrato da API.';


--
-- Name: COLUMN atividades.hora_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.hora_atividade IS 'Campo time no contrato da API.';


--
-- Name: COLUMN atividades.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.criado_por IS 'Campo createdBy no contrato da API.';


--
-- Name: COLUMN atividades.email_criador; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.email_criador IS 'Campo createdByEmail no contrato da API.';


--
-- Name: COLUMN atividades.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN atividades.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.alterado_em IS 'Campo updatedAt no contrato da API.';


--
-- Name: COLUMN atividades.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';


--
-- Name: COLUMN atividades.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN atividades.id_regra_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_regra_recorrencia IS 'FK opcional para regras_recorrencia.id_regra_recorrencia. Identifica a regra que gerou a ocorrência; excluir fisicamente a regra desvincula a atividade sem excluí-la.';


--
-- Name: COLUMN atividades.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN atividades.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN atividades.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: aulas_recuperacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.aulas_recuperacao (
    edital_id integer NOT NULL,
    ordem integer NOT NULL,
    dia date NOT NULL,
    inicio time without time zone NOT NULL,
    fim time without time zone NOT NULL,
    materia text NOT NULL,
    turma text,
    professor text,
    local text,
    prova boolean DEFAULT false NOT NULL,
    CONSTRAINT aulas_recuperacao_check CHECK ((fim > inicio)),
    CONSTRAINT aulas_recuperacao_local_check CHECK ((length(local) <= 120)),
    CONSTRAINT aulas_recuperacao_materia_check CHECK (((length(materia) >= 1) AND (length(materia) <= 120))),
    CONSTRAINT aulas_recuperacao_ordem_check CHECK ((ordem >= 1)),
    CONSTRAINT aulas_recuperacao_professor_check CHECK ((length(professor) <= 120)),
    CONSTRAINT aulas_recuperacao_turma_check CHECK ((length(turma) <= 100))
);


--
-- Name: COLUMN aulas_recuperacao.prova; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.aulas_recuperacao.prova IS 'Indica uma prova de recuperação, distinta de uma aula de revisão.';


--
-- Name: cartoes_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.cartoes_kanban (
    id_cartao_kanban bigint CONSTRAINT cartoes_kanban_id_not_null NOT NULL,
    id_quadro_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    referencia_coluna character varying(80),
    titulo character varying(160),
    descricao character varying(3000),
    prioridade character varying(16),
    prazo date,
    id_responsavel character varying(128),
    etiquetas character varying(30)[],
    referencias_atividades character varying(128)[],
    CONSTRAINT cartoes_kanban_ordem_check CHECK ((ordem >= 0))
);


--
-- Name: TABLE cartoes_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.cartoes_kanban IS 'Cartões dos quadros';


--
-- Name: COLUMN cartoes_kanban.id_cartao_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_cartao_kanban IS 'Identificador numérico de cartoes_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN cartoes_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_quadro_kanban IS 'Quadro ao qual o cartão pertence. Referencia quadros_kanban.id_quadro_kanban; junto com referencia_coluna, exige uma coluna desse mesmo quadro.';


--
-- Name: COLUMN cartoes_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencia IS 'Campo id no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.referencia_coluna; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencia_coluna IS 'Campo columnId no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.titulo IS 'Campo title no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.descricao IS 'Campo description no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.prioridade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.prioridade IS 'Campo priority no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.prazo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.prazo IS 'Campo dueDate no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.id_responsavel; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_responsavel IS 'Campo assigneeId no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.etiquetas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.etiquetas IS 'Campo labels no contrato da API.';


--
-- Name: COLUMN cartoes_kanban.referencias_atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencias_atividades IS 'Campo activityIds no contrato da API.';


--
-- Name: cartoes_kanban_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.cartoes_kanban ALTER COLUMN id_cartao_kanban ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.cartoes_kanban_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: disciplinas_series; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.disciplinas_series (
    id_disciplina bigint NOT NULL,
    ano_serie smallint NOT NULL,
    CONSTRAINT disciplinas_series_ano_serie_check CHECK (((ano_serie >= 1) AND (ano_serie <= 3)))
);


--
-- Name: TABLE disciplinas_series; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.disciplinas_series IS 'Vínculo entre o catálogo compartilhado de disciplinas e as séries do Ensino Médio. A área de Notas consulta esse vínculo para validar notas, sem duplicar os nomes das matérias.';


--
-- Name: COLUMN disciplinas_series.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas_series.id_disciplina IS 'Disciplina do catálogo geral, também usado pelos horários. A chave estrangeira impede uma matéria inexistente.';


--
-- Name: COLUMN disciplinas_series.ano_serie; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas_series.ano_serie IS 'Série de 1 a 3 em que a disciplina é oferecida. Compõe a chave para reutilizar a mesma matéria em séries diferentes.';


--
-- Name: professores; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.professores (
    id_professor bigint CONSTRAINT school_teachers_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_teachers_name_not_null NOT NULL,
    CONSTRAINT school_teachers_name_check CHECK ((btrim((nome)::text) <> ''::text))
);


--
-- Name: TABLE professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.professores IS 'Nomes de professores reutilizados pelos horários.';


--
-- Name: COLUMN professores.id_professor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.professores.id_professor IS 'Identificador numérico de professores. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: vinculos_professores_turmas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.vinculos_professores_turmas (
    id bigint NOT NULL,
    id_turma bigint NOT NULL,
    id_disciplina bigint NOT NULL,
    id_professor bigint NOT NULL,
    vigencia_inicio date NOT NULL,
    vigencia_fim date,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vinculos_professores_turmas_check CHECK (((vigencia_fim IS NULL) OR (vigencia_fim >= vigencia_inicio)))
);


--
-- Name: TABLE vinculos_professores_turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.vinculos_professores_turmas IS 'Professor confirmado por turma e disciplina durante uma vigência.';


--
-- Name: visao_disciplinas_notas; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_disciplinas_notas AS
 SELECT d.id_disciplina AS id,
    s.ano_serie,
    (
        CASE d.nome
            WHEN 'Desenvolvimento de Aplicação Dinâmica'::text THEN 'Desenvolvimento Aplicação Dinâmica'::character varying
            WHEN 'Engenharia e Qualidae de Software'::text THEN 'Engenharia e Qualidade de Software'::character varying
            WHEN 'Língua Portuguesa e Suas Literaturas'::text THEN 'Língua Portuguesa e suas Literaturas'::character varying
            WHEN 'Matemática 9-Banco de dados'::text THEN 'Matemática 9-Banco de Dados'::character varying
            WHEN 'Lingua inglesa'::text THEN 'Língua Inglesa'::character varying
            WHEN 'Biologia 2 - ESG'::text THEN 'Biologia 2-ESG-Environment, Social and Governance'::character varying
            WHEN 'Matemática 14-Inteligência Artificial'::text THEN 'Matemática 14 - Inteligência Artificial'::character varying
            ELSE d.nome
        END)::character varying(160) AS nome
   FROM (tech2d.disciplinas_series s
     JOIN tech2d.disciplinas d ON ((d.id_disciplina = s.id_disciplina)));


--
-- Name: VIEW visao_disciplinas_notas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_disciplinas_notas IS 'Projeção do catálogo compartilhado para o Notas. Conserva os rótulos que o frontend usa como chaves, sem armazenar outro catálogo de nomes.';


--
-- Name: catalogo_atividades_professores; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.catalogo_atividades_professores AS
 SELECT a.referencia_api AS id_atividade,
    a.titulo,
    a.tipo_atividade AS tipo,
    a.data_atividade AS data,
    to_char((a.hora_atividade)::interval, 'HH24:MI'::text) AS hora,
    a.id_disciplina,
    d.nome AS disciplina,
    a.id_turma,
    t.nome AS turma,
    p.id_professor,
    p.nome AS professor,
        CASE
            WHEN (a.id_turma IS NULL) THEN 'atividade_geral'::text
            WHEN (a.id_disciplina IS NULL) THEN 'disciplina_pendente'::text
            WHEN (p.id_professor IS NULL) THEN 'professor_pendente'::text
            ELSE 'associado'::text
        END AS estado_atribuicao,
    (COALESCE(( SELECT n.nome
           FROM tech2d.visao_disciplinas_notas n
          WHERE (n.id = d.id_disciplina)
          ORDER BY n.ano_serie DESC
         LIMIT 1), d.nome))::character varying(150) AS disciplina_original,
    COALESCE(t.referencia_agenda, t.nome) AS turma_original,
    r.referencia_api AS referencia_recorrencia
   FROM (((((tech2d.atividades a
     LEFT JOIN tech2d.regras_recorrencia r USING (id_regra_recorrencia))
     LEFT JOIN tech2d.disciplinas d ON ((d.id_disciplina = a.id_disciplina)))
     LEFT JOIN tech2d.turmas t ON ((t.id_turma = a.id_turma)))
     LEFT JOIN tech2d.vinculos_professores_turmas x ON (((x.id_turma = a.id_turma) AND (x.id_disciplina = a.id_disciplina) AND (a.data_atividade <@ daterange(x.vigencia_inicio, x.vigencia_fim, '[]'::text)))))
     LEFT JOIN tech2d.professores p ON ((p.id_professor = x.id_professor)));


--
-- Name: catalogo_horarios; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.catalogo_horarios AS
 SELECT h.id_horario_aula AS id,
    h.dia_semana,
    h.ativo,
    t.nome AS nome_turma,
    tech2d.ler_registro(h.id_horario_interno, 'schedules'::character varying) AS dados
   FROM (tech2d.horarios_aula h
     JOIN tech2d.turmas t ON ((t.id_turma = h.id_turma)));


--
-- Name: VIEW catalogo_horarios; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.catalogo_horarios IS 'Reúne professor, disciplina, turma, faixa de horário, andar e sala.';


--
-- Name: colunas_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.colunas_kanban (
    id_coluna_kanban bigint CONSTRAINT colunas_kanban_id_not_null NOT NULL,
    id_quadro_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    nome character varying(60),
    cor character varying(16),
    concluida boolean,
    CONSTRAINT colunas_kanban_ordem_check CHECK ((ordem >= 0))
);


--
-- Name: TABLE colunas_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.colunas_kanban IS 'Colunas dos quadros';


--
-- Name: COLUMN colunas_kanban.id_coluna_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.id_coluna_kanban IS 'Identificador numérico de colunas_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN colunas_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.id_quadro_kanban IS 'Quadro ao qual a coluna pertence. Referencia quadros_kanban.id_quadro_kanban.';


--
-- Name: COLUMN colunas_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.referencia IS 'Campo id no contrato da API.';


--
-- Name: COLUMN colunas_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.nome IS 'Campo name no contrato da API.';


--
-- Name: COLUMN colunas_kanban.cor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.cor IS 'Campo color no contrato da API.';


--
-- Name: COLUMN colunas_kanban.concluida; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.concluida IS 'Campo done no contrato da API.';


--
-- Name: colunas_kanban_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.colunas_kanban ALTER COLUMN id_coluna_kanban ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.colunas_kanban_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: config_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.config_assistente (
    id integer NOT NULL,
    limite_diario integer NOT NULL,
    versao integer NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_por text NOT NULL,
    CONSTRAINT config_assistente_id_check CHECK ((id = 1)),
    CONSTRAINT config_assistente_limite_diario_check CHECK (((limite_diario >= 1) AND (limite_diario <= 1000))),
    CONSTRAINT config_assistente_versao_check CHECK ((versao > 0))
);


--
-- Name: config_fechamento_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.config_fechamento_agenda (
    id integer NOT NULL,
    versao integer DEFAULT 0 NOT NULL,
    rascunho jsonb,
    publicado jsonb,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT config_fechamento_agenda_id_check CHECK ((id = 1)),
    CONSTRAINT config_fechamento_agenda_publicado_check CHECK ((jsonb_typeof(publicado) = 'object'::text)),
    CONSTRAINT config_fechamento_agenda_rascunho_check CHECK ((jsonb_typeof(rascunho) = 'object'::text)),
    CONSTRAINT config_fechamento_agenda_versao_check CHECK ((versao >= 0))
);


--
-- Name: editais_recuperacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.editais_recuperacao (
    id integer NOT NULL,
    titulo text NOT NULL,
    descricao text NOT NULL,
    link text,
    inicio timestamp with time zone,
    fim timestamp with time zone,
    CONSTRAINT editais_recuperacao_check CHECK ((fim > inicio)),
    CONSTRAINT editais_recuperacao_descricao_check CHECK ((length(descricao) <= 6000)),
    CONSTRAINT editais_recuperacao_janela_completa CHECK (((inicio IS NULL) = (fim IS NULL))),
    CONSTRAINT editais_recuperacao_link_check CHECK ((length(link) <= 1000)),
    CONSTRAINT editais_recuperacao_titulo_check CHECK (((length(titulo) >= 1) AND (length(titulo) <= 140)))
);


--
-- Name: editais_recuperacao_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.editais_recuperacao ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.editais_recuperacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: espacos_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.espacos_kanban (
    id_espaco_kanban bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT espacos_kanban_id_registro_not_null NOT NULL,
    id_proprietario character varying(128),
    versao_formato smallint,
    criado_em character varying(40),
    alterado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    compartilhado boolean NOT NULL,
    CONSTRAINT espacos_kanban_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT espacos_kanban_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE espacos_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.espacos_kanban IS 'Espaços pessoais e compartilhados do Kanban';


--
-- Name: COLUMN espacos_kanban.id_espaco_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.id_espaco_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN espacos_kanban.id_proprietario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.id_proprietario IS 'Campo ownerId no contrato da API.';


--
-- Name: COLUMN espacos_kanban.versao_formato; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.versao_formato IS 'Campo schemaVersion no contrato da API.';


--
-- Name: COLUMN espacos_kanban.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN espacos_kanban.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.alterado_em IS 'Campo updatedAt no contrato da API.';


--
-- Name: COLUMN espacos_kanban.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN espacos_kanban.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN espacos_kanban.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: COLUMN espacos_kanban.compartilhado; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.compartilhado IS 'Distingue espaços pessoais e compartilhados no contrato da API.';


--
-- Name: itens_checklist; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.itens_checklist (
    id_item_checklist bigint CONSTRAINT itens_checklist_id_not_null NOT NULL,
    id_cartao_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    descricao character varying(200),
    concluido boolean,
    CONSTRAINT itens_checklist_ordem_check CHECK ((ordem >= 0))
);


--
-- Name: TABLE itens_checklist; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.itens_checklist IS 'Itens das listas dos cartões';


--
-- Name: COLUMN itens_checklist.id_item_checklist; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.id_item_checklist IS 'Identificador numérico de itens_checklist. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN itens_checklist.id_cartao_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.id_cartao_kanban IS 'Cartão que contém o item de checklist. Referencia cartoes_kanban.id_cartao_kanban.';


--
-- Name: COLUMN itens_checklist.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.referencia IS 'Campo id no contrato da API.';


--
-- Name: COLUMN itens_checklist.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.descricao IS 'Campo text no contrato da API.';


--
-- Name: COLUMN itens_checklist.concluido; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.concluido IS 'Campo done no contrato da API.';


--
-- Name: itens_checklist_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.itens_checklist ALTER COLUMN id_item_checklist ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.itens_checklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: limites_mensagens_ia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limites_mensagens_ia (
    firebase_uid text NOT NULL,
    data_uso date NOT NULL,
    quantidade integer NOT NULL,
    CONSTRAINT limites_mensagens_ia_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT limites_mensagens_ia_quantidade_check CHECK ((quantidade >= 0))
);


--
-- Name: limpeza_anexos_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limpeza_anexos_agenda (
    chave_arquivo text NOT NULL,
    tentar_apos timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE limpeza_anexos_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.limpeza_anexos_agenda IS 'Fila de limpeza de anexos R2 desvinculados pelo expurgo e por recorrências.';


--
-- Name: limpezas_anuais_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limpezas_anuais_agenda (
    operacao text NOT NULL,
    administrador_uid text NOT NULL,
    revisao text NOT NULL,
    executada_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    resultado jsonb NOT NULL
);


--
-- Name: notas_cadernos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_cadernos (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    modo_primeiro character varying(5) NOT NULL,
    modo_segundo character varying(5) NOT NULL,
    versao bigint DEFAULT 0 NOT NULL,
    regra_calculo character varying(32) DEFAULT 'tech-2026-v1'::character varying NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    alterado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notas_cadernos_ano_letivo_check CHECK (((ano_letivo >= 2020) AND (ano_letivo <= 2100))),
    CONSTRAINT notas_cadernos_ano_serie_check CHECK (((ano_serie >= 1) AND (ano_serie <= 3))),
    CONSTRAINT notas_cadernos_modo_primeiro_check CHECK (((modo_primeiro)::text = ANY (ARRAY[('notas'::character varying)::text, ('media'::character varying)::text]))),
    CONSTRAINT notas_cadernos_modo_segundo_check CHECK (((modo_segundo)::text = ANY (ARRAY[('notas'::character varying)::text, ('media'::character varying)::text]))),
    CONSTRAINT notas_cadernos_versao_check CHECK ((versao >= 0))
);


--
-- Name: TABLE notas_cadernos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_cadernos IS 'Caderno privado da conta Firebase por ano letivo, série, modos de entrada e versão otimista.';


--
-- Name: COLUMN notas_cadernos.id_usuario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.id_usuario IS 'UID validado no Firebase Authentication, nunca escolhido pelo cliente.';


--
-- Name: COLUMN notas_cadernos.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.versao IS 'Versão usada para impedir sobrescrita por outra aba ou dispositivo.';


--
-- Name: COLUMN notas_cadernos.regra_calculo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.regra_calculo IS 'Versão da fórmula, para rastreabilidade dos cálculos.';


--
-- Name: notas_lancamentos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_lancamentos (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    id_disciplina bigint NOT NULL,
    semestre smallint NOT NULL,
    n1 numeric(4,2),
    n2 numeric(4,2),
    media_informada numeric(4,2),
    peso_n1 smallint DEFAULT 50 NOT NULL,
    CONSTRAINT notas_lancamentos_media_informada_check CHECK (((media_informada >= (0)::numeric) AND (media_informada <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_n1_check CHECK (((n1 >= (0)::numeric) AND (n1 <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_n2_check CHECK (((n2 >= (0)::numeric) AND (n2 <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_peso_n1_check CHECK (((peso_n1 >= 10) AND (peso_n1 <= 90) AND (((peso_n1)::integer % 5) = 0))),
    CONSTRAINT notas_lancamentos_semestre_check CHECK ((semestre = ANY (ARRAY[1, 2])))
);


--
-- Name: TABLE notas_lancamentos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_lancamentos IS 'Notas N1/N2, média informada e pesos por disciplina e semestre. Nota vazia é NULL.';


--
-- Name: notas_recuperacoes; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_recuperacoes (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    id_disciplina bigint NOT NULL,
    nota numeric(4,2),
    CONSTRAINT notas_recuperacoes_nota_check CHECK (((nota >= (0)::numeric) AND (nota <= (10)::numeric)))
);


--
-- Name: TABLE notas_recuperacoes; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_recuperacoes IS 'Nota de recuperação final por conta, ano letivo e disciplina.';


--
-- Name: participantes_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.participantes_kanban (
    id_participante_kanban bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT participantes_kanban_id_registro_not_null NOT NULL,
    referencia_quadro character varying(80),
    id_usuario character varying(128),
    email character varying(320),
    nome character varying(80),
    criado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT participantes_kanban_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT participantes_kanban_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE participantes_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.participantes_kanban IS 'Participantes de quadros compartilhados';


--
-- Name: COLUMN participantes_kanban.id_participante_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.id_participante_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN participantes_kanban.referencia_quadro; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.referencia_quadro IS 'Campo boardId no contrato da API.';


--
-- Name: COLUMN participantes_kanban.id_usuario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.id_usuario IS 'Campo userId no contrato da API.';


--
-- Name: COLUMN participantes_kanban.email; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.email IS 'Campo userEmail no contrato da API.';


--
-- Name: COLUMN participantes_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.nome IS 'Campo name no contrato da API.';


--
-- Name: COLUMN participantes_kanban.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN participantes_kanban.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN participantes_kanban.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN participantes_kanban.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: perfis; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.perfis (
    id_perfil bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) NOT NULL,
    nome character varying(80),
    empresa character varying(100),
    turma_informada character varying(80),
    sala character varying(80),
    andar character varying(80),
    url_foto character varying(2048),
    alterado_em character varying(40),
    versao bigint,
    atualizado_em timestamp with time zone,
    referencia_api character varying(320) NOT NULL,
    resumo_semanal_ativo boolean,
    id_turma_resumo bigint,
    resumo_alterado_em_ms bigint,
    resumo_versao bigint,
    resumo_atualizado_em timestamp with time zone,
    CONSTRAINT perfis_conteudo_presente CHECK (((versao IS NOT NULL) OR (resumo_versao IS NOT NULL))),
    CONSTRAINT perfis_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT perfis_resumo_versao_check CHECK ((resumo_versao > 0)),
    CONSTRAINT perfis_resumo_versao_data CHECK (((resumo_versao IS NULL) = (resumo_atualizado_em IS NULL))),
    CONSTRAINT perfis_versao_check CHECK ((versao > 0)),
    CONSTRAINT perfis_versao_data CHECK (((versao IS NULL) = (atualizado_em IS NULL)))
);


--
-- Name: TABLE perfis; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.perfis IS 'Dados do perfil e preferências privadas do resumo semanal por usuário. A leitura pública seleciona somente os dados de apresentação e somente linhas com perfil publicado.';


--
-- Name: COLUMN perfis.id_perfil; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.id_perfil IS 'Identificador numérico do perfil do usuário. Chave primária gerada pela sequência ids_entidades.';


--
-- Name: COLUMN perfis.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.nome IS 'Campo displayName no contrato da API.';


--
-- Name: COLUMN perfis.empresa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.empresa IS 'Campo company no contrato da API.';


--
-- Name: COLUMN perfis.turma_informada; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.turma_informada IS 'Texto livre publicado pelo dono do perfil, como 2ºD. Não é a turma de autorização do representante nem uma referência obrigatória ao catálogo escolar.';


--
-- Name: COLUMN perfis.sala; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.sala IS 'Campo room no contrato da API.';


--
-- Name: COLUMN perfis.andar; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.andar IS 'Campo floor no contrato da API.';


--
-- Name: COLUMN perfis.url_foto; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.url_foto IS 'Campo photoUrl no contrato da API.';


--
-- Name: COLUMN perfis.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.alterado_em IS 'Campo updatedAt no contrato da API.';


--
-- Name: COLUMN perfis.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.versao IS 'Versão de edição dos dados de apresentação. Nula quando a conta apenas configurou o resumo e não publicou um perfil.';


--
-- Name: COLUMN perfis.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.atualizado_em IS 'Instante da última gravação dos dados de apresentação; nulo quando não há perfil publicado.';


--
-- Name: COLUMN perfis.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: COLUMN perfis.resumo_semanal_ativo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_semanal_ativo IS 'Escolha privada de receber o resumo semanal por e-mail. Nula quando não há preferência cadastrada.';


--
-- Name: COLUMN perfis.id_turma_resumo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.id_turma_resumo IS 'FK para turmas.id_turma. Turma selecionada para o resumo semanal, independente da turma livre informada no perfil público.';


--
-- Name: COLUMN perfis.resumo_alterado_em_ms; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_alterado_em_ms IS 'Momento da atualização da preferência em milissegundos desde o Unix epoch, preservado no contrato do serviço de e-mail.';


--
-- Name: COLUMN perfis.resumo_versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_versao IS 'Versão da preferência privada. Permite editar o perfil público e a inscrição no resumo sem sobrescrever uma seção ao salvar a outra.';


--
-- Name: COLUMN perfis.resumo_atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_atualizado_em IS 'Instante da última gravação da preferência privada do resumo; nulo quando não existe inscrição configurada.';


--
-- Name: perfis_administrativos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.perfis_administrativos (
    id_perfil_administrativo bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT perfis_administrativos_id_registro_not_null NOT NULL,
    papel character varying(32),
    criado_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT perfis_administrativos_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT perfis_administrativos_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE perfis_administrativos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.perfis_administrativos IS 'Papéis administrativos';


--
-- Name: COLUMN perfis_administrativos.id_perfil_administrativo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.id_perfil_administrativo IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN perfis_administrativos.papel; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.papel IS 'Campo role no contrato da API.';


--
-- Name: COLUMN perfis_administrativos.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN perfis_administrativos.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN perfis_administrativos.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN perfis_administrativos.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN perfis_administrativos.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: quadros_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.quadros_kanban (
    id_quadro_kanban bigint CONSTRAINT quadros_kanban_id_not_null NOT NULL,
    id_espaco_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    nome character varying(80),
    cor character varying(16),
    compacto boolean,
    CONSTRAINT quadros_kanban_ordem_check CHECK ((ordem >= 0))
);


--
-- Name: TABLE quadros_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.quadros_kanban IS 'Quadros do Kanban em cada espaço';


--
-- Name: COLUMN quadros_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.id_quadro_kanban IS 'Identificador numérico de quadros_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';


--
-- Name: COLUMN quadros_kanban.id_espaco_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.id_espaco_kanban IS 'Espaço pessoal ou compartilhado que contém o quadro. Referencia espacos_kanban.id_espaco_kanban.';


--
-- Name: COLUMN quadros_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.referencia IS 'Campo id no contrato da API.';


--
-- Name: COLUMN quadros_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.nome IS 'Campo name no contrato da API.';


--
-- Name: COLUMN quadros_kanban.cor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.cor IS 'Campo color no contrato da API.';


--
-- Name: COLUMN quadros_kanban.compacto; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.compacto IS 'Campo compact no contrato da API.';


--
-- Name: quadros_kanban_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.quadros_kanban ALTER COLUMN id_quadro_kanban ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.quadros_kanban_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recibos_gravacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.recibos_gravacao (
    id_recibo_gravacao character varying(128) CONSTRAINT app_commits_id_not_null NOT NULL,
    autor character varying(256) CONSTRAINT app_commits_actor_not_null NOT NULL,
    hash_requisicao character varying(64) CONSTRAINT app_commits_digest_not_null NOT NULL,
    confirmado_em timestamp with time zone DEFAULT now() CONSTRAINT app_commits_committed_at_not_null NOT NULL
);


--
-- Name: TABLE recibos_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.recibos_gravacao IS 'Recibos que impedem uma gravação repetida de ser aplicada duas vezes.';


--
-- Name: COLUMN recibos_gravacao.id_recibo_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.recibos_gravacao.id_recibo_gravacao IS 'Identificador externo do lote confirmado, recebido em commit.id. O valor continua estável nos reenvios e é exposto como id pela view de recibos.';


--
-- Name: regras_retencao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.regras_retencao (
    id_regra_retencao bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT regras_retencao_id_registro_not_null NOT NULL,
    dias smallint,
    ativa boolean,
    alterado_por character varying(128),
    alterado_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT regras_retencao_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT regras_retencao_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE regras_retencao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.regras_retencao IS 'Políticas de expurgo por turma';


--
-- Name: COLUMN regras_retencao.id_regra_retencao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.id_regra_retencao IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN regras_retencao.dias; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.dias IS 'Campo days no contrato da API.';


--
-- Name: COLUMN regras_retencao.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.ativa IS 'Campo enabled no contrato da API.';


--
-- Name: COLUMN regras_retencao.alterado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.alterado_por IS 'Campo updatedBy no contrato da API.';


--
-- Name: COLUMN regras_retencao.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.alterado_em IS 'Campo updatedAt no contrato da API.';


--
-- Name: COLUMN regras_retencao.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN regras_retencao.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN regras_retencao.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN regras_retencao.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: reservas_mensagens_ia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.reservas_mensagens_ia (
    firebase_uid text NOT NULL,
    operacao text NOT NULL,
    data_uso date NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    saldo_final integer,
    limite_aplicado integer,
    CONSTRAINT reservas_mensagens_ia_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT reservas_mensagens_ia_limite_aplicado_check CHECK ((limite_aplicado > 0)),
    CONSTRAINT reservas_mensagens_ia_operacao_check CHECK (((length(operacao) >= 1) AND (length(operacao) <= 161))),
    CONSTRAINT reservas_mensagens_ia_saldo_final_check CHECK ((saldo_final >= 0))
);


--
-- Name: school_classes_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.turmas ALTER COLUMN id_turma ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.school_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_subjects_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.disciplinas ALTER COLUMN id_disciplina ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.school_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_teachers_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.professores ALTER COLUMN id_professor ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.school_teachers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_time_slots_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.faixas_horario ALTER COLUMN id_faixa_horario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.school_time_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sugestoes_melhoria; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.sugestoes_melhoria (
    id_sugestao_melhoria bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT sugestoes_melhoria_id_registro_not_null NOT NULL,
    mensagem character varying(2000),
    criado_por character varying(128),
    email_criador character varying(320),
    criado_em character varying(40),
    credito_autorizado boolean,
    nome_credito character varying(60),
    situacao character varying(32),
    concluida_em character varying(40),
    concluida_por character varying(128),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT sugestoes_melhoria_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT sugestoes_melhoria_versao_check CHECK ((versao > 0))
);


--
-- Name: TABLE sugestoes_melhoria; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.sugestoes_melhoria IS 'Sugestões de melhoria da Agenda';


--
-- Name: COLUMN sugestoes_melhoria.id_sugestao_melhoria; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_sugestao_melhoria IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';


--
-- Name: COLUMN sugestoes_melhoria.mensagem; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.mensagem IS 'Campo message no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.criado_por IS 'Campo createdBy no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.email_criador; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.email_criador IS 'Campo createdByEmail no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.criado_em IS 'Campo createdAt no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.credito_autorizado; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.credito_autorizado IS 'Campo publicCreditAllowed no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.nome_credito; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.nome_credito IS 'Campo publicCreditName no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.situacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.situacao IS 'Campo status no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.concluida_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.concluida_em IS 'Campo completedAt no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.concluida_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.concluida_por IS 'Campo completedBy no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';


--
-- Name: COLUMN sugestoes_melhoria.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';


--
-- Name: COLUMN sugestoes_melhoria.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';


--
-- Name: COLUMN sugestoes_melhoria.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';


--
-- Name: uso_contas_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.uso_contas_assistente (
    dia date NOT NULL,
    firebase_uid text NOT NULL,
    mensagens integer NOT NULL,
    CONSTRAINT uso_contas_assistente_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT uso_contas_assistente_mensagens_check CHECK ((mensagens > 0))
);


--
-- Name: uso_diario_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.uso_diario_assistente (
    dia date NOT NULL,
    mensagens integer NOT NULL,
    CONSTRAINT uso_diario_assistente_mensagens_check CHECK ((mensagens > 0))
);


--
-- Name: TABLE uso_diario_assistente; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.uso_diario_assistente IS 'Total de mensagens aceitas pelo Assistente por dia de Brasília.';


--
-- Name: vinculos_professores_turmas_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.vinculos_professores_turmas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.vinculos_professores_turmas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vinculos_turma_perfil; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.vinculos_turma_perfil (
    firebase_uid text NOT NULL,
    turma text NOT NULL,
    alterada_em timestamp with time zone NOT NULL,
    pedido_turma text,
    pedido_em timestamp with time zone,
    CONSTRAINT vinculos_turma_perfil_check CHECK (((pedido_turma IS NULL) = (pedido_em IS NULL))),
    CONSTRAINT vinculos_turma_perfil_check1 CHECK (((pedido_turma IS NULL) OR (pedido_turma <> turma))),
    CONSTRAINT vinculos_turma_perfil_pedido_turma_check CHECK (((length(pedido_turma) >= 1) AND (length(pedido_turma) <= 80))),
    CONSTRAINT vinculos_turma_perfil_turma_check CHECK (((length(turma) >= 1) AND (length(turma) <= 80)))
);


--
-- Name: visao_atividades; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_atividades AS
 SELECT referencia_api AS id,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = a.id_turma)) AS turma_id,
    titulo AS title,
    COALESCE(descricao, ''::character varying) AS description,
    tipo_atividade AS type,
    (( SELECT COALESCE(( SELECT rotulo_nota.nome
                   FROM tech2d.visao_disciplinas_notas rotulo_nota
                  WHERE (rotulo_nota.id = rotulo_disciplina.id_disciplina)
                  ORDER BY rotulo_nota.ano_serie DESC
                 LIMIT 1), rotulo_disciplina.nome) AS "coalesce"
           FROM tech2d.disciplinas rotulo_disciplina
          WHERE (rotulo_disciplina.id_disciplina = a.id_disciplina)))::character varying(150) AS subject,
    (data_atividade)::character varying(10) AS date,
    to_char((hora_atividade)::interval, 'HH24:MI'::text) AS "time",
    criado_por AS created_by,
    email_criador AS created_by_email,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE (rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia)) AS recurring_id,
    COALESCE(( SELECT jsonb_agg(tech2d.ler_anexos_atividade(f.id_anexo_atividade) ORDER BY f.id_anexo_atividade) AS jsonb_agg
           FROM tech2d.anexos_atividade f
          WHERE (f.id_atividade = a.id_atividade)), '[]'::jsonb) AS attachments,
    (criado_em)::timestamp with time zone AS created_at,
    (alterado_em)::timestamp with time zone AS updated_at,
    versao AS version
   FROM tech2d.atividades a;


--
-- Name: VIEW visao_atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_atividades IS 'Atividades com seus anexos, para o calendário e os links diretos.';


--
-- Name: visao_atividades_automacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_atividades_automacao AS
 SELECT referencia_api AS id,
    tech2d.referencia_api('activities'::character varying, ''::character varying, referencia_api) AS caminho,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = a.id_turma)) AS turma,
    data_atividade AS data,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE (rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia)) AS referencia_recorrencia,
    tech2d.ler_registro(id_atividade, 'activities'::character varying) AS conteudo
   FROM tech2d.atividades a;


--
-- Name: VIEW visao_atividades_automacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_atividades_automacao IS 'Atividades com turma, data e recorrência tipadas para os jobs. O conteúdo é reconstruído apenas para uso no arquivamento.';


--
-- Name: visao_catalogo_horarios; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_catalogo_horarios AS
 SELECT id,
    dia_semana AS day_of_week,
    ativo AS active,
    nome_turma AS class_name,
    dados AS data
   FROM tech2d.catalogo_horarios;


--
-- Name: VIEW visao_catalogo_horarios; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_catalogo_horarios IS 'Apelidos de colunas usados pela API do Cadê o professor.';


--
-- Name: visao_disciplinas; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_disciplinas WITH (security_invoker='true') AS
 SELECT id_disciplina AS id,
    nome AS name
   FROM tech2d.disciplinas;


--
-- Name: VIEW visao_disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_disciplinas IS 'Interface SQL de compatibilidade para disciplinas';


--
-- Name: visao_documentos_aplicacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_documentos_aplicacao AS
 SELECT tech2d.referencia_api('activities'::character varying, ''::character varying, atividades.referencia_api) AS path,
    'activities'::text AS collection,
    atividades.referencia_api AS id,
    tech2d.ler_registro(atividades.id_atividade, 'activities'::character varying) AS data,
    atividades.versao AS version,
    atividades.atualizado_em AS updated_at
   FROM tech2d.atividades
UNION ALL
 SELECT tech2d.referencia_api('admins'::character varying, ''::character varying, perfis_administrativos.referencia_api) AS path,
    'admins'::text AS collection,
    perfis_administrativos.referencia_api AS id,
    tech2d.ler_registro(perfis_administrativos.id_perfil_administrativo, 'admins'::character varying) AS data,
    perfis_administrativos.versao AS version,
    perfis_administrativos.atualizado_em AS updated_at
   FROM tech2d.perfis_administrativos
UNION ALL
 SELECT tech2d.referencia_api('recurringActivities'::character varying, ''::character varying, regras_recorrencia.referencia_api) AS path,
    'recurringActivities'::text AS collection,
    regras_recorrencia.referencia_api AS id,
    tech2d.ler_registro(regras_recorrencia.id_regra_recorrencia, 'recurringActivities'::character varying) AS data,
    regras_recorrencia.versao AS version,
    regras_recorrencia.atualizado_em AS updated_at
   FROM tech2d.regras_recorrencia
UNION ALL
 SELECT tech2d.referencia_api('activityRetention'::character varying, ''::character varying, regras_retencao.referencia_api) AS path,
    'activityRetention'::text AS collection,
    regras_retencao.referencia_api AS id,
    tech2d.ler_registro(regras_retencao.id_regra_retencao, 'activityRetention'::character varying) AS data,
    regras_retencao.versao AS version,
    regras_retencao.atualizado_em AS updated_at
   FROM tech2d.regras_retencao
UNION ALL
 SELECT tech2d.referencia_api('agendaClasses'::character varying, ''::character varying, turmas_agenda.referencia_api) AS path,
    'agendaClasses'::text AS collection,
    turmas_agenda.referencia_api AS id,
    tech2d.ler_registro(turmas_agenda.id_turma_agenda, 'agendaClasses'::character varying) AS data,
    turmas_agenda.versao AS version,
    turmas_agenda.atualizado_em AS updated_at
   FROM tech2d.turmas_agenda
UNION ALL
 SELECT tech2d.referencia_api('feedback'::character varying, ''::character varying, sugestoes_melhoria.referencia_api) AS path,
    'feedback'::text AS collection,
    sugestoes_melhoria.referencia_api AS id,
    tech2d.ler_registro(sugestoes_melhoria.id_sugestao_melhoria, 'feedback'::character varying) AS data,
    sugestoes_melhoria.versao AS version,
    sugestoes_melhoria.atualizado_em AS updated_at
   FROM tech2d.sugestoes_melhoria
UNION ALL
 SELECT tech2d.referencia_api('schedules'::character varying, ''::character varying, horarios_aula.id_horario_aula) AS path,
    'schedules'::text AS collection,
    horarios_aula.id_horario_aula AS id,
    tech2d.ler_registro(horarios_aula.id_horario_interno, 'schedules'::character varying) AS data,
    horarios_aula.versao AS version,
    horarios_aula.atualizado_em AS updated_at
   FROM tech2d.horarios_aula
UNION ALL
 SELECT tech2d.referencia_api('userProfiles'::character varying, ''::character varying, perfis.referencia_api) AS path,
    'userProfiles'::text AS collection,
    perfis.referencia_api AS id,
    tech2d.ler_registro(perfis.id_perfil, 'userProfiles'::character varying) AS data,
    perfis.versao AS version,
    perfis.atualizado_em AS updated_at
   FROM tech2d.perfis
  WHERE (perfis.versao IS NOT NULL)
UNION ALL
 SELECT tech2d.referencia_api('_agendaDigestPreferences'::character varying, ''::character varying, perfis.referencia_api) AS path,
    '_agendaDigestPreferences'::text AS collection,
    perfis.referencia_api AS id,
    tech2d.ler_registro(perfis.id_perfil, '_agendaDigestPreferences'::character varying) AS data,
    perfis.resumo_versao AS version,
    perfis.resumo_atualizado_em AS updated_at
   FROM tech2d.perfis
  WHERE (perfis.resumo_versao IS NOT NULL)
UNION ALL
 SELECT tech2d.referencia_api('personalKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'personalKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'personalKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE (NOT espacos_kanban.compartilhado)
UNION ALL
 SELECT tech2d.referencia_api('kanbanMemberships'::character varying, ''::character varying, participantes_kanban.referencia_api) AS path,
    'kanbanMemberships'::text AS collection,
    participantes_kanban.referencia_api AS id,
    tech2d.ler_registro(participantes_kanban.id_participante_kanban, 'kanbanMemberships'::character varying) AS data,
    participantes_kanban.versao AS version,
    participantes_kanban.atualizado_em AS updated_at
   FROM tech2d.participantes_kanban
UNION ALL
 SELECT tech2d.referencia_api('sharedKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'sharedKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'sharedKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE espacos_kanban.compartilhado;


--
-- Name: VIEW visao_documentos_aplicacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_documentos_aplicacao IS 'Contrato de leitura da API. Reconstrói os objetos a partir das tabelas tipadas.';


--
-- Name: visao_documentos_catalogo; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_documentos_catalogo AS
 SELECT 'schedules'::character varying(40) AS collection,
    horarios_aula.id_horario_aula AS id,
    tech2d.ler_registro(horarios_aula.id_horario_interno, 'schedules'::character varying) AS data
   FROM tech2d.horarios_aula
UNION ALL
 SELECT 'agendaClasses'::character varying(40) AS collection,
    turmas_agenda.referencia_api AS id,
    tech2d.ler_registro(turmas_agenda.id_turma_agenda, 'agendaClasses'::character varying) AS data
   FROM tech2d.turmas_agenda;


--
-- Name: VIEW visao_documentos_catalogo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_documentos_catalogo IS 'Catálogo calculado a partir das tabelas tipadas.';


--
-- Name: visao_faixas_horario; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_faixas_horario WITH (security_invoker='true') AS
 SELECT id_faixa_horario AS id,
    hora_inicio AS start_time,
    hora_fim AS end_time
   FROM tech2d.faixas_horario;


--
-- Name: VIEW visao_faixas_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_faixas_horario IS 'Interface SQL de compatibilidade para faixas_horario';


--
-- Name: visao_horarios_aula; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_horarios_aula WITH (security_invoker='true') AS
 SELECT id_horario_aula AS id,
    id_professor AS teacher_id,
    id_disciplina AS subject_id,
    id_turma AS class_id,
    id_faixa_horario AS time_slot_id,
    dia_semana AS day_of_week,
    ativo AS active
   FROM tech2d.horarios_aula;


--
-- Name: VIEW visao_horarios_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_horarios_aula IS 'Interface SQL de compatibilidade para horarios_aula';


--
-- Name: visao_notas_resultados; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_notas_resultados WITH (security_invoker='true') AS
 WITH semestres AS (
         SELECT c.id_usuario,
            c.ano_letivo,
            c.ano_serie,
            c.regra_calculo,
            c.versao,
            d.id AS id_disciplina,
            d.nome,
                CASE
                    WHEN ((c.modo_primeiro)::text = 'media'::text) THEN p.media_informada
                    ELSE round((((p.n1 * (p.peso_n1)::numeric) + (p.n2 * ((100 - p.peso_n1))::numeric)) / (100)::numeric), 2)
                END AS media_primeiro,
                CASE
                    WHEN ((c.modo_segundo)::text = 'media'::text) THEN s.media_informada
                    ELSE round((((s.n1 * (s.peso_n1)::numeric) + (s.n2 * ((100 - s.peso_n1))::numeric)) / (100)::numeric), 2)
                END AS media_segundo,
            r.nota AS recuperacao_final
           FROM ((((tech2d.notas_cadernos c
             JOIN tech2d.visao_disciplinas_notas d USING (ano_serie))
             LEFT JOIN tech2d.notas_lancamentos p ON ((((p.id_usuario)::text = (c.id_usuario)::text) AND (p.ano_letivo = c.ano_letivo) AND (p.id_disciplina = d.id) AND (p.semestre = 1))))
             LEFT JOIN tech2d.notas_lancamentos s ON ((((s.id_usuario)::text = (c.id_usuario)::text) AND (s.ano_letivo = c.ano_letivo) AND (s.id_disciplina = d.id) AND (s.semestre = 2))))
             LEFT JOIN tech2d.notas_recuperacoes r ON ((((r.id_usuario)::text = (c.id_usuario)::text) AND (r.ano_letivo = c.ano_letivo) AND (r.id_disciplina = d.id))))
        ), recuperadas AS (
         SELECT semestres.id_usuario,
            semestres.ano_letivo,
            semestres.ano_serie,
            semestres.regra_calculo,
            semestres.versao,
            semestres.id_disciplina,
            semestres.nome,
            semestres.media_primeiro,
            semestres.media_segundo,
            semestres.recuperacao_final,
                CASE
                    WHEN ((semestres.media_segundo > COALESCE(semestres.media_primeiro, (0)::numeric)) AND (round(LEAST(((COALESCE(semestres.media_primeiro, (0)::numeric) + semestres.media_segundo) / (2)::numeric), (7)::numeric), 2) > COALESCE(semestres.media_primeiro, (0)::numeric))) THEN round(LEAST(((COALESCE(semestres.media_primeiro, (0)::numeric) + semestres.media_segundo) / (2)::numeric), (7)::numeric), 2)
                    ELSE NULL::numeric
                END AS media_recuperada
           FROM semestres
        ), anuais AS (
         SELECT recuperadas.id_usuario,
            recuperadas.ano_letivo,
            recuperadas.ano_serie,
            recuperadas.regra_calculo,
            recuperadas.versao,
            recuperadas.id_disciplina,
            recuperadas.nome,
            recuperadas.media_primeiro,
            recuperadas.media_segundo,
            recuperadas.recuperacao_final,
            recuperadas.media_recuperada,
                CASE
                    WHEN (recuperadas.media_segundo IS NULL) THEN recuperadas.media_primeiro
                    ELSE round(((COALESCE(recuperadas.media_recuperada, recuperadas.media_primeiro, (0)::numeric) + (recuperadas.media_segundo * (2)::numeric)) / (3)::numeric), 2)
                END AS media_anual
           FROM recuperadas
        )
 SELECT id_usuario,
    ano_letivo,
    ano_serie,
    regra_calculo,
    versao,
    id_disciplina,
    nome,
    media_primeiro,
    media_segundo,
    recuperacao_final,
    media_recuperada,
    media_anual,
        CASE
            WHEN ((media_segundo IS NOT NULL) AND (media_anual < (7)::numeric)) THEN GREATEST((0)::numeric, ((12)::numeric - media_anual))
            ELSE NULL::numeric
        END AS nota_necessaria,
        CASE
            WHEN ((media_segundo IS NOT NULL) AND (media_anual < (7)::numeric) AND (recuperacao_final IS NOT NULL)) THEN round(((media_anual + recuperacao_final) / (2)::numeric), 2)
            ELSE NULL::numeric
        END AS media_final,
        CASE
            WHEN ((media_primeiro IS NULL) AND (media_segundo IS NULL)) THEN 'sem-notas'::text
            WHEN (media_segundo IS NULL) THEN 'andamento'::text
            WHEN (media_anual >= (7)::numeric) THEN 'aprovado'::text
            WHEN (recuperacao_final IS NULL) THEN 'recuperacao'::text
            WHEN (round(((media_anual + recuperacao_final) / (2)::numeric), 2) >= (6)::numeric) THEN 'aprovado-rec'::text
            ELSE 'reprovado'::text
        END AS situacao
   FROM anuais;


--
-- Name: VIEW visao_notas_resultados; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_notas_resultados IS 'Médias por conta e disciplina do catálogo compartilhado; aplica as fórmulas tech-2026-v1 e preserva RLS nas tabelas de notas.';


--
-- Name: visao_perfis_administrativos; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_perfis_administrativos AS
 SELECT referencia_api AS uid,
    papel AS role,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = p.id_turma)) AS turma_id,
    tech2d.ler_registro(id_perfil_administrativo, 'admins'::character varying) AS data
   FROM tech2d.perfis_administrativos p;


--
-- Name: VIEW visao_perfis_administrativos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_perfis_administrativos IS 'Papéis e turmas administrativas no formato consumido pela API.';


--
-- Name: visao_professores; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_professores WITH (security_invoker='true') AS
 SELECT id_professor AS id,
    nome AS name
   FROM tech2d.professores;


--
-- Name: VIEW visao_professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_professores IS 'Interface SQL de compatibilidade para professores';


--
-- Name: visao_recibos_gravacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_recibos_gravacao WITH (security_invoker='true') AS
 SELECT id_recibo_gravacao AS id,
    autor AS actor,
    hash_requisicao AS digest,
    confirmado_em AS committed_at
   FROM tech2d.recibos_gravacao;


--
-- Name: VIEW visao_recibos_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_recibos_gravacao IS 'Interface SQL de compatibilidade para recibos_gravacao';


--
-- Name: visao_turmas; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_turmas WITH (security_invoker='true') AS
 SELECT id_turma AS id,
    nome AS name
   FROM tech2d.turmas;


--
-- Name: VIEW visao_turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_turmas IS 'Interface SQL de compatibilidade para turmas';


--
-- Name: visitas_aos_sites; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.visitas_aos_sites (
    dia date CONSTRAINT agenda_access_day_not_null NOT NULL,
    intervalo_meia_hora bigint CONSTRAINT agenda_access_half_hour_not_null NOT NULL,
    tipo_visitante character varying(32) CONSTRAINT agenda_access_kind_not_null NOT NULL,
    chave_visitante character varying(128) CONSTRAINT agenda_access_visitor_key_not_null NOT NULL,
    site character varying(32) DEFAULT 'agenda'::text CONSTRAINT agenda_access_site_not_null NOT NULL,
    CONSTRAINT agenda_access_check CHECK (((((tipo_visitante)::text = 'anonymous'::text) AND ((chave_visitante)::text ~ '^[0-9a-f]{64}$'::text)) OR (((tipo_visitante)::text = 'account'::text) AND ((char_length((chave_visitante)::text) >= 1) AND (char_length((chave_visitante)::text) <= 128))))),
    CONSTRAINT agenda_access_kind_check CHECK (((tipo_visitante)::text = ANY (ARRAY['account'::text, 'anonymous'::text]))),
    CONSTRAINT visitas_aos_sites_site_check CHECK (((site)::text = ANY (ARRAY[('agenda'::character varying)::text, ('professores'::character varying)::text, ('pegaki'::character varying)::text, ('kanban'::character varying)::text])))
);


--
-- Name: TABLE visitas_aos_sites; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.visitas_aos_sites IS 'Visitas da Agenda e do Cadê o professor, agrupadas por visitante e intervalo de 30 minutos.';


--
-- Name: anexos_atividade anexos_atividade_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.anexos_atividade
    ADD CONSTRAINT anexos_atividade_pkey PRIMARY KEY (id_anexo_atividade);


--
-- Name: apelidos_disciplinas apelidos_disciplinas_id_disciplina_chave_normalizada_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_id_disciplina_chave_normalizada_key UNIQUE (id_disciplina, chave_normalizada);


--
-- Name: apelidos_disciplinas apelidos_disciplinas_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_pkey PRIMARY KEY (id);


--
-- Name: apelidos_professores apelidos_professores_id_professor_chave_normalizada_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_id_professor_chave_normalizada_key UNIQUE (id_professor, chave_normalizada);


--
-- Name: apelidos_professores apelidos_professores_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_pkey PRIMARY KEY (id);


--
-- Name: recibos_gravacao app_commits_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.recibos_gravacao
    ADD CONSTRAINT app_commits_pkey PRIMARY KEY (id_recibo_gravacao);


--
-- Name: atividades atividades_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_pkey PRIMARY KEY (id_atividade);


--
-- Name: atividades atividades_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_referencia_api_key UNIQUE (referencia_api);


--
-- Name: aulas_recuperacao aulas_recuperacao_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.aulas_recuperacao
    ADD CONSTRAINT aulas_recuperacao_pkey PRIMARY KEY (edital_id, ordem);


--
-- Name: cartoes_kanban cartoes_kanban_id_quadro_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_id_quadro_kanban_ordem_key UNIQUE (id_quadro_kanban, ordem);


--
-- Name: cartoes_kanban cartoes_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_pkey PRIMARY KEY (id_cartao_kanban);


--
-- Name: colunas_kanban colunas_kanban_id_quadro_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_id_quadro_kanban_ordem_key UNIQUE (id_quadro_kanban, ordem);


--
-- Name: colunas_kanban colunas_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_pkey PRIMARY KEY (id_coluna_kanban);


--
-- Name: colunas_kanban colunas_kanban_referencia_quadro; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_referencia_quadro UNIQUE (id_quadro_kanban, referencia);


--
-- Name: config_assistente config_assistente_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.config_assistente
    ADD CONSTRAINT config_assistente_pkey PRIMARY KEY (id);


--
-- Name: config_fechamento_agenda config_fechamento_agenda_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.config_fechamento_agenda
    ADD CONSTRAINT config_fechamento_agenda_pkey PRIMARY KEY (id);


--
-- Name: disciplinas_series disciplinas_series_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas_series
    ADD CONSTRAINT disciplinas_series_pkey PRIMARY KEY (id_disciplina, ano_serie);


--
-- Name: editais_recuperacao editais_recuperacao_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.editais_recuperacao
    ADD CONSTRAINT editais_recuperacao_pkey PRIMARY KEY (id);


--
-- Name: espacos_kanban espacos_kanban_compartilhado_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.espacos_kanban
    ADD CONSTRAINT espacos_kanban_compartilhado_referencia_api_key UNIQUE (compartilhado, referencia_api);


--
-- Name: espacos_kanban espacos_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.espacos_kanban
    ADD CONSTRAINT espacos_kanban_pkey PRIMARY KEY (id_espaco_kanban);


--
-- Name: horarios_aula horarios_aula_id_registro_aplicacao_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT horarios_aula_id_registro_aplicacao_key UNIQUE (id_horario_interno);


--
-- Name: itens_checklist itens_checklist_id_cartao_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_id_cartao_kanban_ordem_key UNIQUE (id_cartao_kanban, ordem);


--
-- Name: itens_checklist itens_checklist_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_pkey PRIMARY KEY (id_item_checklist);


--
-- Name: limites_mensagens_ia limites_mensagens_ia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.limites_mensagens_ia
    ADD CONSTRAINT limites_mensagens_ia_pkey PRIMARY KEY (firebase_uid);


--
-- Name: limpeza_anexos_agenda limpeza_anexos_agenda_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.limpeza_anexos_agenda
    ADD CONSTRAINT limpeza_anexos_agenda_pkey PRIMARY KEY (chave_arquivo);


--
-- Name: limpezas_anuais_agenda limpezas_anuais_agenda_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.limpezas_anuais_agenda
    ADD CONSTRAINT limpezas_anuais_agenda_pkey PRIMARY KEY (operacao);


--
-- Name: notas_cadernos notas_cadernos_id_usuario_ano_letivo_ano_serie_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_cadernos
    ADD CONSTRAINT notas_cadernos_id_usuario_ano_letivo_ano_serie_key UNIQUE (id_usuario, ano_letivo, ano_serie);


--
-- Name: notas_cadernos notas_cadernos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_cadernos
    ADD CONSTRAINT notas_cadernos_pkey PRIMARY KEY (id_usuario, ano_letivo);


--
-- Name: notas_lancamentos notas_lancamentos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_pkey PRIMARY KEY (id_usuario, ano_letivo, id_disciplina, semestre);


--
-- Name: notas_recuperacoes notas_recuperacoes_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_recuperacoes
    ADD CONSTRAINT notas_recuperacoes_pkey PRIMARY KEY (id_usuario, ano_letivo, id_disciplina);


--
-- Name: participantes_kanban participantes_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.participantes_kanban
    ADD CONSTRAINT participantes_kanban_pkey PRIMARY KEY (id_participante_kanban);


--
-- Name: participantes_kanban participantes_kanban_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.participantes_kanban
    ADD CONSTRAINT participantes_kanban_referencia_api_key UNIQUE (referencia_api);


--
-- Name: perfis_administrativos perfis_administrativos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_pkey PRIMARY KEY (id_perfil_administrativo);


--
-- Name: perfis_administrativos perfis_administrativos_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_referencia_api_key UNIQUE (referencia_api);


--
-- Name: perfis perfis_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_pkey PRIMARY KEY (id_perfil);


--
-- Name: perfis perfis_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_referencia_api_key UNIQUE (referencia_api);


--
-- Name: quadros_kanban quadros_kanban_id_espaco_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_id_espaco_kanban_ordem_key UNIQUE (id_espaco_kanban, ordem);


--
-- Name: quadros_kanban quadros_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_pkey PRIMARY KEY (id_quadro_kanban);


--
-- Name: regras_recorrencia regras_recorrencia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_pkey PRIMARY KEY (id_regra_recorrencia);


--
-- Name: regras_recorrencia regras_recorrencia_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_referencia_api_key UNIQUE (referencia_api);


--
-- Name: regras_retencao regras_retencao_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_pkey PRIMARY KEY (id_regra_retencao);


--
-- Name: regras_retencao regras_retencao_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_referencia_api_key UNIQUE (referencia_api);


--
-- Name: reservas_mensagens_ia reservas_mensagens_ia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.reservas_mensagens_ia
    ADD CONSTRAINT reservas_mensagens_ia_pkey PRIMARY KEY (firebase_uid, operacao);


--
-- Name: turmas school_classes_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT school_classes_name_key UNIQUE (nome);


--
-- Name: turmas school_classes_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT school_classes_pkey PRIMARY KEY (id_turma);


--
-- Name: horarios_aula school_schedules_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_pkey PRIMARY KEY (id_horario_aula);


--
-- Name: disciplinas school_subjects_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas
    ADD CONSTRAINT school_subjects_name_key UNIQUE (nome);


--
-- Name: disciplinas school_subjects_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas
    ADD CONSTRAINT school_subjects_pkey PRIMARY KEY (id_disciplina);


--
-- Name: professores school_teachers_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.professores
    ADD CONSTRAINT school_teachers_name_key UNIQUE (nome);


--
-- Name: professores school_teachers_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.professores
    ADD CONSTRAINT school_teachers_pkey PRIMARY KEY (id_professor);


--
-- Name: faixas_horario school_time_slots_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.faixas_horario
    ADD CONSTRAINT school_time_slots_pkey PRIMARY KEY (id_faixa_horario);


--
-- Name: faixas_horario school_time_slots_start_time_end_time_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.faixas_horario
    ADD CONSTRAINT school_time_slots_start_time_end_time_key UNIQUE (hora_inicio, hora_fim);


--
-- Name: sugestoes_melhoria sugestoes_melhoria_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_pkey PRIMARY KEY (id_sugestao_melhoria);


--
-- Name: sugestoes_melhoria sugestoes_melhoria_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_referencia_api_key UNIQUE (referencia_api);


--
-- Name: turmas_agenda turmas_agenda_id_turma_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_id_turma_key UNIQUE (id_turma);


--
-- Name: turmas_agenda turmas_agenda_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_pkey PRIMARY KEY (id_turma_agenda);


--
-- Name: turmas_agenda turmas_agenda_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_referencia_api_key UNIQUE (referencia_api);


--
-- Name: turmas turmas_referencia_agenda_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT turmas_referencia_agenda_key UNIQUE (referencia_agenda);


--
-- Name: uso_contas_assistente uso_contas_assistente_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.uso_contas_assistente
    ADD CONSTRAINT uso_contas_assistente_pkey PRIMARY KEY (dia, firebase_uid);


--
-- Name: uso_diario_assistente uso_diario_assistente_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.uso_diario_assistente
    ADD CONSTRAINT uso_diario_assistente_pkey PRIMARY KEY (dia);


--
-- Name: vinculos_professores_turmas vinculos_professores_turmas_numrange_numrange1_daterange_excl; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_numrange_numrange1_daterange_excl EXCLUDE USING gist (numrange((id_turma)::numeric, (id_turma)::numeric, '[]'::text) WITH &&, numrange((id_disciplina)::numeric, (id_disciplina)::numeric, '[]'::text) WITH &&, daterange(vigencia_inicio, vigencia_fim, '[]'::text) WITH &&);


--
-- Name: vinculos_professores_turmas vinculos_professores_turmas_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_pkey PRIMARY KEY (id);


--
-- Name: vinculos_turma_perfil vinculos_turma_perfil_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_turma_perfil
    ADD CONSTRAINT vinculos_turma_perfil_pkey PRIMARY KEY (firebase_uid);


--
-- Name: visitas_aos_sites visitas_aos_sites_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.visitas_aos_sites
    ADD CONSTRAINT visitas_aos_sites_pkey PRIMARY KEY (site, dia, intervalo_meia_hora, tipo_visitante, chave_visitante);


--
-- Name: apelidos_disciplinas_chave; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX apelidos_disciplinas_chave ON tech2d.apelidos_disciplinas USING btree (chave_normalizada);


--
-- Name: apelidos_professores_chave; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX apelidos_professores_chave ON tech2d.apelidos_professores USING btree (chave_normalizada);


--
-- Name: atividades_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_caminho_api_idx ON tech2d.atividades USING btree (tech2d.referencia_api('activities'::character varying, ''::character varying, referencia_api));


--
-- Name: atividades_data; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_data ON tech2d.atividades USING btree (data_atividade);


--
-- Name: atividades_disciplina_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_disciplina_idx ON tech2d.atividades USING btree (id_disciplina);


--
-- Name: atividades_regra_recorrencia_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_regra_recorrencia_idx ON tech2d.atividades USING btree (id_regra_recorrencia);


--
-- Name: atividades_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_turma_idx ON tech2d.atividades USING btree (id_turma);


--
-- Name: espacos_kanban_personalkanban_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX espacos_kanban_personalkanban_caminho_api_idx ON tech2d.espacos_kanban USING btree (tech2d.referencia_api('personalKanban'::character varying, ''::character varying, referencia_api)) WHERE (NOT compartilhado);


--
-- Name: espacos_kanban_sharedkanban_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX espacos_kanban_sharedkanban_caminho_api_idx ON tech2d.espacos_kanban USING btree (tech2d.referencia_api('sharedKanban'::character varying, ''::character varying, referencia_api)) WHERE compartilhado;


--
-- Name: horarios_aula_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX horarios_aula_caminho_api_idx ON tech2d.horarios_aula USING btree (tech2d.referencia_api('schedules'::character varying, ''::character varying, id_horario_aula));


--
-- Name: limpeza_anexos_agenda_pendentes_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX limpeza_anexos_agenda_pendentes_idx ON tech2d.limpeza_anexos_agenda USING btree (tentar_apos, chave_arquivo);


--
-- Name: limpezas_anuais_agenda_executada_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX limpezas_anuais_agenda_executada_idx ON tech2d.limpezas_anuais_agenda USING btree (executada_em DESC);


--
-- Name: participantes_kanban_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX participantes_kanban_caminho_api_idx ON tech2d.participantes_kanban USING btree (tech2d.referencia_api('kanbanMemberships'::character varying, ''::character varying, referencia_api));


--
-- Name: participantes_kanban_quadro; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX participantes_kanban_quadro ON tech2d.participantes_kanban USING btree (referencia_quadro);


--
-- Name: perfis_administrativos_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_administrativos_caminho_api_idx ON tech2d.perfis_administrativos USING btree (tech2d.referencia_api('admins'::character varying, ''::character varying, referencia_api));


--
-- Name: perfis_administrativos_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_administrativos_turma_idx ON tech2d.perfis_administrativos USING btree (id_turma);


--
-- Name: perfis_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_caminho_api_idx ON tech2d.perfis USING btree (tech2d.referencia_api('userProfiles'::character varying, ''::character varying, referencia_api));


--
-- Name: perfis_turma_resumo_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_turma_resumo_idx ON tech2d.perfis USING btree (id_turma_resumo) WHERE (id_turma_resumo IS NOT NULL);


--
-- Name: regras_recorrencia_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_recorrencia_caminho_api_idx ON tech2d.regras_recorrencia USING btree (tech2d.referencia_api('recurringActivities'::character varying, ''::character varying, referencia_api));


--
-- Name: regras_recorrencia_disciplina_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_recorrencia_disciplina_idx ON tech2d.regras_recorrencia USING btree (id_disciplina);


--
-- Name: regras_recorrencia_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_recorrencia_turma_idx ON tech2d.regras_recorrencia USING btree (id_turma);


--
-- Name: regras_retencao_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_retencao_caminho_api_idx ON tech2d.regras_retencao USING btree (tech2d.referencia_api('activityRetention'::character varying, ''::character varying, referencia_api));


--
-- Name: regras_retencao_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_retencao_turma_idx ON tech2d.regras_retencao USING btree (id_turma);


--
-- Name: school_schedules_active_class_day; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX school_schedules_active_class_day ON tech2d.horarios_aula USING btree (id_turma, dia_semana) WHERE ativo;


--
-- Name: sugestoes_melhoria_autor; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX sugestoes_melhoria_autor ON tech2d.sugestoes_melhoria USING btree (criado_por);


--
-- Name: sugestoes_melhoria_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX sugestoes_melhoria_caminho_api_idx ON tech2d.sugestoes_melhoria USING btree (tech2d.referencia_api('feedback'::character varying, ''::character varying, referencia_api));


--
-- Name: sugestoes_melhoria_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX sugestoes_melhoria_turma_idx ON tech2d.sugestoes_melhoria USING btree (id_turma);


--
-- Name: turmas_agenda_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX turmas_agenda_caminho_api_idx ON tech2d.turmas_agenda USING btree (tech2d.referencia_api('agendaClasses'::character varying, ''::character varying, referencia_api));


--
-- Name: turmas_agenda_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX turmas_agenda_turma_idx ON tech2d.turmas_agenda USING btree (id_turma);


--
-- Name: vinculos_professores_turmas_busca; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX vinculos_professores_turmas_busca ON tech2d.vinculos_professores_turmas USING btree (id_turma, id_disciplina, vigencia_inicio, vigencia_fim);


--
-- Name: vinculos_professores_turmas_professor; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX vinculos_professores_turmas_professor ON tech2d.vinculos_professores_turmas USING btree (id_professor, id_turma, id_disciplina, vigencia_inicio, vigencia_fim);


--
-- Name: vinculos_turma_pedidos_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX vinculos_turma_pedidos_idx ON tech2d.vinculos_turma_perfil USING btree (pedido_em, firebase_uid) WHERE (pedido_em IS NOT NULL);


--
-- Name: horarios_aula vincular_disciplina_notaki; Type: TRIGGER; Schema: tech2d; Owner: -
--

CREATE TRIGGER vincular_disciplina_notaki AFTER INSERT OR UPDATE OF id_turma, id_disciplina, ativo ON tech2d.horarios_aula FOR EACH ROW WHEN (new.ativo) EXECUTE FUNCTION tech2d.vincular_nova_disciplina_notaki();


--
-- Name: anexos_atividade anexos_atividade_id_atividade_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.anexos_atividade
    ADD CONSTRAINT anexos_atividade_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES tech2d.atividades(id_atividade) ON DELETE CASCADE;


--
-- Name: apelidos_disciplinas apelidos_disciplinas_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;


--
-- Name: apelidos_professores apelidos_professores_id_professor_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_id_professor_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT;


--
-- Name: atividades atividades_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;


--
-- Name: atividades atividades_id_regra_recorrencia_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_regra_recorrencia_fkey FOREIGN KEY (id_regra_recorrencia) REFERENCES tech2d.regras_recorrencia(id_regra_recorrencia) ON DELETE SET NULL;


--
-- Name: atividades atividades_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: aulas_recuperacao aulas_recuperacao_edital_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.aulas_recuperacao
    ADD CONSTRAINT aulas_recuperacao_edital_id_fkey FOREIGN KEY (edital_id) REFERENCES tech2d.editais_recuperacao(id);


--
-- Name: cartoes_kanban cartoes_kanban_coluna; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_coluna FOREIGN KEY (id_quadro_kanban, referencia_coluna) REFERENCES tech2d.colunas_kanban(id_quadro_kanban, referencia) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: cartoes_kanban cartoes_kanban_id_quadro_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_id_quadro_kanban_fkey FOREIGN KEY (id_quadro_kanban) REFERENCES tech2d.quadros_kanban(id_quadro_kanban) ON DELETE CASCADE;


--
-- Name: colunas_kanban colunas_kanban_id_quadro_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_id_quadro_kanban_fkey FOREIGN KEY (id_quadro_kanban) REFERENCES tech2d.quadros_kanban(id_quadro_kanban) ON DELETE CASCADE;


--
-- Name: disciplinas_series disciplinas_series_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas_series
    ADD CONSTRAINT disciplinas_series_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina);


--
-- Name: itens_checklist itens_checklist_id_cartao_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_id_cartao_kanban_fkey FOREIGN KEY (id_cartao_kanban) REFERENCES tech2d.cartoes_kanban(id_cartao_kanban) ON DELETE CASCADE;


--
-- Name: notas_lancamentos notas_lancamentos_disciplina_serie_fk; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_disciplina_serie_fk FOREIGN KEY (id_disciplina, ano_serie) REFERENCES tech2d.disciplinas_series(id_disciplina, ano_serie);


--
-- Name: notas_lancamentos notas_lancamentos_id_usuario_ano_letivo_ano_serie_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_id_usuario_ano_letivo_ano_serie_fkey FOREIGN KEY (id_usuario, ano_letivo, ano_serie) REFERENCES tech2d.notas_cadernos(id_usuario, ano_letivo, ano_serie) ON DELETE CASCADE;


--
-- Name: notas_recuperacoes notas_recuperacoes_disciplina_serie_fk; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_recuperacoes
    ADD CONSTRAINT notas_recuperacoes_disciplina_serie_fk FOREIGN KEY (id_disciplina, ano_serie) REFERENCES tech2d.disciplinas_series(id_disciplina, ano_serie);


--
-- Name: notas_recuperacoes notas_recuperacoes_id_usuario_ano_letivo_ano_serie_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_recuperacoes
    ADD CONSTRAINT notas_recuperacoes_id_usuario_ano_letivo_ano_serie_fkey FOREIGN KEY (id_usuario, ano_letivo, ano_serie) REFERENCES tech2d.notas_cadernos(id_usuario, ano_letivo, ano_serie) ON DELETE CASCADE;


--
-- Name: perfis_administrativos perfis_administrativos_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: perfis perfis_id_turma_resumo_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_id_turma_resumo_fkey FOREIGN KEY (id_turma_resumo) REFERENCES tech2d.turmas(id_turma);


--
-- Name: quadros_kanban quadros_kanban_id_espaco_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_id_espaco_kanban_fkey FOREIGN KEY (id_espaco_kanban) REFERENCES tech2d.espacos_kanban(id_espaco_kanban) ON DELETE CASCADE;


--
-- Name: regras_recorrencia regras_recorrencia_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;


--
-- Name: regras_recorrencia regras_recorrencia_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: regras_retencao regras_retencao_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: horarios_aula school_schedules_class_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_class_id_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma);


--
-- Name: horarios_aula school_schedules_subject_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_subject_id_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina);


--
-- Name: horarios_aula school_schedules_teacher_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_teacher_id_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor);


--
-- Name: horarios_aula school_schedules_time_slot_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_time_slot_id_fkey FOREIGN KEY (id_faixa_horario) REFERENCES tech2d.faixas_horario(id_faixa_horario);


--
-- Name: sugestoes_melhoria sugestoes_melhoria_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: turmas_agenda turmas_agenda_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;


--
-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_professor_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_professor_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT;


--
-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;


--
-- Name: notas_cadernos leitura_backup; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY leitura_backup ON tech2d.notas_cadernos FOR SELECT TO tech2d_backup USING (true);


--
-- Name: notas_lancamentos leitura_backup; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY leitura_backup ON tech2d.notas_lancamentos FOR SELECT TO tech2d_backup USING (true);


--
-- Name: notas_recuperacoes leitura_backup; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY leitura_backup ON tech2d.notas_recuperacoes FOR SELECT TO tech2d_backup USING (true);


--
-- Name: notas_cadernos; Type: ROW SECURITY; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.notas_cadernos ENABLE ROW LEVEL SECURITY;

--
-- Name: notas_cadernos notas_cadernos_conta; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY notas_cadernos_conta ON tech2d.notas_cadernos USING (((id_usuario)::text = current_setting('tech2d.uid'::text, true))) WITH CHECK (((id_usuario)::text = current_setting('tech2d.uid'::text, true)));


--
-- Name: notas_lancamentos; Type: ROW SECURITY; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.notas_lancamentos ENABLE ROW LEVEL SECURITY;

--
-- Name: notas_lancamentos notas_lancamentos_conta; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY notas_lancamentos_conta ON tech2d.notas_lancamentos USING (((id_usuario)::text = current_setting('tech2d.uid'::text, true))) WITH CHECK (((id_usuario)::text = current_setting('tech2d.uid'::text, true)));


--
-- Name: notas_recuperacoes; Type: ROW SECURITY; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.notas_recuperacoes ENABLE ROW LEVEL SECURITY;

--
-- Name: notas_recuperacoes notas_recuperacoes_conta; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY notas_recuperacoes_conta ON tech2d.notas_recuperacoes USING (((id_usuario)::text = current_setting('tech2d.uid'::text, true))) WITH CHECK (((id_usuario)::text = current_setting('tech2d.uid'::text, true)));


--
-- Name: SCHEMA tech2d; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA tech2d TO tech2d_api;
GRANT USAGE ON SCHEMA tech2d TO tech2d_prod_ai_reader;
GRANT USAGE ON SCHEMA tech2d TO tech2d_prod_ai_quota;
GRANT USAGE ON SCHEMA tech2d TO assistente_ia_readonly;
GRANT USAGE ON SCHEMA tech2d TO tech2d_backup;


--
-- Name: FUNCTION consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) TO tech2d_api;


--
-- Name: FUNCTION gravar_registros(lote jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.gravar_registros(lote jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.gravar_registros(lote jsonb) TO tech2d_api;


--
-- Name: FUNCTION inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION ler_anexos_atividade(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_anexos_atividade(alvo bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.ler_anexos_atividade(alvo bigint) TO tech2d_api;


--
-- Name: FUNCTION ler_atividades(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_atividades(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_cartoes_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_cartoes_kanban(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_colunas_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_colunas_kanban(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_espacos_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_espacos_kanban(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_horarios_aula(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_horarios_aula(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_itens_checklist(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_itens_checklist(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_participantes_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_participantes_kanban(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_perfis(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_perfis(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_perfis_administrativos(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_perfis_administrativos(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_quadros_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_quadros_kanban(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_registro(alvo bigint, tipo character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying) TO tech2d_api;


--
-- Name: FUNCTION ler_regras_recorrencia(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_regras_recorrencia(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_regras_retencao(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_regras_retencao(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_sugestoes_melhoria(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION ler_turmas_agenda(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_turmas_agenda(alvo bigint) FROM PUBLIC;


--
-- Name: FUNCTION padronizar_listas_registro(tipo character varying, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.padronizar_listas_registro(tipo character varying, objeto jsonb) FROM PUBLIC;


--
-- Name: FUNCTION referencia_api(tipo character varying, pai character varying, referencia character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) TO tech2d_api;


--
-- Name: FUNCTION remover_nulos_raiz(objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) TO tech2d_api;


--
-- Name: FUNCTION revisao_catalogo_publico(catalogo character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) TO tech2d_api;


--
-- Name: FUNCTION travar_gravacao(caminhos text[]); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.travar_gravacao(caminhos text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.travar_gravacao(caminhos text[]) TO tech2d_api;


--
-- Name: FUNCTION vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint) FROM PUBLIC;


--
-- Name: FUNCTION vincular_nova_disciplina_notaki(); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.vincular_nova_disciplina_notaki() FROM PUBLIC;


--
-- Name: TABLE anexos_atividade; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.anexos_atividade TO tech2d_backup;


--
-- Name: SEQUENCE anexos_atividade_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.anexos_atividade_id_seq TO tech2d_backup;


--
-- Name: TABLE apelidos_disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.apelidos_disciplinas TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.apelidos_disciplinas TO tech2d_backup;


--
-- Name: SEQUENCE apelidos_disciplinas_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.apelidos_disciplinas_id_seq TO tech2d_backup;


--
-- Name: TABLE apelidos_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.apelidos_professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.apelidos_professores TO tech2d_backup;


--
-- Name: SEQUENCE apelidos_professores_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.apelidos_professores_id_seq TO tech2d_backup;


--
-- Name: SEQUENCE ids_entidades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.ids_entidades TO tech2d_backup;


--
-- Name: TABLE turmas_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.turmas_agenda TO tech2d_backup;


--
-- Name: TABLE assistant_class_catalog; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_class_catalog TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_class_catalog TO tech2d_backup;


--
-- Name: TABLE disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.disciplinas TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.disciplinas TO tech2d_backup;


--
-- Name: TABLE regras_recorrencia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.regras_recorrencia TO tech2d_backup;


--
-- Name: TABLE turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.turmas TO tech2d_backup;


--
-- Name: TABLE assistant_recurring_activities; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_recurring_activities TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_recurring_activities TO tech2d_backup;


--
-- Name: TABLE faixas_horario; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.faixas_horario TO tech2d_backup;


--
-- Name: TABLE horarios_aula; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.horarios_aula TO tech2d_backup;


--
-- Name: TABLE assistant_teacher_schedule; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_teacher_schedule TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_teacher_schedule TO tech2d_backup;


--
-- Name: TABLE atividades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.atividades TO tech2d_backup;


--
-- Name: TABLE aulas_recuperacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.aulas_recuperacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.aulas_recuperacao TO tech2d_backup;


--
-- Name: TABLE cartoes_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.cartoes_kanban TO tech2d_backup;


--
-- Name: SEQUENCE cartoes_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.cartoes_kanban_id_seq TO tech2d_backup;


--
-- Name: TABLE disciplinas_series; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.disciplinas_series TO tech2d_api;
GRANT SELECT ON TABLE tech2d.disciplinas_series TO tech2d_backup;


--
-- Name: TABLE professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.professores TO tech2d_backup;


--
-- Name: TABLE vinculos_professores_turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.vinculos_professores_turmas TO tech2d_backup;


--
-- Name: TABLE visao_disciplinas_notas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_disciplinas_notas TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_disciplinas_notas TO tech2d_backup;


--
-- Name: TABLE catalogo_atividades_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.catalogo_atividades_professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.catalogo_atividades_professores TO tech2d_backup;


--
-- Name: TABLE catalogo_horarios; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.catalogo_horarios TO tech2d_api;
GRANT SELECT ON TABLE tech2d.catalogo_horarios TO tech2d_backup;


--
-- Name: TABLE colunas_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.colunas_kanban TO tech2d_backup;


--
-- Name: SEQUENCE colunas_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.colunas_kanban_id_seq TO tech2d_backup;


--
-- Name: TABLE config_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_prod_ai_quota;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.config_assistente TO tech2d_api;
GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_backup;


--
-- Name: TABLE config_fechamento_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,UPDATE ON TABLE tech2d.config_fechamento_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.config_fechamento_agenda TO tech2d_backup;


--
-- Name: TABLE editais_recuperacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.editais_recuperacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.editais_recuperacao TO tech2d_backup;


--
-- Name: SEQUENCE editais_recuperacao_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.editais_recuperacao_id_seq TO tech2d_backup;


--
-- Name: TABLE espacos_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.espacos_kanban TO tech2d_backup;


--
-- Name: TABLE itens_checklist; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.itens_checklist TO tech2d_backup;


--
-- Name: SEQUENCE itens_checklist_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.itens_checklist_id_seq TO tech2d_backup;


--
-- Name: TABLE limites_mensagens_ia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.limites_mensagens_ia TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.limites_mensagens_ia TO tech2d_backup;


--
-- Name: TABLE limpeza_anexos_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.limpeza_anexos_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.limpeza_anexos_agenda TO tech2d_backup;


--
-- Name: TABLE limpezas_anuais_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.limpezas_anuais_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.limpezas_anuais_agenda TO tech2d_backup;


--
-- Name: TABLE notas_cadernos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_cadernos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_cadernos TO tech2d_backup;


--
-- Name: TABLE notas_lancamentos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_lancamentos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_lancamentos TO tech2d_backup;


--
-- Name: TABLE notas_recuperacoes; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_recuperacoes TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_recuperacoes TO tech2d_backup;


--
-- Name: TABLE participantes_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.participantes_kanban TO tech2d_backup;


--
-- Name: TABLE perfis; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.perfis TO tech2d_backup;


--
-- Name: TABLE perfis_administrativos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.perfis_administrativos TO tech2d_backup;


--
-- Name: TABLE quadros_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.quadros_kanban TO tech2d_backup;


--
-- Name: SEQUENCE quadros_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.quadros_kanban_id_seq TO tech2d_backup;


--
-- Name: TABLE recibos_gravacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.recibos_gravacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.recibos_gravacao TO tech2d_backup;


--
-- Name: TABLE regras_retencao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.regras_retencao TO tech2d_backup;


--
-- Name: TABLE reservas_mensagens_ia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.reservas_mensagens_ia TO tech2d_prod_ai_quota;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.reservas_mensagens_ia TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.reservas_mensagens_ia TO tech2d_backup;


--
-- Name: SEQUENCE school_classes_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_classes_id_seq TO tech2d_backup;


--
-- Name: SEQUENCE school_subjects_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_subjects_id_seq TO tech2d_backup;


--
-- Name: SEQUENCE school_teachers_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_teachers_id_seq TO tech2d_backup;


--
-- Name: SEQUENCE school_time_slots_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_time_slots_id_seq TO tech2d_backup;


--
-- Name: TABLE sugestoes_melhoria; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.sugestoes_melhoria TO tech2d_backup;


--
-- Name: TABLE uso_contas_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_contas_assistente TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_contas_assistente TO tech2d_api;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_contas_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_contas_assistente TO tech2d_backup;


--
-- Name: TABLE uso_diario_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_diario_assistente TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_diario_assistente TO tech2d_api;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_diario_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_diario_assistente TO tech2d_backup;


--
-- Name: SEQUENCE vinculos_professores_turmas_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.vinculos_professores_turmas_id_seq TO tech2d_backup;


--
-- Name: TABLE vinculos_turma_perfil; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.vinculos_turma_perfil TO tech2d_api;
GRANT SELECT ON TABLE tech2d.vinculos_turma_perfil TO tech2d_backup;


--
-- Name: TABLE visao_atividades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_atividades TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_atividades TO tech2d_backup;


--
-- Name: TABLE visao_atividades_automacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_atividades_automacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_atividades_automacao TO tech2d_backup;


--
-- Name: TABLE visao_catalogo_horarios; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_catalogo_horarios TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_catalogo_horarios TO tech2d_backup;


--
-- Name: TABLE visao_disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_disciplinas TO tech2d_backup;


--
-- Name: TABLE visao_documentos_aplicacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_documentos_aplicacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_documentos_aplicacao TO tech2d_backup;


--
-- Name: TABLE visao_documentos_catalogo; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_documentos_catalogo TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_documentos_catalogo TO tech2d_backup;


--
-- Name: TABLE visao_faixas_horario; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_faixas_horario TO tech2d_backup;


--
-- Name: TABLE visao_horarios_aula; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_horarios_aula TO tech2d_backup;


--
-- Name: TABLE visao_notas_resultados; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_notas_resultados TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_notas_resultados TO tech2d_backup;


--
-- Name: TABLE visao_perfis_administrativos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_perfis_administrativos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_perfis_administrativos TO tech2d_backup;


--
-- Name: TABLE visao_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_professores TO tech2d_backup;


--
-- Name: TABLE visao_recibos_gravacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.visao_recibos_gravacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_recibos_gravacao TO tech2d_backup;


--
-- Name: TABLE visao_turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_turmas TO tech2d_backup;


--
-- Name: TABLE visitas_aos_sites; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE ON TABLE tech2d.visitas_aos_sites TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visitas_aos_sites TO tech2d_backup;


--
-- PostgreSQL database dump complete
--

\unrestrict Tech2dSchemaExport

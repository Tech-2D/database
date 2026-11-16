-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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
BEGIN
  IF ((objeto->>'startTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'endTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
    AND (objeto->>'dayOfWeek') ~ '^[0-6]$'
    AND jsonb_typeof(objeto->'active')='boolean') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Invalid schedule projection' USING ERRCODE='check_violation';
  END IF;
  inicio := (objeto->>'startTime')::time;
  fim := (objeto->>'endTime')::time;
  INSERT INTO tech2d.professores(nome) VALUES(objeto->>'professor') ON CONFLICT(nome) DO NOTHING;
  disciplina_catalogo:=tech2d.resolver_disciplina(objeto->>'subject');
  turma_catalogo:=tech2d.resolver_turma(objeto->>'className',false);
  INSERT INTO tech2d.faixas_horario(hora_inicio,hora_fim) VALUES(inicio,fim) ON CONFLICT(hora_inicio,hora_fim) DO NOTHING;
  INSERT INTO tech2d.horarios_aula (versao,atualizado_em,id_horario_aula,id_horario_interno,id_professor,id_disciplina,id_turma,id_faixa_horario,dia_semana,ativo,andar,sala,criado_em,alterado_em)
  SELECT 1,now(),chave_api,alvo,p.id_professor,d.id_disciplina,t.id_turma,f.id_faixa_horario,(objeto->>'dayOfWeek')::smallint,(objeto->>'active')::boolean,
    objeto->>'floor',objeto->>'roomDescription',objeto->>'createdAt',objeto->>'updatedAt'
  FROM tech2d.professores p,tech2d.disciplinas d,tech2d.turmas t,tech2d.faixas_horario f
  WHERE p.nome=objeto->>'professor' AND d.id_disciplina=disciplina_catalogo AND t.id_turma=turma_catalogo
    AND f.hora_inicio=inicio AND f.hora_fim=fim
  ON CONFLICT(id_horario_aula) DO UPDATE SET versao=horarios_aula.versao+1, atualizado_em=excluded.atualizado_em, id_horario_interno=excluded.id_horario_interno,id_professor=excluded.id_professor,
    id_disciplina=excluded.id_disciplina,id_turma=excluded.id_turma,id_faixa_horario=excluded.id_faixa_horario,
    dia_semana=excluded.dia_semana,ativo=excluded.ativo,andar=excluded.andar,sala=excluded.sala,
    criado_em=excluded.criado_em,alterado_em=excluded.alterado_em;
END $_$;

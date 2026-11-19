-- Atualiza a resolução de professores pelos horários. A consolidação de registros operacionais é executada apenas pela API.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));

-- Reutiliza o cadastro nos próximos imports com diferenças de caixa ou espaços.
CREATE OR REPLACE FUNCTION tech2d.gravar_horarios_aula(alvo bigint, objeto jsonb, chave_api varchar, compartilhado_api boolean, pai_api varchar, id_pai_api bigint)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
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
END $function$;

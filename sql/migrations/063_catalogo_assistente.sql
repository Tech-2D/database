-- Catálogo do Assistente sobre a estrutura oficial 062.
-- Runtime roles are provisioned separately. Apply migrations with the database owner.
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_prod_ai_reader') THEN
    CREATE ROLE tech2d_prod_ai_reader LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_prod_ai_quota') THEN
    CREATE ROLE tech2d_prod_ai_quota LOGIN;
  END IF;
END
$roles$;
GRANT USAGE ON SCHEMA tech2d TO tech2d_prod_ai_reader, tech2d_prod_ai_quota;

CREATE TABLE tech2d.apelidos_professores (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_professor bigint NOT NULL REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT,
  apelido text NOT NULL CHECK (btrim(apelido) <> ''),
  chave_normalizada text NOT NULL CHECK (btrim(chave_normalizada) <> ''),
  criado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_professor, chave_normalizada)
);
CREATE INDEX apelidos_professores_chave ON tech2d.apelidos_professores(chave_normalizada);

CREATE TABLE tech2d.apelidos_disciplinas (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_disciplina bigint NOT NULL REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT,
  apelido text NOT NULL CHECK (btrim(apelido) <> ''),
  chave_normalizada text NOT NULL CHECK (btrim(chave_normalizada) <> ''),
  criado_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_disciplina, chave_normalizada)
);
CREATE INDEX apelidos_disciplinas_chave ON tech2d.apelidos_disciplinas(chave_normalizada);

CREATE TABLE tech2d.vinculos_professores_turmas (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_turma bigint NOT NULL REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT,
  id_disciplina bigint NOT NULL REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT,
  id_professor bigint NOT NULL REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT,
  vigencia_inicio date NOT NULL,
  vigencia_fim date,
  criado_em timestamptz NOT NULL DEFAULT now(),
  CHECK (vigencia_fim IS NULL OR vigencia_fim >= vigencia_inicio),
  -- Um intervalo numérico com um único valor equivale à igualdade do ID.
  -- Assim, o GiST nativo valida a vigência sem depender de btree_gist.
  EXCLUDE USING gist (
    (numrange(id_turma, id_turma, '[]')) WITH &&,
    (numrange(id_disciplina, id_disciplina, '[]')) WITH &&,
    (daterange(vigencia_inicio, vigencia_fim, '[]')) WITH &&
  )
);
CREATE INDEX vinculos_professores_turmas_busca
  ON tech2d.vinculos_professores_turmas(id_turma,id_disciplina,vigencia_inicio,vigencia_fim);
CREATE INDEX vinculos_professores_turmas_professor
  ON tech2d.vinculos_professores_turmas(id_professor,id_turma,id_disciplina,vigencia_inicio,vigencia_fim);

COMMENT ON TABLE tech2d.apelidos_professores IS 'Apelidos aprovados usados pela IA para identificar professores.';
COMMENT ON TABLE tech2d.apelidos_disciplinas IS 'Apelidos aprovados usados pela IA para identificar disciplinas.';
COMMENT ON TABLE tech2d.vinculos_professores_turmas IS 'Professor confirmado por turma e disciplina durante uma vigência.';

CREATE VIEW tech2d.catalogo_atividades_professores AS
SELECT a.referencia_api AS id_atividade, a.titulo, a.tipo_atividade AS tipo,
  a.data_atividade AS data, to_char(a.hora_atividade::interval, 'HH24:MI') AS hora,
  a.id_disciplina, d.nome AS disciplina, a.id_turma, t.nome AS turma,
  p.id_professor, p.nome AS professor,
  CASE WHEN a.id_turma IS NULL THEN 'atividade_geral'
       WHEN a.id_disciplina IS NULL THEN 'disciplina_pendente'
       WHEN p.id_professor IS NULL THEN 'professor_pendente'
       ELSE 'associado' END AS estado_atribuicao,
  coalesce((SELECT n.nome FROM tech2d.visao_disciplinas_notas n
    WHERE n.id=d.id_disciplina ORDER BY n.ano_serie DESC LIMIT 1), d.nome)::varchar(150) AS disciplina_original,
  coalesce(t.referencia_agenda,t.nome) AS turma_original,
  r.referencia_api AS referencia_recorrencia
FROM tech2d.atividades a
LEFT JOIN tech2d.regras_recorrencia r USING(id_regra_recorrencia)
LEFT JOIN tech2d.disciplinas d ON d.id_disciplina=a.id_disciplina
LEFT JOIN tech2d.turmas t ON t.id_turma=a.id_turma
LEFT JOIN tech2d.vinculos_professores_turmas x
  ON (x.id_turma,x.id_disciplina)=(a.id_turma,a.id_disciplina)
 AND a.data_atividade <@ daterange(x.vigencia_inicio,x.vigencia_fim,'[]')
LEFT JOIN tech2d.professores p ON p.id_professor=x.id_professor;

-- Migration 061 removed the deleted flag from recurring activities.
CREATE VIEW tech2d.assistant_recurring_activities AS
SELECT r.referencia_api AS id, jsonb_strip_nulls(jsonb_build_object(
  'turmaId', coalesce(t.referencia_agenda,t.nome),
  'subject', d.nome,
  'active', r.ativa,
  'type', r.tipo_atividade,
  'startDate', r.data_inicio,
  'endDate', r.data_fim,
  'weekdays', r.dias_semana,
  'intervalWeeks', r.intervalo_semanas,
  'time', to_char(r.hora_atividade,'HH24:MI'),
  'title', r.titulo
)) AS data
FROM tech2d.regras_recorrencia r
LEFT JOIN tech2d.turmas t USING(id_turma)
LEFT JOIN tech2d.disciplinas d USING(id_disciplina);

CREATE VIEW tech2d.assistant_class_catalog AS
SELECT a.referencia_api::text AS id
FROM tech2d.turmas_agenda a
WHERE a.ativa;

REVOKE ALL ON tech2d.apelidos_professores,tech2d.apelidos_disciplinas,
  tech2d.vinculos_professores_turmas,tech2d.catalogo_atividades_professores,
  tech2d.assistant_recurring_activities,tech2d.assistant_class_catalog FROM PUBLIC;
CREATE OR REPLACE VIEW tech2d.assistant_teacher_schedule AS
SELECT h.id_professor, h.dia_semana, f.hora_inicio, f.hora_fim,
       d.nome AS disciplina, t.nome AS turma, h.andar, h.sala
FROM tech2d.horarios_aula h
JOIN tech2d.faixas_horario f USING (id_faixa_horario)
JOIN tech2d.disciplinas d USING (id_disciplina)
JOIN tech2d.turmas t USING (id_turma)
WHERE h.ativo;
REVOKE ALL ON tech2d.assistant_teacher_schedule FROM PUBLIC;
GRANT SELECT ON tech2d.disciplinas, tech2d.professores,
  tech2d.apelidos_professores, tech2d.apelidos_disciplinas,
  tech2d.catalogo_atividades_professores, tech2d.assistant_recurring_activities,
  tech2d.assistant_class_catalog, tech2d.assistant_teacher_schedule
  TO tech2d_prod_ai_reader;

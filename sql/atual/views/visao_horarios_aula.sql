-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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

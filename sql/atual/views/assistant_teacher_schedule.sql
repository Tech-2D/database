-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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

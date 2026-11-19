-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: assistant_recurring_activities; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.assistant_recurring_activities AS
 SELECT r.referencia_api AS id,
    jsonb_strip_nulls(jsonb_build_object('turmaId', COALESCE(t.referencia_agenda, t.nome), 'subject', d.nome, 'active', r.ativa, 'type', r.tipo_atividade, 'startDate', r.data_inicio, 'endDate', r.data_fim, 'weekdays', r.dias_semana, 'intervalWeeks', r.intervalo_semanas, 'time', to_char((r.hora_atividade)::interval, 'HH24:MI'::text), 'title', r.titulo)) AS data
   FROM ((tech2d.regras_recorrencia r
     LEFT JOIN tech2d.turmas t USING (id_turma))
     LEFT JOIN tech2d.disciplinas d USING (id_disciplina));

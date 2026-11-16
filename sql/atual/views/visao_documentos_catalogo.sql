-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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

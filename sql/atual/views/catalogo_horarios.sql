-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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

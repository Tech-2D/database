-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_catalogo_horarios; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_catalogo_horarios AS
 SELECT id,
    dia_semana AS day_of_week,
    ativo AS active,
    nome_turma AS class_name,
    dados AS data
   FROM tech2d.catalogo_horarios;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

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

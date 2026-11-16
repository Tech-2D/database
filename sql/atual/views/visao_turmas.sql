-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_turmas; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_turmas WITH (security_invoker='true') AS
 SELECT id_turma AS id,
    nome AS name
   FROM tech2d.turmas;

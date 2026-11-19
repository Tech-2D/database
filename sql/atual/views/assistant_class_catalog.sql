-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: assistant_class_catalog; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.assistant_class_catalog AS
 SELECT (referencia_api)::text AS id
   FROM tech2d.turmas_agenda a
  WHERE ativa;

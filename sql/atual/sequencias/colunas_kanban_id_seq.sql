-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: colunas_kanban_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.colunas_kanban ALTER COLUMN id_coluna_kanban ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.colunas_kanban_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

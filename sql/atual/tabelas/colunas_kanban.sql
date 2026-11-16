-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: colunas_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.colunas_kanban (
    id_coluna_kanban bigint CONSTRAINT colunas_kanban_id_not_null NOT NULL,
    id_quadro_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    nome character varying(60),
    cor character varying(16),
    concluida boolean,
    CONSTRAINT colunas_kanban_ordem_check CHECK ((ordem >= 0))
);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: quadros_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.quadros_kanban (
    id_quadro_kanban bigint CONSTRAINT quadros_kanban_id_not_null NOT NULL,
    id_espaco_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    nome character varying(80),
    cor character varying(16),
    compacto boolean,
    CONSTRAINT quadros_kanban_ordem_check CHECK ((ordem >= 0))
);

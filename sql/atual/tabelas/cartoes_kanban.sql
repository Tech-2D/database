-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: cartoes_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.cartoes_kanban (
    id_cartao_kanban bigint CONSTRAINT cartoes_kanban_id_not_null NOT NULL,
    id_quadro_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    referencia_coluna character varying(80),
    titulo character varying(160),
    descricao character varying(3000),
    prioridade character varying(16),
    prazo date,
    id_responsavel character varying(128),
    etiquetas character varying(30)[],
    referencias_atividades character varying(128)[],
    CONSTRAINT cartoes_kanban_ordem_check CHECK ((ordem >= 0))
);

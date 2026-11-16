-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: itens_checklist; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.itens_checklist (
    id_item_checklist bigint CONSTRAINT itens_checklist_id_not_null NOT NULL,
    id_cartao_kanban bigint NOT NULL,
    ordem integer NOT NULL,
    referencia character varying(80),
    descricao character varying(200),
    concluido boolean,
    CONSTRAINT itens_checklist_ordem_check CHECK ((ordem >= 0))
);

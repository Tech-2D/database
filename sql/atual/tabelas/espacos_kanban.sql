-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: espacos_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.espacos_kanban (
    id_espaco_kanban bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT espacos_kanban_id_registro_not_null NOT NULL,
    id_proprietario character varying(128),
    versao_formato smallint,
    criado_em character varying(40),
    alterado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    compartilhado boolean NOT NULL,
    CONSTRAINT espacos_kanban_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT espacos_kanban_versao_check CHECK ((versao > 0))
);

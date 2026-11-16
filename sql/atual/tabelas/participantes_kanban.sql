-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: participantes_kanban; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.participantes_kanban (
    id_participante_kanban bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT participantes_kanban_id_registro_not_null NOT NULL,
    referencia_quadro character varying(80),
    id_usuario character varying(128),
    email character varying(320),
    nome character varying(80),
    criado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT participantes_kanban_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT participantes_kanban_versao_check CHECK ((versao > 0))
);

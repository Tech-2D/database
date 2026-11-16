-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: turmas_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.turmas_agenda (
    id_turma_agenda bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT turmas_agenda_id_registro_not_null NOT NULL,
    ativa boolean,
    referencia_pedido character varying(180),
    aprovada_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT turmas_agenda_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT turmas_agenda_versao_check CHECK ((versao > 0))
);

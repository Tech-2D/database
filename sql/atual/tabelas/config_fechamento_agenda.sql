-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: config_fechamento_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.config_fechamento_agenda (
    id integer NOT NULL,
    versao integer DEFAULT 0 NOT NULL,
    rascunho jsonb,
    publicado jsonb,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT config_fechamento_agenda_id_check CHECK ((id = 1)),
    CONSTRAINT config_fechamento_agenda_publicado_check CHECK ((jsonb_typeof(publicado) = 'object'::text)),
    CONSTRAINT config_fechamento_agenda_rascunho_check CHECK ((jsonb_typeof(rascunho) = 'object'::text)),
    CONSTRAINT config_fechamento_agenda_versao_check CHECK ((versao >= 0))
);

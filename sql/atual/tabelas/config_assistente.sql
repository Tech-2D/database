-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: config_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.config_assistente (
    id integer NOT NULL,
    limite_diario integer NOT NULL,
    versao integer NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_por text NOT NULL,
    CONSTRAINT config_assistente_id_check CHECK ((id = 1)),
    CONSTRAINT config_assistente_limite_diario_check CHECK (((limite_diario >= 1) AND (limite_diario <= 1000))),
    CONSTRAINT config_assistente_versao_check CHECK ((versao > 0))
);

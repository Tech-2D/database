-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: recibos_gravacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.recibos_gravacao (
    id_recibo_gravacao character varying(128) CONSTRAINT app_commits_id_not_null NOT NULL,
    autor character varying(256) CONSTRAINT app_commits_actor_not_null NOT NULL,
    hash_requisicao character varying(64) CONSTRAINT app_commits_digest_not_null NOT NULL,
    confirmado_em timestamp with time zone DEFAULT now() CONSTRAINT app_commits_committed_at_not_null NOT NULL
);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: apelidos_professores; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.apelidos_professores (
    id bigint NOT NULL,
    id_professor bigint NOT NULL,
    apelido text NOT NULL,
    chave_normalizada text NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apelidos_professores_apelido_check CHECK ((btrim(apelido) <> ''::text)),
    CONSTRAINT apelidos_professores_chave_normalizada_check CHECK ((btrim(chave_normalizada) <> ''::text))
);

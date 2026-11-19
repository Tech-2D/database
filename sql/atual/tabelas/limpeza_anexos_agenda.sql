-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limpeza_anexos_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limpeza_anexos_agenda (
    chave_arquivo text NOT NULL,
    tentar_apos timestamp with time zone DEFAULT now() NOT NULL
);

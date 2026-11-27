-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: editais_recuperacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.editais_recuperacao (
    id integer NOT NULL,
    titulo text NOT NULL,
    descricao text NOT NULL,
    link text,
    inicio timestamp with time zone,
    fim timestamp with time zone,
    CONSTRAINT editais_recuperacao_check CHECK ((fim > inicio)),
    CONSTRAINT editais_recuperacao_descricao_check CHECK ((length(descricao) <= 6000)),
    CONSTRAINT editais_recuperacao_janela_completa CHECK (((inicio IS NULL) = (fim IS NULL))),
    CONSTRAINT editais_recuperacao_link_check CHECK ((length(link) <= 1000)),
    CONSTRAINT editais_recuperacao_titulo_check CHECK (((length(titulo) >= 1) AND (length(titulo) <= 140)))
);

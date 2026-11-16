-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_recuperacoes; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_recuperacoes (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    id_disciplina bigint NOT NULL,
    nota numeric(4,2),
    CONSTRAINT notas_recuperacoes_nota_check CHECK (((nota >= (0)::numeric) AND (nota <= (10)::numeric)))
);

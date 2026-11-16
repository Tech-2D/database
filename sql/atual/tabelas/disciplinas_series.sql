-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: disciplinas_series; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.disciplinas_series (
    id_disciplina bigint NOT NULL,
    ano_serie smallint NOT NULL,
    CONSTRAINT disciplinas_series_ano_serie_check CHECK (((ano_serie >= 1) AND (ano_serie <= 3)))
);

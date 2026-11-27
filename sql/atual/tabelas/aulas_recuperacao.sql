-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: aulas_recuperacao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.aulas_recuperacao (
    edital_id integer NOT NULL,
    ordem integer NOT NULL,
    dia date NOT NULL,
    inicio time without time zone NOT NULL,
    fim time without time zone NOT NULL,
    materia text NOT NULL,
    turma text,
    professor text,
    local text,
    prova boolean DEFAULT false NOT NULL,
    CONSTRAINT aulas_recuperacao_check CHECK ((fim > inicio)),
    CONSTRAINT aulas_recuperacao_local_check CHECK ((length(local) <= 120)),
    CONSTRAINT aulas_recuperacao_materia_check CHECK (((length(materia) >= 1) AND (length(materia) <= 120))),
    CONSTRAINT aulas_recuperacao_ordem_check CHECK ((ordem >= 1)),
    CONSTRAINT aulas_recuperacao_professor_check CHECK ((length(professor) <= 120)),
    CONSTRAINT aulas_recuperacao_turma_check CHECK ((length(turma) <= 100))
);

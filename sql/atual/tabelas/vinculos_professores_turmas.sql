-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_professores_turmas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.vinculos_professores_turmas (
    id bigint NOT NULL,
    id_turma bigint NOT NULL,
    id_disciplina bigint NOT NULL,
    id_professor bigint NOT NULL,
    vigencia_inicio date NOT NULL,
    vigencia_fim date,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vinculos_professores_turmas_check CHECK (((vigencia_fim IS NULL) OR (vigencia_fim >= vigencia_inicio)))
);

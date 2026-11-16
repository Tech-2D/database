-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: disciplinas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.disciplinas (
    id_disciplina bigint CONSTRAINT school_subjects_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_subjects_name_not_null NOT NULL,
    CONSTRAINT school_subjects_name_check CHECK ((btrim((nome)::text) <> ''::text))
);

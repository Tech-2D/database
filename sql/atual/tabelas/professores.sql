-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: professores; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.professores (
    id_professor bigint CONSTRAINT school_teachers_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_teachers_name_not_null NOT NULL,
    CONSTRAINT school_teachers_name_check CHECK ((btrim((nome)::text) <> ''::text))
);

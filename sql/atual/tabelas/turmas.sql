-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: turmas; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.turmas (
    id_turma bigint CONSTRAINT school_classes_id_not_null NOT NULL,
    nome character varying(150) CONSTRAINT school_classes_name_not_null NOT NULL,
    referencia_agenda character varying(150),
    CONSTRAINT school_classes_name_check CHECK ((btrim((nome)::text) <> ''::text))
);

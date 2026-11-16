-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_lancamentos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_lancamentos (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    id_disciplina bigint NOT NULL,
    semestre smallint NOT NULL,
    n1 numeric(4,2),
    n2 numeric(4,2),
    media_informada numeric(4,2),
    peso_n1 smallint DEFAULT 50 NOT NULL,
    CONSTRAINT notas_lancamentos_media_informada_check CHECK (((media_informada >= (0)::numeric) AND (media_informada <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_n1_check CHECK (((n1 >= (0)::numeric) AND (n1 <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_n2_check CHECK (((n2 >= (0)::numeric) AND (n2 <= (10)::numeric))),
    CONSTRAINT notas_lancamentos_peso_n1_check CHECK ((((peso_n1 >= 10) AND (peso_n1 <= 90)) AND (((peso_n1)::integer % 5) = 0))),
    CONSTRAINT notas_lancamentos_semestre_check CHECK ((semestre = ANY (ARRAY[1, 2])))
);

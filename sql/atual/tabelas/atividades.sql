-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.atividades (
    id_atividade bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT atividades_id_registro_not_null NOT NULL,
    titulo character varying(120),
    descricao character varying(2000),
    tipo_atividade character varying(32),
    data_atividade date,
    hora_atividade time without time zone,
    criado_por character varying(128),
    email_criador character varying(320),
    criado_em character varying(40),
    alterado_em character varying(40),
    id_disciplina bigint,
    id_turma bigint,
    id_regra_recorrencia bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT atividades_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT atividades_versao_check CHECK ((versao > 0))
);

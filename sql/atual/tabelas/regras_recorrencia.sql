-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_recorrencia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.regras_recorrencia (
    id_regra_recorrencia bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT regras_recorrencia_id_registro_not_null NOT NULL,
    titulo character varying(120),
    descricao character varying(2000),
    tipo_atividade character varying(32),
    hora_atividade time without time zone,
    criado_por character varying(128),
    criado_em character varying(40),
    data_inicio date,
    data_fim date,
    ativa boolean,
    intervalo_semanas smallint,
    dias_semana smallint[],
    id_disciplina bigint,
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT regras_recorrencia_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT regras_recorrencia_versao_check CHECK ((versao > 0))
);

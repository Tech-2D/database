-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_retencao; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.regras_retencao (
    id_regra_retencao bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT regras_retencao_id_registro_not_null NOT NULL,
    dias smallint,
    ativa boolean,
    alterado_por character varying(128),
    alterado_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT regras_retencao_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT regras_retencao_versao_check CHECK ((versao > 0))
);

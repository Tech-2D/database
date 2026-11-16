-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: sugestoes_melhoria; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.sugestoes_melhoria (
    id_sugestao_melhoria bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT sugestoes_melhoria_id_registro_not_null NOT NULL,
    mensagem character varying(2000),
    criado_por character varying(128),
    email_criador character varying(320),
    criado_em character varying(40),
    credito_autorizado boolean,
    nome_credito character varying(60),
    situacao character varying(32),
    concluida_em character varying(40),
    concluida_por character varying(128),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT sugestoes_melhoria_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT sugestoes_melhoria_versao_check CHECK ((versao > 0))
);

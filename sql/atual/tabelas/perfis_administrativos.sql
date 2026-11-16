-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_administrativos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.perfis_administrativos (
    id_perfil_administrativo bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT perfis_administrativos_id_registro_not_null NOT NULL,
    papel character varying(32),
    criado_em character varying(40),
    id_turma bigint,
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    referencia_api character varying(320) NOT NULL,
    CONSTRAINT perfis_administrativos_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT perfis_administrativos_versao_check CHECK ((versao > 0))
);

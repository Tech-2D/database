-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.perfis (
    id_perfil bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) NOT NULL,
    nome character varying(80),
    empresa character varying(100),
    turma_informada character varying(80),
    sala character varying(80),
    andar character varying(80),
    url_foto character varying(2048),
    alterado_em character varying(40),
    versao bigint,
    atualizado_em timestamp with time zone,
    referencia_api character varying(320) NOT NULL,
    resumo_semanal_ativo boolean,
    id_turma_resumo bigint,
    resumo_alterado_em_ms bigint,
    resumo_versao bigint,
    resumo_atualizado_em timestamp with time zone,
    CONSTRAINT perfis_conteudo_presente CHECK (((versao IS NOT NULL) OR (resumo_versao IS NOT NULL))),
    CONSTRAINT perfis_referencia_api_check CHECK (((referencia_api)::text <> ''::text)),
    CONSTRAINT perfis_resumo_versao_check CHECK ((resumo_versao > 0)),
    CONSTRAINT perfis_resumo_versao_data CHECK (((resumo_versao IS NULL) = (resumo_atualizado_em IS NULL))),
    CONSTRAINT perfis_versao_check CHECK ((versao > 0)),
    CONSTRAINT perfis_versao_data CHECK (((versao IS NULL) = (atualizado_em IS NULL)))
);

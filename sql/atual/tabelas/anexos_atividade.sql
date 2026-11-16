-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: anexos_atividade; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.anexos_atividade (
    id_anexo_atividade bigint CONSTRAINT anexos_atividade_id_not_null NOT NULL,
    id_atividade bigint NOT NULL,
    referencia character varying(180),
    nome character varying(500),
    tipo_mime character varying(150),
    tamanho_bytes bigint,
    chave_arquivo character varying(1024),
    enviado_em character varying(40),
    enviado_por character varying(128)
);

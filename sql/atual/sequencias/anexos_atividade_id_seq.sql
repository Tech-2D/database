-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: anexos_atividade_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.anexos_atividade ALTER COLUMN id_anexo_atividade ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.anexos_atividade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

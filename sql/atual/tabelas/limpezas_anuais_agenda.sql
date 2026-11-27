-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limpezas_anuais_agenda; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limpezas_anuais_agenda (
    operacao text NOT NULL,
    administrador_uid text NOT NULL,
    revisao text NOT NULL,
    executada_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    resultado jsonb NOT NULL
);

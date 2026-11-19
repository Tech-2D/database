-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: uso_diario_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.uso_diario_assistente (
    dia date NOT NULL,
    mensagens integer NOT NULL,
    CONSTRAINT uso_diario_assistente_mensagens_check CHECK ((mensagens > 0))
);

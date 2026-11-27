-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: uso_contas_assistente; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.uso_contas_assistente (
    dia date NOT NULL,
    firebase_uid text NOT NULL,
    mensagens integer NOT NULL,
    CONSTRAINT uso_contas_assistente_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT uso_contas_assistente_mensagens_check CHECK ((mensagens > 0))
);

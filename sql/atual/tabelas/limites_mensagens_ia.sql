-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limites_mensagens_ia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.limites_mensagens_ia (
    firebase_uid text NOT NULL,
    data_uso date NOT NULL,
    quantidade integer NOT NULL,
    CONSTRAINT limites_mensagens_ia_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT limites_mensagens_ia_quantidade_check CHECK ((quantidade >= 0))
);

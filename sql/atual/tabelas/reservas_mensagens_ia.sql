-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: reservas_mensagens_ia; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.reservas_mensagens_ia (
    firebase_uid text NOT NULL,
    operacao text NOT NULL,
    data_uso date NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    saldo_final integer,
    limite_aplicado integer,
    CONSTRAINT reservas_mensagens_ia_firebase_uid_check CHECK (((length(firebase_uid) >= 1) AND (length(firebase_uid) <= 128))),
    CONSTRAINT reservas_mensagens_ia_limite_aplicado_check CHECK ((limite_aplicado > 0)),
    CONSTRAINT reservas_mensagens_ia_operacao_check CHECK (((length(operacao) >= 1) AND (length(operacao) <= 161))),
    CONSTRAINT reservas_mensagens_ia_saldo_final_check CHECK ((saldo_final >= 0))
);

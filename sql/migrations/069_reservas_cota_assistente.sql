CREATE TABLE tech2d.reservas_mensagens_ia (
    firebase_uid text NOT NULL CHECK (length(firebase_uid) BETWEEN 1 AND 128),
    operacao text NOT NULL CHECK (length(operacao) BETWEEN 1 AND 161),
    data_uso date NOT NULL,
    expira_em timestamptz NOT NULL,
    saldo_final integer CHECK (saldo_final >= 0),
    PRIMARY KEY (firebase_uid, operacao)
);
REVOKE ALL ON tech2d.reservas_mensagens_ia FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech2d.reservas_mensagens_ia TO tech2d_prod_ai_quota;

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_qa_ai_quota') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON tech2d.reservas_mensagens_ia TO tech2d_qa_ai_quota;
    END IF;
END $$;

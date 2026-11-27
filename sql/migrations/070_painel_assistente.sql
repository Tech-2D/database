CREATE TABLE tech2d.config_assistente (
    id integer PRIMARY KEY CHECK (id = 1),
    limite_diario integer NOT NULL CHECK (limite_diario BETWEEN 1 AND 1000),
    versao integer NOT NULL CHECK (versao > 0),
    atualizado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_por text NOT NULL
);

CREATE TABLE tech2d.uso_contas_assistente (
    dia date NOT NULL,
    firebase_uid text NOT NULL CHECK (length(firebase_uid) BETWEEN 1 AND 128),
    mensagens integer NOT NULL CHECK (mensagens > 0),
    PRIMARY KEY (dia, firebase_uid)
);

ALTER TABLE tech2d.reservas_mensagens_ia ADD COLUMN limite_aplicado integer CHECK (limite_aplicado > 0);

REVOKE ALL ON tech2d.config_assistente, tech2d.uso_contas_assistente FROM PUBLIC;
GRANT SELECT ON tech2d.config_assistente TO tech2d_prod_ai_quota;
GRANT SELECT, INSERT, UPDATE ON tech2d.uso_contas_assistente TO tech2d_prod_ai_quota;

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_api') THEN
        GRANT SELECT, INSERT, UPDATE ON tech2d.config_assistente TO tech2d_api;
        GRANT SELECT ON tech2d.uso_contas_assistente TO tech2d_api;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_qa_ai_quota') THEN
        GRANT SELECT ON tech2d.config_assistente TO tech2d_qa_ai_quota;
        GRANT SELECT, INSERT, UPDATE ON tech2d.uso_contas_assistente TO tech2d_qa_ai_quota;
    END IF;
END $$;

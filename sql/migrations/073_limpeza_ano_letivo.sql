CREATE TABLE tech2d.limpezas_anuais_agenda (
    operacao text PRIMARY KEY,
    administrador_uid text NOT NULL,
    revisao text NOT NULL,
    executada_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    resultado jsonb NOT NULL
);

CREATE INDEX limpezas_anuais_agenda_executada_idx ON tech2d.limpezas_anuais_agenda (executada_em DESC);
REVOKE ALL ON tech2d.limpezas_anuais_agenda FROM PUBLIC;
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_api') THEN
        GRANT SELECT, INSERT ON tech2d.limpezas_anuais_agenda TO tech2d_api;
    END IF;
END $$;

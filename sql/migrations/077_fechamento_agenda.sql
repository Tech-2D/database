CREATE TABLE tech2d.config_fechamento_agenda (
    id integer PRIMARY KEY CHECK (id = 1),
    versao integer NOT NULL DEFAULT 0 CHECK (versao >= 0),
    rascunho jsonb CHECK (jsonb_typeof(rascunho) = 'object'),
    publicado jsonb CHECK (jsonb_typeof(publicado) = 'object'),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

INSERT INTO tech2d.config_fechamento_agenda (id) VALUES (1);
REVOKE ALL ON tech2d.config_fechamento_agenda FROM PUBLIC;

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_api') THEN
        GRANT SELECT, UPDATE ON tech2d.config_fechamento_agenda TO tech2d_api;
    END IF;
END $$;

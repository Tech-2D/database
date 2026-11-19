CREATE TABLE tech2d.uso_diario_assistente (
    dia date PRIMARY KEY,
    mensagens integer NOT NULL CHECK (mensagens > 0)
);

COMMENT ON TABLE tech2d.uso_diario_assistente IS 'Total de mensagens aceitas pelo Assistente por dia de Brasília.';
REVOKE ALL ON tech2d.uso_diario_assistente FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON tech2d.uso_diario_assistente TO tech2d_prod_ai_quota;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_api') THEN
    GRANT SELECT ON tech2d.uso_diario_assistente TO tech2d_api;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_qa_ai_quota') THEN
    GRANT SELECT, INSERT, UPDATE ON tech2d.uso_diario_assistente TO tech2d_qa_ai_quota;
  END IF;
END $$;

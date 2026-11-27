ALTER TABLE tech2d.aulas_recuperacao
    DROP CONSTRAINT aulas_recuperacao_ordem_check,
    ADD CONSTRAINT aulas_recuperacao_ordem_check CHECK (ordem >= 1);

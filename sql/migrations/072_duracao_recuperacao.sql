ALTER TABLE tech2d.editais_recuperacao
    ALTER COLUMN inicio DROP NOT NULL,
    ALTER COLUMN fim DROP NOT NULL,
    ADD CONSTRAINT editais_recuperacao_janela_completa CHECK ((inicio IS NULL) = (fim IS NULL));

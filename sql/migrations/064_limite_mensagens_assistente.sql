-- Contagem diária do Assistente por conta Firebase e data de São Paulo.
CREATE TABLE tech2d.limites_mensagens_ia (
    firebase_uid text PRIMARY KEY CHECK (length(firebase_uid) BETWEEN 1 AND 128),
    data_uso date NOT NULL,
    quantidade integer NOT NULL CHECK (quantidade >= 0)
);
REVOKE ALL ON tech2d.limites_mensagens_ia FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON tech2d.limites_mensagens_ia TO tech2d_prod_ai_quota;

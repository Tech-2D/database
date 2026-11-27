CREATE TABLE tech2d.editais_recuperacao (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo text NOT NULL CHECK (length(titulo) BETWEEN 1 AND 140),
    descricao text NOT NULL CHECK (length(descricao) <= 6000),
    link text CHECK (length(link) <= 1000),
    inicio timestamptz NOT NULL,
    fim timestamptz NOT NULL CHECK (fim > inicio)
);

CREATE TABLE tech2d.aulas_recuperacao (
    edital_id integer REFERENCES tech2d.editais_recuperacao(id),
    ordem integer CHECK (ordem BETWEEN 1 AND 200),
    dia date NOT NULL,
    inicio time NOT NULL,
    fim time NOT NULL CHECK (fim > inicio),
    materia text NOT NULL CHECK (length(materia) BETWEEN 1 AND 120),
    turma text CHECK (length(turma) <= 100),
    professor text CHECK (length(professor) <= 120),
    local text CHECK (length(local) <= 120),
    PRIMARY KEY (edital_id, ordem)
);

REVOKE ALL ON tech2d.editais_recuperacao, tech2d.aulas_recuperacao FROM PUBLIC;

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_api') THEN
        GRANT SELECT, INSERT ON tech2d.editais_recuperacao, tech2d.aulas_recuperacao TO tech2d_api;
    END IF;
END $$;

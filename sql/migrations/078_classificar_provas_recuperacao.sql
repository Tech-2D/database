ALTER TABLE tech2d.aulas_recuperacao
    ADD COLUMN prova boolean NOT NULL DEFAULT false;

UPDATE tech2d.aulas_recuperacao
SET prova = true
WHERE materia ~* '[[:space:]]+\(prova\)[[:space:]]*$';

COMMENT ON COLUMN tech2d.aulas_recuperacao.prova IS 'Indica uma prova de recuperação, distinta de uma aula de revisão.';

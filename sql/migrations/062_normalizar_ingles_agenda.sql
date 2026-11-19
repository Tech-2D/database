-- Mantém o ID compartilhado pelos horários, atividades e notas.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));

UPDATE tech2d.disciplinas AS antiga
SET nome = 'Língua Inglesa'
WHERE antiga.nome = 'Lingua Inglêsa'
  AND NOT EXISTS (
    SELECT 1 FROM tech2d.disciplinas AS atual WHERE atual.nome = 'Língua Inglesa'
  );

-- Mantém as associações da série para notas já salvas e acrescenta as disciplinas
-- da grade ativa do Tech. A API continua usando as chaves dos cadernos existentes.
LOCK TABLE tech2d.horarios_aula IN SHARE ROW EXCLUSIVE MODE;

CREATE FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint)
RETURNS void
LANGUAGE sql
SET search_path TO 'pg_catalog'
AS $function$
  INSERT INTO tech2d.disciplinas_series (id_disciplina, ano_serie)
  SELECT COALESCE(canonica.id, disciplina.id), left(turma.nome, 1)::smallint
  FROM tech2d.turmas turma
  JOIN tech2d.disciplinas disciplina ON disciplina.id = disciplina_id
  LEFT JOIN tech2d.disciplinas canonica ON canonica.nome = CASE disciplina.nome
    WHEN 'Desenvolvimento Aplicação Dinâmica' THEN 'Desenvolvimento de Aplicação Dinâmica'
    WHEN 'Engenharia e Qualidade de Software' THEN 'Engenharia e Qualidae de Software'
    WHEN 'Língua Portuguesa e suas Literaturas' THEN 'Língua Portuguesa e Suas Literaturas'
    WHEN 'Matemática 9-Banco de Dados' THEN 'Matemática 9-Banco de dados'
    WHEN 'Língua Inglesa' THEN 'Lingua inglesa'
    WHEN 'Lingua Inglêsa' THEN 'Lingua inglesa'
    WHEN 'Biologia 2-ESG-Environment, Social and Governance' THEN 'Biologia 2 - ESG'
    WHEN 'Matemática 14 - Inteligência Artificial' THEN 'Matemática 14-Inteligência Artificial'
    ELSE disciplina.nome
  END
  WHERE turma.id = turma_id AND turma.nome ~ '^[123]º Tec '
  ON CONFLICT DO NOTHING;
$function$;

REVOKE ALL ON FUNCTION tech2d.vincular_disciplina_notaki(bigint, bigint) FROM PUBLIC;

SELECT tech2d.vincular_disciplina_notaki(h.id_turma, h.id_disciplina)
FROM (SELECT DISTINCT id_turma, id_disciplina FROM tech2d.horarios_aula WHERE ativo) h;

CREATE FUNCTION tech2d.vincular_nova_disciplina_notaki()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  PERFORM tech2d.vincular_disciplina_notaki(NEW.id_turma, NEW.id_disciplina);
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION tech2d.vincular_nova_disciplina_notaki() FROM PUBLIC;

CREATE TRIGGER vincular_disciplina_notaki
AFTER INSERT OR UPDATE OF id_turma, id_disciplina, ativo ON tech2d.horarios_aula
FOR EACH ROW WHEN (NEW.ativo)
EXECUTE FUNCTION tech2d.vincular_nova_disciplina_notaki();

COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:039_disciplinas_notaki_por_turma';

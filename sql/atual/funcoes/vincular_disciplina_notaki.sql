-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vincular_disciplina_notaki(bigint, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint) RETURNS void
    LANGUAGE sql
    SET search_path TO 'pg_catalog'
    AS $$
  INSERT INTO tech2d.disciplinas_series (id_disciplina, ano_serie)
  SELECT COALESCE(canonica.id_disciplina, disciplina.id_disciplina), left(turma.nome, 1)::smallint
  FROM tech2d.turmas turma
  JOIN tech2d.disciplinas disciplina ON disciplina.id_disciplina = disciplina_id
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
  WHERE turma.id_turma = turma_id AND turma.nome ~ '^[123]º Tec '
  ON CONFLICT DO NOTHING;
$$;

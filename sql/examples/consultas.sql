-- Versão instalada, registrada no comentário do schema.
SELECT obj_description('tech2d'::regnamespace, 'pg_namespace') AS versao_do_schema;

-- Atividades gerais e da turma de exemplo nos próximos sete dias.
WITH periodo AS (
  SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date AS data_inicio
)
SELECT a.referencia_api AS id_publico, a.data_atividade, a.hora_atividade,
  a.titulo, a.tipo_atividade, turma.nome AS turma
FROM tech2d.atividades AS a
LEFT JOIN tech2d.turmas AS turma ON turma.id_turma = a.id_turma
CROSS JOIN periodo AS p
WHERE (turma.nome = 'TURMA-EXEMPLO' OR a.id_turma IS NULL)
  AND a.data_atividade >= p.data_inicio
  AND a.data_atividade < p.data_inicio + 7
ORDER BY a.data_atividade, a.hora_atividade NULLS LAST, a.referencia_api;

-- Horários ativos da turma de exemplo e suas referências.
SELECT h.id_horario_aula, turma.nome AS turma, professor.nome AS professor,
  disciplina.nome AS disciplina, h.dia_semana, faixa.hora_inicio, faixa.hora_fim
FROM tech2d.horarios_aula AS h
JOIN tech2d.turmas AS turma ON turma.id_turma = h.id_turma
JOIN tech2d.professores AS professor ON professor.id_professor = h.id_professor
JOIN tech2d.disciplinas AS disciplina ON disciplina.id_disciplina = h.id_disciplina
JOIN tech2d.faixas_horario AS faixa ON faixa.id_faixa_horario = h.id_faixa_horario
WHERE turma.nome = 'TURMA-EXEMPLO' AND h.ativo
ORDER BY h.dia_semana, faixa.hora_inicio, h.id_horario_aula;

-- Total agregado por site e dia, sem identificadores individuais.
SELECT site, dia,
  count(*) FILTER (WHERE tipo_visitante = 'account') AS com_login,
  count(*) FILTER (WHERE tipo_visitante = 'anonymous') AS anonimos
FROM tech2d.visitas_aos_sites
WHERE dia >= (now() AT TIME ZONE 'America/Sao_Paulo')::date - 6
GROUP BY site, dia
ORDER BY dia DESC, site;

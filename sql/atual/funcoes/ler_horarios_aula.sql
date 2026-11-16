-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_horarios_aula(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_horarios_aula(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object('professor',p.nome,'subject',d.nome,'className',t.nome,
    'startTime',to_char(f.hora_inicio,'HH24:MI'),'endTime',to_char(f.hora_fim,'HH24:MI'),'dayOfWeek',h.dia_semana,
    'active',h.ativo,'floor',h.andar,'roomDescription',h.sala,'createdAt',h.criado_em,'updatedAt',h.alterado_em))
  FROM tech2d.horarios_aula h
  JOIN tech2d.professores p ON p.id_professor=h.id_professor JOIN tech2d.disciplinas d ON d.id_disciplina=h.id_disciplina
  JOIN tech2d.turmas t ON t.id_turma=h.id_turma JOIN tech2d.faixas_horario f ON f.id_faixa_horario=h.id_faixa_horario
  WHERE h.id_horario_interno=alvo;
$$;

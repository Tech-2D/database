-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_documentos_aplicacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_documentos_aplicacao AS
 SELECT tech2d.referencia_api('activities'::character varying, ''::character varying, atividades.referencia_api) AS path,
    'activities'::text AS collection,
    atividades.referencia_api AS id,
    tech2d.ler_registro(atividades.id_atividade, 'activities'::character varying) AS data,
    atividades.versao AS version,
    atividades.atualizado_em AS updated_at
   FROM tech2d.atividades
UNION ALL
 SELECT tech2d.referencia_api('admins'::character varying, ''::character varying, perfis_administrativos.referencia_api) AS path,
    'admins'::text AS collection,
    perfis_administrativos.referencia_api AS id,
    tech2d.ler_registro(perfis_administrativos.id_perfil_administrativo, 'admins'::character varying) AS data,
    perfis_administrativos.versao AS version,
    perfis_administrativos.atualizado_em AS updated_at
   FROM tech2d.perfis_administrativos
UNION ALL
 SELECT tech2d.referencia_api('recurringActivities'::character varying, ''::character varying, regras_recorrencia.referencia_api) AS path,
    'recurringActivities'::text AS collection,
    regras_recorrencia.referencia_api AS id,
    tech2d.ler_registro(regras_recorrencia.id_regra_recorrencia, 'recurringActivities'::character varying) AS data,
    regras_recorrencia.versao AS version,
    regras_recorrencia.atualizado_em AS updated_at
   FROM tech2d.regras_recorrencia
UNION ALL
 SELECT tech2d.referencia_api('activityRetention'::character varying, ''::character varying, regras_retencao.referencia_api) AS path,
    'activityRetention'::text AS collection,
    regras_retencao.referencia_api AS id,
    tech2d.ler_registro(regras_retencao.id_regra_retencao, 'activityRetention'::character varying) AS data,
    regras_retencao.versao AS version,
    regras_retencao.atualizado_em AS updated_at
   FROM tech2d.regras_retencao
UNION ALL
 SELECT tech2d.referencia_api('agendaClasses'::character varying, ''::character varying, turmas_agenda.referencia_api) AS path,
    'agendaClasses'::text AS collection,
    turmas_agenda.referencia_api AS id,
    tech2d.ler_registro(turmas_agenda.id_turma_agenda, 'agendaClasses'::character varying) AS data,
    turmas_agenda.versao AS version,
    turmas_agenda.atualizado_em AS updated_at
   FROM tech2d.turmas_agenda
UNION ALL
 SELECT tech2d.referencia_api('feedback'::character varying, ''::character varying, sugestoes_melhoria.referencia_api) AS path,
    'feedback'::text AS collection,
    sugestoes_melhoria.referencia_api AS id,
    tech2d.ler_registro(sugestoes_melhoria.id_sugestao_melhoria, 'feedback'::character varying) AS data,
    sugestoes_melhoria.versao AS version,
    sugestoes_melhoria.atualizado_em AS updated_at
   FROM tech2d.sugestoes_melhoria
UNION ALL
 SELECT tech2d.referencia_api('schedules'::character varying, ''::character varying, horarios_aula.id_horario_aula) AS path,
    'schedules'::text AS collection,
    horarios_aula.id_horario_aula AS id,
    tech2d.ler_registro(horarios_aula.id_horario_interno, 'schedules'::character varying) AS data,
    horarios_aula.versao AS version,
    horarios_aula.atualizado_em AS updated_at
   FROM tech2d.horarios_aula
UNION ALL
 SELECT tech2d.referencia_api('userProfiles'::character varying, ''::character varying, perfis.referencia_api) AS path,
    'userProfiles'::text AS collection,
    perfis.referencia_api AS id,
    tech2d.ler_registro(perfis.id_perfil, 'userProfiles'::character varying) AS data,
    perfis.versao AS version,
    perfis.atualizado_em AS updated_at
   FROM tech2d.perfis
  WHERE (perfis.versao IS NOT NULL)
UNION ALL
 SELECT tech2d.referencia_api('_agendaDigestPreferences'::character varying, ''::character varying, perfis.referencia_api) AS path,
    '_agendaDigestPreferences'::text AS collection,
    perfis.referencia_api AS id,
    tech2d.ler_registro(perfis.id_perfil, '_agendaDigestPreferences'::character varying) AS data,
    perfis.resumo_versao AS version,
    perfis.resumo_atualizado_em AS updated_at
   FROM tech2d.perfis
  WHERE (perfis.resumo_versao IS NOT NULL)
UNION ALL
 SELECT tech2d.referencia_api('personalKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'personalKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'personalKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE (NOT espacos_kanban.compartilhado)
UNION ALL
 SELECT tech2d.referencia_api('kanbanMemberships'::character varying, ''::character varying, participantes_kanban.referencia_api) AS path,
    'kanbanMemberships'::text AS collection,
    participantes_kanban.referencia_api AS id,
    tech2d.ler_registro(participantes_kanban.id_participante_kanban, 'kanbanMemberships'::character varying) AS data,
    participantes_kanban.versao AS version,
    participantes_kanban.atualizado_em AS updated_at
   FROM tech2d.participantes_kanban
UNION ALL
 SELECT tech2d.referencia_api('sharedKanban'::character varying, ''::character varying, espacos_kanban.referencia_api) AS path,
    'sharedKanban'::text AS collection,
    espacos_kanban.referencia_api AS id,
    tech2d.ler_registro(espacos_kanban.id_espaco_kanban, 'sharedKanban'::character varying) AS data,
    espacos_kanban.versao AS version,
    espacos_kanban.atualizado_em AS updated_at
   FROM tech2d.espacos_kanban
  WHERE espacos_kanban.compartilhado;

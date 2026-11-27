-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: SCHEMA tech2d; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA tech2d TO tech2d_api;
GRANT USAGE ON SCHEMA tech2d TO tech2d_prod_ai_reader;
GRANT USAGE ON SCHEMA tech2d TO tech2d_prod_ai_quota;
GRANT USAGE ON SCHEMA tech2d TO assistente_ia_readonly;
GRANT USAGE ON SCHEMA tech2d TO tech2d_backup;

-- Name: FUNCTION consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) TO tech2d_api;

-- Name: FUNCTION gravar_registros(lote jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.gravar_registros(lote jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.gravar_registros(lote jsonb) TO tech2d_api;

-- Name: FUNCTION inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_anexos_atividade(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_cartoes_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_colunas_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_itens_checklist(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.inserir_quadros_kanban(pai bigint, posicao integer, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION ler_anexos_atividade(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_anexos_atividade(alvo bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.ler_anexos_atividade(alvo bigint) TO tech2d_api;

-- Name: FUNCTION ler_atividades(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_atividades(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_cartoes_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_cartoes_kanban(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_colunas_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_colunas_kanban(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_espacos_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_espacos_kanban(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_horarios_aula(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_horarios_aula(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_itens_checklist(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_itens_checklist(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_participantes_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_participantes_kanban(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_perfis(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_perfis(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_perfis_administrativos(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_perfis_administrativos(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_quadros_kanban(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_quadros_kanban(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_registro(alvo bigint, tipo character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.ler_registro(alvo bigint, tipo character varying) TO tech2d_api;

-- Name: FUNCTION ler_regras_recorrencia(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_regras_recorrencia(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_regras_retencao(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_regras_retencao(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_sugestoes_melhoria(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION ler_turmas_agenda(alvo bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.ler_turmas_agenda(alvo bigint) FROM PUBLIC;

-- Name: FUNCTION padronizar_listas_registro(tipo character varying, objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.padronizar_listas_registro(tipo character varying, objeto jsonb) FROM PUBLIC;

-- Name: FUNCTION referencia_api(tipo character varying, pai character varying, referencia character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.referencia_api(tipo character varying, pai character varying, referencia character varying) TO tech2d_api;

-- Name: FUNCTION remover_nulos_raiz(objeto jsonb); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.remover_nulos_raiz(objeto jsonb) TO tech2d_api;

-- Name: FUNCTION revisao_catalogo_publico(catalogo character varying); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) TO tech2d_api;

-- Name: FUNCTION travar_gravacao(caminhos text[]); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.travar_gravacao(caminhos text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION tech2d.travar_gravacao(caminhos text[]) TO tech2d_api;

-- Name: FUNCTION vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.vincular_disciplina_notaki(turma_id bigint, disciplina_id bigint) FROM PUBLIC;

-- Name: FUNCTION vincular_nova_disciplina_notaki(); Type: ACL; Schema: tech2d; Owner: -
--

REVOKE ALL ON FUNCTION tech2d.vincular_nova_disciplina_notaki() FROM PUBLIC;

-- Name: TABLE anexos_atividade; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.anexos_atividade TO tech2d_backup;

-- Name: SEQUENCE anexos_atividade_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.anexos_atividade_id_seq TO tech2d_backup;

-- Name: TABLE apelidos_disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.apelidos_disciplinas TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.apelidos_disciplinas TO tech2d_backup;

-- Name: SEQUENCE apelidos_disciplinas_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.apelidos_disciplinas_id_seq TO tech2d_backup;

-- Name: TABLE apelidos_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.apelidos_professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.apelidos_professores TO tech2d_backup;

-- Name: SEQUENCE apelidos_professores_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.apelidos_professores_id_seq TO tech2d_backup;

-- Name: SEQUENCE ids_entidades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.ids_entidades TO tech2d_backup;

-- Name: TABLE turmas_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.turmas_agenda TO tech2d_backup;

-- Name: TABLE assistant_class_catalog; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_class_catalog TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_class_catalog TO tech2d_backup;

-- Name: TABLE disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.disciplinas TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.disciplinas TO tech2d_backup;

-- Name: TABLE regras_recorrencia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.regras_recorrencia TO tech2d_backup;

-- Name: TABLE turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.turmas TO tech2d_backup;

-- Name: TABLE assistant_recurring_activities; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_recurring_activities TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_recurring_activities TO tech2d_backup;

-- Name: TABLE faixas_horario; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.faixas_horario TO tech2d_backup;

-- Name: TABLE horarios_aula; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.horarios_aula TO tech2d_backup;

-- Name: TABLE assistant_teacher_schedule; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.assistant_teacher_schedule TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.assistant_teacher_schedule TO tech2d_backup;

-- Name: TABLE atividades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.atividades TO tech2d_backup;

-- Name: TABLE aulas_recuperacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.aulas_recuperacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.aulas_recuperacao TO tech2d_backup;

-- Name: TABLE cartoes_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.cartoes_kanban TO tech2d_backup;

-- Name: SEQUENCE cartoes_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.cartoes_kanban_id_seq TO tech2d_backup;

-- Name: TABLE disciplinas_series; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.disciplinas_series TO tech2d_api;
GRANT SELECT ON TABLE tech2d.disciplinas_series TO tech2d_backup;

-- Name: TABLE professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.professores TO tech2d_backup;

-- Name: TABLE vinculos_professores_turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.vinculos_professores_turmas TO tech2d_backup;

-- Name: TABLE visao_disciplinas_notas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_disciplinas_notas TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_disciplinas_notas TO tech2d_backup;

-- Name: TABLE catalogo_atividades_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.catalogo_atividades_professores TO tech2d_prod_ai_reader;
GRANT SELECT ON TABLE tech2d.catalogo_atividades_professores TO tech2d_backup;

-- Name: TABLE catalogo_horarios; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.catalogo_horarios TO tech2d_api;
GRANT SELECT ON TABLE tech2d.catalogo_horarios TO tech2d_backup;

-- Name: TABLE colunas_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.colunas_kanban TO tech2d_backup;

-- Name: SEQUENCE colunas_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.colunas_kanban_id_seq TO tech2d_backup;

-- Name: TABLE config_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_prod_ai_quota;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.config_assistente TO tech2d_api;
GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.config_assistente TO tech2d_backup;

-- Name: TABLE config_fechamento_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,UPDATE ON TABLE tech2d.config_fechamento_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.config_fechamento_agenda TO tech2d_backup;

-- Name: TABLE editais_recuperacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.editais_recuperacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.editais_recuperacao TO tech2d_backup;

-- Name: SEQUENCE editais_recuperacao_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.editais_recuperacao_id_seq TO tech2d_backup;

-- Name: TABLE espacos_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.espacos_kanban TO tech2d_backup;

-- Name: TABLE itens_checklist; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.itens_checklist TO tech2d_backup;

-- Name: SEQUENCE itens_checklist_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.itens_checklist_id_seq TO tech2d_backup;

-- Name: TABLE limites_mensagens_ia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.limites_mensagens_ia TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.limites_mensagens_ia TO tech2d_backup;

-- Name: TABLE limpeza_anexos_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.limpeza_anexos_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.limpeza_anexos_agenda TO tech2d_backup;

-- Name: TABLE limpezas_anuais_agenda; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.limpezas_anuais_agenda TO tech2d_api;
GRANT SELECT ON TABLE tech2d.limpezas_anuais_agenda TO tech2d_backup;

-- Name: TABLE notas_cadernos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_cadernos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_cadernos TO tech2d_backup;

-- Name: TABLE notas_lancamentos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_lancamentos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_lancamentos TO tech2d_backup;

-- Name: TABLE notas_recuperacoes; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.notas_recuperacoes TO tech2d_api;
GRANT SELECT ON TABLE tech2d.notas_recuperacoes TO tech2d_backup;

-- Name: TABLE participantes_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.participantes_kanban TO tech2d_backup;

-- Name: TABLE perfis; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.perfis TO tech2d_backup;

-- Name: TABLE perfis_administrativos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.perfis_administrativos TO tech2d_backup;

-- Name: TABLE quadros_kanban; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.quadros_kanban TO tech2d_backup;

-- Name: SEQUENCE quadros_kanban_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.quadros_kanban_id_seq TO tech2d_backup;

-- Name: TABLE recibos_gravacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.recibos_gravacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.recibos_gravacao TO tech2d_backup;

-- Name: TABLE regras_retencao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.regras_retencao TO tech2d_backup;

-- Name: TABLE reservas_mensagens_ia; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.reservas_mensagens_ia TO tech2d_prod_ai_quota;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE tech2d.reservas_mensagens_ia TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.reservas_mensagens_ia TO tech2d_backup;

-- Name: SEQUENCE school_classes_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_classes_id_seq TO tech2d_backup;

-- Name: SEQUENCE school_subjects_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_subjects_id_seq TO tech2d_backup;

-- Name: SEQUENCE school_teachers_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_teachers_id_seq TO tech2d_backup;

-- Name: SEQUENCE school_time_slots_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.school_time_slots_id_seq TO tech2d_backup;

-- Name: TABLE sugestoes_melhoria; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.sugestoes_melhoria TO tech2d_backup;

-- Name: TABLE uso_contas_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_contas_assistente TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_contas_assistente TO tech2d_api;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_contas_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_contas_assistente TO tech2d_backup;

-- Name: TABLE uso_diario_assistente; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_diario_assistente TO tech2d_prod_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_diario_assistente TO tech2d_api;
GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.uso_diario_assistente TO tech2d_qa_ai_quota;
GRANT SELECT ON TABLE tech2d.uso_diario_assistente TO tech2d_backup;

-- Name: SEQUENCE vinculos_professores_turmas_id_seq; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON SEQUENCE tech2d.vinculos_professores_turmas_id_seq TO tech2d_backup;

-- Name: TABLE vinculos_turma_perfil; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE tech2d.vinculos_turma_perfil TO tech2d_api;
GRANT SELECT ON TABLE tech2d.vinculos_turma_perfil TO tech2d_backup;

-- Name: TABLE visao_atividades; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_atividades TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_atividades TO tech2d_backup;

-- Name: TABLE visao_atividades_automacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_atividades_automacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_atividades_automacao TO tech2d_backup;

-- Name: TABLE visao_catalogo_horarios; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_catalogo_horarios TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_catalogo_horarios TO tech2d_backup;

-- Name: TABLE visao_disciplinas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_disciplinas TO tech2d_backup;

-- Name: TABLE visao_documentos_aplicacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_documentos_aplicacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_documentos_aplicacao TO tech2d_backup;

-- Name: TABLE visao_documentos_catalogo; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_documentos_catalogo TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_documentos_catalogo TO tech2d_backup;

-- Name: TABLE visao_faixas_horario; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_faixas_horario TO tech2d_backup;

-- Name: TABLE visao_horarios_aula; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_horarios_aula TO tech2d_backup;

-- Name: TABLE visao_notas_resultados; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_notas_resultados TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_notas_resultados TO tech2d_backup;

-- Name: TABLE visao_perfis_administrativos; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_perfis_administrativos TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_perfis_administrativos TO tech2d_backup;

-- Name: TABLE visao_professores; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_professores TO tech2d_backup;

-- Name: TABLE visao_recibos_gravacao; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT ON TABLE tech2d.visao_recibos_gravacao TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visao_recibos_gravacao TO tech2d_backup;

-- Name: TABLE visao_turmas; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT ON TABLE tech2d.visao_turmas TO tech2d_backup;

-- Name: TABLE visitas_aos_sites; Type: ACL; Schema: tech2d; Owner: -
--

GRANT SELECT,INSERT,DELETE ON TABLE tech2d.visitas_aos_sites TO tech2d_api;
GRANT SELECT ON TABLE tech2d.visitas_aos_sites TO tech2d_backup;

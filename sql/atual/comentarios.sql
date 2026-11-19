-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: SCHEMA tech2d; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:068_fila_anexos_e_travas';

-- Name: FUNCTION buscar_id_turma(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.buscar_id_turma(valor text) IS 'Busca sem gravar o ID de uma turma por referência estável da Agenda ou nome do catálogo. Usada nas consultas indexadas do calendário.';

-- Name: FUNCTION chave_turma(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.chave_turma(valor text) IS 'Permite comparar rótulos da mesma turma, como 2° TECH D e 2º Tec D, sem criar outra turma.';

-- Name: FUNCTION consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean) IS 'Seleciona atividades gerais e da turma e reúne os documentos do catálogo em uma consulta limitada.';

-- Name: FUNCTION nome_disciplina_agenda(alvo bigint); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.nome_disciplina_agenda(alvo bigint) IS 'Reconstrói o rótulo da disciplina usando a convenção já compartilhada com Notas, sem duplicar disciplinas para diferenças de exibição.';

-- Name: FUNCTION nome_turma_agenda(alvo bigint); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.nome_turma_agenda(alvo bigint) IS 'Reconstrói o identificador textual esperado pela Agenda a partir do ID escolar, mantendo as permissões e os links existentes.';

-- Name: FUNCTION normalizar_rotulo(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.normalizar_rotulo(valor text) IS 'Normaliza somente para localizar um rótulo existente, ignorando caixa, acentos e pontuação; não substitui os nomes guardados no catálogo.';

-- Name: FUNCTION resolver_disciplina(valor text); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.resolver_disciplina(valor text) IS 'Reutiliza disciplinas por nome exato, rótulo de Notas ou correspondência única normalizada. Rejeita ambiguidades; cadastra uma matéria apenas quando ela ainda não existe. Não concede autorização.';

-- Name: FUNCTION resolver_turma(valor text, agenda boolean); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.resolver_turma(valor text, agenda boolean) IS 'Reutiliza a turma existente por referência, nome ou correspondência única normalizada. Cadastra somente nomes novos e registra uma vez a referência da Agenda, quando solicitado. Não concede autorização.';

-- Name: FUNCTION revisao_catalogo_publico(catalogo character varying); Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) IS 'Calcula a revisão do catálogo com as versões dos registros e os nomes/referências de disciplinas e turmas; alterações nesses catálogos também invalidam o cache Redis.';

-- Name: TABLE anexos_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.anexos_atividade IS 'Metadados dos arquivos anexados às atividades';

-- Name: COLUMN anexos_atividade.id_anexo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.id_anexo_atividade IS 'Identificador numérico de anexos_atividade. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN anexos_atividade.id_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.id_atividade IS 'Atividade que contém o anexo. Referencia atividades.id_atividade; a exclusão da atividade remove os metadados de seus anexos.';

-- Name: COLUMN anexos_atividade.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.referencia IS 'Campo id no contrato da API.';

-- Name: COLUMN anexos_atividade.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.nome IS 'Campo name no contrato da API.';

-- Name: COLUMN anexos_atividade.tipo_mime; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.tipo_mime IS 'Campo contentType no contrato da API.';

-- Name: COLUMN anexos_atividade.tamanho_bytes; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.tamanho_bytes IS 'Campo size no contrato da API.';

-- Name: COLUMN anexos_atividade.chave_arquivo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.chave_arquivo IS 'Campo storagePath no contrato da API.';

-- Name: COLUMN anexos_atividade.enviado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.enviado_em IS 'Campo uploadedAt no contrato da API.';

-- Name: COLUMN anexos_atividade.enviado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.anexos_atividade.enviado_por IS 'Campo uploadedBy no contrato da API.';

-- Name: TABLE apelidos_disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.apelidos_disciplinas IS 'Apelidos aprovados usados pela IA para identificar disciplinas.';

-- Name: TABLE apelidos_professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.apelidos_professores IS 'Apelidos aprovados usados pela IA para identificar professores.';

-- Name: SEQUENCE ids_entidades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON SEQUENCE tech2d.ids_entidades IS 'Gera novos IDs numéricos sem reutilizar os IDs existentes.';

-- Name: TABLE turmas_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.turmas_agenda IS 'Turmas habilitadas na Agenda';

-- Name: COLUMN turmas_agenda.id_turma_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.id_turma_agenda IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN turmas_agenda.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.ativa IS 'Campo active no contrato da API.';

-- Name: COLUMN turmas_agenda.referencia_pedido; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.referencia_pedido IS 'Campo requestId no contrato da API.';

-- Name: COLUMN turmas_agenda.aprovada_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.aprovada_em IS 'Campo approvedAt no contrato da API.';

-- Name: COLUMN turmas_agenda.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN turmas_agenda.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN turmas_agenda.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN turmas_agenda.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas_agenda.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.disciplinas IS 'Nomes das disciplinas reutilizadas pelos horários.';

-- Name: COLUMN disciplinas.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas.id_disciplina IS 'Identificador numérico de disciplinas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: TABLE regras_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.regras_recorrencia IS 'Regras de repetição';

-- Name: COLUMN regras_recorrencia.id_regra_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_regra_recorrencia IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN regras_recorrencia.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.titulo IS 'Campo title no contrato da API.';

-- Name: COLUMN regras_recorrencia.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.descricao IS 'Campo description no contrato da API.';

-- Name: COLUMN regras_recorrencia.tipo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.tipo_atividade IS 'Campo type no contrato da API.';

-- Name: COLUMN regras_recorrencia.hora_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.hora_atividade IS 'Campo time no contrato da API.';

-- Name: COLUMN regras_recorrencia.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.criado_por IS 'Campo createdBy no contrato da API.';

-- Name: COLUMN regras_recorrencia.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN regras_recorrencia.data_inicio; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.data_inicio IS 'Campo startDate no contrato da API.';

-- Name: COLUMN regras_recorrencia.data_fim; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.data_fim IS 'Campo endDate no contrato da API.';

-- Name: COLUMN regras_recorrencia.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.ativa IS 'Campo active no contrato da API.';

-- Name: COLUMN regras_recorrencia.intervalo_semanas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.intervalo_semanas IS 'Campo intervalWeeks no contrato da API.';

-- Name: COLUMN regras_recorrencia.dias_semana; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.dias_semana IS 'Campo weekdays no contrato da API.';

-- Name: COLUMN regras_recorrencia.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';

-- Name: COLUMN regras_recorrencia.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN regras_recorrencia.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN regras_recorrencia.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN regras_recorrencia.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_recorrencia.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.turmas IS 'Nomes das turmas do catálogo de horários.';

-- Name: COLUMN turmas.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas.id_turma IS 'Identificador numérico de turmas. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN turmas.referencia_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.turmas.referencia_agenda IS 'Identificador textual estável da turma na Agenda, como 2° TECH D. É guardado uma única vez; os vínculos das tabelas usam id_turma.';

-- Name: TABLE faixas_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.faixas_horario IS 'Pares de horário de início e fim reutilizados pelas aulas.';

-- Name: COLUMN faixas_horario.id_faixa_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.faixas_horario.id_faixa_horario IS 'Identificador numérico de faixas_horario. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: TABLE horarios_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.horarios_aula IS 'Liga professor, disciplina, turma e faixa de horário a um dia da semana.';

-- Name: COLUMN horarios_aula.id_horario_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.id_horario_aula IS 'Identificador textual do horário preservado no contrato da API. id_horario_interno identifica o mesmo horário internamente.';

-- Name: COLUMN horarios_aula.id_horario_interno; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.id_horario_interno IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN horarios_aula.andar; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.andar IS 'Andar informado para a aula.';

-- Name: COLUMN horarios_aula.sala; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.sala IS 'Descrição da sala ou localização da aula.';

-- Name: COLUMN horarios_aula.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN horarios_aula.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.horarios_aula.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: TABLE atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.atividades IS 'Atividades da Agenda';

-- Name: COLUMN atividades.id_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_atividade IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN atividades.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.titulo IS 'Campo title no contrato da API.';

-- Name: COLUMN atividades.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.descricao IS 'Campo description no contrato da API.';

-- Name: COLUMN atividades.tipo_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.tipo_atividade IS 'Campo type no contrato da API.';

-- Name: COLUMN atividades.data_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.data_atividade IS 'Campo date no contrato da API.';

-- Name: COLUMN atividades.hora_atividade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.hora_atividade IS 'Campo time no contrato da API.';

-- Name: COLUMN atividades.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.criado_por IS 'Campo createdBy no contrato da API.';

-- Name: COLUMN atividades.email_criador; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.email_criador IS 'Campo createdByEmail no contrato da API.';

-- Name: COLUMN atividades.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN atividades.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.alterado_em IS 'Campo updatedAt no contrato da API.';

-- Name: COLUMN atividades.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';

-- Name: COLUMN atividades.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN atividades.id_regra_recorrencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.id_regra_recorrencia IS 'FK opcional para regras_recorrencia.id_regra_recorrencia. Identifica a regra que gerou a ocorrência; excluir fisicamente a regra desvincula a atividade sem excluí-la.';

-- Name: COLUMN atividades.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN atividades.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN atividades.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.atividades.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE cartoes_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.cartoes_kanban IS 'Cartões dos quadros';

-- Name: COLUMN cartoes_kanban.id_cartao_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_cartao_kanban IS 'Identificador numérico de cartoes_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN cartoes_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_quadro_kanban IS 'Quadro ao qual o cartão pertence. Referencia quadros_kanban.id_quadro_kanban; junto com referencia_coluna, exige uma coluna desse mesmo quadro.';

-- Name: COLUMN cartoes_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencia IS 'Campo id no contrato da API.';

-- Name: COLUMN cartoes_kanban.referencia_coluna; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencia_coluna IS 'Campo columnId no contrato da API.';

-- Name: COLUMN cartoes_kanban.titulo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.titulo IS 'Campo title no contrato da API.';

-- Name: COLUMN cartoes_kanban.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.descricao IS 'Campo description no contrato da API.';

-- Name: COLUMN cartoes_kanban.prioridade; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.prioridade IS 'Campo priority no contrato da API.';

-- Name: COLUMN cartoes_kanban.prazo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.prazo IS 'Campo dueDate no contrato da API.';

-- Name: COLUMN cartoes_kanban.id_responsavel; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.id_responsavel IS 'Campo assigneeId no contrato da API.';

-- Name: COLUMN cartoes_kanban.etiquetas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.etiquetas IS 'Campo labels no contrato da API.';

-- Name: COLUMN cartoes_kanban.referencias_atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.cartoes_kanban.referencias_atividades IS 'Campo activityIds no contrato da API.';

-- Name: TABLE disciplinas_series; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.disciplinas_series IS 'Vínculo entre o catálogo compartilhado de disciplinas e as séries do Ensino Médio. A área de Notas consulta esse vínculo para validar notas, sem duplicar os nomes das matérias.';

-- Name: COLUMN disciplinas_series.id_disciplina; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas_series.id_disciplina IS 'Disciplina do catálogo geral, também usado pelos horários. A chave estrangeira impede uma matéria inexistente.';

-- Name: COLUMN disciplinas_series.ano_serie; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.disciplinas_series.ano_serie IS 'Série de 1 a 3 em que a disciplina é oferecida. Compõe a chave para reutilizar a mesma matéria em séries diferentes.';

-- Name: TABLE professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.professores IS 'Nomes de professores reutilizados pelos horários.';

-- Name: COLUMN professores.id_professor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.professores.id_professor IS 'Identificador numérico de professores. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: TABLE vinculos_professores_turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.vinculos_professores_turmas IS 'Professor confirmado por turma e disciplina durante uma vigência.';

-- Name: VIEW visao_disciplinas_notas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_disciplinas_notas IS 'Projeção do catálogo compartilhado para o Notas. Conserva os rótulos que o frontend usa como chaves, sem armazenar outro catálogo de nomes.';

-- Name: VIEW catalogo_horarios; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.catalogo_horarios IS 'Reúne professor, disciplina, turma, faixa de horário, andar e sala.';

-- Name: TABLE colunas_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.colunas_kanban IS 'Colunas dos quadros';

-- Name: COLUMN colunas_kanban.id_coluna_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.id_coluna_kanban IS 'Identificador numérico de colunas_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN colunas_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.id_quadro_kanban IS 'Quadro ao qual a coluna pertence. Referencia quadros_kanban.id_quadro_kanban.';

-- Name: COLUMN colunas_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.referencia IS 'Campo id no contrato da API.';

-- Name: COLUMN colunas_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.nome IS 'Campo name no contrato da API.';

-- Name: COLUMN colunas_kanban.cor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.cor IS 'Campo color no contrato da API.';

-- Name: COLUMN colunas_kanban.concluida; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.colunas_kanban.concluida IS 'Campo done no contrato da API.';

-- Name: TABLE espacos_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.espacos_kanban IS 'Espaços pessoais e compartilhados do Kanban';

-- Name: COLUMN espacos_kanban.id_espaco_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.id_espaco_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN espacos_kanban.id_proprietario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.id_proprietario IS 'Campo ownerId no contrato da API.';

-- Name: COLUMN espacos_kanban.versao_formato; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.versao_formato IS 'Campo schemaVersion no contrato da API.';

-- Name: COLUMN espacos_kanban.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN espacos_kanban.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.alterado_em IS 'Campo updatedAt no contrato da API.';

-- Name: COLUMN espacos_kanban.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN espacos_kanban.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN espacos_kanban.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: COLUMN espacos_kanban.compartilhado; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.espacos_kanban.compartilhado IS 'Distingue espaços pessoais e compartilhados no contrato da API.';

-- Name: TABLE itens_checklist; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.itens_checklist IS 'Itens das listas dos cartões';

-- Name: COLUMN itens_checklist.id_item_checklist; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.id_item_checklist IS 'Identificador numérico de itens_checklist. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN itens_checklist.id_cartao_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.id_cartao_kanban IS 'Cartão que contém o item de checklist. Referencia cartoes_kanban.id_cartao_kanban.';

-- Name: COLUMN itens_checklist.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.referencia IS 'Campo id no contrato da API.';

-- Name: COLUMN itens_checklist.descricao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.descricao IS 'Campo text no contrato da API.';

-- Name: COLUMN itens_checklist.concluido; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.itens_checklist.concluido IS 'Campo done no contrato da API.';

-- Name: TABLE limpeza_anexos_agenda; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.limpeza_anexos_agenda IS 'Fila de limpeza de anexos R2 desvinculados pelo expurgo e por recorrências.';

-- Name: TABLE notas_cadernos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_cadernos IS 'Caderno privado da conta Firebase por ano letivo, série, modos de entrada e versão otimista.';

-- Name: COLUMN notas_cadernos.id_usuario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.id_usuario IS 'UID validado no Firebase Authentication, nunca escolhido pelo cliente.';

-- Name: COLUMN notas_cadernos.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.versao IS 'Versão usada para impedir sobrescrita por outra aba ou dispositivo.';

-- Name: COLUMN notas_cadernos.regra_calculo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.notas_cadernos.regra_calculo IS 'Versão da fórmula, para rastreabilidade dos cálculos.';

-- Name: TABLE notas_lancamentos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_lancamentos IS 'Notas N1/N2, média informada e pesos por disciplina e semestre. Nota vazia é NULL.';

-- Name: TABLE notas_recuperacoes; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.notas_recuperacoes IS 'Nota de recuperação final por conta, ano letivo e disciplina.';

-- Name: TABLE participantes_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.participantes_kanban IS 'Participantes de quadros compartilhados';

-- Name: COLUMN participantes_kanban.id_participante_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.id_participante_kanban IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN participantes_kanban.referencia_quadro; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.referencia_quadro IS 'Campo boardId no contrato da API.';

-- Name: COLUMN participantes_kanban.id_usuario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.id_usuario IS 'Campo userId no contrato da API.';

-- Name: COLUMN participantes_kanban.email; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.email IS 'Campo userEmail no contrato da API.';

-- Name: COLUMN participantes_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.nome IS 'Campo name no contrato da API.';

-- Name: COLUMN participantes_kanban.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN participantes_kanban.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN participantes_kanban.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN participantes_kanban.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.participantes_kanban.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE perfis; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.perfis IS 'Dados do perfil e preferências privadas do resumo semanal por usuário. A leitura pública seleciona somente os dados de apresentação e somente linhas com perfil publicado.';

-- Name: COLUMN perfis.id_perfil; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.id_perfil IS 'Identificador numérico do perfil do usuário. Chave primária gerada pela sequência ids_entidades.';

-- Name: COLUMN perfis.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.nome IS 'Campo displayName no contrato da API.';

-- Name: COLUMN perfis.empresa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.empresa IS 'Campo company no contrato da API.';

-- Name: COLUMN perfis.turma_informada; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.turma_informada IS 'Texto livre publicado pelo dono do perfil, como 2ºD. Não é a turma de autorização do representante nem uma referência obrigatória ao catálogo escolar.';

-- Name: COLUMN perfis.sala; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.sala IS 'Campo room no contrato da API.';

-- Name: COLUMN perfis.andar; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.andar IS 'Campo floor no contrato da API.';

-- Name: COLUMN perfis.url_foto; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.url_foto IS 'Campo photoUrl no contrato da API.';

-- Name: COLUMN perfis.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.alterado_em IS 'Campo updatedAt no contrato da API.';

-- Name: COLUMN perfis.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.versao IS 'Versão de edição dos dados de apresentação. Nula quando a conta apenas configurou o resumo e não publicou um perfil.';

-- Name: COLUMN perfis.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.atualizado_em IS 'Instante da última gravação dos dados de apresentação; nulo quando não há perfil publicado.';

-- Name: COLUMN perfis.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: COLUMN perfis.resumo_semanal_ativo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_semanal_ativo IS 'Escolha privada de receber o resumo semanal por e-mail. Nula quando não há preferência cadastrada.';

-- Name: COLUMN perfis.id_turma_resumo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.id_turma_resumo IS 'FK para turmas.id_turma. Turma selecionada para o resumo semanal, independente da turma livre informada no perfil público.';

-- Name: COLUMN perfis.resumo_alterado_em_ms; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_alterado_em_ms IS 'Momento da atualização da preferência em milissegundos desde o Unix epoch, preservado no contrato do serviço de e-mail.';

-- Name: COLUMN perfis.resumo_versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_versao IS 'Versão da preferência privada. Permite editar o perfil público e a inscrição no resumo sem sobrescrever uma seção ao salvar a outra.';

-- Name: COLUMN perfis.resumo_atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis.resumo_atualizado_em IS 'Instante da última gravação da preferência privada do resumo; nulo quando não existe inscrição configurada.';

-- Name: TABLE perfis_administrativos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.perfis_administrativos IS 'Papéis administrativos';

-- Name: COLUMN perfis_administrativos.id_perfil_administrativo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.id_perfil_administrativo IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN perfis_administrativos.papel; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.papel IS 'Campo role no contrato da API.';

-- Name: COLUMN perfis_administrativos.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN perfis_administrativos.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN perfis_administrativos.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN perfis_administrativos.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN perfis_administrativos.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.perfis_administrativos.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE quadros_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.quadros_kanban IS 'Quadros do Kanban em cada espaço';

-- Name: COLUMN quadros_kanban.id_quadro_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.id_quadro_kanban IS 'Identificador numérico de quadros_kanban. É a chave primária desta entidade e o destino dos relacionamentos correspondentes.';

-- Name: COLUMN quadros_kanban.id_espaco_kanban; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.id_espaco_kanban IS 'Espaço pessoal ou compartilhado que contém o quadro. Referencia espacos_kanban.id_espaco_kanban.';

-- Name: COLUMN quadros_kanban.referencia; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.referencia IS 'Campo id no contrato da API.';

-- Name: COLUMN quadros_kanban.nome; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.nome IS 'Campo name no contrato da API.';

-- Name: COLUMN quadros_kanban.cor; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.cor IS 'Campo color no contrato da API.';

-- Name: COLUMN quadros_kanban.compacto; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.quadros_kanban.compacto IS 'Campo compact no contrato da API.';

-- Name: TABLE recibos_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.recibos_gravacao IS 'Recibos que impedem uma gravação repetida de ser aplicada duas vezes.';

-- Name: COLUMN recibos_gravacao.id_recibo_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.recibos_gravacao.id_recibo_gravacao IS 'Identificador externo do lote confirmado, recebido em commit.id. O valor continua estável nos reenvios e é exposto como id pela view de recibos.';

-- Name: TABLE regras_retencao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.regras_retencao IS 'Políticas de expurgo por turma';

-- Name: COLUMN regras_retencao.id_regra_retencao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.id_regra_retencao IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN regras_retencao.dias; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.dias IS 'Campo days no contrato da API.';

-- Name: COLUMN regras_retencao.ativa; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.ativa IS 'Campo enabled no contrato da API.';

-- Name: COLUMN regras_retencao.alterado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.alterado_por IS 'Campo updatedBy no contrato da API.';

-- Name: COLUMN regras_retencao.alterado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.alterado_em IS 'Campo updatedAt no contrato da API.';

-- Name: COLUMN regras_retencao.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN regras_retencao.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN regras_retencao.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN regras_retencao.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.regras_retencao.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE sugestoes_melhoria; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.sugestoes_melhoria IS 'Sugestões de melhoria da Agenda';

-- Name: COLUMN sugestoes_melhoria.id_sugestao_melhoria; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_sugestao_melhoria IS 'Identificador numérico da própria entidade. Preserva o valor original e recebe novos IDs da sequência ids_entidades.';

-- Name: COLUMN sugestoes_melhoria.mensagem; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.mensagem IS 'Campo message no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.criado_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.criado_por IS 'Campo createdBy no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.email_criador; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.email_criador IS 'Campo createdByEmail no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.criado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.criado_em IS 'Campo createdAt no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.credito_autorizado; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.credito_autorizado IS 'Campo publicCreditAllowed no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.nome_credito; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.nome_credito IS 'Campo publicCreditName no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.situacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.situacao IS 'Campo status no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.concluida_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.concluida_em IS 'Campo completedAt no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.concluida_por; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.concluida_por IS 'Campo completedBy no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.id_turma; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';

-- Name: COLUMN sugestoes_melhoria.versao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.versao IS 'Revisão da entidade usada para detectar edições concorrentes.';

-- Name: COLUMN sugestoes_melhoria.atualizado_em; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.atualizado_em IS 'Instante da última gravação da entidade no contrato da API.';

-- Name: COLUMN sugestoes_melhoria.referencia_api; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON COLUMN tech2d.sugestoes_melhoria.referencia_api IS 'Identificador externo estável usado pelo contrato da API e pelos links da entidade.';

-- Name: TABLE uso_diario_assistente; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.uso_diario_assistente IS 'Total de mensagens aceitas pelo Assistente por dia de Brasília.';

-- Name: VIEW visao_atividades; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_atividades IS 'Atividades com seus anexos, para o calendário e os links diretos.';

-- Name: VIEW visao_atividades_automacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_atividades_automacao IS 'Atividades com turma, data e recorrência tipadas para os jobs. O conteúdo é reconstruído apenas para uso no arquivamento.';

-- Name: VIEW visao_catalogo_horarios; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_catalogo_horarios IS 'Apelidos de colunas usados pela API do Cadê o professor.';

-- Name: VIEW visao_disciplinas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_disciplinas IS 'Interface SQL de compatibilidade para disciplinas';

-- Name: VIEW visao_documentos_aplicacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_documentos_aplicacao IS 'Contrato de leitura da API. Reconstrói os objetos a partir das tabelas tipadas.';

-- Name: VIEW visao_documentos_catalogo; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_documentos_catalogo IS 'Catálogo calculado a partir das tabelas tipadas.';

-- Name: VIEW visao_faixas_horario; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_faixas_horario IS 'Interface SQL de compatibilidade para faixas_horario';

-- Name: VIEW visao_horarios_aula; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_horarios_aula IS 'Interface SQL de compatibilidade para horarios_aula';

-- Name: VIEW visao_notas_resultados; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_notas_resultados IS 'Médias por conta e disciplina do catálogo compartilhado; aplica as fórmulas tech-2026-v1 e preserva RLS nas tabelas de notas.';

-- Name: VIEW visao_perfis_administrativos; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_perfis_administrativos IS 'Papéis e turmas administrativas no formato consumido pela API.';

-- Name: VIEW visao_professores; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_professores IS 'Interface SQL de compatibilidade para professores';

-- Name: VIEW visao_recibos_gravacao; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_recibos_gravacao IS 'Interface SQL de compatibilidade para recibos_gravacao';

-- Name: VIEW visao_turmas; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON VIEW tech2d.visao_turmas IS 'Interface SQL de compatibilidade para turmas';

-- Name: TABLE visitas_aos_sites; Type: COMMENT; Schema: tech2d; Owner: -
--

COMMENT ON TABLE tech2d.visitas_aos_sites IS 'Visitas da Agenda e do Cadê o professor, agrupadas por visitante e intervalo de 30 minutos.';

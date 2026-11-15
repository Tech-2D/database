---
title: Modelagem e relações
description: Explore as tabelas do PostgreSQL, suas chaves e as views que usam cada objeto.
wide: true
---

<link rel="preload" href="{{ '/assets/model-explorer.js' | relative_url }}?v={{ site.github.build_revision }}" as="script">
<script type="module" src="{{ '/assets/model-explorer.js' | relative_url }}?v={{ site.github.build_revision }}"></script>

<section class="model-explorer" data-model-explorer aria-label="Explorador da modelagem física" hidden>
  <div class="model-toolbar">
    <div class="model-controls">
      <label>Área<select data-model-area><option value="">Todas as áreas</option>{% for group in site.data.catalog %}<option value="{{ group.id }}">{{ group.name | escape }}</option>{% endfor %}</select></label>
      <label><span class="catalog-label-icon">{% include doc-icon.html name="search" %}Buscar tabela ou coluna</span><input type="search" data-model-search placeholder="Ex.: horários, turma ou id_professor"></label>
    </div>
    <fieldset class="model-path-controls">
      <legend>Percorrer relações</legend>
      <label for="model-destination" class="visually-hidden">Tabela de destino</label>
      <select id="model-destination" data-model-destination></select>
      <button type="button" data-model-route>Mostrar caminho</button>
      <button type="button" data-model-clear hidden>Limpar caminho</button>
    </fieldset>
    <div data-model-path aria-live="polite"></div>
  </div>
  <div class="model-grid">
    <aside class="model-picker" aria-label="Tabelas disponíveis">
      <p data-model-result role="status"></p>
      <div class="model-table-list" data-model-list></div>
    </aside>
    <div data-model-details></div>
  </div>
</section>

<script type="application/json" id="model-schema">{{ site.data.schema | jsonify | replace: '<', '\u003c' }}</script>
<script type="application/json" id="model-groups">{{ site.data.catalog | jsonify | replace: '<', '\u003c' }}</script>
<script type="application/json" id="model-views">{{ site.data.views | jsonify | replace: '<', '\u003c' }}</script>
<script type="application/json" id="model-usage">{{ site.data.table_usage | jsonify | replace: '<', '\u003c' }}</script>
<script type="application/json" id="model-notes">{{ site.data.column_notes | jsonify | replace: '<', '\u003c' }}</script>

## Relações por área

Os vínculos do explorador vêm das chaves estrangeiras declaradas no PostgreSQL. Algumas regras da aplicação, descritas abaixo, usam identificadores validados pela API.

## Horários dos professores

A tabela [Horários de aula]({{ '/postgresql.html#obj-horarios_aula' | relative_url }}) guarda o dia da semana e o estado ativo da aula. As quatro chaves estrangeiras apontam para nomes e horários reutilizados.

<div class="relation-map" aria-label="Relações dos horários de aula">
  <a class="relation-core" href="{{ '/postgresql.html#obj-horarios_aula' | relative_url }}"><strong>Horários de aula</strong><code>horarios_aula</code></a>
  <div class="relation-branches">
    {% assign schedules = site.data.schema | where: "name", "horarios_aula" | first %}
    {% assign schedule_group = site.data.catalog | where: "id", "horarios" | first %}
    {% for relation in schedules.references %}
    {% assign related = schedule_group.objects | where: "name", relation.table | first %}
    <a href="{{ '/postgresql.html' | relative_url }}#obj-{{ relation.table }}"><strong>{{ related.title }}</strong><code>{{ relation.table }}</code><small><code>{{ relation.column }}</code> → <code>{{ relation.target }}</code></small></a>
    {% endfor %}
  </div>
</div>

A visão [Catálogo de horários]({{ '/views.html#view-catalogo_horarios' | relative_url }}) reúne os nomes das referências, os horários e as colunas `andar` e `sala` da própria aula.

## Identidade e links

Cada entidade guarda seu próprio ID numérico, como `atividades.id_atividade`, e sua referência externa em `referencia_api`. Os horários preservam a referência textual em `id_horario_aula`. A sequência `ids_entidades` gera novos números; ela não armazena registros. Os campos `versao` e `atualizado_em` ficam na própria entidade e permitem detectar conflitos de edição. Os IDs e links existentes foram preservados.

## Atividades e anexos

`atividades` guarda título, descrição, data e hora. `id_disciplina` referencia `disciplinas.id_disciplina` e `id_turma` referencia `turmas.id_turma`. Uma FK de turma nula indica atividade geral. Os nomes são reconstruídos a partir dos catálogos. `anexos_atividade` guarda os metadados dos arquivos. A FK `id_atividade` aponta para `atividades.id_atividade`, deixando explícito a qual atividade o anexo pertence. Não há coluna `ordem`: a API devolve os anexos em sequência estável pelo ID numérico.

`atividades.id_turma` e `horarios_aula.id_turma` apontam para a mesma turma escolar. `turmas.referencia_agenda` conserva o identificador textual esperado pelos links e pelas permissões, sem duplicá-lo em cada atividade.

O expurgo diário usa a regra de retenção da turma. A API exclui os anexos do Cloudflare R2 e, após a confirmação, remove a atividade e seus metadados do PostgreSQL. Uma falha no R2 mantém a atividade para nova tentativa.

## Sugestões de melhoria

`sugestoes_melhoria` registra o feedback autenticado, sua situação e a autorização opcional de crédito público nas atualizações. O autor continua podendo enviar sugestões e os administradores podem marcá-las como concluídas. A conversa privada foi removida na versão 053.

## Kanban

`espacos_kanban` identifica o proprietário e agrupa quadros pessoais ou compartilhados. Quadros, colunas, cartões e itens de checklist ficam em tabelas relacionadas. O vínculo entre cartão e coluna exige que os dois pertençam ao mesmo quadro. Participantes e pedidos de acesso ficam em tabelas próprias.

## Recibos de gravação: onde são usados

A tabela [recibos_gravacao]({{ '/postgresql.html#obj-recibos_gravacao' | relative_url }}) confirma lotes processados pela ação `commit` de `/api/data`. A API acessa a tabela pela [visao_recibos_gravacao]({{ '/views.html#view-visao_recibos_gravacao' | relative_url }}); essa view é uma projeção dos mesmos registros, sem outra cópia dos dados.

| Parte do sistema | Como usa o recibo |
| --- | --- |
| Criar e editar atividades | A fila da interface mantém o ID do lote ao tentar o envio novamente. Se a gravação já foi confirmada, a API reconhece o reenvio sem recriar a atividade ou repetir a edição. |
| Meu Kanban | As alterações enviadas pelo fluxo de documentos, como salvar cartões e reorganizar quadros, usam a mesma confirmação de lotes. Isso complementa o controle de versão que detecta edições concorrentes. |
| Sugestões | As gravações que passam pelo mesmo endpoint também recebem recibo, evitando repetir operações quando a resposta não chega ao navegador. |
| Aprovação de representantes | A aprovação SQL e seu recibo são confirmados juntos. O convite preparado no Redis só é aceito quando seu ID de operação, autor e hash correspondem ao recibo confirmado. Um convite preparado antes de uma transação revertida não libera acesso. |

Por exemplo: o representante salva uma atividade, o banco confirma a transação e a conexão cai antes de a resposta chegar. O navegador tenta novamente com o mesmo `commit.id`. A API encontra o recibo, confere o autor e o conteúdo e responde `replay:true`, sem repetir o lote. Se alguém reutilizar o mesmo ID com conteúdo diferente ou outra identidade, recebe HTTP 409.

### Por que permanece no PostgreSQL

O recibo é inserido **na mesma transação das alterações**. O banco confirma tudo junto ou reverte tudo. Mover somente o recibo para o Redis permitiria confirmar a atividade no PostgreSQL e falhar ao registrar sua confirmação no Redis, deixando o próximo envio sem prova de que a operação já terminou. O convite de representante também depende dessa prova SQL.

O recibo não contém o texto da atividade ou as mensagens, não substitui uma auditoria e não conta visitas. Ele contém apenas o ID do lote, a identidade de quem o enviou, o hash da requisição e a data de confirmação. Atualmente **não há TTL nem limpeza automática por idade** nessa tabela. Uma retenção futura precisa considerar o prazo de reenvio dos clientes e a validade dos convites.

Esse mecanismo não atende automaticamente todas as rotas: o salvamento de Notas, por exemplo, usa transação e controle de versão próprios; os avisos armazenados diretamente no Redis têm seu próprio fluxo de gravação.

No código da API, os pontos principais são [commitDocuments em document-store.js](https://github.com/Tech-2D/api/blob/main/src/document-store.js), [o encaminhamento em data-route.js](https://github.com/Tech-2D/api/blob/main/src/data-route.js) e [a validação dos convites em representative-invites.js](https://github.com/Tech-2D/api/blob/main/src/representative-invites.js). Na interface, [queuedWrites.ts](https://github.com/Tech-2D/web/blob/main/src/queuedWrites.ts) mantém o lote da fila para as tentativas de envio.

## Visitas e permissões

- [Visitas aos sites]({{ '/postgresql.html#obj-visitas_aos_sites' | relative_url }}) separa as visitas por site e deduplica acessos dentro de intervalos de 30 minutos.
  O painel de usuários também usa essas visitas para mostrar a data mais recente de cada conta na Agenda.
- [Perfis de acesso administrativo]({{ '/postgresql.html#obj-perfis_administrativos' | relative_url }}) guarda uma projeção do papel e da turma. A identidade da conta vem do Firebase Authentication.
- Os [bloqueios temporários da Agenda]({{ '/redis.html#bloqueios-da-agenda' | relative_url }}) ficam no Redis, identificados pelo UID da conta e com o prazo escolhido pelo administrador.

Os vínculos de horários usam chaves estrangeiras no PostgreSQL. Os vínculos entre documentos, contas e atividades usam identificadores que a API valida.

## Histórico do Firestore

A exportação privada guarda a cópia original do Firestore. A tabela de arquivo e o esquema relacional foram retirados do Aiven. O processo está registrado no [Histórico do Firestore]({{ '/firestore-legado.html' | relative_url }}).

## Nomes explícitos nas chaves estrangeiras

Os antigos campos `id_pai` foram substituídos por nomes que indicam o destino do vínculo:

| Tabela | Coluna | Referência |
| --- | --- | --- |
| anexos_atividade | id_atividade | atividades.id_atividade |
| quadros_kanban | id_espaco_kanban | espacos_kanban.id_espaco_kanban |
| colunas_kanban | id_quadro_kanban | quadros_kanban.id_quadro_kanban |
| cartoes_kanban | id_quadro_kanban | quadros_kanban.id_quadro_kanban |
| itens_checklist | id_cartao_kanban | cartoes_kanban.id_cartao_kanban |

Em `cartoes_kanban`, `(id_quadro_kanban, referencia_coluna)` também referencia `(id_quadro_kanban, referencia)` de `colunas_kanban`, garantindo que a coluna pertença ao mesmo quadro.

As chaves primárias pertencem às próprias entidades. As FKs representam vínculos de negócio, como o anexo com sua atividade, o cartão com sua coluna.

## Convenção de nomes dos campos

- Os nomes físicos ficam em português, em `snake_case`, sem acentos.
- PKs simples identificam a entidade: `id_atividade`, `id_anexo_atividade`, `id_quadro_kanban`, `id_professor`. As PKs compostas de Notas e visitas mantêm os campos que representam sua identidade real.
- FKs identificam o destino: por exemplo, `anexos_atividade.id_atividade` referencia `atividades.id_atividade`. Uma PK que também é FK mantém o nome da entidade de negócio.
- Vínculos com os catálogos usam `id_turma` e `id_disciplina`. Os nomes são obtidos na leitura. Texto livre e propostas ainda não cadastradas são identificados explicitamente como `turma_informada` e `nome_turma_solicitada`.
- Campos de atividades usam `tipo_atividade`, `data_atividade` e `hora_atividade`. A recorrência usa `data_inicio` e `data_fim`.
- Instantes usam o sufixo `_em`; contadores temporais em milissegundos mantêm `_em_ms`. As descrições informam unidade e significado.
- `referencia_...` identifica um valor externo do contrato, separado da PK física.

As views continuam expondo os aliases necessários ao contrato da API. Por exemplo, `visao_recibos_gravacao.id` vem de `recibos_gravacao.id_recibo_gravacao`. Essa compatibilidade evita alterar os sites e as automações junto com cada renomeação física.

## Catálogos compartilhados e FKs reais

A versão 048 substitui os nomes repetidos por vínculos com as entidades existentes:

| Tabelas | FK | Catálogo ou entidade de destino |
| --- | --- | --- |
| atividades, regras_recorrencia, sugestoes_atividade | id_disciplina | disciplinas.id_disciplina |
| atividades, regras_recorrencia, regras_retencao, sugestoes_atividade, sugestoes_melhoria, pedidos_representacao, perfis_administrativos, preferencias_resumo, turmas_agenda | id_turma | turmas.id_turma |
| atividades | id_regra_recorrencia | regras_recorrencia.id_regra_recorrencia |

Por exemplo, o horário de **2º Tec D** e uma atividade de **2° TECH D** compartilham o mesmo `id_turma`. A forma usada pela Agenda fica uma única vez em `turmas.referencia_agenda`. Para matérias, os rótulos de Notas já existentes são usados para localizar o cadastro correto; não se cria outra disciplina por uma diferença conhecida de exibição.

Os escritores SQL reutilizam o catálogo e rejeitam correspondências ambíguas. Nomes realmente novos, aceitos pelo fluxo autorizado da aplicação, podem ser cadastrados no catálogo compartilhado. Essas funções não substituem a autorização de usuários na API.

As duplicatas comprovadas de Língua Inglesa e Língua Portuguesa 2 são consolidadas, mantendo os IDs que têm notas e redirecionando os horários. Uma duplicata que também tenha lançamentos de notas em outro ID exige revisão: a normalização aborta em vez de descartar esse histórico.

`consultar_catalogo_agenda` filtra as atividades pelo ID de turma, com índices nas novas FKs. A revisão de cache inclui os catálogos, para que mudanças de nomes e referências também atualizem as respostas do Redis. Os nomes continuam sendo entregues à interface pela API.

### Onde texto continua correto

- `pedidos_agenda.nome_turma_solicitada` é uma proposta que pode ainda não ter correspondente aprovado.
- `perfis.turma_informada`, empresa, sala e andar são informações livres da pessoa, sem catálogo obrigatório.
- UIDs do Firebase Authentication não apontam para `perfis`: nem toda conta publica um perfil.
- Nome e e-mail de um participante do Kanban são informações de identificação do acesso, não uma FK para um perfil público opcional.
- Referências externas de cartões e quadros fazem parte do contrato do agregado do Kanban; não são nomes de disciplinas ou de turmas. A estrutura interna já tem FKs entre espaço, quadro, coluna, cartão e checklist.

A exclusão física de uma regra de recorrência também desvincula suas ocorrências, sem apagar as atividades. Excluir uma disciplina ou turma ainda referenciada é impedido pelo banco.

## Resumo semanal por e-mail

As preferências de turma e de recebimento ficam em `preferencias_resumo`. O controle temporário de entrega usa uma reserva por conta e semana no Redis. O serviço cria a reserva antes de tentar enviar o e-mail e atualiza seu estado depois. A reserva expira 28 dias após o início da semana resumida. [Chave e prazo de expiração]({{ '/redis.html#reservas-resumo-semanal' | relative_url }})

## Preparação e limpeza de uploads

A autorização de upload fica no Redis por meio de um registro pendente. É possível confirmar o arquivo durante uma hora. A confirmação grava `anexos_atividade` no PostgreSQL antes de remover a autorização. Envios abandonados mantêm a referência ao objeto até a limpeza do R2. A limpeza verifica se o objeto já está vinculado a uma atividade antes de apagar qualquer arquivo. [Chaves dos uploads pendentes]({{ '/redis.html#uploads-pendentes' | relative_url }})

## Limites de serviço

Recuperação de senha, anexos e fotos usam contadores no Redis com janela de uma hora. Uma gravação verifica a versão de todos os contadores antes de atualizar qualquer um. O prazo de expiração começa no primeiro uso da janela e permanece fixo. [Chaves dos limites de serviço]({{ '/redis.html#limites-de-servico' | relative_url }})

## Perfil do usuário

`perfis` é a tabela de dados do perfil, usada na edição e apresentação de nome, empresa, turma informada, sala, andar e foto. A PK `id_perfil` identifica a linha e `referencia_api` preserva o UID da conta esperado pela API. Os dados existentes e suas versões foram preservados na renomeação da versão 054. A senha permanece no Firebase Authentication. Preferências específicas, como receber o resumo semanal, continuam em suas tabelas próprias.

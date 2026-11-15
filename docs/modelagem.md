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

`registros_aplicacao.id` é um `bigint` gerado pelo banco. As tabelas de negócio usam `id_registro` para referenciá-lo. A API continua aceitando uma referência como `activities/ABC` para localizar uma atividade aberta por um link antigo. O banco separa o tipo `activities` e a referência `ABC` em colunas.

## Atividades e anexos

`atividades` guarda título, descrição, disciplina, turma, data e hora. Uma turma nula indica atividade geral. `anexos_atividade` guarda os metadados dos arquivos. A FK `id_atividade` aponta para `atividades.id_registro`, deixando explícito a qual atividade o anexo pertence. Não há coluna `ordem`: a API devolve os anexos em sequência estável pelo ID numérico.

`atividades.turma` usa a chave de turma da Agenda. `horarios_aula.id_turma` aponta para o identificador numérico do catálogo de aulas.

O expurgo diário usa a regra de retenção da turma. A API exclui os anexos do Cloudflare R2 e, após a confirmação, remove a atividade e seus metadados do PostgreSQL. Uma falha no R2 mantém a atividade para nova tentativa.

## Sugestões e conversas

`sugestoes_melhoria` registra o feedback autenticado. Cada linha de `mensagens_sugestao` se liga à sugestão por `registros_aplicacao.id_registro_pai`. A API limita a conversa ao autor da sugestão e aos administradores.

## Kanban

`espacos_kanban` identifica o proprietário e agrupa quadros pessoais ou compartilhados. Quadros, colunas, cartões e itens de checklist ficam em tabelas relacionadas. O vínculo entre cartão e coluna exige que os dois pertençam ao mesmo quadro. Participantes e pedidos de acesso ficam em tabelas próprias.

## Recibos de gravação: onde são usados

A tabela [recibos_gravacao]({{ '/postgresql.html#obj-recibos_gravacao' | relative_url }}) confirma lotes processados pela ação `commit` de `/api/data`. A API acessa a tabela pela [visao_recibos_gravacao]({{ '/views.html#view-visao_recibos_gravacao' | relative_url }}); essa view é uma projeção dos mesmos registros, sem outra cópia dos dados.

| Parte do sistema | Como usa o recibo |
| --- | --- |
| Criar e editar atividades | A fila da interface mantém o ID do lote ao tentar o envio novamente. Se a gravação já foi confirmada, a API reconhece o reenvio sem recriar a atividade ou repetir a edição. |
| Meu Kanban | As alterações enviadas pelo fluxo de documentos, como salvar cartões e reorganizar quadros, usam a mesma confirmação de lotes. Isso complementa o controle de versão que detecta edições concorrentes. |
| Sugestões e conversas | As gravações que passam pelo mesmo endpoint também recebem recibo, evitando repetir operações quando a resposta não chega ao navegador. |
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
| anexos_atividade | id_atividade | atividades.id_registro |
| quadros_kanban | id_espaco_kanban | espacos_kanban.id_registro |
| colunas_kanban | id_quadro_kanban | quadros_kanban.id |
| cartoes_kanban | id_quadro_kanban | quadros_kanban.id |
| itens_checklist | id_cartao_kanban | cartoes_kanban.id |
| registros_aplicacao | id_registro_pai | registros_aplicacao.id |

Em `cartoes_kanban`, `(id_quadro_kanban, referencia_coluna)` também referencia `(id_quadro_kanban, referencia)` de `colunas_kanban`, garantindo que a coluna pertença ao mesmo quadro.

Nas tabelas que usam `id_registro` como PK e FK, esse campo referencia `registros_aplicacao.id`: é a identidade compartilhada do registro, diferente dos vínculos com atividade, quadro ou cartão acima.

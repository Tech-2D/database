---
title: Tabelas e colunas
description: Consulte tabelas, colunas, chaves e relações do esquema tech2d.
wide: true
---

Todas as tabelas ficam no schema `tech2d`. As áreas desta página agrupam os recursos para consulta, sem separar fisicamente o banco. As tabelas usam colunas tipadas e chaves estrangeiras. Cada entidade guarda sua identidade numérica, referência externa, versão e data de atualização. A sequência `ids_entidades` gera os novos IDs. As views preparam o formato que a API entrega aos sites.

## Tabelas por área

{% assign tables = site.data.schema | where: "kind", "table" %}
<p class="catalog-overview"><strong>{{ tables.size }} tabelas</strong> no schema <code>tech2d</code> · <a href="{{ '/views.html' | relative_url }}">{{ site.data.views.size }} views</a> · <a href="{{ '/schemas.html' | relative_url }}">Organização por áreas</a></p>

Busque por tabela, coluna ou tipo, ou filtre por área. Cada card explica onde a tabela é usada no sistema; abaixo de cada campo está sua finalidade e por que ele é necessário.

<div class="catalog-controls" data-catalog-controls hidden>
  <label for="catalog-search"><span class="catalog-label-icon">{% include doc-icon.html name="search" %}Buscar no catálogo</span><input id="catalog-search" type="search" placeholder="Ex.: visitas, id_turma ou jsonb" autocomplete="off"></label>
  <label for="catalog-group">Área<select id="catalog-group"><option value="">Todas as áreas</option>{% for group in site.data.catalog %}<option value="{{ group.id }}">{{ group.name }}</option>{% endfor %}</select></label>
  <div class="catalog-actions">
    <button type="button" data-catalog-back hidden>Ver todas as tabelas</button>
    <p class="catalog-status" data-catalog-status role="status"></p>
  </div>
</div>

{% for group in site.data.catalog %}
<section class="catalog-group schema-card-group" data-catalog-group="{{ group.id }}" aria-labelledby="{{ group.id }}">
  <h3 id="{{ group.id }}">{{ group.name }}</h3>
  {% for item in group.objects %}
  {% assign object = site.data.schema | where: "name", item.name | first %}
  {% assign usage = site.data.table_usage[item.name] %}
  <article class="schema-card" id="obj-{{ item.name }}" data-catalog-object>
    <header class="schema-card-header">
      {% include doc-icon.html name="table" %}
      <div><h4>{{ item.name }}</h4><p>tech2d · {{ object.columns.size }} colunas</p></div>
      {% if object.foreign_key_count > 0 %}<span class="schema-tag schema-tag-fk" title="Total de chaves estrangeiras">{{ object.foreign_key_count }} FK</span>{% endif %}
    </header>
    <p class="schema-feature">{% include doc-icon.html name="layers" %}{{ usage.feature | escape }}</p>
    <p class="schema-card-description">{{ usage.description | default: object.comment | default: item.title | escape }}</p>
    <ul class="schema-columns" aria-label="Colunas de {{ item.name }}">
      {% for column in object.columns %}
      {% assign refs = object.references | where: "column", column.name %}
      <li class="schema-column">
        <span class="schema-column-name">{% if object.primary_key contains column.name %}<span class="column-key">{% include doc-icon.html name="key" %}</span>{% elsif refs.size > 0 %}<span class="column-link">{% include doc-icon.html name="link" %}</span>{% endif %}<code>{{ column.name }}</code></span>
        <span class="schema-column-properties">
          <code class="schema-column-type">{{ column.type | replace: "character varying", "varchar" | replace: "timestamp with time zone", "timestamptz" | escape }}</code>
          {% if object.primary_key contains column.name %}<span class="schema-tag schema-tag-pk" title="Chave primária">PK</span>{% endif %}
          {% if refs.size > 0 %}<span class="schema-tag schema-tag-fk" title="Chave estrangeira">FK</span>{% endif %}
          {% if column.unique %}<span class="schema-tag schema-tag-unique">UNIQUE</span>{% endif %}
          {% if column.check %}<span class="schema-tag schema-tag-check">CHECK</span>{% endif %}
          {% if column.generated %}<span class="schema-tag schema-tag-identity">IDENTITY</span>{% endif %}
          {% unless column.nullable %}<span class="schema-tag schema-tag-required">NOT NULL</span>{% endunless %}
        </span>
        {% assign note = site.data.column_notes[item.name][column.name] | default: column.comment %}
        <small class="schema-column-note">{{ note | escape }}</small>
      </li>
      {% endfor %}
    </ul>
  </article>
  {% endfor %}
</section>
{% endfor %}

<p id="obj-catalogo_horarios">A definição de <a href="{{ '/views.html' | relative_url }}#view-catalogo_horarios"><code>catalogo_horarios</code></a> fica na página de views.</p>

## Como os registros se ligam

Abra a [modelagem]({{ '/modelagem.html' | relative_url }}) para seguir os vínculos de horários, atividades e contas.

`atividades.data_atividade` usa `date` e `atividades.hora_atividade` usa `time`. O horário é opcional. Cada anexo fica em uma linha de `anexos_atividade`, com `id_atividade`, nome, tamanho e referência ao arquivo no R2. A sequência é dada pelo ID, sem uma coluna de ordem.

## Acesso ao banco

O Worker se conecta com o papel dedicado `tech2d_api`. O provisionamento da API concede as operações necessárias por tabela. A aplicação aplica as permissões por conta, papel e turma antes de ler ou gravar. Os arquivos de migração podem ser executados em um banco local sem criar esse papel.

Os catálogos públicos passam por projeções que selecionam os campos da resposta. Os arquivos da migração, as auditorias e os dados de moderação são acessados pelos fluxos administrativos correspondentes ou pela operação do banco.

## Migrações SQL

| Versão | O que cria ou altera |
| --- | --- |
| 001 | Esquema, arquivo de origem, atividades, perfis, catálogo e auditoria inicial |
| 002 | Documentos de aplicação, recibos, auditoria e estado de migração |
| 003 | Histórico das revisões da origem |
| 004 | Registro de visitas da Agenda |
| 005 | Últimos acessos autenticados e bloqueios da Agenda |
| 006 | Separação das visitas por site e últimos acessos do Cadê o professor |
| 007 | Tabelas relacionais de horários, chaves estrangeiras, migração dos registros existentes e view de leitura |
| 008 | Remoção dos campos já normalizados da projeção JSONB de horários, após a troca de leitura na API |
| 009 | Renomeia `agenda_access` para `site_visits` e padroniza o nome da chave primária |
| 010 | Documenta em português a função de cada tabela e da visão de horários |
| 011 | Renomeia `site_visits` e suas colunas para português |
| 012 | Renomeia `agenda_recent_users` e suas colunas para português |
| 013 | Renomeia as tabelas e colunas restantes e a visão de horários. Mantém as visões de compatibilidade da API |
| 014 | Define tamanhos de `varchar` nas 51 colunas de texto das tabelas operacionais |
| 015 | Cria as views de compatibilidade com prefixo `visao_` |
| 016 | Retira os nomes em inglês após a atualização dos serviços |
| 017 | Remove a cópia bruta do Firestore e sua view |
| 018 | Remove os controles de migração e registra a versão no comentário do schema |
| 019 | Instala a interface de gravação usada pela API durante a troca |
| 020 | Usa chaves numéricas e colunas tipadas. Separa anexos, votos, Kanban e dados históricos |
| 021 | Centraliza o catálogo e o arquivamento de atividades em funções e cria a view usada pelos jobs |
| 022 | Remove `campos_nulos` das tabelas e ajusta a serialização dos registros |
| 023 | Expõe a revisão restrita dos catálogos públicos para o cache Redis |
| 024 | Adiciona cadernos privados de notas da área de Notas |
| 025 | Remove a tabela e a view de revisões da migração para PostgreSQL |
| 026 | Adiciona o registro de acessos autenticados à área de Notas |
| 027 | Consolida os acessos recentes da Agenda e dos professores por site e conta |
| 028 | Unifica o arquivo de atividades, remove marcadores de listas e aposenta a auditoria antiga |
| 029–032 | Unifica os acessos dos três sites e faz a área de Notas reutilizar o catálogo geral de disciplinas |
| 033 | Retira enquetes, opções, votos, autorizações de eleitores e as funções exclusivas do recurso |
| 034 | Retira a tabela de anotações do antigo Caderno Infinito e o contrato notebookNotes da API |
| 035 | Retira a tabela de comunicados gerais após a mudança para Redis |
| 036 | Retira as tabelas de arquivo após a adoção do expurgo direto |
| 037 | Move o histórico público de atualizações para o Redis com prazo de 14 dias por publicação |
| 038 | Move os avisos das turmas para o Redis com prazo de sete dias por publicação |
| 039 | Disponibiliza as disciplinas do Notaki por turma |
| 040 | Retira os acessos recentes e limita os bloqueios da Agenda ao e-mail |
| 041 | Retira o histórico de auditoria e os valores anteriores das alterações |
| 042 | Move os bloqueios temporários da Agenda para o Redis, por UID da conta |
| 043 | Retira o chat dos representantes e suas mensagens |
| 044 | Move os convites de representantes para o Redis com prazo de sete dias |

Em um banco local vazio, siga os passos em [Consultas SQL]({{ '/consultas.html' | relative_url }}). O script de instalação aplica as migrações na ordem acima.

[Ver arquivos SQL](https://github.com/Tech-2D/database/tree/main/sql/migrations) · [Rodar em um banco local](https://github.com/Tech-2D/database#rodar-o-sql-localmente) · [Consultas de exemplo](https://github.com/Tech-2D/database/blob/main/sql/examples/consultas.sql)

A versão **045** padroniza os nomes da área de Notas: `notas_cadernos`, `notas_lancamentos`, `notas_recuperacoes`, `visao_disciplinas_notas` e `visao_notas_resultados`. O rename preserva dados, permissões, vínculos e RLS.

A versão **046** substitui as seis FKs chamadas `id_pai` por nomes explícitos de relacionamento e remove `ordem` de `anexos_atividade`. Funções SQL e a view de atividades usam os novos campos; os anexos são retornados por ID.

A versão **047** padroniza 54 nomes de colunas, incluindo as PKs simples com o nome da entidade, nomes textuais de turma e disciplina e datas das atividades. As funções SQL usam as novas colunas; as views preservam o contrato da API.

A versão **048** cria FKs de disciplinas em três tabelas e de turmas em nove tabelas, além dos vínculos de recorrência e upload. Os nomes repetidos são retirados; a leitura reconstrói os rótulos. O catálogo escolar guarda uma única referência externa da Agenda. Texto livre e propostas não aprovadas continuam explicitamente textuais.

A versão **049** transfere o controle de entregas do resumo semanal para o Redis e remove `entregas_resumo`. As preferências de recebimento permaneceram no SQL e, na versão 056, foram incorporadas a `perfis`.

A versão **050** remove `envios_anexos`. Uploads pendentes ficam no Redis e os anexos confirmados continuam em `anexos_atividade`.

A versão **051** remove `limites_servico`. Os contadores de recuperação de senha e upload de anexos e fotos ficam no Redis com expiração automática.

## Identidade nas próprias entidades

A versão `052_identidade_nas_entidades` removeu a tabela central de identidades. As 17 entidades mantêm os IDs existentes e passam a guardar sua própria versão e referência. As views e funções SQL continuam entregando o contrato da API, preservando os links e a detecção de conflitos. A conferência da troca preservou 1.561 documentos e o resultado de cinco views.

## Retirada da conversa de melhorias

Na versão `053_retirar_conversas_sugestoes`, a tabela de mensagens privadas e suas rotas foram removidas. A tabela `sugestoes_melhoria` continua guardando os pedidos, o andamento e a autorização para crédito público.

## Solicitações temporárias no Redis

A versão `055_pedidos_temporarios_redis` removeu as tabelas de sugestões de atividades e pedidos de Agenda. Esses dois fluxos usam Redis com TTL fixo de 7 dias. Na versão 055, a estrutura SQL passou a ter 29 tabelas; a aprovação de uma turma continua sendo persistida em `turmas_agenda`.

## Preferências do resumo no perfil

A versão `056_resumo_no_perfil` incorporou as inscrições do resumo semanal à tabela `perfis` e removeu `preferencias_resumo`. A estrutura passou a ter 28 tabelas nessa versão. As projeções da API continuam separando a apresentação pública da inscrição privada; os perfis e as preferências existentes foram preservados.

## Fila de anexos do Kanban no Redis

A versão `057_limpeza_kanban_redis_list` removeu `limpeza_anexos_kanban` e deixou o PostgreSQL com 27 tabelas. As pendências usam duas Lists do Redis sem TTL. A rotina diária verifica o recibo da operação no PostgreSQL e se o cartão ainda está ausente antes de apagar arquivos no R2. A fila depende da persistência do serviço Redis para sobreviver a uma perda dos dados do servidor.

## Solicitações de acesso no Kanban

A versão `058_pedidos_kanban_redis` removeu a tabela `pedidos_kanban`. O PostgreSQL passou a ter 26 tabelas. Os pedidos ficam no Redis por sete dias após o envio ou a última mudança de estado. O vínculo que concede acesso fica em `participantes_kanban` e continua válido até ser removido. A API só mostra a aprovação no Redis após a confirmação do recibo SQL. A remoção de acesso funciona mesmo quando o pedido já expirou.

## Pedidos de representação e recorrências

A versão `060_pedidos_representacao_redis` moveu os pedidos de representação para o Redis com TTL de sete dias. O PostgreSQL passou a ter 25 tabelas. A versão `061_simplificar_recorrencias` removeu os campos `excluida` e `email_criador` das regras. Uma série encerrada é removida após a limpeza das próximas ocorrências, e as atividades antigas permanecem.

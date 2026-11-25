---
title: Redis
description: Chaves, prazos de expiração e pontos da aplicação que usam Redis.
wide: true
database: redis
---

<section class="redis-guide" aria-labelledby="como-redis-funciona">
  <div>
    <h2 id="como-redis-funciona">{% include doc-icon.html name="cache" %}Onde o Redis entra</h2>
    <p>O Redis guarda cópias rápidas de consultas, conteúdo com prazo de validade e filas de trabalho. O PostgreSQL mantém os dados permanentes, como atividades, horários, perfis e permissões aprovadas. O TTL é o tempo que falta para uma chave ser apagada automaticamente.</p>
  </div>
  <dl>
    <div><dt>Cache de consultas</dt><dd>60 segundos a 5 minutos</dd></div>
    <div><dt>Comunicados e avisos</dt><dd>7 dias</dd></div>
    <div><dt>Sugestões e pedidos de Agenda</dt><dd>7 dias</dd></div>
    <div><dt>Atualizações da Agenda</dt><dd>14 dias</dd></div>
    <div><dt>Bloqueios de conta</dt><dd>Prazo configurável</dd></div>
    <div><dt>Período de recuperação</dt><dd>Até o fim da publicação</dd></div>
  </dl>
</section>

## Como ler este catálogo

| Conceito | O que significa na aplicação |
| --- | --- |
| **String** | Um valor único, como um aviso em JSON, uma assinatura de requisição ou um token de processamento. |
| **Índice ZSET** | Um conjunto ordenado de IDs ou referências. Ajuda a encontrar registros por turma, data ou solicitante. O conteúdo de cada item fica em outro registro. |
| **Hash** | Vários registros dentro de uma chave. Nos uploads, cada campo identifica um arquivo ainda pendente. |
| **List** | Uma fila de trabalho. Na limpeza do Kanban, guarda os arquivos que ainda precisam ser removidos do R2. |
| **Recibo** | Reconhece uma requisição já concluída. Se houver reenvio por falha de rede, evita publicar ou contar a mesma operação duas vezes. |

**Expiração do conteúdo:** avisos e pedidos não possuem uma cópia permanente no PostgreSQL. Ao vencerem, deixam de estar disponíveis. O vencimento de um convite não remove a permissão de um representante que já ativou sua conta.

**Expiração do cache:** apenas a cópia da consulta é removida. A próxima consulta recompõe a resposta a partir do PostgreSQL.

**Índices e filas** podem ter prazos diferentes dos itens que referenciam. Os registros de uploads e as filas de limpeza do Kanban ficam sem TTL para que o serviço possa limpar arquivos pendentes no R2 mesmo após uma interrupção.

<section class="redis-inventory" id="catalogo-redis" aria-labelledby="chaves">
  <div class="redis-inventory-heading">
    <h2 id="chaves">{% include doc-icon.html name="key" %}Chaves do Redis</h2>
    <div data-catalog-controls hidden><p class="catalog-status" data-catalog-status role="status"></p></div>
  </div>
  <div class="redis-key-guide">
    <dl class="redis-key-examples">
      <div><dt>Padrão de nome</dt><dd><code>tech2d:{grupo}:finalidade:&lt;identificador&gt;</code></dd></div>
      <div><dt>Exemplo de aviso</dt><dd><code>tech2d:{avisos}:item:AVISO_EXEMPLO</code></dd></div>
    </dl>
    <dl class="redis-key-parts">
      <div><dt><code>tech2d</code> e <code>finalidade</code></dt><dd>Indicam o sistema e o uso da chave. Os nomes fixos usam português sem acentos e <code>:</code> separa as partes.</dd></div>
      <div><dt><code>{grupo}</code></dt><dd>Um nome fixo como <code>{avisos}</code> mantém juntas as chaves usadas na mesma operação Redis.</dd></div>
      <div><dt><code>&lt;identificador&gt;</code></dt><dd>Quando aparece no padrão, substitua pelo valor indicado. Pode ser uma turma, um hash usado na busca, um UID do Firebase, um ID de operação ou uma revisão do cache.</dd></div>
    </dl>
  </div>

  {% for group in site.data.redis_catalog %}
  <section class="redis-group" id="{{ group.id }}" data-catalog-group="{{ group.id }}" aria-labelledby="{{ group.id }}-titulo">
    <header class="redis-group-heading">
      <h3 id="{{ group.id }}-titulo">{% include doc-icon.html name=group.icon %}{{ group.title }}</h3>
      <p>{{ group.description | escape }}</p>
    </header>
    <div class="redis-key-list">
      {% for item in group.entries %}
      <article class="redis-key" id="{{ item.id }}" data-catalog-object data-ttl-seconds="{{ item.ttl_seconds }}" aria-labelledby="{{ item.id }}-titulo">
        <div class="redis-key-heading">
          <h4 id="{{ item.id }}-titulo">{{ item.name | escape }}</h4>
          <span class="redis-ttl" title="{{ item.expiry | escape }}"><span>TTL</span> {{ item.ttl }}</span>
        </div>
        <p class="redis-key-path"><code>{{ item.key | escape }}</code></p>
        <p>{{ item.description | escape }}</p>
        <dl class="redis-key-details">
          <div><dt>Estrutura</dt><dd>{{ item.type }}</dd></div>
          <div><dt>Quando é removida</dt><dd>{{ item.expiry | escape }}</dd></div>
          <div><dt>Onde a API usa</dt><dd><code>{{ item.route | escape }}</code></dd></div>
        </dl>
      </article>
      {% endfor %}
    </div>
    <p class="redis-source"><a href="https://github.com/Tech-2D/api/blob/main/src/{{ group.source }}">Ver {{ group.source }} na API</a> · Requer acesso ao repositório no GitHub</p>
  </section>
  {% endfor %}
</section>

<h2 id="operacao">Comportamento da API</h2>

<dl class="redis-operations">
  <div>
    <dt>Quando os dados mudam</dt>
    <dd>A API calcula a revisão do catálogo no PostgreSQL antes de ler o cache. Uma alteração muda a revisão e direciona a consulta para outra chave. A cópia da revisão anterior expira pelo TTL.</dd>
  </div>
  <div>
    <dt>Quando o Redis fica indisponível</dt>
    <dd>Se a falha ocorrer na etapa de cache, a API carrega atividades e horários do PostgreSQL. Nas respostas de calendário e atualizações, a API devolve uma lista vazia de atualizações ou um comunicado nulo se a leitura desses dados falhar. O quadro de avisos e as consultas de pedidos podem ficar indisponíveis. Em rotas com moderação ativa, a API precisa confirmar a situação do bloqueio antes de liberar o acesso.</dd>
  </div>
  <div>
    <dt>Como diagnosticar o cache</dt>
    <dd>Confira o cabeçalho <code>X-Catalog-Cache</code> nas rotas de cache. Ele informa o estado da cópia dos dados SQL. A comunicação do Worker com o Redis tem limite de 700 ms por chamada, incluindo a autenticação no Redis.</dd>
    <dd><ul class="redis-cache-states">
      <li><code>HIT</code> Resposta servida do cache.</li>
      <li><code>MISS</code> Resposta gerada pelo PostgreSQL após não encontrar uma cópia utilizável.</li>
      <li><code>BYPASS</code> Cache desativado ou conexão sem configuração.</li>
      <li><code>UNAVAILABLE</code> Falha na revisão do catálogo ou no acesso ao Redis.</li>
    </ul></dd>
  </div>
  <div>
    <dt>Quem acessa as chaves</dt>
    <dd>O navegador usa a sessão do Firebase Authentication para consultar a API. Serviços como anexos e resumo semanal usam a rota interna da API com credenciais próprias. O Worker acessa o Redis e aplica as regras de autorização de cada rota.</dd>
  </div>
</dl>

<p class="redis-source"><a href="https://redis.io/docs/latest/commands/expire/">Expiração no Redis</a> · <a href="https://redis.io/docs/latest/commands/set/">Gravação com prazo e preservação do TTL</a></p>

---
title: Redis
description: Chaves, prazos de expiração e pontos da aplicação que usam Redis.
wide: true
database: redis
---

<section class="redis-guide" aria-labelledby="como-redis-funciona">
  <div>
    <h2 id="como-redis-funciona">{% include doc-icon.html name="cache" %}Onde o Redis entra</h2>
    <p>A API usa Redis para acelerar o calendário e os horários e para guardar publicações com prazo de validade. O TTL informa por quanto tempo uma chave existe. Ao fim do prazo, o Redis a remove.</p>
  </div>
  <dl>
    <div><dt>Cache de consultas</dt><dd>60 segundos a 5 minutos</dd></div>
    <div><dt>Comunicados e avisos</dt><dd>7 dias</dd></div>
    <div><dt>Sugestões e pedidos de Agenda</dt><dd>7 dias</dd></div>
    <div><dt>Atualizações da Agenda</dt><dd>14 dias</dd></div>
    <div><dt>Bloqueios de conta</dt><dd>Prazo configurável</dd></div>
  </dl>
</section>

<section class="redis-inventory" id="catalogo-redis" aria-labelledby="chaves">
  <div class="redis-inventory-heading">
    <h2 id="chaves">{% include doc-icon.html name="key" %}Chaves do Redis</h2>
    <div data-catalog-controls hidden><p class="catalog-status" data-catalog-status role="status"></p></div>
  </div>
  <p>Os nomes abaixo são padrões. Nas chaves <code>tech2d:sql:public:v2</code>, <code>{revisao}</code> é o valor calculado no PostgreSQL e <code>{hash_filtros}</code> é o SHA-256 dos filtros da consulta. Nos outros grupos, <code>{announcement}</code>, <code>{agenda-updates}</code> e <code>{board-notices}</code> são partes literais da chave.</p>

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
          <div><dt>Tipo</dt><dd>{{ item.type }}</dd></div>
          <div><dt>Expiração</dt><dd>{{ item.expiry | escape }}</dd></div>
          <div><dt>Rotas</dt><dd><code>{{ item.route | escape }}</code></dd></div>
        </dl>
      </article>
      {% endfor %}
    </div>
    <p class="redis-source"><a href="https://github.com/Tech-2D/api/blob/main/src/{{ group.source }}">Ver {{ group.source }} na API</a></p>
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
    <dd>A API busca atividades, turmas e horários no PostgreSQL. O calendário abre sem o comunicado geral e sem as publicações de atualização enquanto o Redis estiver indisponível. O quadro de avisos indica falha na consulta. Gravações de comunicados, atualizações e avisos retornam erro. Consultas e gravações de sugestões de atividades e pedidos de Agenda também retornam indisponibilidade, sem recorrer a uma cópia SQL. A Agenda também retorna indisponibilidade nas rotas protegidas quando a validação de bloqueio falha.</dd>
  </div>
  <div>
    <dt>Como diagnosticar o cache</dt>
    <dd>Confira o header <code>X-Catalog-Cache</code> nas rotas de cache. O Worker limita cada operação Redis a 700 ms.</dd>
    <dd><ul class="redis-cache-states">
      <li><code>HIT</code> Resposta servida do cache.</li>
      <li><code>MISS</code> Resposta gerada pelo PostgreSQL.</li>
      <li><code>BYPASS</code> Cache desativado ou conexão sem configuração.</li>
      <li><code>UNAVAILABLE</code> Falha na revisão do catálogo ou no acesso ao Redis.</li>
    </ul></dd>
  </div>
  <div>
    <dt>Quem acessa as chaves</dt>
    <dd>O navegador consulta a API com a sessão do Firebase Authentication. O Worker usa as credenciais do Redis guardadas nos secrets e verifica permissões no PostgreSQL antes de gravar.</dd>
  </div>
</dl>

<p class="redis-source"><a href="https://redis.io/docs/latest/commands/expire/">Expiração no Redis</a> · <a href="https://redis.io/docs/latest/commands/set/">Gravação com prazo e preservação do TTL</a></p>

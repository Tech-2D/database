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
  </dl>
</section>

## Como ler este catálogo

| Conceito | O que significa na aplicação |
| --- | --- |
| **String (JSON)** | Um registro completo, como um aviso ou pedido. JSON aqui é o formato do valor no Redis. |
| **Índice ZSET** | Uma lista ordenada de IDs ou referências. Ajuda a encontrar registros por turma, data ou solicitante; não substitui o conteúdo de cada item. |
| **Hash** | Vários registros dentro de uma chave. Nos uploads, cada campo identifica um arquivo ainda pendente. |
| **List** | Uma fila de trabalho. Na limpeza do Kanban, guarda os arquivos que ainda precisam ser removidos do R2. |
| **Recibo** | Reconhece uma requisição já concluída. Se houver reenvio por falha de rede, evita publicar ou contar a mesma operação duas vezes. |

**Expiração do conteúdo:** avisos e pedidos não possuem uma cópia permanente no PostgreSQL. Ao vencerem, deixam de estar disponíveis. O vencimento de um convite não remove a permissão de um representante que já ativou sua conta.

**Expiração do cache:** apenas a cópia da consulta é removida. A próxima consulta recompõe a resposta a partir do PostgreSQL.

**Índices e filas:** o índice pode durar até a expiração do último item, enquanto cada conteúdo mantém seu próprio prazo. Filas de limpeza ficam sem TTL para que uma falha temporária no R2 não deixe arquivos esquecidos.

<section class="redis-inventory" id="catalogo-redis" aria-labelledby="chaves">
  <div class="redis-inventory-heading">
    <h2 id="chaves">{% include doc-icon.html name="key" %}Chaves do Redis</h2>
    <div data-catalog-controls hidden><p class="catalog-status" data-catalog-status role="status"></p></div>
  </div>
  <p>O padrão é <code>tech2d:{grupo}:finalidade:&lt;identificador&gt;</code>. Os nomes fixos estão em português, sem acentos e separados por <code>:</code>. Por exemplo: <code>tech2d:{avisos}:item:AVISO_EXEMPLO</code>.</p>
  <p>As chaves de agrupamento, como <code>{avisos}</code>, são literais: identificam o grupo e mantêm juntas as chaves usadas na mesma operação Redis. Já os trechos entre <code>&lt;...&gt;</code> devem ser substituídos pelo ID, turma ou hash indicado. O hash é uma assinatura determinística usada para localizar o registro; não é uma senha nem uma autorização de acesso. O UID vem do Firebase Authentication. IDs de operação identificam tentativas de gravação; a revisão identifica a versão dos dados que gerou o cache.</p>

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
    <dd>Se a falha for no cache, a API consulta atividades e horários no PostgreSQL. Recursos que existem apenas no Redis, como avisos e pedidos, podem ficar indisponíveis — expiração e falha de conexão são situações diferentes. Operações protegidas que dependem da checagem de bloqueio não são liberadas sem essa verificação. A API não cria uma cópia SQL silenciosa desses dados temporários.</dd>
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

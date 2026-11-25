---
title: Modelagem de dados
description: Como a Agenda e o Cadê o professor armazenam, consultam e protegem seus dados.
permalink: /
---

<div class="system-flow" aria-label="Caminho de uma consulta">
  <span><strong>Agenda e Cadê o professor</strong><small>Sites</small></span>
  <span class="flow-arrow" aria-hidden="true">→</span>
  <span><strong>Cloudflare Workers</strong><small>API compartilhada</small></span>
  <span class="flow-arrow" aria-hidden="true">→</span>
  <span><strong>PostgreSQL</strong><small>Neon, via Hyperdrive</small></span>
</div>

{% assign table_count = site.data.schema | where: "kind", "table" | size %}
{% assign functions = site.data.routines | where: "procedure", false %}
{% assign procedures = site.data.routines | where: "procedure", true %}
<div class="workspace-stats" aria-label="Inventário PostgreSQL">
  <a href="{{ '/postgresql.html' | relative_url }}"><strong>{{ table_count }}</strong><span>{% include doc-icon.html name="table" %}Tabelas</span></a>
  <a href="{{ '/views.html' | relative_url }}"><strong>{{ site.data.views.size }}</strong><span>{% include doc-icon.html name="eye" %}Views</span></a>
  <a href="{{ '/funcoes.html' | relative_url }}"><strong>{{ functions.size }}</strong><span>{% include doc-icon.html name="code" %}Funções</span></a>
  <a href="{{ '/procedures.html' | relative_url }}"><strong>{{ procedures.size }}</strong><span>{% include doc-icon.html name="diagram" %}Procedures</span></a>
</div>

## Encontre o que você precisa

<div class="doc-links">
  <a href="{{ '/postgresql.html' | relative_url }}"><strong>Explorar tabelas e colunas</strong><span>Busque pelo nome de uma tabela ou coluna e confira tipos, chaves e finalidade.</span></a>
  <a href="{{ '/schemas.html' | relative_url }}"><strong>Localizar tabelas por área</strong><span>Encontre os dados de cada recurso e veja as simplificações aplicadas ao banco.</span></a>
  <a href="{{ '/views.html' | relative_url }}"><strong>Consultar as views da API</strong><span>Veja a origem dos dados e os nomes dos campos usados pela API.</span></a>
  <a href="{{ '/modelagem.html' | relative_url }}"><strong>Entender a modelagem</strong><span>Busque por tabelas e colunas, veja quem usa cada tabela e percorra as chaves estrangeiras.</span></a>
  <a href="{{ '/consultas.html' | relative_url }}"><strong>Consultar exemplos SQL</strong><span>Copie consultas de atividades, horários e totais de visitas para usar em um banco local.</span></a>
  <a href="{{ '/redis.html' | relative_url }}"><strong>Consultar o Redis</strong><span>Veja as chaves, os prazos e a integração do cache com o PostgreSQL.</span></a>
</div>

## Serviços e dados

<div class="service-directory">
  <ul class="service-grid" aria-label="Serviços em uso">
    <li class="service-item">
      <span class="service-item-icon">{% include doc-icon.html name="database" %}</span>
      <div>
        <span class="service-role">Banco principal</span>
        <h3>PostgreSQL</h3>
        <p>Guarda atividades, horários, permissões e estatísticas.</p>
      </div>
    </li>
    <li class="service-item">
      <span class="service-item-icon">{% include doc-icon.html name="cache" %}</span>
      <div>
        <span class="service-role">Cache e dados temporários</span>
        <h3>Redis</h3>
        <p>Acelera a leitura dos catálogos. Comunicados e avisos ficam por <strong>7 dias</strong> e atualizações da Agenda por <strong>14 dias</strong>.</p>
      </div>
    </li>
    <li class="service-item">
      <span class="service-item-icon">{% include doc-icon.html name="key" %}</span>
      <div>
        <span class="service-role">Login</span>
        <h3>Firebase Authentication</h3>
        <p>Identifica a conta. A API valida a sessão e aplica as permissões.</p>
      </div>
    </li>
    <li class="service-item">
      <span class="service-item-icon">{% include doc-icon.html name="layers" %}</span>
      <div>
        <span class="service-role">Armazenamento de arquivos</span>
        <h3>Cloudflare R2</h3>
        <p>Guarda os anexos. A API verifica quem pode acessar cada arquivo.</p>
      </div>
    </li>
  </ul>
  <div class="service-footer">
    <p><strong>Histórico da migração.</strong> O Firestore foi a origem dos dados migrados para o PostgreSQL.</p>
    <a class="service-code" href="https://github.com/Tech-2D/api">{% include doc-icon.html name="code" %} Código da API compartilhada {% include doc-icon.html name="arrow" %}</a>
  </div>
</div>

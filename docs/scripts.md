---
title: Scripts de instalação
description: Instale a estrutura atual ou consulte o código SQL de cada objeto.
---

A referência atual é **{{ site.data.sql_inventory.version }}**, extraída do PostgreSQL **{{ site.data.sql_inventory.serverVersion }}**. Os arquivos preservam as dependências e as permissões do banco; contêm apenas definições, sem registros de pessoas nem credenciais.

## Estrutura atual

| Objeto | Quantidade | Código SQL |
| --- | --- | --- |
| Tabelas | {{ site.data.sql_inventory.counts.TABLE }} | [CREATE TABLE por tabela](https://github.com/Tech-2D/database/tree/main/sql/atual/tabelas) |
| Views | {{ site.data.sql_inventory.counts.VIEW }} | [CREATE VIEW por view](https://github.com/Tech-2D/database/tree/main/sql/atual/views) |
| Funções | {{ site.data.sql_inventory.counts.FUNCTION }} | [Código completo das funções](https://github.com/Tech-2D/database/tree/main/sql/atual/funcoes) |
| Procedures | {{ site.data.sql_inventory.counts.PROCEDURE }} | {% if site.data.sql_inventory.counts.PROCEDURE > 0 %}[Código das procedures](https://github.com/Tech-2D/database/tree/main/sql/atual/procedures){% else %}Não existem na versão atual. Consulte a página de [procedures]({{ "/procedures.html" | relative_url }}).{% endif %} |
| Sequências | {{ site.data.sql_inventory.counts.SEQUENCE }} | [Geração de IDs](https://github.com/Tech-2D/database/tree/main/sql/atual/sequencias) |
| Trigger | {{ site.data.sql_inventory.counts.TRIGGER }} | [Gatilhos](https://github.com/Tech-2D/database/tree/main/sql/atual/gatilhos) |
| Políticas RLS | {{ site.data.sql_inventory.counts.POLICY }} | [Políticas](https://github.com/Tech-2D/database/tree/main/sql/atual/politicas) · [Ativação de RLS](https://github.com/Tech-2D/database/tree/main/sql/atual/seguranca) |
| Índices e relações | — | [Índices](https://github.com/Tech-2D/database/tree/main/sql/atual/indices) · [PK, FK e restrições](https://github.com/Tech-2D/database/tree/main/sql/atual/restricoes) |
| Permissões e comentários | — | [GRANT e REVOKE](https://github.com/Tech-2D/database/blob/main/sql/atual/permissoes.sql) · [Comentários](https://github.com/Tech-2D/database/blob/main/sql/atual/comentarios.sql) |

[Ver o SQL consolidado](https://github.com/Tech-2D/database/blob/main/sql/atual/estrutura.sql) · [Consultar o inventário de objetos](https://github.com/Tech-2D/database/blob/main/sql/atual/catalogo.json)

Cada tabela, função e view do catálogo tem um link para seu código. Os arquivos individuais ajudam a estudar a definição; a instalação completa usa a ordem do consolidado.

## Instalar em um banco local vazio

Use PostgreSQL 18 ou superior e uma conta local com permissão de criar bancos e papéis. Na raiz do clone:

```sh
createdb tech2d_local
psql -X -d tech2d_local -v ON_ERROR_STOP=1 --single-transaction -f sql/instalar.psql
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -f sql/examples/consultas.sql
```

O instalador recusa um schema `tech2d` existente. Cria os papéis de referência sem login ou senha e não insere dados de negócio. Não deve ser executado sobre produção. As funções SECURITY DEFINER ficam sob a propriedade da conta que instala o snapshot; o provisionamento seguro de produção continua sob responsabilidade da API.

Os arquivos em `sql/migrations/` descrevem as mudanças passadas, incluindo objetos depois removidos. Para consultar o que existe hoje, use `sql/atual/`. Para atualizar uma instalação existente, siga o executor de migrações da API, com as etapas de publicação e transferência de dados pertinentes.

## Validação

O snapshot e as 61 migrações foram instalados em bancos vazios PostgreSQL 18.6 e produziram estruturas equivalentes. Também foram conferidos os exemplos SQL, a consulta do catálogo com o papel limitado da API, a reexecução do histórico e a recusa de reinstalação sobre schema existente.

Para repetir a conferência, configure `PGHOST`, `PGPORT` e `PGUSER` de um servidor PostgreSQL local:

```sh
npm ci
npm run check
npm run check:sql
```

O teste SQL aceita somente um host local explícito, cria três bancos temporários e remove os bancos que criou ao terminar. Veja os detalhes no [guia dos scripts](https://github.com/Tech-2D/database/blob/main/sql/README.md).

## Atualizar os códigos

O script [export-sql.mjs](https://github.com/Tech-2D/database/blob/main/scripts/export-sql.mjs) usa `pg_dump --schema-only` para regenerar o consolidado e os arquivos por objeto. A conexão deve vir de variáveis ou arquivo seguro ignorado pelo Git. Use um `pg_dump` da versão principal do servidor ou mais recente. O script também aceita um dump DDL existente com `--from`.

Redis tem [uma seção própria]({{ '/redis.html' | relative_url }}) para chaves, TTL e uso na aplicação; seus valores e credenciais não fazem parte dos scripts SQL.

# Modelagem de dados da Tech-2D

Documentação e scripts do PostgreSQL e do Redis usados pela Agenda e pelo Cadê o professor. [Abrir documentação](https://tech-2d.github.io/database/).

A estrutura consolidada corresponde à versão **078_classificar_provas_recuperacao**, conferida no catálogo do Neon. O schema `tech2d` tem **39 tabelas, 19 views, 52 funções e 0 procedures**. O inventário inclui sequências, índices, restrições, gatilho, políticas RLS, comentários e permissões. O SQL consolidado contém apenas as definições.

| Conteúdo | Onde encontrar |
| --- | --- |
| Instalação completa em banco vazio | [sql/instalar.psql](sql/instalar.psql) |
| Estrutura atual, em ordem de criação | [sql/atual/estrutura.sql](sql/atual/estrutura.sql) |
| CREATE TABLE por tabela | [sql/atual/tabelas](sql/atual/tabelas/) |
| Código das views | [sql/atual/views](sql/atual/views/) |
| Código das funções | [sql/atual/funcoes](sql/atual/funcoes/) |
| Índices, relações, políticas e demais objetos | [Inventário completo](sql/atual/catalogo.json) |
| Permissões e comentários | [Permissões](sql/atual/permissoes.sql) · [Comentários](sql/atual/comentarios.sql) |
| Histórico de alterações da API | [sql/migrations](sql/migrations/) · [executor](sql/migrate.psql) |
| Instruções dos scripts e validação | [Guia SQL](sql/README.md) |
| Tabelas, campos e finalidade no sistema | [Catálogo PostgreSQL](docs/postgresql.md) |
| Chaves Redis, TTL e funcionamento | [Redis](docs/redis.md) |
| Consultas de exemplo | [sql/examples/consultas.sql](sql/examples/consultas.sql) |

## Instalar a estrutura atual localmente

Use PostgreSQL **18 ou superior**, com `createdb` e `psql` no PATH. Execute na raiz do clone, com uma conta local que possa criar bancos e papéis:

```sh
createdb tech2d_local
psql -X -d tech2d_local -v ON_ERROR_STOP=1 --single-transaction -f sql/instalar.psql
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -f sql/examples/consultas.sql
```

A instalação é destinada a um banco local vazio e exige um schema `tech2d` inexistente. Ela cria os papéis referenciados nos GRANT sem login nem senha e inicializa a configuração com a Agenda aberta. As tabelas de dados de negócio começam vazias.

Os arquivos individuais servem para consultar o código. Eles possuem dependências entre si; não execute as pastas em ordem alfabética. O arquivo `estrutura.sql` preserva a ordem correta do `pg_dump`. Para atualizar um banco existente, use as migrações da [API](https://github.com/Tech-2D/api), conforme as instruções de cada alteração.

## Conferir os scripts

```sh
npm ci
npm run check
```

Com um servidor PostgreSQL 18 **local** disponível, configure `PGHOST`, `PGPORT` e `PGUSER`, e execute:

```sh
npm run check:sql
```

O teste exige `PGHOST=127.0.0.1`, `localhost` ou `::1`. Cria três bancos temporários, instala o snapshot e o histórico completo, compara os objetos, executa consultas e verifica permissões e reexecução. Ao terminar, remove apenas os bancos de teste criados por ele. Se os binários não estiverem no PATH, configure `PG_BIN` com a pasta `bin` do PostgreSQL.

O snapshot da versão 078 passou nessa validação no PostgreSQL 18.6. Os metadados foram conferidos contra o Neon PostgreSQL 18.7.

## Manter estrutura e documentação sincronizadas

A [API](https://github.com/Tech-2D/api) continua sendo a fonte das migrações. As cargas de dados operacionais ficam na API. A referência pública contém a estrutura SQL. Após uma alteração:

1. Atualize `sql/migrations/` e o executor `sql/migrate.psql`, preservando a ordem numérica e a versão no comentário do schema.
2. Exporte a estrutura do banco já atualizado usando `pg_dump` da mesma versão principal do servidor ou mais recente. Configure a conexão apenas em arquivo seguro ignorado pelo Git ou variáveis de ambiente.
3. Regenere os inventários, atualize as explicações e execute os checks.

```sh
# DATABASE_URL e PG_CA_FILE vêm do ambiente/arquivo seguro; não copie senhas para o repositório.
node --env-file=/caminho/seguro/conexao.env scripts/export-sql.mjs

# Ou reorganize um dump DDL já obtido:
node scripts/export-sql.mjs --from /caminho/seguro/estrutura.sql

# Após instalar a referência local, regenere os inventários visuais:
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -At -f sql/catalog.psql -o docs/_data/schema.json
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -At -f sql/routines.psql -o docs/_data/routines.json
npm run check
npm run check:sql
```

`PG_DUMP` permite informar o caminho do executável. Para conexões remotas, o exportador usa TLS com validação completa por padrão e aceita `PG_CA_FILE` para o certificado CA. Ele não imprime detalhes privados quando a conexão falha. Revise o diff antes de publicar qualquer exportação.

`docs/_data/catalog.yml`, `table_usage.json` e `column_notes.json` explicam a área do sistema e cada campo. `views.json` documenta a origem e as colunas das views. `sql_inventory.json` é gerado pelo exportador e mantém as contagens de SQL mostradas no site. Os scripts em `sql/migrations/` descrevem estados históricos; os objetos atuais ficam em `sql/atual/`.

## Site da documentação

O GitHub Pages publica a pasta `docs/`. O site usa Tailwind CSS 4 e foi inspirado na organização do [Astro Database Workspace](https://github.com/Astro-Inter/astro-database). Depois de alterar classes ou estilos, gere e inclua o CSS:

```sh
npm run build:css
```

Redis está documentado separadamente, com chaves e TTL. Ele não é instalado pelo DDL do PostgreSQL e não há credenciais nem cópia dos seus valores neste repositório.

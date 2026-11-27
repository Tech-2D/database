# Scripts PostgreSQL

## Qual arquivo usar

- **Banco local novo:** `instalar.psql` prepara os papéis locais sem login e executa `atual/estrutura.sql` dentro da transação fornecida pelo comando `psql --single-transaction`.
- **Ler o código de um objeto:** procure em `atual/tabelas`, `atual/views` ou `atual/funcoes`. As demais pastas contêm sequências, índices, restrições, trigger e políticas. `atual/catalogo.json` relaciona cada objeto ao arquivo correspondente.
- **Consultar dados:** `examples/consultas.sql` contém consultas de leitura sobre a estrutura atual.
- **Entender uma alteração passada:** `migrations/` e `migrate.psql` preservam o histórico. Uma migração pode citar objetos antigos removidos depois; isso não significa que eles ainda existam no banco atual.

O snapshot atual é `078_classificar_provas_recuperacao`, gerado no PostgreSQL 18.6 e conferido contra o catálogo do Neon 18.7. Há 39 tabelas, 19 views, 52 funções, 14 sequências, um gatilho e seis políticas RLS. O inventário registra zero procedures.

`estrutura.sql` contém definições completas, comentários e GRANT/REVOKE, na ordem das dependências. Os arquivos individuais são referências para leitura: comentários ficam em `comentarios.sql`, permissões em `permissoes.sql`, e PK/FK/UNIQUE em `restricoes/`. Não substitua a instalação completa por executar arquivos isolados.

## Instalação em banco vazio

Com PostgreSQL 18+ e uma conta local com CREATEROLE:

```sh
createdb tech2d_local
psql -X -d tech2d_local -v ON_ERROR_STOP=1 --single-transaction -f sql/instalar.psql
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -f sql/examples/consultas.sql
```

O instalador recusa um schema `tech2d` já existente. Ele cria apenas os papéis de referência declarados em `papeis-locais.sql`, sem login ou senha, e inicializa o registro que mantém a Agenda aberta. `permissoes-provisionadas.sql` reproduz no histórico local os acessos de serviço conferidos no Neon, incluindo as políticas de leitura das tabelas de Notas para o backup.

Os SECURITY DEFINER são propriedade da conta que instala o snapshot, devido a `--no-owner`. Em produção, propriedade, login e rotação de segredos são responsabilidades do provisionamento da API. O snapshot não substitui esse processo.

## Validação reproduzível

Na raiz do repositório, execute `npm run check` e, com `PGHOST` local explícito, `npm run check:sql`. O segundo verifica:

1. Criação completa a partir do snapshot, incluindo permissões.
2. Criação a partir do histórico até a migração 078 e equivalência dos objetos, após normalizar a representação de CHECK pelo PostgreSQL.
3. Reexecução do histórico sem alterações na estrutura.
4. Consultas reais com o papel limitado da API e exemplos SQL.
5. Ausência de CREATE no schema e de UPDATE direto em perfis administrativos para a API.
6. Recusa de reinstalação sobre schema existente, preservando os objetos.

O teste cria e remove somente bancos locais temporários. A validação da versão 078 rodou no PostgreSQL 18.6 com dados de negócio vazios.

## Atualização da referência

Use `npm run export:sql` com as variáveis seguras de conexão já configuradas ou `node scripts/export-sql.mjs --from arquivo.sql` para separar um dump somente de estrutura. O `pg_dump` deve ser da versão do servidor ou mais recente; TLS é validado por padrão. O exportador mantém `estrutura.sql`, os arquivos por objeto, o inventário e as contagens do site sincronizados.

O dump não contém linhas das tabelas nem estado atual das sequências. Imagens, documentos R2, chaves Redis e usuários do Firebase Authentication não fazem parte da instalação DDL.

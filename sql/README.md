# Scripts PostgreSQL

## Qual arquivo usar

- **Banco local novo:** `instalar.psql` prepara os papéis locais sem login e executa `atual/estrutura.sql` dentro da transação fornecida pelo comando `psql --single-transaction`.
- **Ler o código de um objeto:** procure em `atual/tabelas`, `atual/views` ou `atual/funcoes`. As demais pastas contêm sequências, índices, restrições, trigger e políticas. `atual/catalogo.json` relaciona cada objeto ao arquivo correspondente.
- **Consultar dados:** `examples/consultas.sql` contém consultas de leitura sobre a estrutura atual.
- **Entender uma alteração passada:** `migrations/` e `migrate.psql` preservam o histórico. Uma migração pode citar objetos antigos removidos depois; isso não significa que eles ainda existam no banco atual.

O snapshot atual é `061_simplificar_recorrencias`, exportado do PostgreSQL 18.6. Há 25 tabelas, 15 views, 51 funções, 10 sequências, um trigger e três políticas RLS. **Não existem procedures nessa versão**; quando forem criadas, o exportador passará a gerar `atual/procedures/`.

`estrutura.sql` contém definições completas, comentários e GRANT/REVOKE, na ordem das dependências. Os arquivos individuais são referências para leitura: comentários ficam em `comentarios.sql`, permissões em `permissoes.sql`, e PK/FK/UNIQUE em `restricoes/`. Não substitua a instalação completa por executar arquivos isolados.

## Instalação em banco vazio

Com PostgreSQL 18+ e uma conta local com CREATEROLE:

```sh
createdb tech2d_local
psql -X -d tech2d_local -v ON_ERROR_STOP=1 --single-transaction -f sql/instalar.psql
psql -X -d tech2d_local -v ON_ERROR_STOP=1 -f sql/examples/consultas.sql
```

O instalador recusa um schema `tech2d` já existente. Não executa DROP, não cria usuários de login, não contém senhas e não insere dados de negócio. Os papéis `tech2d_api` e `assistente_ia_readonly` são criados localmente apenas se não existirem, pois aparecem nos GRANT exportados. O segundo possui somente USAGE no schema nessa exportação; isso não concede SELECT sobre tabelas.

Os SECURITY DEFINER são propriedade da conta que instala o snapshot, devido a `--no-owner`. Em produção, propriedade, login e rotação de segredos são responsabilidades do provisionamento da API. O snapshot não substitui esse processo.

## Validação reproduzível

Na raiz do repositório, execute `npm run check` e, com `PGHOST` local explícito, `npm run check:sql`. O segundo verifica:

1. Criação completa a partir do snapshot, incluindo permissões.
2. Criação a partir das 61 migrações e equivalência dos objetos, após normalizar a representação de CHECK pelo PostgreSQL.
3. Reexecução do histórico sem alterações na estrutura.
4. Consultas reais com o papel limitado da API e exemplos SQL.
5. Ausência de CREATE no schema e de UPDATE direto em perfis administrativos para a API.
6. Recusa de reinstalação sobre schema existente, preservando os objetos.

O teste cria e remove somente bancos locais temporários com nomes próprios. **Nenhum registro de produção é necessário**. O PostgreSQL temporário que foi usado para a conferência de 15/11/2026 era da versão 18.6.

## Atualização da referência

Use `npm run export:sql` com as variáveis seguras de conexão já configuradas ou `node scripts/export-sql.mjs --from arquivo.sql` para separar um dump somente de estrutura. O `pg_dump` deve ser da versão do servidor ou mais recente; TLS é validado por padrão. O exportador mantém `estrutura.sql`, os arquivos por objeto, o inventário e as contagens do site sincronizados.

O dump não contém linhas das tabelas nem estado atual das sequências. Imagens, documentos R2, chaves Redis e usuários do Firebase Authentication não fazem parte da instalação DDL.

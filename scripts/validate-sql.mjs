import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../', import.meta.url))
if (!['localhost', '127.0.0.1', '::1'].includes(process.env.PGHOST || '')) {
  throw Error('Defina PGHOST explicitamente como localhost, 127.0.0.1 ou ::1. Este teste cria e remove apenas bancos locais temporários.')
}
const env = { ...process.env, PGDATABASE: 'postgres', PGCONNECT_TIMEOUT: '10' }
delete env.DATABASE_URL
const databases = []
const prefix = `tech2d_validation_${process.pid}_${Date.now()}`
const bin = name => process.env.PG_BIN ? path.join(process.env.PG_BIN, name + (process.platform === 'win32' ? '.exe' : '')) : name
function run(name, args, input) {
  const r = spawnSync(bin(name), args, { cwd: root, env, input, encoding: 'utf8', windowsHide: true, maxBuffer: 32 * 1024 * 1024 })
  if (r.error || r.status !== 0) throw Error(`${name} falhou: ${(r.stderr || r.error?.code || '').slice(-3000)}`)
  return r.stdout
}
function sql(db, command) { return run('psql', ['-X', '-d', db, '-v', 'ON_ERROR_STOP=1', '-At', '-c', command]).trim() }
function create(suffix) {
  const name = `${prefix}_${suffix}`
  run('createdb', [name]); databases.push(name); return name
}
function dump(db) {
  return run('pg_dump', ['-d', db, '--schema-only', '--schema=tech2d', '--no-owner', '--no-privileges', '--no-tablespaces', '--restrict-key=Tech2dValidation']).replace(/\r\n/g, '\n')
}
try {
  const snapshot = create('snapshot')
  const migrations = create('history')
  const canonical = create('canonical')
  run('psql', ['-X', '-d', snapshot, '-v', 'ON_ERROR_STOP=1', '--single-transaction', '-f', 'sql/instalar.psql'])
  run('psql', ['-X', '-d', migrations, '-v', 'ON_ERROR_STOP=1', '--single-transaction', '-f', 'sql/migrate.psql'])
  // PostgreSQL rewrites some CHECK casts on their first restore. Compare both after parsing.
  run('psql', ['-X', '-d', canonical, '-v', 'ON_ERROR_STOP=1', '--single-transaction'], dump(migrations))
  assert.equal(dump(canonical), dump(snapshot), 'O snapshot diverge da estrutura criada pelas migrações')
  // Running the history again must keep the same schema.
  const before = dump(migrations)
  run('psql', ['-X', '-d', migrations, '-v', 'ON_ERROR_STOP=1', '--single-transaction', '-f', 'sql/migrate.psql'])
  assert.equal(dump(migrations), before, 'Reexecutar migrações mudou a estrutura')
  const inventory = JSON.parse(await readFile(path.join(root, 'sql/atual/catalogo.json'), 'utf8'))
  assert.equal(Number(sql(snapshot, "SELECT count(*) FROM pg_tables WHERE schemaname='tech2d'")), inventory.counts.TABLE)
  assert.equal(Number(sql(snapshot, "SELECT count(*) FROM pg_views WHERE schemaname='tech2d'")), inventory.counts.VIEW)
  assert.equal(Number(sql(snapshot, "SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='tech2d' AND p.prokind='f'")), inventory.counts.FUNCTION)
  assert.equal(sql(snapshot, "SELECT has_schema_privilege('tech2d_api','tech2d','CREATE')"), 'f', 'O papel da API não deve criar objetos')
  assert.equal(sql(snapshot, "SELECT has_table_privilege('tech2d_api','tech2d.perfis_administrativos','UPDATE')"), 'f', 'O papel da API não deve editar diretamente permissões')
  sql(snapshot, 'SET ROLE tech2d_api; SELECT count(*) FROM tech2d.visao_atividades; SELECT count(*) FROM tech2d.visao_documentos_catalogo; SELECT * FROM tech2d.consultar_catalogo_agenda(NULL::text, true); RESET ROLE;')
  run('psql', ['-X', '-d', snapshot, '-v', 'ON_ERROR_STOP=1', '-f', 'sql/examples/consultas.sql'])
  // Installation must refuse an existing schema, preserving every object.
  const again = spawnSync(bin('psql'), ['-X', '-d', snapshot, '-v', 'ON_ERROR_STOP=1', '--single-transaction', '-f', 'sql/instalar.psql'], { cwd: root, env, encoding: 'utf8', windowsHide: true })
  assert.notEqual(again.status, 0, 'A instalação deve recusar schema existente')
  assert.equal(dump(snapshot), dump(canonical))
  console.log(`PostgreSQL validado: instalação vazia, histórico completo equivalente, reexecução, consultas, permissões e proteção contra reinstalação. ${inventory.counts.TABLE} tabelas, ${inventory.counts.VIEW} views, ${inventory.counts.FUNCTION} funções.`)
} finally {
  for (const db of databases.reverse()) run('dropdb', ['--if-exists', db])
}

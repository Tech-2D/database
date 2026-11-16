import { mkdir, readFile, writeFile, unlink } from 'node:fs/promises'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const root = fileURLToPath(new URL('../', import.meta.url))
const output = path.join(root, 'sql/atual')
const categories = {
  SCHEMA: 'schema', TABLE: 'tabelas', VIEW: 'views', FUNCTION: 'funcoes', PROCEDURE: 'procedures',
  SEQUENCE: 'sequencias', INDEX: 'indices', TRIGGER: 'gatilhos', POLICY: 'politicas',
  CONSTRAINT: 'restricoes', 'FK CONSTRAINT': 'restricoes', DEFAULT: 'defaults',
  'ROW SECURITY': 'seguranca', ACL: 'permissoes', 'DEFAULT ACL': 'permissoes',
  COMMENT: 'comentarios', 'SEQUENCE OWNED BY': 'sequencias',
}

function dumpSchema() {
  const env = { ...process.env, PGCONNECT_TIMEOUT: '20', PGCLIENTENCODING: 'UTF8' }
  if (env.DATABASE_URL) {
    const url = new URL(env.DATABASE_URL)
    if (!['postgres:', 'postgresql:'].includes(url.protocol)) throw Error('DATABASE_URL_INVALID')
    Object.assign(env, { PGHOST: url.hostname, PGPORT: url.port || '5432',
      PGUSER: decodeURIComponent(url.username), PGPASSWORD: decodeURIComponent(url.password),
      PGDATABASE: decodeURIComponent(url.pathname.slice(1)), PGSSLMODE: env.PGSSLMODE || 'verify-full' })
    if (env.PG_CA_FILE) env.PGSSLROOTCERT = path.resolve(env.PG_CA_FILE)
    delete env.DATABASE_URL
  }
  const result = spawnSync(env.PG_DUMP || 'pg_dump', [
    '--schema-only', '--schema=tech2d', '--no-owner', '--no-tablespaces', '--no-password',
    '--restrict-key=Tech2dSchemaExport',
  ], { env, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, windowsHide: true })
  // Never print connection details or errors that might contain secrets.
  if (result.error || result.status !== 0) throw Error('PG_DUMP_FAILED_CHECK_VERSION_TLS_AND_ACCESS')
  return result.stdout
}

try {
  const from = process.argv.indexOf('--from')
  if (from !== -1 && !process.argv[from + 1]) throw Error('DUMP_FILE_REQUIRED')
  let sql = from === -1 ? dumpSchema() : await readFile(process.argv[from + 1], 'utf8')
  sql = sql.replace(/\r\n/g, '\n').replace(/^-- (Started|Completed) on .*\n/gm, '')
  if (!sql.includes('CREATE SCHEMA tech2d;') || /^(COPY |INSERT INTO )/m.test(sql)) throw Error('EXPECTED_SCHEMA_ONLY_DUMP')
  const marker = sql.match(/tech2d-schema-version:([\w]+)/)?.[1]
  if (!marker) throw Error('SCHEMA_VERSION_MISSING')
  const headers = [...sql.matchAll(/^-- Name: (.+); Type: ([A-Z ]+); Schema: (.*); Owner: (.*)\n/gm)]
  if (!headers.length) throw Error('NO_DUMP_OBJECTS')
  const files = new Map()
  const objects = []
  const counts = {}
  for (let i = 0; i < headers.length; i++) {
    const match = headers[i]
    const [, name, type, schema] = match
    if (schema !== 'tech2d' && !(schema === '-' && ['SCHEMA', 'COMMENT', 'ACL', 'DEFAULT ACL'].includes(type))) throw Error('UNEXPECTED_SCHEMA')
    const category = categories[type]
    if (!category) throw Error('UNSUPPORTED_DUMP_OBJECT_' + type.replaceAll(' ', '_'))
    // Same-name overloads are kept together; pg_dump order remains in estrutura.sql.
    const stem = (name.split('(')[0].replace(/^(TABLE|FUNCTION|PROCEDURE|SCHEMA|VIEW|COLUMN|SEQUENCE|INDEX|CONSTRAINT|POLICY|TRIGGER) /, '')
      .replaceAll(/[^A-Za-z0-9_]+/g, '_').replace(/^_|_$/g, '') || 'schema').toLowerCase()
    const file = type === 'COMMENT' ? 'comentarios.sql' : ['ACL', 'DEFAULT ACL'].includes(type) ? 'permissoes.sql' : `${category}/${['CONSTRAINT', 'FK CONSTRAINT'].includes(type) ? name.split(' ')[0].replace(/[^A-Za-z0-9_]/g, '_') : stem}.sql`
    const end = i + 1 < headers.length ? headers[i + 1].index - 3 : sql.indexOf('-- PostgreSQL database dump complete', match.index)
    const block = sql.slice(match.index, end > match.index ? end : sql.length).replace(/\n--\n?$/, '').trimEnd()
    files.set(file, (files.get(file) || '-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.\n\n') + block + '\n\n')
    objects.push({ name, type, schema: schema === '-' ? null : schema, file })
    counts[type] = (counts[type] || 0) + 1
  }
  counts.PROCEDURE ||= 0
  await mkdir(output, { recursive: true })
  // Only remove previously generated files tracked by this manifest.
  let previous = []
  try { previous = JSON.parse(await readFile(path.join(output, 'catalogo.json'), 'utf8')).objects || [] }
  catch (error) { if (error.code !== 'ENOENT') throw error }
  for (const old of new Set(previous.map(o => o.file))) {
    if (files.has(old)) continue
    const target = path.resolve(output, old)
    if (!target.startsWith(output + path.sep)) throw Error('INVALID_PREVIOUS_FILE')
    await unlink(target).catch(e => { if (e.code !== 'ENOENT') throw e })
  }
  for (const [name, contents] of files) {
    const target = path.join(output, name)
    await mkdir(path.dirname(target), { recursive: true })
    await writeFile(target, contents.trimEnd() + '\n')
  }
  await writeFile(path.join(output, 'estrutura.sql'), sql.trimEnd() + '\n')
  await writeFile(path.join(output, 'catalogo.json'), JSON.stringify({ schema: 'tech2d', version: marker,
    serverVersion: sql.match(/Dumped from database version (.+)/)?.[1],
    dumpVersion: sql.match(/Dumped by pg_dump version (.+)/)?.[1], counts, objects }, null, 2) + '\n')
  await writeFile(path.join(root, 'docs/_data/sql_inventory.json'), JSON.stringify({ version: marker, serverVersion: sql.match(/Dumped from database version (.+)/)?.[1], counts }, null, 2) + '\n')
  console.log(`SQL ${marker}: ${counts.TABLE || 0} tabelas, ${counts.VIEW || 0} views, ${counts.FUNCTION || 0} funções, ${counts.PROCEDURE || 0} procedures. Sem dados de usuários.`)
} catch (error) {
  console.error(`Exportação interrompida: ${/^[A-Z0-9_]+$/.test(error.message) ? error.message : 'CHECK_EXPORT_CONFIGURATION'}`)
  process.exitCode = 1
}

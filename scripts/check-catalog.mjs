import { readFile } from 'node:fs/promises'
import assert from 'node:assert/strict'
const read = path => readFile(new URL('../' + path, import.meta.url), 'utf8')
const schema = JSON.parse(await read('docs/_data/schema.json'))
const notes = JSON.parse(await read('docs/_data/column_notes.json'))
const usage = JSON.parse(await read('docs/_data/table_usage.json'))
const catalog = [...(await read('docs/_data/catalog.yml')).matchAll(/^    - name: (\w+)$/gm)].map(m => m[1])
const names = schema.map(t => t.name)
assert.deepEqual([...catalog].sort(), [...names].sort(), 'O menu deve conter cada tabela uma única vez')
assert.deepEqual(Object.keys(usage).sort(), [...names].sort(), 'Toda tabela deve ter um uso documentado')
assert.deepEqual(Object.keys(notes).sort(), [...names].sort(), 'As notas devem corresponder às tabelas atuais')
let columns = 0
for (const table of schema) {
  assert.ok(usage[table.name].feature && usage[table.name].description.length > 80, table.name + ': explicar tela e serviço')
  for (const column of table.columns) {
    assert.ok(notes[table.name][column.name]?.length > 20, table.name + '.' + column.name + ': explicar a finalidade')
    assert.doesNotMatch(notes[table.name][column.name], /^Campo \w+ no contrato/, 'Substituir rótulo técnico por uma explicação')
    columns++
  }
  for (const ref of table.references) assert.ok(names.includes(ref.table), 'Referência a uma tabela retirada: ' + ref.table)
}
console.log(`Catálogo validado: ${schema.length} tabelas, ${columns} campos, todos com explicação.`)

// Every object linked from the site must have an exported SQL definition.
const sqlInventory = JSON.parse(await read('sql/atual/catalogo.json'))
const siteInventory = JSON.parse(await read('docs/_data/sql_inventory.json'))
assert.equal(siteInventory.version, sqlInventory.version, 'A versão SQL do site está desatualizada')
assert.deepEqual(siteInventory.counts, sqlInventory.counts)
const routines = JSON.parse(await read('docs/_data/routines.json'))
const views = JSON.parse(await read('docs/_data/views.json'))
const exported = type => sqlInventory.objects.filter(o => o.type === type)
assert.deepEqual(exported('TABLE').map(o => o.name).sort(), [...names].sort())
assert.deepEqual(exported('VIEW').map(o => o.name).sort(), views.map(v => v.name).sort())
assert.equal(exported('FUNCTION').length, routines.filter(r => !r.procedure).length)
assert.equal(exported('PROCEDURE').length, routines.filter(r => r.procedure).length)
for (const routine of routines) {
  const category = routine.procedure ? 'procedures' : 'funcoes'
  assert.match(await read(`sql/atual/${category}/${routine.name}.sql`), /CREATE (FUNCTION|PROCEDURE)/)
}
for (const file of new Set(sqlInventory.objects.map(o => o.file))) {
  assert.ok(!file.includes('..') && !file.startsWith('/'), 'Arquivo SQL deve ficar no inventário')
  assert.ok((await read('sql/atual/' + file)).trim(), 'SQL vazio: ' + file)
}
const ddl = await read('sql/atual/estrutura.sql')
assert.ok(ddl.includes('tech2d-schema-version:' + sqlInventory.version))
assert.doesNotMatch(ddl, /^(COPY |INSERT INTO )/m, 'O snapshot deve conter apenas estrutura')
console.log(`Scripts SQL validados: ${exported('VIEW').length} views, ${exported('FUNCTION').length} funções e todos os links do catálogo.`)

const redisNames = JSON.parse(await read('docs/_data/redis_names.json'))
const redisCatalog = await read('docs/_data/redis_catalog.yml')
const iconLibrary = await read('docs/_includes/doc-icons.html')
for (const [, icon] of redisCatalog.matchAll(/^  icon: ([\w-]+)$/gm)) {
  assert.ok(iconLibrary.includes(`id="icon-${icon}"`), 'Ícone do catálogo Redis sem definição: ' + icon)
}
const documentedKeys = [...redisCatalog.matchAll(/^      key: '([^']+)'$/gm)].map(m => m[1])
assert.ok(documentedKeys.length > 25, 'Documentar os grupos Redis usados pela aplicação')
assert.equal(new Set(documentedKeys).size, documentedKeys.length, 'O catálogo Redis contém chaves duplicadas')
for (const key of documentedKeys) {
  const example = key.replace('<tipo>', 'atividades').replace('<quadro_ou_usuario>', 'quadro').replaceAll(/<[^>]+>/g, 'EXEMPLO')
  assert.ok(redisNames.some(r => example === r.current || example.startsWith(r.current + ':')), 'Padrão Redis sem implementação documentada: ' + key)
  assert.ok(!redisNames.some(r => example === r.legacy || example.startsWith(r.legacy + ':')), 'Nome antigo no catálogo Redis: ' + key)
}
console.log(`Redis validado: ${documentedKeys.length} padrões de chaves atuais no catálogo.`)

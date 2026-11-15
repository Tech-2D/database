---
layout: default
title: Notas
---

O caderno de notas privado usa o PostgreSQL centralizado. As migrations 030 e 032 substituíram o catálogo separado da área de Notas pelo catálogo compartilhado de disciplinas. O Firebase Authentication identifica a conta; a API obtém o UID do token validado, sem aceitar um proprietário pelo corpo da requisição.

| Objeto | Finalidade |
| --- | --- |
| `disciplinas` | Catálogo de matérias compartilhado com os horários. |
| `disciplinas_series` | Associação entre a matéria existente e a série em que ela é oferecida. |
| `visao_disciplinas_notas` | Projeção de leitura com os rótulos compatíveis com a interface da área de Notas, sem outro cadastro de nomes. |
| `notas_cadernos` | Conta, ano letivo, série, modos de entrada, versão da fórmula e controle de concorrência. |
| `notas_lancamentos` | N1, N2, média informada e peso da N1 por disciplina e semestre. |
| `notas_recuperacoes` | Nota de recuperação final por disciplina. |
| `visao_notas_resultados` | Médias semestrais, média recuperada, anual, final, nota necessária e situação. |

Notas vazias são `NULL`, mantendo a distinção entre “sem nota” e zero. As notas variam de 0 a 10 com duas casas decimais; pesos variam de 10% a 90%, em passos de 5%. Chaves estrangeiras impedem misturar disciplinas e cadernos de séries diferentes.

A visão usa a regra `tech-2026-v1`, equivalente ao cálculo da área de Notas: média ponderada por semestre, segundo semestre com peso 2 na média anual, recuperação de média limitada a 7 e recuperação final com aprovação a partir de 6. O catálogo compartilhado associa disciplinas às séries do Ensino Médio (1º, 2º e 3º anos), incluindo as matérias vinculadas aos horários das turmas Tech.

## Acesso e sincronização

`GET /api/pegaki?academicYear=2026&gradeYear=2` carrega o próprio caderno. `POST /api/pegaki` salva notas e modos em uma transação, exigindo `expectedVersion`. Uma versão desatualizada recebe HTTP 409, preservando o caderno já gravado por outra aba ou dispositivo.

As tabelas privadas têm Row Level Security. O usuário de runtime recebe apenas os privilégios necessários e configura `tech2d.uid` dentro da transação; esse contexto é descartado ao terminar a requisição. A visão usa `security_invoker`, preservando as mesmas políticas. Ela não integra o catálogo público nem o endpoint genérico de documentos.

Sem login, a área de Notas continua usando o armazenamento local. Depois do login, as notas da conta são carregadas separadamente; a pessoa pode importar as notas antigas do navegador e salvar na conta. Os PDFs permanecem no dispositivo: somente as notas extraídas são enviadas ao salvar.

## Uso futuro pela IA

A visão fornece dados estruturados e resultados reproduzíveis, com conta, ano letivo, disciplina e versão da regra. Esta mudança não envia notas a uma IA e não cria um acesso administrativo global. Uma integração futura deverá consultar a própria conta autenticada e definir o uso das notas de forma explícita.

## Série, turma e habilitação da Agenda

A série do caderno é o ano do Ensino Médio (1, 2 ou 3), usado para escolher as matérias e validar as notas. Ela não é uma sala como 2º TECH D. A área de Notas não mantém outra tabela de turmas.

`turmas` identifica as salas dos horários. `turmas_agenda` registra a habilitação de uma agenda no fluxo de aprovação. A implementação atual mantém esses dois papéis separados; seus nomes não devem ser tratados como identificadores intercambiáveis.

## Nomenclatura atual

A versão 045 renomeia as três tabelas para `notas_cadernos`, `notas_lancamentos` e `notas_recuperacoes`, sem copiar ou excluir registros. As views são `visao_disciplinas_notas` e `visao_notas_resultados`. Índices, restrições e políticas de isolamento também usam o prefixo `notas`.

A rota técnica `/api/pegaki` permanece compatível com os clientes existentes; ela consulta as tabelas de Notas. O valor histórico `pegaki` nas estatísticas identifica acessos a essa área e não representa uma tabela separada.

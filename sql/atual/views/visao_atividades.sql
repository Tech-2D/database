-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_atividades; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_atividades AS
 SELECT referencia_api AS id,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = a.id_turma)) AS turma_id,
    titulo AS title,
    COALESCE(descricao, ''::character varying) AS description,
    tipo_atividade AS type,
    (( SELECT COALESCE(( SELECT rotulo_nota.nome
                   FROM tech2d.visao_disciplinas_notas rotulo_nota
                  WHERE (rotulo_nota.id = rotulo_disciplina.id_disciplina)
                  ORDER BY rotulo_nota.ano_serie DESC
                 LIMIT 1), rotulo_disciplina.nome) AS "coalesce"
           FROM tech2d.disciplinas rotulo_disciplina
          WHERE (rotulo_disciplina.id_disciplina = a.id_disciplina)))::character varying(150) AS subject,
    (data_atividade)::character varying(10) AS date,
    to_char((hora_atividade)::interval, 'HH24:MI'::text) AS "time",
    criado_por AS created_by,
    email_criador AS created_by_email,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE (rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia)) AS recurring_id,
    COALESCE(( SELECT jsonb_agg(tech2d.ler_anexos_atividade(f.id_anexo_atividade) ORDER BY f.id_anexo_atividade) AS jsonb_agg
           FROM tech2d.anexos_atividade f
          WHERE (f.id_atividade = a.id_atividade)), '[]'::jsonb) AS attachments,
    (criado_em)::timestamp with time zone AS created_at,
    (alterado_em)::timestamp with time zone AS updated_at,
    versao AS version
   FROM tech2d.atividades a;

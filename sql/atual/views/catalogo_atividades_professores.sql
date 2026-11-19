-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: catalogo_atividades_professores; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.catalogo_atividades_professores AS
 SELECT a.referencia_api AS id_atividade,
    a.titulo,
    a.tipo_atividade AS tipo,
    a.data_atividade AS data,
    to_char((a.hora_atividade)::interval, 'HH24:MI'::text) AS hora,
    a.id_disciplina,
    d.nome AS disciplina,
    a.id_turma,
    t.nome AS turma,
    p.id_professor,
    p.nome AS professor,
        CASE
            WHEN (a.id_turma IS NULL) THEN 'atividade_geral'::text
            WHEN (a.id_disciplina IS NULL) THEN 'disciplina_pendente'::text
            WHEN (p.id_professor IS NULL) THEN 'professor_pendente'::text
            ELSE 'associado'::text
        END AS estado_atribuicao,
    (COALESCE(( SELECT n.nome
           FROM tech2d.visao_disciplinas_notas n
          WHERE (n.id = d.id_disciplina)
          ORDER BY n.ano_serie DESC
         LIMIT 1), d.nome))::character varying(150) AS disciplina_original,
    COALESCE(t.referencia_agenda, t.nome) AS turma_original,
    r.referencia_api AS referencia_recorrencia
   FROM (((((tech2d.atividades a
     LEFT JOIN tech2d.regras_recorrencia r USING (id_regra_recorrencia))
     LEFT JOIN tech2d.disciplinas d ON ((d.id_disciplina = a.id_disciplina)))
     LEFT JOIN tech2d.turmas t ON ((t.id_turma = a.id_turma)))
     LEFT JOIN tech2d.vinculos_professores_turmas x ON ((((x.id_turma = a.id_turma) AND (x.id_disciplina = a.id_disciplina)) AND (a.data_atividade <@ daterange(x.vigencia_inicio, x.vigencia_fim, '[]'::text)))))
     LEFT JOIN tech2d.professores p ON ((p.id_professor = x.id_professor)));

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_atividades_automacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_atividades_automacao AS
 SELECT referencia_api AS id,
    tech2d.referencia_api('activities'::character varying, ''::character varying, referencia_api) AS caminho,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = a.id_turma)) AS turma,
    data_atividade AS data,
    ( SELECT rotulo_regra.referencia_api
           FROM tech2d.regras_recorrencia rotulo_regra
          WHERE (rotulo_regra.id_regra_recorrencia = a.id_regra_recorrencia)) AS referencia_recorrencia,
    tech2d.ler_registro(id_atividade, 'activities'::character varying) AS conteudo
   FROM tech2d.atividades a;

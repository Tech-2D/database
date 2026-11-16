-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_perfis_administrativos; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_perfis_administrativos AS
 SELECT referencia_api AS uid,
    papel AS role,
    ( SELECT COALESCE(rotulo_turma.referencia_agenda, rotulo_turma.nome) AS "coalesce"
           FROM tech2d.turmas rotulo_turma
          WHERE (rotulo_turma.id_turma = p.id_turma)) AS turma_id,
    tech2d.ler_registro(id_perfil_administrativo, 'admins'::character varying) AS data
   FROM tech2d.perfis_administrativos p;

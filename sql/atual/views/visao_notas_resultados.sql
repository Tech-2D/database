-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_notas_resultados; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_notas_resultados WITH (security_invoker='true') AS
 WITH semestres AS (
         SELECT c.id_usuario,
            c.ano_letivo,
            c.ano_serie,
            c.regra_calculo,
            c.versao,
            d.id AS id_disciplina,
            d.nome,
                CASE
                    WHEN ((c.modo_primeiro)::text = 'media'::text) THEN p.media_informada
                    ELSE round((((p.n1 * (p.peso_n1)::numeric) + (p.n2 * ((100 - p.peso_n1))::numeric)) / (100)::numeric), 2)
                END AS media_primeiro,
                CASE
                    WHEN ((c.modo_segundo)::text = 'media'::text) THEN s.media_informada
                    ELSE round((((s.n1 * (s.peso_n1)::numeric) + (s.n2 * ((100 - s.peso_n1))::numeric)) / (100)::numeric), 2)
                END AS media_segundo,
            r.nota AS recuperacao_final
           FROM ((((tech2d.notas_cadernos c
             JOIN tech2d.visao_disciplinas_notas d USING (ano_serie))
             LEFT JOIN tech2d.notas_lancamentos p ON ((((p.id_usuario)::text = (c.id_usuario)::text) AND (p.ano_letivo = c.ano_letivo) AND (p.id_disciplina = d.id) AND (p.semestre = 1))))
             LEFT JOIN tech2d.notas_lancamentos s ON ((((s.id_usuario)::text = (c.id_usuario)::text) AND (s.ano_letivo = c.ano_letivo) AND (s.id_disciplina = d.id) AND (s.semestre = 2))))
             LEFT JOIN tech2d.notas_recuperacoes r ON ((((r.id_usuario)::text = (c.id_usuario)::text) AND (r.ano_letivo = c.ano_letivo) AND (r.id_disciplina = d.id))))
        ), recuperadas AS (
         SELECT semestres.id_usuario,
            semestres.ano_letivo,
            semestres.ano_serie,
            semestres.regra_calculo,
            semestres.versao,
            semestres.id_disciplina,
            semestres.nome,
            semestres.media_primeiro,
            semestres.media_segundo,
            semestres.recuperacao_final,
                CASE
                    WHEN ((semestres.media_segundo > COALESCE(semestres.media_primeiro, (0)::numeric)) AND (round(LEAST(((COALESCE(semestres.media_primeiro, (0)::numeric) + semestres.media_segundo) / (2)::numeric), (7)::numeric), 2) > COALESCE(semestres.media_primeiro, (0)::numeric))) THEN round(LEAST(((COALESCE(semestres.media_primeiro, (0)::numeric) + semestres.media_segundo) / (2)::numeric), (7)::numeric), 2)
                    ELSE NULL::numeric
                END AS media_recuperada
           FROM semestres
        ), anuais AS (
         SELECT recuperadas.id_usuario,
            recuperadas.ano_letivo,
            recuperadas.ano_serie,
            recuperadas.regra_calculo,
            recuperadas.versao,
            recuperadas.id_disciplina,
            recuperadas.nome,
            recuperadas.media_primeiro,
            recuperadas.media_segundo,
            recuperadas.recuperacao_final,
            recuperadas.media_recuperada,
                CASE
                    WHEN (recuperadas.media_segundo IS NULL) THEN recuperadas.media_primeiro
                    ELSE round(((COALESCE(recuperadas.media_recuperada, recuperadas.media_primeiro, (0)::numeric) + (recuperadas.media_segundo * (2)::numeric)) / (3)::numeric), 2)
                END AS media_anual
           FROM recuperadas
        )
 SELECT id_usuario,
    ano_letivo,
    ano_serie,
    regra_calculo,
    versao,
    id_disciplina,
    nome,
    media_primeiro,
    media_segundo,
    recuperacao_final,
    media_recuperada,
    media_anual,
        CASE
            WHEN ((media_segundo IS NOT NULL) AND (media_anual < (7)::numeric)) THEN GREATEST((0)::numeric, ((12)::numeric - media_anual))
            ELSE NULL::numeric
        END AS nota_necessaria,
        CASE
            WHEN ((media_segundo IS NOT NULL) AND (media_anual < (7)::numeric) AND (recuperacao_final IS NOT NULL)) THEN round(((media_anual + recuperacao_final) / (2)::numeric), 2)
            ELSE NULL::numeric
        END AS media_final,
        CASE
            WHEN ((media_primeiro IS NULL) AND (media_segundo IS NULL)) THEN 'sem-notas'::text
            WHEN (media_segundo IS NULL) THEN 'andamento'::text
            WHEN (media_anual >= (7)::numeric) THEN 'aprovado'::text
            WHEN (recuperacao_final IS NULL) THEN 'recuperacao'::text
            WHEN (round(((media_anual + recuperacao_final) / (2)::numeric), 2) >= (6)::numeric) THEN 'aprovado-rec'::text
            ELSE 'reprovado'::text
        END AS situacao
   FROM anuais;

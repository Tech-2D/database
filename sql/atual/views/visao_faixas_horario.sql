-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_faixas_horario; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_faixas_horario WITH (security_invoker='true') AS
 SELECT id_faixa_horario AS id,
    hora_inicio AS start_time,
    hora_fim AS end_time
   FROM tech2d.faixas_horario;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visao_recibos_gravacao; Type: VIEW; Schema: tech2d; Owner: -
--

CREATE VIEW tech2d.visao_recibos_gravacao WITH (security_invoker='true') AS
 SELECT id_recibo_gravacao AS id,
    autor AS actor,
    hash_requisicao AS digest,
    confirmado_em AS committed_at
   FROM tech2d.recibos_gravacao;

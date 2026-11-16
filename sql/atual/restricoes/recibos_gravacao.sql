-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: recibos_gravacao app_commits_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.recibos_gravacao
    ADD CONSTRAINT app_commits_pkey PRIMARY KEY (id_recibo_gravacao);

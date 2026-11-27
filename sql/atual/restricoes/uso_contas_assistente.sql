-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: uso_contas_assistente uso_contas_assistente_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.uso_contas_assistente
    ADD CONSTRAINT uso_contas_assistente_pkey PRIMARY KEY (dia, firebase_uid);

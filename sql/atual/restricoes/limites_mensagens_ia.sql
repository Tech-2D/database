-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limites_mensagens_ia limites_mensagens_ia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.limites_mensagens_ia
    ADD CONSTRAINT limites_mensagens_ia_pkey PRIMARY KEY (firebase_uid);

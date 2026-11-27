-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: reservas_mensagens_ia reservas_mensagens_ia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.reservas_mensagens_ia
    ADD CONSTRAINT reservas_mensagens_ia_pkey PRIMARY KEY (firebase_uid, operacao);

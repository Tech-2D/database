-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: participantes_kanban participantes_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.participantes_kanban
    ADD CONSTRAINT participantes_kanban_pkey PRIMARY KEY (id_participante_kanban);

-- Name: participantes_kanban participantes_kanban_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.participantes_kanban
    ADD CONSTRAINT participantes_kanban_referencia_api_key UNIQUE (referencia_api);

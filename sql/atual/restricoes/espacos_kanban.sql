-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: espacos_kanban espacos_kanban_compartilhado_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.espacos_kanban
    ADD CONSTRAINT espacos_kanban_compartilhado_referencia_api_key UNIQUE (compartilhado, referencia_api);

-- Name: espacos_kanban espacos_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.espacos_kanban
    ADD CONSTRAINT espacos_kanban_pkey PRIMARY KEY (id_espaco_kanban);

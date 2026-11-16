-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: colunas_kanban colunas_kanban_id_quadro_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_id_quadro_kanban_ordem_key UNIQUE (id_quadro_kanban, ordem);

-- Name: colunas_kanban colunas_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_pkey PRIMARY KEY (id_coluna_kanban);

-- Name: colunas_kanban colunas_kanban_referencia_quadro; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_referencia_quadro UNIQUE (id_quadro_kanban, referencia);

-- Name: colunas_kanban colunas_kanban_id_quadro_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.colunas_kanban
    ADD CONSTRAINT colunas_kanban_id_quadro_kanban_fkey FOREIGN KEY (id_quadro_kanban) REFERENCES tech2d.quadros_kanban(id_quadro_kanban) ON DELETE CASCADE;

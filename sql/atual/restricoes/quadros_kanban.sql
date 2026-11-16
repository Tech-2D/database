-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: quadros_kanban quadros_kanban_id_espaco_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_id_espaco_kanban_ordem_key UNIQUE (id_espaco_kanban, ordem);

-- Name: quadros_kanban quadros_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_pkey PRIMARY KEY (id_quadro_kanban);

-- Name: quadros_kanban quadros_kanban_id_espaco_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.quadros_kanban
    ADD CONSTRAINT quadros_kanban_id_espaco_kanban_fkey FOREIGN KEY (id_espaco_kanban) REFERENCES tech2d.espacos_kanban(id_espaco_kanban) ON DELETE CASCADE;

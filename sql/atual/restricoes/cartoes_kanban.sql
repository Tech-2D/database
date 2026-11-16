-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: cartoes_kanban cartoes_kanban_id_quadro_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_id_quadro_kanban_ordem_key UNIQUE (id_quadro_kanban, ordem);

-- Name: cartoes_kanban cartoes_kanban_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_pkey PRIMARY KEY (id_cartao_kanban);

-- Name: cartoes_kanban cartoes_kanban_coluna; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_coluna FOREIGN KEY (id_quadro_kanban, referencia_coluna) REFERENCES tech2d.colunas_kanban(id_quadro_kanban, referencia) DEFERRABLE INITIALLY DEFERRED;

-- Name: cartoes_kanban cartoes_kanban_id_quadro_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.cartoes_kanban
    ADD CONSTRAINT cartoes_kanban_id_quadro_kanban_fkey FOREIGN KEY (id_quadro_kanban) REFERENCES tech2d.quadros_kanban(id_quadro_kanban) ON DELETE CASCADE;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: itens_checklist itens_checklist_id_cartao_kanban_ordem_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_id_cartao_kanban_ordem_key UNIQUE (id_cartao_kanban, ordem);

-- Name: itens_checklist itens_checklist_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_pkey PRIMARY KEY (id_item_checklist);

-- Name: itens_checklist itens_checklist_id_cartao_kanban_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.itens_checklist
    ADD CONSTRAINT itens_checklist_id_cartao_kanban_fkey FOREIGN KEY (id_cartao_kanban) REFERENCES tech2d.cartoes_kanban(id_cartao_kanban) ON DELETE CASCADE;

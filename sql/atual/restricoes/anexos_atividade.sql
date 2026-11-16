-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: anexos_atividade anexos_atividade_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.anexos_atividade
    ADD CONSTRAINT anexos_atividade_pkey PRIMARY KEY (id_anexo_atividade);

-- Name: anexos_atividade anexos_atividade_id_atividade_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.anexos_atividade
    ADD CONSTRAINT anexos_atividade_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES tech2d.atividades(id_atividade) ON DELETE CASCADE;

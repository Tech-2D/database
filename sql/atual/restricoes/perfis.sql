-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis perfis_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_pkey PRIMARY KEY (id_perfil);

-- Name: perfis perfis_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_referencia_api_key UNIQUE (referencia_api);

-- Name: perfis perfis_id_turma_resumo_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis
    ADD CONSTRAINT perfis_id_turma_resumo_fkey FOREIGN KEY (id_turma_resumo) REFERENCES tech2d.turmas(id_turma);

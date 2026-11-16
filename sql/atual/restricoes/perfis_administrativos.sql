-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_administrativos perfis_administrativos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_pkey PRIMARY KEY (id_perfil_administrativo);

-- Name: perfis_administrativos perfis_administrativos_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_referencia_api_key UNIQUE (referencia_api);

-- Name: perfis_administrativos perfis_administrativos_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.perfis_administrativos
    ADD CONSTRAINT perfis_administrativos_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

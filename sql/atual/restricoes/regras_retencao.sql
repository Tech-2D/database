-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_retencao regras_retencao_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_pkey PRIMARY KEY (id_regra_retencao);

-- Name: regras_retencao regras_retencao_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_referencia_api_key UNIQUE (referencia_api);

-- Name: regras_retencao regras_retencao_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_retencao
    ADD CONSTRAINT regras_retencao_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

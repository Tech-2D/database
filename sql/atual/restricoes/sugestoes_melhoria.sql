-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: sugestoes_melhoria sugestoes_melhoria_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_pkey PRIMARY KEY (id_sugestao_melhoria);

-- Name: sugestoes_melhoria sugestoes_melhoria_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_referencia_api_key UNIQUE (referencia_api);

-- Name: sugestoes_melhoria sugestoes_melhoria_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.sugestoes_melhoria
    ADD CONSTRAINT sugestoes_melhoria_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

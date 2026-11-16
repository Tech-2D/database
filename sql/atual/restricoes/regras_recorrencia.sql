-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_recorrencia regras_recorrencia_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_pkey PRIMARY KEY (id_regra_recorrencia);

-- Name: regras_recorrencia regras_recorrencia_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_referencia_api_key UNIQUE (referencia_api);

-- Name: regras_recorrencia regras_recorrencia_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;

-- Name: regras_recorrencia regras_recorrencia_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.regras_recorrencia
    ADD CONSTRAINT regras_recorrencia_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

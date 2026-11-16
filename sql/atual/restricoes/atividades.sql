-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades atividades_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_pkey PRIMARY KEY (id_atividade);

-- Name: atividades atividades_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_referencia_api_key UNIQUE (referencia_api);

-- Name: atividades atividades_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;

-- Name: atividades atividades_id_regra_recorrencia_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_regra_recorrencia_fkey FOREIGN KEY (id_regra_recorrencia) REFERENCES tech2d.regras_recorrencia(id_regra_recorrencia) ON DELETE SET NULL;

-- Name: atividades atividades_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.atividades
    ADD CONSTRAINT atividades_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

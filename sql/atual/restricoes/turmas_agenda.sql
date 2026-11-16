-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: turmas_agenda turmas_agenda_id_turma_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_id_turma_key UNIQUE (id_turma);

-- Name: turmas_agenda turmas_agenda_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_pkey PRIMARY KEY (id_turma_agenda);

-- Name: turmas_agenda turmas_agenda_referencia_api_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_referencia_api_key UNIQUE (referencia_api);

-- Name: turmas_agenda turmas_agenda_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas_agenda
    ADD CONSTRAINT turmas_agenda_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

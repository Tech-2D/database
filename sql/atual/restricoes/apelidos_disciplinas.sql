-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: apelidos_disciplinas apelidos_disciplinas_id_disciplina_chave_normalizada_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_id_disciplina_chave_normalizada_key UNIQUE (id_disciplina, chave_normalizada);

-- Name: apelidos_disciplinas apelidos_disciplinas_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_pkey PRIMARY KEY (id);

-- Name: apelidos_disciplinas apelidos_disciplinas_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_disciplinas
    ADD CONSTRAINT apelidos_disciplinas_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;

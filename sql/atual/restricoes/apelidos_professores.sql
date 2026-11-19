-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: apelidos_professores apelidos_professores_id_professor_chave_normalizada_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_id_professor_chave_normalizada_key UNIQUE (id_professor, chave_normalizada);

-- Name: apelidos_professores apelidos_professores_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_pkey PRIMARY KEY (id);

-- Name: apelidos_professores apelidos_professores_id_professor_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.apelidos_professores
    ADD CONSTRAINT apelidos_professores_id_professor_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT;

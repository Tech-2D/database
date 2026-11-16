-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: disciplinas_series disciplinas_series_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas_series
    ADD CONSTRAINT disciplinas_series_pkey PRIMARY KEY (id_disciplina, ano_serie);

-- Name: disciplinas_series disciplinas_series_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas_series
    ADD CONSTRAINT disciplinas_series_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina);

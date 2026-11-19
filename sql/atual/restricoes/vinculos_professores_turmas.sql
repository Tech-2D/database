-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_professores_turmas vinculos_professores_turmas_numrange_numrange1_daterange_excl; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_numrange_numrange1_daterange_excl EXCLUDE USING gist (numrange((id_turma)::numeric, (id_turma)::numeric, '[]'::text) WITH &&, numrange((id_disciplina)::numeric, (id_disciplina)::numeric, '[]'::text) WITH &&, daterange(vigencia_inicio, vigencia_fim, '[]'::text) WITH &&);

-- Name: vinculos_professores_turmas vinculos_professores_turmas_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_pkey PRIMARY KEY (id);

-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_disciplina_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_disciplina_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;

-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_professor_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_professor_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor) ON DELETE RESTRICT;

-- Name: vinculos_professores_turmas vinculos_professores_turmas_id_turma_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_professores_turmas
    ADD CONSTRAINT vinculos_professores_turmas_id_turma_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;

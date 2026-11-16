-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: horarios_aula horarios_aula_id_registro_aplicacao_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT horarios_aula_id_registro_aplicacao_key UNIQUE (id_horario_interno);

-- Name: horarios_aula school_schedules_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_pkey PRIMARY KEY (id_horario_aula);

-- Name: horarios_aula school_schedules_class_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_class_id_fkey FOREIGN KEY (id_turma) REFERENCES tech2d.turmas(id_turma);

-- Name: horarios_aula school_schedules_subject_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_subject_id_fkey FOREIGN KEY (id_disciplina) REFERENCES tech2d.disciplinas(id_disciplina);

-- Name: horarios_aula school_schedules_teacher_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_teacher_id_fkey FOREIGN KEY (id_professor) REFERENCES tech2d.professores(id_professor);

-- Name: horarios_aula school_schedules_time_slot_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.horarios_aula
    ADD CONSTRAINT school_schedules_time_slot_id_fkey FOREIGN KEY (id_faixa_horario) REFERENCES tech2d.faixas_horario(id_faixa_horario);

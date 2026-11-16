-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_lancamentos notas_lancamentos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_pkey PRIMARY KEY (id_usuario, ano_letivo, id_disciplina, semestre);

-- Name: notas_lancamentos notas_lancamentos_disciplina_serie_fk; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_disciplina_serie_fk FOREIGN KEY (id_disciplina, ano_serie) REFERENCES tech2d.disciplinas_series(id_disciplina, ano_serie);

-- Name: notas_lancamentos notas_lancamentos_id_usuario_ano_letivo_ano_serie_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_lancamentos
    ADD CONSTRAINT notas_lancamentos_id_usuario_ano_letivo_ano_serie_fkey FOREIGN KEY (id_usuario, ano_letivo, ano_serie) REFERENCES tech2d.notas_cadernos(id_usuario, ano_letivo, ano_serie) ON DELETE CASCADE;

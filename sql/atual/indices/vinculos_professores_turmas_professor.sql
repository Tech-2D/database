-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_professores_turmas_professor; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX vinculos_professores_turmas_professor ON tech2d.vinculos_professores_turmas USING btree (id_professor, id_turma, id_disciplina, vigencia_inicio, vigencia_fim);

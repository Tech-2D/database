-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades_disciplina_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_disciplina_idx ON tech2d.atividades USING btree (id_disciplina);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_recorrencia_disciplina_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_recorrencia_disciplina_idx ON tech2d.regras_recorrencia USING btree (id_disciplina);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_retencao_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_retencao_turma_idx ON tech2d.regras_retencao USING btree (id_turma);

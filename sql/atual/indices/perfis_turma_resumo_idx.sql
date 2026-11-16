-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_turma_resumo_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_turma_resumo_idx ON tech2d.perfis USING btree (id_turma_resumo) WHERE (id_turma_resumo IS NOT NULL);

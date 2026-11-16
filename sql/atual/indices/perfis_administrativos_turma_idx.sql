-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_administrativos_turma_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_administrativos_turma_idx ON tech2d.perfis_administrativos USING btree (id_turma);

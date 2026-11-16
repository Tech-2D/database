-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades_regra_recorrencia_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_regra_recorrencia_idx ON tech2d.atividades USING btree (id_regra_recorrencia);

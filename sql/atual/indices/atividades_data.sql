-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades_data; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_data ON tech2d.atividades USING btree (data_atividade);

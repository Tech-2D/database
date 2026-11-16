-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: atividades_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX atividades_caminho_api_idx ON tech2d.atividades USING btree (tech2d.referencia_api('activities'::character varying, ''::character varying, referencia_api));

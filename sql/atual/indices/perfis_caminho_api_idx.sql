-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_caminho_api_idx ON tech2d.perfis USING btree (tech2d.referencia_api('userProfiles'::character varying, ''::character varying, referencia_api));

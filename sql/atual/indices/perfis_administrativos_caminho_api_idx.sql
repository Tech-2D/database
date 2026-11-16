-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: perfis_administrativos_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX perfis_administrativos_caminho_api_idx ON tech2d.perfis_administrativos USING btree (tech2d.referencia_api('admins'::character varying, ''::character varying, referencia_api));

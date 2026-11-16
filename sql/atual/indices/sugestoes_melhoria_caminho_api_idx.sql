-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: sugestoes_melhoria_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX sugestoes_melhoria_caminho_api_idx ON tech2d.sugestoes_melhoria USING btree (tech2d.referencia_api('feedback'::character varying, ''::character varying, referencia_api));

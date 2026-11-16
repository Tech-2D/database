-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: regras_recorrencia_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX regras_recorrencia_caminho_api_idx ON tech2d.regras_recorrencia USING btree (tech2d.referencia_api('recurringActivities'::character varying, ''::character varying, referencia_api));

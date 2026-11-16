-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: participantes_kanban_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX participantes_kanban_caminho_api_idx ON tech2d.participantes_kanban USING btree (tech2d.referencia_api('kanbanMemberships'::character varying, ''::character varying, referencia_api));

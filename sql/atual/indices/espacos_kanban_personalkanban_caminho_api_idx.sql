-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: espacos_kanban_personalkanban_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX espacos_kanban_personalkanban_caminho_api_idx ON tech2d.espacos_kanban USING btree (tech2d.referencia_api('personalKanban'::character varying, ''::character varying, referencia_api)) WHERE (NOT compartilhado);

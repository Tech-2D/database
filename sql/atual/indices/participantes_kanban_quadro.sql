-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: participantes_kanban_quadro; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX participantes_kanban_quadro ON tech2d.participantes_kanban USING btree (referencia_quadro);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: sugestoes_melhoria_autor; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX sugestoes_melhoria_autor ON tech2d.sugestoes_melhoria USING btree (criado_por);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: apelidos_disciplinas_chave; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX apelidos_disciplinas_chave ON tech2d.apelidos_disciplinas USING btree (chave_normalizada);

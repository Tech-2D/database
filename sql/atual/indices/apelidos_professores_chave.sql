-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: apelidos_professores_chave; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX apelidos_professores_chave ON tech2d.apelidos_professores USING btree (chave_normalizada);

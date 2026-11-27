-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limpezas_anuais_agenda_executada_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX limpezas_anuais_agenda_executada_idx ON tech2d.limpezas_anuais_agenda USING btree (executada_em DESC);

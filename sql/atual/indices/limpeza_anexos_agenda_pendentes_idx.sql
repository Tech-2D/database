-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: limpeza_anexos_agenda_pendentes_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX limpeza_anexos_agenda_pendentes_idx ON tech2d.limpeza_anexos_agenda USING btree (tentar_apos, chave_arquivo);

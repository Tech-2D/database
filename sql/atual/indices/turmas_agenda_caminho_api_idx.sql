-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: turmas_agenda_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX turmas_agenda_caminho_api_idx ON tech2d.turmas_agenda USING btree (tech2d.referencia_api('agendaClasses'::character varying, ''::character varying, referencia_api));

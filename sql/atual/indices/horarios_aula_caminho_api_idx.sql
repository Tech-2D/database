-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: horarios_aula_caminho_api_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX horarios_aula_caminho_api_idx ON tech2d.horarios_aula USING btree (tech2d.referencia_api('schedules'::character varying, ''::character varying, id_horario_aula));

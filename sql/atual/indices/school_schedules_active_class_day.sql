-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: school_schedules_active_class_day; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX school_schedules_active_class_day ON tech2d.horarios_aula USING btree (id_turma, dia_semana) WHERE ativo;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: faixas_horario school_time_slots_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.faixas_horario
    ADD CONSTRAINT school_time_slots_pkey PRIMARY KEY (id_faixa_horario);

-- Name: faixas_horario school_time_slots_start_time_end_time_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.faixas_horario
    ADD CONSTRAINT school_time_slots_start_time_end_time_key UNIQUE (hora_inicio, hora_fim);

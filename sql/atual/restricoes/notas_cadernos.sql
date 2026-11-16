-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_cadernos notas_cadernos_id_usuario_ano_letivo_ano_serie_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_cadernos
    ADD CONSTRAINT notas_cadernos_id_usuario_ano_letivo_ano_serie_key UNIQUE (id_usuario, ano_letivo, ano_serie);

-- Name: notas_cadernos notas_cadernos_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.notas_cadernos
    ADD CONSTRAINT notas_cadernos_pkey PRIMARY KEY (id_usuario, ano_letivo);

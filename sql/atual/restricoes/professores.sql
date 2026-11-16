-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: professores school_teachers_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.professores
    ADD CONSTRAINT school_teachers_name_key UNIQUE (nome);

-- Name: professores school_teachers_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.professores
    ADD CONSTRAINT school_teachers_pkey PRIMARY KEY (id_professor);

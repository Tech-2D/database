-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: disciplinas school_subjects_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas
    ADD CONSTRAINT school_subjects_name_key UNIQUE (nome);

-- Name: disciplinas school_subjects_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.disciplinas
    ADD CONSTRAINT school_subjects_pkey PRIMARY KEY (id_disciplina);

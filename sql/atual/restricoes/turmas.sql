-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: turmas school_classes_name_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT school_classes_name_key UNIQUE (nome);

-- Name: turmas school_classes_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT school_classes_pkey PRIMARY KEY (id_turma);

-- Name: turmas turmas_referencia_agenda_key; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.turmas
    ADD CONSTRAINT turmas_referencia_agenda_key UNIQUE (referencia_agenda);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_turma_perfil vinculos_turma_perfil_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.vinculos_turma_perfil
    ADD CONSTRAINT vinculos_turma_perfil_pkey PRIMARY KEY (firebase_uid);

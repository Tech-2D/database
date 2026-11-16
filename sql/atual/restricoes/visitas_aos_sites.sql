-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visitas_aos_sites visitas_aos_sites_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.visitas_aos_sites
    ADD CONSTRAINT visitas_aos_sites_pkey PRIMARY KEY (site, dia, intervalo_meia_hora, tipo_visitante, chave_visitante);

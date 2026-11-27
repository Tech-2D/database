-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: aulas_recuperacao aulas_recuperacao_pkey; Type: CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.aulas_recuperacao
    ADD CONSTRAINT aulas_recuperacao_pkey PRIMARY KEY (edital_id, ordem);

-- Name: aulas_recuperacao aulas_recuperacao_edital_id_fkey; Type: FK CONSTRAINT; Schema: tech2d; Owner: -
--

ALTER TABLE ONLY tech2d.aulas_recuperacao
    ADD CONSTRAINT aulas_recuperacao_edital_id_fkey FOREIGN KEY (edital_id) REFERENCES tech2d.editais_recuperacao(id);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_recuperacoes leitura_backup; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY leitura_backup ON tech2d.notas_recuperacoes FOR SELECT TO tech2d_backup USING (true);

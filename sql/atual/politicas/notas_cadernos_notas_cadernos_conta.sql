-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_cadernos notas_cadernos_conta; Type: POLICY; Schema: tech2d; Owner: -
--

CREATE POLICY notas_cadernos_conta ON tech2d.notas_cadernos USING (((id_usuario)::text = current_setting('tech2d.uid'::text, true))) WITH CHECK (((id_usuario)::text = current_setting('tech2d.uid'::text, true)));

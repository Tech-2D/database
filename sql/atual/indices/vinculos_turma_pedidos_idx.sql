-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_turma_pedidos_idx; Type: INDEX; Schema: tech2d; Owner: -
--

CREATE INDEX vinculos_turma_pedidos_idx ON tech2d.vinculos_turma_perfil USING btree (pedido_em, firebase_uid) WHERE (pedido_em IS NOT NULL);

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: horarios_aula vincular_disciplina_notaki; Type: TRIGGER; Schema: tech2d; Owner: -
--

CREATE TRIGGER vincular_disciplina_notaki AFTER INSERT OR UPDATE OF id_turma, id_disciplina, ativo ON tech2d.horarios_aula FOR EACH ROW WHEN (new.ativo) EXECUTE FUNCTION tech2d.vincular_nova_disciplina_notaki();

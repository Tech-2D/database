-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_turmas_agenda(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_turmas_agenda(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.turmas_agenda (versao,atualizado_em,referencia_api,id_turma_agenda,id_turma,ativa,referencia_pedido,aprovada_em) VALUES (1,now(),chave_api,alvo,tech2d.resolver_turma(objeto->>'name'),(objeto->>'active')::boolean,objeto->>'requestId',objeto->>'approvedAt')
  ON CONFLICT(id_turma_agenda) DO UPDATE SET versao=turmas_agenda.versao+1, atualizado_em=excluded.atualizado_em, id_turma=excluded.id_turma, ativa=excluded.ativa, referencia_pedido=excluded.referencia_pedido, aprovada_em=excluded.aprovada_em;
END $$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_participantes_kanban(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_participantes_kanban(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.participantes_kanban (versao,atualizado_em,referencia_api,id_participante_kanban,referencia_quadro,id_usuario,email,nome,criado_em) VALUES (1,now(),chave_api,alvo,objeto->>'boardId',objeto->>'userId',objeto->>'userEmail',objeto->>'name',objeto->>'createdAt')
  ON CONFLICT(id_participante_kanban) DO UPDATE SET versao=participantes_kanban.versao+1, atualizado_em=excluded.atualizado_em, referencia_quadro=excluded.referencia_quadro, id_usuario=excluded.id_usuario, email=excluded.email, nome=excluded.nome, criado_em=excluded.criado_em;
END $$;

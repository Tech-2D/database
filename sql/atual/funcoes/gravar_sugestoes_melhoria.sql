-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: gravar_sugestoes_melhoria(bigint, jsonb, character varying, boolean, character varying, bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.gravar_sugestoes_melhoria(alvo bigint, objeto jsonb, chave_api character varying, compartilhado_api boolean, pai_api character varying, id_pai_api bigint) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  INSERT INTO tech2d.sugestoes_melhoria (versao,atualizado_em,referencia_api,id_sugestao_melhoria,mensagem,id_turma,criado_por,email_criador,criado_em,credito_autorizado,nome_credito,situacao,concluida_em,concluida_por) VALUES (1,now(),chave_api,alvo,objeto->>'message',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'publicCreditAllowed')::boolean,objeto->>'publicCreditName',objeto->>'status',objeto->>'completedAt',objeto->>'completedBy')
  ON CONFLICT(id_sugestao_melhoria) DO UPDATE SET versao=sugestoes_melhoria.versao+1, atualizado_em=excluded.atualizado_em, mensagem=excluded.mensagem, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, credito_autorizado=excluded.credito_autorizado, nome_credito=excluded.nome_credito, situacao=excluded.situacao, concluida_em=excluded.concluida_em, concluida_por=excluded.concluida_por;
END $$;

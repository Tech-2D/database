-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_perfis_administrativos(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_perfis_administrativos(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'role', d.papel,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdAt', d.criado_em

  ))

  FROM tech2d.perfis_administrativos d WHERE d.id_perfil_administrativo=alvo;

$$;

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_perfis(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_perfis(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'displayName', d.nome,

    'company', d.empresa,

    'className', d.turma_informada,

    'room', d.sala,

    'floor', d.andar,

    'photoUrl', d.url_foto,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.perfis d WHERE d.id_perfil=alvo AND d.versao IS NOT NULL;

$$;

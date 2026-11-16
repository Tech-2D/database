-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: ler_participantes_kanban(bigint); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.ler_participantes_kanban(alvo bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(
    'boardId', d.referencia_quadro,
    'userId', d.id_usuario,
    'userEmail', d.email,
    'name', d.nome,
    'createdAt', d.criado_em
  ))
  FROM tech2d.participantes_kanban d WHERE d.id_participante_kanban=alvo;
$$;

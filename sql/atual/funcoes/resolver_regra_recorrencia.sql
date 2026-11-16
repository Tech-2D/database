-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: resolver_regra_recorrencia(text); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.resolver_regra_recorrencia(valor text) RETURNS bigint
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE alvo bigint;
BEGIN
  IF valor IS NULL THEN RETURN NULL; END IF;
  SELECT id_regra_recorrencia INTO alvo FROM tech2d.regras_recorrencia WHERE referencia_api=valor;
  IF alvo IS NULL THEN RAISE EXCEPTION 'Regra de recorrência inexistente' USING ERRCODE='23503'; END IF;
  RETURN alvo;
END
$$;

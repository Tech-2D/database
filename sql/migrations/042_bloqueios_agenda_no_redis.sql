-- Deploy Redis-backed moderation before removing SQL storage.
DO $$
BEGIN
  IF EXISTS (SELECT FROM tech2d.bloqueios_agenda) THEN
    RAISE EXCEPTION 'Há bloqueios SQL a migrar antes da remoção';
  END IF;
END;
$$;
DROP VIEW tech2d.visao_bloqueios_agenda;
DROP TABLE tech2d.bloqueios_agenda;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:042_bloqueios_agenda_no_redis';

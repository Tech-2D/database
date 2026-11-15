-- Apenas renomeia objetos: preserva registros, vínculos, permissões e isolamento por conta.
SELECT pg_advisory_xact_lock(hashtext('tech2d-notas-structure'));
ALTER TABLE tech2d.pegaki_cadernos RENAME TO notas_cadernos;
ALTER TABLE tech2d.pegaki_notas RENAME TO notas_lancamentos;
ALTER TABLE tech2d.pegaki_recuperacoes RENAME TO notas_recuperacoes;
ALTER VIEW tech2d.visao_disciplinas_pegaki RENAME TO visao_disciplinas_notas;
ALTER VIEW tech2d.visao_pegaki_resultados RENAME TO visao_notas_resultados;
DO $rename$
DECLARE obj record; novo varchar(128);
BEGIN
  FOR obj IN SELECT c.conname, r.relname FROM pg_constraint c JOIN pg_class r ON r.oid=c.conrelid JOIN pg_namespace n ON n.oid=r.relnamespace WHERE n.nspname='tech2d' AND c.conname LIKE '%pegaki%' LOOP
    novo:=replace(replace(obj.conname,'pegaki_notas','notas_lancamentos'),'pegaki','notas');
    EXECUTE format('ALTER TABLE tech2d.%I RENAME CONSTRAINT %I TO %I',obj.relname,obj.conname,novo);
  END LOOP;
  FOR obj IN SELECT tablename,policyname FROM pg_policies WHERE schemaname='tech2d' AND policyname LIKE '%pegaki%' LOOP
    novo:=replace(replace(obj.policyname,'pegaki_notas','notas_lancamentos'),'pegaki','notas');
    EXECUTE format('ALTER POLICY %I ON tech2d.%I RENAME TO %I',obj.policyname,obj.tablename,novo);
  END LOOP;
  FOR obj IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='tech2d' AND c.relkind='i' AND c.relname LIKE '%pegaki%' LOOP
    novo:=replace(replace(obj.relname,'pegaki_notas','notas_lancamentos'),'pegaki','notas');
    EXECUTE format('ALTER INDEX tech2d.%I RENAME TO %I',obj.relname,novo);
  END LOOP;
  FOR obj IN SELECT c.relname,c.relkind,obj_description(c.oid,'pg_class') AS descricao FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='tech2d' AND c.relkind IN ('r','v') AND obj_description(c.oid,'pg_class') ILIKE '%pegaki%' LOOP
    EXECUTE format('COMMENT ON %s tech2d.%I IS %L',CASE WHEN obj.relkind='v' THEN 'VIEW' ELSE 'TABLE' END,obj.relname,regexp_replace(regexp_replace(obj.descricao,'O Pegaki','A área de Notas','g'),'pegaki','Notas','gi'));
  END LOOP;
END
$rename$;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:045_nomenclatura_notas';

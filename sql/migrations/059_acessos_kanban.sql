ALTER TABLE tech2d.visitas_aos_sites
  DROP CONSTRAINT visitas_aos_sites_site_check,
  ADD CONSTRAINT visitas_aos_sites_site_check
    CHECK (site IN ('agenda', 'professores', 'pegaki', 'kanban'));

COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:059_acessos_kanban';

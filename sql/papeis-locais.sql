-- Apenas para desenvolvimento local. Sem senhas ou permissões de login.
-- Os nomes são referenciados nos GRANT do snapshot de produção.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_api') THEN
    CREATE ROLE tech2d_api NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'assistente_ia_readonly') THEN
    CREATE ROLE assistente_ia_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_prod_ai_reader') THEN
    CREATE ROLE tech2d_prod_ai_reader NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_prod_ai_quota') THEN
    CREATE ROLE tech2d_prod_ai_quota NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_qa_ai_quota') THEN
    CREATE ROLE tech2d_qa_ai_quota NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tech2d_backup') THEN
    CREATE ROLE tech2d_backup NOLOGIN;
  END IF;
END;
$$;

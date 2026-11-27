-- Permissões provisionadas junto aos serviços, fora das migrações da API.
-- A referência local cria os papéis sem login.
GRANT USAGE ON SCHEMA tech2d TO assistente_ia_readonly;
GRANT SELECT, INSERT ON tech2d.recibos_gravacao, tech2d.visao_recibos_gravacao TO tech2d_api;
GRANT SELECT, INSERT, UPDATE ON tech2d.uso_diario_assistente TO tech2d_qa_ai_quota;

GRANT USAGE ON SCHEMA tech2d TO tech2d_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA tech2d TO tech2d_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA tech2d TO tech2d_backup;

CREATE POLICY leitura_backup ON tech2d.notas_cadernos FOR SELECT TO tech2d_backup USING (true);
CREATE POLICY leitura_backup ON tech2d.notas_lancamentos FOR SELECT TO tech2d_backup USING (true);
CREATE POLICY leitura_backup ON tech2d.notas_recuperacoes FOR SELECT TO tech2d_backup USING (true);

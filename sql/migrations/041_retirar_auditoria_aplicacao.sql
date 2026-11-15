-- Apply after deploying the API without auditing writes.
DROP VIEW tech2d.visao_auditoria_aplicacao;
DROP FUNCTION tech2d.inserir_auditoria(), tech2d.ler_valor_historico(bigint),
  tech2d.gravar_valor_historico(bigint,bigint,character varying,integer,jsonb);
DROP TABLE tech2d.valores_historico, tech2d.auditoria_aplicacao;
COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:041_retirar_auditoria_aplicacao';

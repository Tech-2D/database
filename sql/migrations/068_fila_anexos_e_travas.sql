-- Chaves imutáveis do R2 que foram desvinculadas em uma transação confirmada.
CREATE TABLE tech2d.limpeza_anexos_agenda (
  chave_arquivo text PRIMARY KEY,
  tentar_apos timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX limpeza_anexos_agenda_pendentes_idx
  ON tech2d.limpeza_anexos_agenda (tentar_apos, chave_arquivo);
COMMENT ON TABLE tech2d.limpeza_anexos_agenda IS 'Fila de limpeza de anexos R2 desvinculados pelo expurgo e por recorrências.';
REVOKE ALL ON tech2d.limpeza_anexos_agenda FROM PUBLIC;

-- Lotes mistos travam Agenda e Kanban, sempre nesta ordem.
CREATE FUNCTION tech2d.travar_gravacao(caminhos text[]) RETURNS void
LANGUAGE plpgsql
SET search_path TO 'pg_catalog'
AS $lock$
DECLARE
  inclui_kanban boolean;
  inclui_agenda boolean;
BEGIN
  SELECT coalesce(bool_or(kanban), false), coalesce(bool_or(NOT kanban), true)
  INTO inclui_kanban, inclui_agenda
  FROM (
    SELECT coalesce(split_part(caminho,'/',1) IN
      ('personalKanban','sharedKanban','kanbanMemberships','kanbanRequests'), false) AS kanban
    FROM unnest(caminhos) AS caminho
  ) escopos;
  IF inclui_agenda THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
  END IF;
  IF inclui_kanban THEN
    PERFORM pg_advisory_xact_lock(hashtext('tech2d-kanban-commit'));
  END IF;
END
$lock$;

REVOKE ALL ON FUNCTION tech2d.travar_gravacao(text[]) FROM PUBLIC;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tech2d_api') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON tech2d.limpeza_anexos_agenda TO tech2d_api;
    GRANT EXECUTE ON FUNCTION tech2d.travar_gravacao(text[]) TO tech2d_api;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION tech2d.gravar_registros(lote jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  item record;
  partes text[];
  grupo varchar(40);
  pai varchar(320);
  chave varchar(320);
  tabela name;
  coluna_id name;
  alvo bigint;
  id_pai bigint;
  espaco_compartilhado boolean;
BEGIN
  PERFORM tech2d.travar_gravacao(ARRAY(SELECT item_lote->>'path' FROM jsonb_array_elements(lote) AS item_lote));
  FOR item IN SELECT r.path,r.data FROM jsonb_to_recordset(lote) AS r(path text,data jsonb)
    ORDER BY (data IS NULL), CASE WHEN path LIKE 'recurringActivities/%' THEN 0 ELSE 1 END,length(path),path
  LOOP
    partes := string_to_array(item.path,'/');
    IF cardinality(partes) <> 2 OR array_position(partes,'') IS NOT NULL THEN
      RAISE EXCEPTION 'ReferÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âªncia invÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡lida' USING ERRCODE='23514';
    END IF;
    grupo := partes[1]; pai := ''; chave := partes[2]; id_pai := NULL;
    CASE grupo
      WHEN 'activities' THEN tabela := 'atividades'; coluna_id := 'id_atividade';
      WHEN 'admins' THEN tabela := 'perfis_administrativos'; coluna_id := 'id_perfil_administrativo';
      WHEN 'recurringActivities' THEN tabela := 'regras_recorrencia'; coluna_id := 'id_regra_recorrencia';
      WHEN 'activityRetention' THEN tabela := 'regras_retencao'; coluna_id := 'id_regra_retencao';
      WHEN 'agendaClasses' THEN tabela := 'turmas_agenda'; coluna_id := 'id_turma_agenda';
      WHEN 'feedback' THEN tabela := 'sugestoes_melhoria'; coluna_id := 'id_sugestao_melhoria';
      WHEN 'schedules' THEN tabela := 'horarios_aula'; coluna_id := 'id_horario_interno';
      WHEN 'userProfiles' THEN tabela := 'perfis'; coluna_id := 'id_perfil';
      WHEN '_agendaDigestPreferences' THEN tabela := 'perfis'; coluna_id := 'id_perfil';
      WHEN 'personalKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      WHEN 'kanbanMemberships' THEN tabela := 'participantes_kanban'; coluna_id := 'id_participante_kanban';
      WHEN 'sharedKanban' THEN tabela := 'espacos_kanban'; coluna_id := 'id_espaco_kanban';
      ELSE RAISE EXCEPTION 'Recurso descontinuado ou desconhecido' USING ERRCODE='23514';
    END CASE;
    espaco_compartilhado := grupo='sharedKanban';
    IF tabela='espacos_kanban' THEN
      SELECT id_espaco_kanban INTO alvo FROM tech2d.espacos_kanban AS e
      WHERE e.compartilhado=espaco_compartilhado AND e.referencia_api=chave;
    ELSIF grupo='schedules' THEN
      SELECT id_horario_interno INTO alvo FROM tech2d.horarios_aula WHERE id_horario_aula=chave;
    ELSE
      EXECUTE format('SELECT %I FROM tech2d.%I WHERE referencia_api=$1',coluna_id,tabela) INTO alvo USING chave;
    END IF;
    IF item.data IS NULL THEN
      IF alvo IS NOT NULL THEN
        IF grupo='userProfiles' AND EXISTS(SELECT 1 FROM tech2d.perfis WHERE id_perfil=alvo AND resumo_versao IS NOT NULL) THEN
          UPDATE tech2d.perfis SET nome=NULL,empresa=NULL,turma_informada=NULL,sala=NULL,andar=NULL,url_foto=NULL,alterado_em=NULL,versao=NULL,atualizado_em=NULL WHERE id_perfil=alvo;
        ELSIF grupo='_agendaDigestPreferences' AND EXISTS(SELECT 1 FROM tech2d.perfis WHERE id_perfil=alvo AND versao IS NOT NULL) THEN
          UPDATE tech2d.perfis SET resumo_semanal_ativo=NULL,id_turma_resumo=NULL,resumo_alterado_em_ms=NULL,resumo_versao=NULL,resumo_atualizado_em=NULL WHERE id_perfil=alvo;
        ELSE
          EXECUTE format('DELETE FROM tech2d.%I WHERE %I=$1',tabela,coluna_id) USING alvo;
        END IF;
      END IF;
    ELSE
      IF alvo IS NULL THEN alvo := nextval('tech2d.ids_entidades'); END IF;
      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data,chave,espaco_compartilhado,pai,id_pai);
    END IF;
  END LOOP;
END
$function$;

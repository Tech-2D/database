-- Reutiliza os catálogos de disciplinas e turmas, preservando os rótulos da API.
SELECT pg_advisory_xact_lock(hashtext('tech2d-application-commit'));
ALTER TABLE tech2d.turmas ADD COLUMN referencia_agenda varchar(150) UNIQUE;
COMMENT ON COLUMN tech2d.turmas.referencia_agenda IS 'Identificador textual estável da turma na Agenda, como 2° TECH D. É guardado uma única vez; os vínculos das tabelas usam id_turma.';

CREATE FUNCTION tech2d.normalizar_rotulo(valor text) RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE SET search_path=pg_catalog AS $fn$
 SELECT regexp_replace(translate(lower(btrim(valor)),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc'),'[^a-z0-9]','','g')::varchar;
$fn$;
CREATE FUNCTION tech2d.chave_turma(valor text) RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE SET search_path=pg_catalog AS $fn$
 SELECT tech2d.normalizar_rotulo(regexp_replace(replace(upper(valor),'TECH','TEC'),'\mANO\M','','g'));
$fn$;
CREATE FUNCTION tech2d.buscar_id_turma(valor text) RETURNS bigint
LANGUAGE sql STABLE STRICT SET search_path=pg_catalog AS $fn$
 SELECT id_turma FROM tech2d.turmas WHERE referencia_agenda=valor OR nome=valor
 ORDER BY (referencia_agenda=valor) DESC NULLS LAST LIMIT 1;
$fn$;
CREATE FUNCTION tech2d.resolver_turma(valor text, agenda boolean DEFAULT true) RETURNS bigint
LANGUAGE plpgsql SET search_path=pg_catalog AS $fn$
DECLARE alvo bigint; ids bigint[]; canonico varchar(150);
BEGIN
 IF valor IS NULL THEN RETURN NULL; END IF;
 IF btrim(valor)='' OR length(valor)>150 THEN RAISE EXCEPTION 'Turma inválida' USING ERRCODE='23514'; END IF;
 alvo:=tech2d.buscar_id_turma(valor);
 IF alvo IS NULL THEN
  SELECT array_agg(id_turma) INTO ids FROM tech2d.turmas WHERE tech2d.chave_turma(nome)=tech2d.chave_turma(valor);
  IF cardinality(ids)>1 THEN RAISE EXCEPTION 'Turma ambígua no catálogo' USING ERRCODE='23514'; END IF;
  alvo:=ids[1];
 END IF;
 IF alvo IS NULL THEN
  canonico:=valor;
  IF upper(valor) ~ '^[123][°º] TECH ' THEN canonico:=regexp_replace(valor,'^([123])[°º] TECH ','\1º Tec ','i'); END IF;
  INSERT INTO tech2d.turmas(nome) VALUES(canonico) ON CONFLICT(nome) DO UPDATE SET nome=excluded.nome RETURNING id_turma INTO alvo;
 END IF;
 IF agenda THEN UPDATE tech2d.turmas SET referencia_agenda=valor WHERE id_turma=alvo AND referencia_agenda IS NULL; END IF;
 RETURN alvo;
END $fn$;
CREATE FUNCTION tech2d.nome_turma_agenda(alvo bigint) RETURNS varchar
LANGUAGE sql STABLE STRICT SET search_path=pg_catalog AS $fn$
 SELECT coalesce(referencia_agenda,nome)::varchar FROM tech2d.turmas WHERE id_turma=alvo;
$fn$;
CREATE FUNCTION tech2d.nome_disciplina_agenda(alvo bigint) RETURNS varchar
LANGUAGE sql STABLE STRICT SET search_path=pg_catalog AS $fn$
 SELECT coalesce((SELECT v.nome FROM tech2d.visao_disciplinas_notas v WHERE v.id=d.id_disciplina ORDER BY v.ano_serie DESC LIMIT 1),d.nome)::varchar
 FROM tech2d.disciplinas d WHERE d.id_disciplina=alvo;
$fn$;
CREATE FUNCTION tech2d.resolver_disciplina(valor text) RETURNS bigint
LANGUAGE plpgsql SET search_path=pg_catalog AS $fn$
DECLARE alvo bigint; ids bigint[];
BEGIN
 IF valor IS NULL THEN RETURN NULL; END IF;
 IF btrim(valor)='' OR length(valor)>150 THEN RAISE EXCEPTION 'Disciplina inválida' USING ERRCODE='23514'; END IF;
 SELECT id_disciplina INTO alvo FROM tech2d.disciplinas WHERE nome=valor;
 IF alvo IS NULL THEN SELECT id INTO alvo FROM tech2d.visao_disciplinas_notas WHERE nome=valor ORDER BY ano_serie DESC LIMIT 1; END IF;
 IF alvo IS NULL THEN
  SELECT array_agg(id_disciplina) INTO ids FROM tech2d.disciplinas WHERE tech2d.normalizar_rotulo(nome)=tech2d.normalizar_rotulo(valor);
  IF cardinality(ids)>1 THEN RAISE EXCEPTION 'Disciplina ambígua no catálogo' USING ERRCODE='23514'; END IF;
  alvo:=ids[1];
 END IF;
 IF alvo IS NULL THEN INSERT INTO tech2d.disciplinas(nome) VALUES(valor) ON CONFLICT(nome) DO UPDATE SET nome=excluded.nome RETURNING id_disciplina INTO alvo; END IF;
 RETURN alvo;
END $fn$;
CREATE FUNCTION tech2d.resolver_referencia_entidade(tipo_entidade varchar, valor text) RETURNS bigint
LANGUAGE plpgsql STABLE SET search_path=pg_catalog AS $fn$
DECLARE alvo bigint;
BEGIN
 IF valor IS NULL THEN RETURN NULL; END IF;
 SELECT id_registro INTO alvo FROM tech2d.registros_aplicacao WHERE tipo=tipo_entidade AND referencia=valor AND referencia_pai='';
 IF alvo IS NULL THEN RAISE EXCEPTION 'Registro relacionado inexistente' USING ERRCODE='23503'; END IF;
 RETURN alvo;
END $fn$;
CREATE FUNCTION tech2d.referencia_entidade(alvo bigint) RETURNS varchar
LANGUAGE sql STABLE STRICT SET search_path=pg_catalog AS $fn$
 SELECT referencia FROM tech2d.registros_aplicacao WHERE id_registro=alvo;
$fn$;
SELECT tech2d.resolver_turma('2° TECH D',true);
SELECT tech2d.resolver_turma('2° TECH E',true);
SELECT tech2d.resolver_turma('2° TECH F',true);
SELECT tech2d.resolver_turma('2° TECH G',true);
SELECT tech2d.resolver_turma('2° TECH H',true);
SELECT tech2d.resolver_turma('2° TECH I',true);
SELECT tech2d.resolver_turma('3° TECH AD H',true);
SELECT tech2d.resolver_turma('3° TECH AD I',true);
SELECT tech2d.resolver_turma('3° TECH DS E',true);
SELECT tech2d.resolver_turma('3° TECH DS F',true);
SELECT tech2d.resolver_turma('3° TECH DS G',true);
-- Une somente duplicatas de rótulo. Notas em dois IDs diferentes exigem revisão explícita.
DO $merge$
DECLARE grupo record; duplicada record; canonica bigint;
BEGIN
 FOR grupo IN SELECT tech2d.normalizar_rotulo(nome) AS chave FROM tech2d.disciplinas GROUP BY tech2d.normalizar_rotulo(nome) HAVING count(*)>1 LOOP
  SELECT d.id_disciplina INTO canonica FROM tech2d.disciplinas d WHERE tech2d.normalizar_rotulo(d.nome)=grupo.chave
  ORDER BY (SELECT count(*) FROM tech2d.notas_lancamentos n WHERE n.id_disciplina=d.id_disciplina) DESC,
   (SELECT count(*) FROM tech2d.disciplinas_series x WHERE x.id_disciplina=d.id_disciplina) DESC,
   (SELECT count(*) FROM tech2d.horarios_aula h WHERE h.id_disciplina=d.id_disciplina) DESC,d.id_disciplina LIMIT 1;
  FOR duplicada IN SELECT id_disciplina FROM tech2d.disciplinas WHERE tech2d.normalizar_rotulo(nome)=grupo.chave AND id_disciplina<>canonica LOOP
   IF EXISTS(SELECT FROM tech2d.notas_lancamentos WHERE id_disciplina=duplicada.id_disciplina) OR EXISTS(SELECT FROM tech2d.notas_recuperacoes WHERE id_disciplina=duplicada.id_disciplina) THEN
    RAISE EXCEPTION 'Duplicata com notas exige revisão antes da unificação' USING ERRCODE='23514';
   END IF;
   UPDATE tech2d.horarios_aula SET id_disciplina=canonica WHERE id_disciplina=duplicada.id_disciplina;
   INSERT INTO tech2d.disciplinas_series(id_disciplina,ano_serie) SELECT canonica,ano_serie FROM tech2d.disciplinas_series WHERE id_disciplina=duplicada.id_disciplina ON CONFLICT DO NOTHING;
   DELETE FROM tech2d.disciplinas_series WHERE id_disciplina=duplicada.id_disciplina;
   DELETE FROM tech2d.disciplinas WHERE id_disciplina=duplicada.id_disciplina;
  END LOOP;
  IF grupo.chave='linguainglesa' THEN UPDATE tech2d.disciplinas SET nome='Língua Inglesa' WHERE id_disciplina=canonica; END IF;
 END LOOP;
END
$merge$;
ALTER TABLE tech2d.atividades ADD COLUMN id_disciplina bigint REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;
UPDATE tech2d.atividades SET id_disciplina=tech2d.resolver_disciplina(nome_disciplina);
CREATE INDEX atividades_disciplina_idx ON tech2d.atividades(id_disciplina);
ALTER TABLE tech2d.regras_recorrencia ADD COLUMN id_disciplina bigint REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;
UPDATE tech2d.regras_recorrencia SET id_disciplina=tech2d.resolver_disciplina(nome_disciplina);
CREATE INDEX regras_recorrencia_disciplina_idx ON tech2d.regras_recorrencia(id_disciplina);
ALTER TABLE tech2d.sugestoes_atividade ADD COLUMN id_disciplina bigint REFERENCES tech2d.disciplinas(id_disciplina) ON DELETE RESTRICT;
UPDATE tech2d.sugestoes_atividade SET id_disciplina=tech2d.resolver_disciplina(nome_disciplina);
CREATE INDEX sugestoes_atividade_disciplina_idx ON tech2d.sugestoes_atividade(id_disciplina);
ALTER TABLE tech2d.atividades ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.atividades SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX atividades_turma_idx ON tech2d.atividades(id_turma);
ALTER TABLE tech2d.regras_recorrencia ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.regras_recorrencia SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX regras_recorrencia_turma_idx ON tech2d.regras_recorrencia(id_turma);
ALTER TABLE tech2d.regras_retencao ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.regras_retencao SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX regras_retencao_turma_idx ON tech2d.regras_retencao(id_turma);
ALTER TABLE tech2d.sugestoes_atividade ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.sugestoes_atividade SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX sugestoes_atividade_turma_idx ON tech2d.sugestoes_atividade(id_turma);
ALTER TABLE tech2d.sugestoes_melhoria ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.sugestoes_melhoria SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX sugestoes_melhoria_turma_idx ON tech2d.sugestoes_melhoria(id_turma);
ALTER TABLE tech2d.pedidos_representacao ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.pedidos_representacao SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX pedidos_representacao_turma_idx ON tech2d.pedidos_representacao(id_turma);
ALTER TABLE tech2d.perfis_administrativos ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.perfis_administrativos SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX perfis_administrativos_turma_idx ON tech2d.perfis_administrativos(id_turma);
ALTER TABLE tech2d.preferencias_resumo ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.preferencias_resumo SET id_turma=tech2d.resolver_turma(nome_turma,true);
CREATE INDEX preferencias_resumo_turma_idx ON tech2d.preferencias_resumo(id_turma);
ALTER TABLE tech2d.turmas_agenda ADD COLUMN id_turma bigint REFERENCES tech2d.turmas(id_turma) ON DELETE RESTRICT;
UPDATE tech2d.turmas_agenda SET id_turma=tech2d.resolver_turma(nome,true);
CREATE INDEX turmas_agenda_turma_idx ON tech2d.turmas_agenda(id_turma);
ALTER TABLE tech2d.turmas_agenda ADD UNIQUE(id_turma);
ALTER TABLE tech2d.atividades ADD COLUMN id_regra_recorrencia bigint REFERENCES tech2d.regras_recorrencia(id_regra_recorrencia) ON DELETE SET NULL;
UPDATE tech2d.atividades SET id_regra_recorrencia=tech2d.resolver_referencia_entidade('recurringActivities',referencia_recorrencia);
CREATE INDEX atividades_regra_recorrencia_idx ON tech2d.atividades(id_regra_recorrencia);
ALTER TABLE tech2d.envios_anexos ADD COLUMN id_atividade bigint REFERENCES tech2d.atividades(id_atividade) ON DELETE SET NULL;
UPDATE tech2d.envios_anexos SET id_atividade=tech2d.resolver_referencia_entidade('activities',referencia_atividade);
CREATE INDEX envios_anexos_atividade_idx ON tech2d.envios_anexos(id_atividade);

CREATE OR REPLACE FUNCTION tech2d.consultar_catalogo_agenda(p_turma text, p_incluir_atividades boolean)
 RETURNS TABLE(activities jsonb, documents jsonb)
 LANGUAGE sql
 SECURITY DEFINER
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  WITH atividades_selecionadas AS (

    SELECT v.*
    FROM tech2d.atividades filtro
    JOIN tech2d.registros_aplicacao reg ON reg.id_registro=filtro.id_atividade
    JOIN tech2d.visao_atividades v ON v.id=reg.referencia

    WHERE p_incluir_atividades

      AND (p_turma IS NULL OR filtro.id_turma = tech2d.buscar_id_turma(p_turma) OR filtro.id_turma IS NULL)

    ORDER BY date, time, id

    LIMIT 10001

  ), documentos_selecionados AS (

    SELECT collection, id, data

    FROM tech2d.visao_documentos_catalogo

    WHERE collection = 'agendaClasses'

    ORDER BY id

    LIMIT 10001

  )

  SELECT

    coalesce((SELECT jsonb_agg(

      to_jsonb(a) || jsonb_build_object('version', a.version::text)

      ORDER BY a.date, a.time, a.id

    ) FROM atividades_selecionadas a), '[]'::jsonb),

    coalesce((SELECT jsonb_agg(

      to_jsonb(d) ORDER BY d.id

    ) FROM documentos_selecionados d), '[]'::jsonb);

$function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_atividades(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.atividades (id_atividade,titulo,descricao,tipo_atividade,id_disciplina,data_atividade,hora_atividade,id_turma,criado_por,email_criador,id_regra_recorrencia,criado_em,alterado_em) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'date')::date,(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',tech2d.resolver_referencia_entidade('recurringActivities',objeto->>'recurringId'),objeto->>'createdAt',objeto->>'updatedAt')

  ON CONFLICT(id_atividade) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, id_regra_recorrencia=excluded.id_regra_recorrencia, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em;

  DELETE FROM tech2d.anexos_atividade WHERE id_atividade=alvo;

  IF jsonb_typeof(objeto->'attachments')='array' THEN

    PERFORM tech2d.inserir_anexos_atividade(alvo,(pos-1)::integer,value)

    FROM jsonb_array_elements(objeto->'attachments') WITH ORDINALITY AS x(value,pos);

  END IF;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_envios_anexos(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.envios_anexos (id_envio_anexo,id_atividade,nome,tipo_mime,tamanho_bytes,chave_arquivo,id_usuario,criado_em_ms) VALUES (alvo,tech2d.resolver_referencia_entidade('activities',objeto->>'activityId'),objeto->>'name',objeto->>'contentType',(objeto->>'size')::bigint,objeto->>'key',objeto->>'uid',(objeto->>'createdAt')::bigint)

  ON CONFLICT(id_envio_anexo) DO UPDATE SET id_atividade=excluded.id_atividade, nome=excluded.nome, tipo_mime=excluded.tipo_mime, tamanho_bytes=excluded.tamanho_bytes, chave_arquivo=excluded.chave_arquivo, id_usuario=excluded.id_usuario, criado_em_ms=excluded.criado_em_ms;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_horarios_aula(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

DECLARE

  chave varchar(320);

  inicio time;

  fim time;
  turma_catalogo bigint;
  disciplina_catalogo bigint;

BEGIN

  SELECT referencia INTO STRICT chave FROM tech2d.registros_aplicacao WHERE id_registro=alvo;

  IF ((objeto->>'startTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'

    AND (objeto->>'endTime') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'

    AND (objeto->>'dayOfWeek') ~ '^[0-6]$'

    AND jsonb_typeof(objeto->'active')='boolean') IS DISTINCT FROM true THEN

    RAISE EXCEPTION 'Invalid schedule projection' USING ERRCODE='check_violation';

  END IF;

  inicio := (objeto->>'startTime')::time;

  fim := (objeto->>'endTime')::time;

  INSERT INTO tech2d.professores(nome) VALUES(objeto->>'professor') ON CONFLICT(nome) DO NOTHING;

  disciplina_catalogo:=tech2d.resolver_disciplina(objeto->>'subject');

  turma_catalogo:=tech2d.resolver_turma(objeto->>'className',false);

  INSERT INTO tech2d.faixas_horario(hora_inicio,hora_fim) VALUES(inicio,fim) ON CONFLICT(hora_inicio,hora_fim) DO NOTHING;



  INSERT INTO tech2d.horarios_aula(id_horario_aula,id_registro_aplicacao,id_professor,id_disciplina,id_turma,id_faixa_horario,dia_semana,ativo,andar,sala,criado_em,alterado_em)

  SELECT chave,alvo,p.id_professor,d.id_disciplina,t.id_turma,f.id_faixa_horario,(objeto->>'dayOfWeek')::smallint,(objeto->>'active')::boolean,

    objeto->>'floor',objeto->>'roomDescription',objeto->>'createdAt',objeto->>'updatedAt'

  FROM tech2d.professores p,tech2d.disciplinas d,tech2d.turmas t,tech2d.faixas_horario f

  WHERE p.nome=objeto->>'professor' AND d.id_disciplina=disciplina_catalogo AND t.id_turma=turma_catalogo

    AND f.hora_inicio=inicio AND f.hora_fim=fim

  ON CONFLICT(id_horario_aula) DO UPDATE SET id_registro_aplicacao=excluded.id_registro_aplicacao,id_professor=excluded.id_professor,

    id_disciplina=excluded.id_disciplina,id_turma=excluded.id_turma,id_faixa_horario=excluded.id_faixa_horario,

    dia_semana=excluded.dia_semana,ativo=excluded.ativo,andar=excluded.andar,sala=excluded.sala,

    criado_em=excluded.criado_em,alterado_em=excluded.alterado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_representacao(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.pedidos_representacao (id_pedido_representacao,id_turma,email,situacao,criado_em,revisado_em) VALUES (alvo,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')

  ON CONFLICT(id_pedido_representacao) DO UPDATE SET id_turma=excluded.id_turma, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_administrativos(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.perfis_administrativos (id_perfil_administrativo,papel,id_turma,criado_em) VALUES (alvo,objeto->>'role',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt')

  ON CONFLICT(id_perfil_administrativo) DO UPDATE SET papel=excluded.papel, id_turma=excluded.id_turma, criado_em=excluded.criado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_preferencias_resumo(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.preferencias_resumo (id_preferencia_resumo,ativo,id_turma,alterada_em_ms) VALUES (alvo,(objeto->>'enabled')::boolean,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'updatedAt')::bigint)

  ON CONFLICT(id_preferencia_resumo) DO UPDATE SET ativo=excluded.ativo, id_turma=excluded.id_turma, alterada_em_ms=excluded.alterada_em_ms;

END $function$
;

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

  alvo bigint;

BEGIN

  FOR item IN SELECT r.path,r.data FROM jsonb_to_recordset(lote) r(path text,data jsonb)

    ORDER BY (data IS NULL),CASE WHEN path LIKE 'recurringActivities/%' THEN 0 ELSE 1 END,length(path),path

  LOOP

    partes := string_to_array(item.path,'/');

    IF cardinality(partes) NOT IN (2,4) OR array_position(partes,'') IS NOT NULL THEN

      RAISE EXCEPTION 'Referência inválida' USING ERRCODE='check_violation';

    END IF;

    grupo := partes[1];

    pai := '';

    chave := partes[2];

    IF cardinality(partes)=4 THEN

      grupo := grupo || '/' || partes[3];

      pai := partes[2];

      chave := partes[4];

    END IF;

    IF grupo IN ('polls','polls/votes','pollVoterAccess','notebookNotes','announcement','purgedActivities','agendaUpdates','boardNotices','representativeChat','representativeInvites') THEN

      RAISE EXCEPTION 'Recurso descontinuado' USING ERRCODE='check_violation';

    END IF;

    IF item.data IS NULL THEN

      DELETE FROM tech2d.registros_aplicacao WHERE tipo=grupo AND referencia_pai=pai AND referencia=chave;

    ELSE

      INSERT INTO tech2d.registros_aplicacao(tipo,referencia_pai,referencia,id_registro_pai)

      VALUES(grupo,pai,chave,(SELECT id_registro FROM tech2d.registros_aplicacao

        WHERE tipo=partes[1] AND referencia_pai='' AND referencia=pai AND pai<>''))

      ON CONFLICT(tipo,referencia_pai,referencia) DO UPDATE

      SET versao=registros_aplicacao.versao+1,atualizado_em=now(),id_registro_pai=excluded.id_registro_pai

      RETURNING id_registro INTO alvo;

      PERFORM tech2d.gravar_conteudo(alvo,grupo,item.data);

      IF pai='' AND grupo='feedback' THEN

        UPDATE tech2d.registros_aplicacao SET id_registro_pai=alvo

        WHERE tipo='feedback/messages'

          AND referencia_pai=chave AND id_registro_pai IS NULL;

      END IF;

    END IF;

  END LOOP;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_recorrencia(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.regras_recorrencia (id_regra_recorrencia,titulo,descricao,tipo_atividade,id_disciplina,hora_atividade,id_turma,criado_por,email_criador,criado_em,data_inicio,data_fim,ativa,excluida,intervalo_semanas,dias_semana) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'startDate')::date,(objeto->>'endDate')::date,(objeto->>'active')::boolean,(objeto->>'deleted')::boolean,(objeto->>'intervalWeeks')::smallint,CASE WHEN jsonb_typeof(objeto->'weekdays')='array' THEN ARRAY(SELECT value::smallint FROM jsonb_array_elements_text(objeto->'weekdays') WITH ORDINALITY AS x(value,pos) ORDER BY pos) END)

  ON CONFLICT(id_regra_recorrencia) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, data_inicio=excluded.data_inicio, data_fim=excluded.data_fim, ativa=excluded.ativa, excluida=excluded.excluida, intervalo_semanas=excluded.intervalo_semanas, dias_semana=excluded.dias_semana;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_regras_retencao(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.regras_retencao (id_regra_retencao,id_turma,dias,ativa,alterado_por,alterado_em) VALUES (alvo,tech2d.resolver_turma(objeto->>'turmaId'),(objeto->>'days')::smallint,(objeto->>'enabled')::boolean,objeto->>'updatedBy',objeto->>'updatedAt')

  ON CONFLICT(id_regra_retencao) DO UPDATE SET id_turma=excluded.id_turma, dias=excluded.dias, ativa=excluded.ativa, alterado_por=excluded.alterado_por, alterado_em=excluded.alterado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_atividade(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.sugestoes_atividade (id_sugestao_atividade,titulo,descricao,tipo_atividade,id_disciplina,data_atividade,hora_atividade,id_turma,criado_em,alterado_em,situacao,resolucao,comentario_revisao,encerrada_em) VALUES (alvo,objeto->>'title',objeto->>'description',objeto->>'type',tech2d.resolver_disciplina(objeto->>'subject'),(objeto->>'date')::date,(objeto->>'time')::time,tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdAt',objeto->>'updatedAt',objeto->>'status',objeto->>'resolution',objeto->>'reviewComment',objeto->>'closedAt')

  ON CONFLICT(id_sugestao_atividade) DO UPDATE SET titulo=excluded.titulo, descricao=excluded.descricao, tipo_atividade=excluded.tipo_atividade, id_disciplina=excluded.id_disciplina, data_atividade=excluded.data_atividade, hora_atividade=excluded.hora_atividade, id_turma=excluded.id_turma, criado_em=excluded.criado_em, alterado_em=excluded.alterado_em, situacao=excluded.situacao, resolucao=excluded.resolucao, comentario_revisao=excluded.comentario_revisao, encerrada_em=excluded.encerrada_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_sugestoes_melhoria(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.sugestoes_melhoria (id_sugestao_melhoria,mensagem,id_turma,criado_por,email_criador,criado_em,credito_autorizado,nome_credito,situacao,concluida_em,concluida_por) VALUES (alvo,objeto->>'message',tech2d.resolver_turma(objeto->>'turmaId'),objeto->>'createdBy',objeto->>'createdByEmail',objeto->>'createdAt',(objeto->>'publicCreditAllowed')::boolean,objeto->>'publicCreditName',objeto->>'status',objeto->>'completedAt',objeto->>'completedBy')

  ON CONFLICT(id_sugestao_melhoria) DO UPDATE SET mensagem=excluded.mensagem, id_turma=excluded.id_turma, criado_por=excluded.criado_por, email_criador=excluded.email_criador, criado_em=excluded.criado_em, credito_autorizado=excluded.credito_autorizado, nome_credito=excluded.nome_credito, situacao=excluded.situacao, concluida_em=excluded.concluida_em, concluida_por=excluded.concluida_por;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.gravar_turmas_agenda(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.turmas_agenda (id_turma_agenda,id_turma,ativa,referencia_pedido,aprovada_em) VALUES (alvo,tech2d.resolver_turma(objeto->>'name'),(objeto->>'active')::boolean,objeto->>'requestId',objeto->>'approvedAt')

  ON CONFLICT(id_turma_agenda) DO UPDATE SET id_turma=excluded.id_turma, ativa=excluded.ativa, referencia_pedido=excluded.referencia_pedido, aprovada_em=excluded.aprovada_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_atividades(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'title', d.titulo,

    'description', d.descricao,

    'type', d.tipo_atividade,

    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),

    'date', d.data_atividade,

    'time', to_char(d.hora_atividade,'HH24:MI'),

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdByEmail', d.email_criador,

    'recurringId', tech2d.referencia_entidade(d.id_regra_recorrencia),

    'createdAt', d.criado_em,

    'updatedAt', d.alterado_em,

    'attachments', (SELECT coalesce(jsonb_agg(tech2d.ler_anexos_atividade(r.id_anexo_atividade) ORDER BY r.id_anexo_atividade),'[]'::jsonb) FROM tech2d.anexos_atividade r WHERE r.id_atividade=d.id_atividade)

  ))

  FROM tech2d.atividades d WHERE d.id_atividade=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_envios_anexos(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'activityId', tech2d.referencia_entidade(d.id_atividade),

    'name', d.nome,

    'contentType', d.tipo_mime,

    'size', d.tamanho_bytes,

    'key', d.chave_arquivo,

    'uid', d.id_usuario,

    'createdAt', d.criado_em_ms

  ))

  FROM tech2d.envios_anexos d WHERE d.id_envio_anexo=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_pedidos_representacao(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'email', d.email,

    'status', d.situacao,

    'createdAt', d.criado_em,

    'reviewedAt', d.revisado_em

  ))

  FROM tech2d.pedidos_representacao d WHERE d.id_pedido_representacao=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_perfis_administrativos(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'role', d.papel,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdAt', d.criado_em

  ))

  FROM tech2d.perfis_administrativos d WHERE d.id_perfil_administrativo=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_preferencias_resumo(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'enabled', d.ativo,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'updatedAt', d.alterada_em_ms

  ))

  FROM tech2d.preferencias_resumo d WHERE d.id_preferencia_resumo=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_regras_recorrencia(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'title', d.titulo,

    'description', d.descricao,

    'type', d.tipo_atividade,

    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),

    'time', to_char(d.hora_atividade,'HH24:MI'),

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdByEmail', d.email_criador,

    'createdAt', d.criado_em,

    'startDate', d.data_inicio,

    'endDate', d.data_fim,

    'active', d.ativa,

    'deleted', d.excluida,

    'intervalWeeks', d.intervalo_semanas,

    'weekdays', d.dias_semana

  ))

  FROM tech2d.regras_recorrencia d WHERE d.id_regra_recorrencia=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_regras_retencao(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'days', d.dias,

    'enabled', d.ativa,

    'updatedBy', d.alterado_por,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.regras_retencao d WHERE d.id_regra_retencao=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_sugestoes_atividade(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'title', d.titulo,

    'description', d.descricao,

    'type', d.tipo_atividade,

    'subject', tech2d.nome_disciplina_agenda(d.id_disciplina),

    'date', d.data_atividade,

    'time', to_char(d.hora_atividade,'HH24:MI'),

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdAt', d.criado_em,

    'updatedAt', d.alterado_em,

    'status', d.situacao,

    'resolution', d.resolucao,

    'reviewComment', d.comentario_revisao,

    'closedAt', d.encerrada_em

  ))

  FROM tech2d.sugestoes_atividade d WHERE d.id_sugestao_atividade=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_sugestoes_melhoria(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'message', d.mensagem,

    'turmaId', tech2d.nome_turma_agenda(d.id_turma),

    'createdBy', d.criado_por,

    'createdByEmail', d.email_criador,

    'createdAt', d.criado_em,

    'publicCreditAllowed', d.credito_autorizado,

    'publicCreditName', d.nome_credito,

    'status', d.situacao,

    'completedAt', d.concluida_em,

    'completedBy', d.concluida_por

  ))

  FROM tech2d.sugestoes_melhoria d WHERE d.id_sugestao_melhoria=alvo;

$function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_turmas_agenda(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'name', tech2d.nome_turma_agenda(d.id_turma),

    'active', d.ativa,

    'requestId', d.referencia_pedido,

    'approvedAt', d.aprovada_em

  ))

  FROM tech2d.turmas_agenda d WHERE d.id_turma_agenda=alvo;

$function$
;

CREATE OR REPLACE VIEW tech2d.visao_atividades AS
 SELECT r.referencia AS id,
    (SELECT coalesce(rotulo_turma.referencia_agenda,rotulo_turma.nome) FROM tech2d.turmas rotulo_turma WHERE rotulo_turma.id_turma=a.id_turma)::character varying(150) AS turma_id,
    a.titulo AS title,
    COALESCE(a.descricao, ''::character varying) AS description,
    a.tipo_atividade AS type,
    (SELECT coalesce((SELECT rotulo_nota.nome FROM tech2d.visao_disciplinas_notas rotulo_nota WHERE rotulo_nota.id=rotulo_disciplina.id_disciplina ORDER BY rotulo_nota.ano_serie DESC LIMIT 1),rotulo_disciplina.nome) FROM tech2d.disciplinas rotulo_disciplina WHERE rotulo_disciplina.id_disciplina=a.id_disciplina)::character varying(150) AS subject,
    a.data_atividade::character varying(10) AS date,
    to_char(a.hora_atividade::interval, 'HH24:MI'::text) AS "time",
    a.criado_por AS created_by,
    a.email_criador AS created_by_email,
    (SELECT rotulo_regra.referencia FROM tech2d.registros_aplicacao rotulo_regra WHERE rotulo_regra.id_registro=a.id_regra_recorrencia)::character varying(320) AS recurring_id,
    COALESCE(( SELECT jsonb_agg(tech2d.ler_anexos_atividade(f.id_anexo_atividade) ORDER BY f.id_anexo_atividade) AS jsonb_agg
           FROM tech2d.anexos_atividade f
          WHERE f.id_atividade = r.id_registro), '[]'::jsonb) AS attachments,
    a.criado_em::timestamp with time zone AS created_at,
    a.alterado_em::timestamp with time zone AS updated_at,
    r.versao AS version
   FROM tech2d.atividades a
     JOIN tech2d.registros_aplicacao r ON r.id_registro = a.id_atividade;

CREATE OR REPLACE VIEW tech2d.visao_atividades_automacao AS
 SELECT r.referencia AS id,
    tech2d.referencia_api(r.tipo, r.referencia_pai, r.referencia) AS caminho,
    (SELECT coalesce(rotulo_turma.referencia_agenda,rotulo_turma.nome) FROM tech2d.turmas rotulo_turma WHERE rotulo_turma.id_turma=a.id_turma)::character varying(150) AS turma,
    a.data_atividade AS data,
    (SELECT rotulo_regra.referencia FROM tech2d.registros_aplicacao rotulo_regra WHERE rotulo_regra.id_registro=a.id_regra_recorrencia)::character varying(320) AS referencia_recorrencia,
    tech2d.ler_registro(r.id_registro, r.tipo) AS conteudo
   FROM tech2d.atividades a
     JOIN tech2d.registros_aplicacao r ON r.id_registro = a.id_atividade
  WHERE r.tipo::text = 'activities'::text;

CREATE OR REPLACE VIEW tech2d.visao_perfis_administrativos AS
 SELECT r.referencia AS uid,
    p.papel AS role,
    (SELECT coalesce(rotulo_turma.referencia_agenda,rotulo_turma.nome) FROM tech2d.turmas rotulo_turma WHERE rotulo_turma.id_turma=p.id_turma)::character varying(150) AS turma_id,
    tech2d.ler_registro(r.id_registro, r.tipo) AS data
   FROM tech2d.perfis_administrativos p
     JOIN tech2d.registros_aplicacao r ON r.id_registro = p.id_perfil_administrativo;
ALTER TABLE tech2d.pedidos_agenda RENAME COLUMN nome_turma TO nome_turma_solicitada;

CREATE OR REPLACE FUNCTION tech2d.gravar_pedidos_agenda(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.pedidos_agenda (id_pedido_agenda,nome_turma_solicitada,email,situacao,criado_em,revisado_em) VALUES (alvo,objeto->>'className',objeto->>'email',objeto->>'status',objeto->>'createdAt',objeto->>'reviewedAt')

  ON CONFLICT(id_pedido_agenda) DO UPDATE SET nome_turma_solicitada=excluded.nome_turma_solicitada, email=excluded.email, situacao=excluded.situacao, criado_em=excluded.criado_em, revisado_em=excluded.revisado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_pedidos_agenda(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'className', d.nome_turma_solicitada,

    'email', d.email,

    'status', d.situacao,

    'createdAt', d.criado_em,

    'reviewedAt', d.revisado_em

  ))

  FROM tech2d.pedidos_agenda d WHERE d.id_pedido_agenda=alvo;

$function$
;
ALTER TABLE tech2d.perfis_comunidade RENAME COLUMN nome_turma TO turma_informada;

CREATE OR REPLACE FUNCTION tech2d.gravar_perfis_comunidade(alvo bigint, objeto jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$

BEGIN

  INSERT INTO tech2d.perfis_comunidade (id_perfil_comunidade,nome,empresa,turma_informada,sala,andar,url_foto,alterado_em) VALUES (alvo,objeto->>'displayName',objeto->>'company',objeto->>'className',objeto->>'room',objeto->>'floor',objeto->>'photoUrl',objeto->>'updatedAt')

  ON CONFLICT(id_perfil_comunidade) DO UPDATE SET nome=excluded.nome, empresa=excluded.empresa, turma_informada=excluded.turma_informada, sala=excluded.sala, andar=excluded.andar, url_foto=excluded.url_foto, alterado_em=excluded.alterado_em;

END $function$
;

CREATE OR REPLACE FUNCTION tech2d.ler_perfis_comunidade(alvo bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$

  SELECT tech2d.remover_nulos_raiz(jsonb_build_object(

    'displayName', d.nome,

    'company', d.empresa,

    'className', d.turma_informada,

    'room', d.sala,

    'floor', d.andar,

    'photoUrl', d.url_foto,

    'updatedAt', d.alterado_em

  ))

  FROM tech2d.perfis_comunidade d WHERE d.id_perfil_comunidade=alvo;

$function$
;
ALTER TABLE tech2d.atividades DROP COLUMN nome_disciplina;
ALTER TABLE tech2d.regras_recorrencia DROP COLUMN nome_disciplina;
ALTER TABLE tech2d.sugestoes_atividade DROP COLUMN nome_disciplina;
ALTER TABLE tech2d.atividades DROP COLUMN nome_turma;
ALTER TABLE tech2d.regras_recorrencia DROP COLUMN nome_turma;
ALTER TABLE tech2d.regras_retencao DROP COLUMN nome_turma;
ALTER TABLE tech2d.sugestoes_atividade DROP COLUMN nome_turma;
ALTER TABLE tech2d.sugestoes_melhoria DROP COLUMN nome_turma;
ALTER TABLE tech2d.pedidos_representacao DROP COLUMN nome_turma;
ALTER TABLE tech2d.perfis_administrativos DROP COLUMN nome_turma;
ALTER TABLE tech2d.preferencias_resumo DROP COLUMN nome_turma;
ALTER TABLE tech2d.turmas_agenda DROP COLUMN nome;
ALTER TABLE tech2d.atividades DROP COLUMN referencia_recorrencia;
ALTER TABLE tech2d.envios_anexos DROP COLUMN referencia_atividade;
COMMENT ON COLUMN tech2d.atividades.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';
COMMENT ON COLUMN tech2d.regras_recorrencia.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';
COMMENT ON COLUMN tech2d.sugestoes_atividade.id_disciplina IS 'FK para disciplinas.id_disciplina. Reutiliza a matéria do catálogo compartilhado com horários e Notas; o rótulo exibido é reconstruído pela API.';
COMMENT ON COLUMN tech2d.atividades.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.regras_recorrencia.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.regras_retencao.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.sugestoes_atividade.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.sugestoes_melhoria.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.pedidos_representacao.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.perfis_administrativos.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.preferencias_resumo.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.turmas_agenda.id_turma IS 'FK para turmas.id_turma, compartilhada com os horários. referencia_agenda no catálogo conserva o identificador textual esperado pela interface.';
COMMENT ON COLUMN tech2d.atividades.id_regra_recorrencia IS 'FK opcional para regras_recorrencia.id_regra_recorrencia. Identifica a regra que gerou a ocorrência; excluir fisicamente a regra desvincula a atividade sem excluí-la.';
COMMENT ON COLUMN tech2d.envios_anexos.id_atividade IS 'FK para atividades.id_atividade. Vincula a preparação do upload à atividade existente; a exclusão da atividade desvincula o envio, preservando os metadados temporários necessários à limpeza do arquivo.';
COMMENT ON COLUMN tech2d.pedidos_agenda.nome_turma_solicitada IS 'Texto da sala proposta por uma pessoa. Pode descrever uma turma que ainda não foi cadastrada ou aprovada; por isso não exige FK para turmas.';
COMMENT ON COLUMN tech2d.perfis_comunidade.turma_informada IS 'Texto livre publicado pelo dono do perfil, como 2ºD. Não é a turma de autorização do representante nem uma referência obrigatória ao catálogo escolar.';
COMMENT ON FUNCTION tech2d.normalizar_rotulo(text) IS 'Normaliza somente para localizar um rótulo existente, ignorando caixa, acentos e pontuação; não substitui os nomes guardados no catálogo.';
COMMENT ON FUNCTION tech2d.chave_turma(text) IS 'Permite comparar rótulos da mesma turma, como 2° TECH D e 2º Tec D, sem criar outra turma.';
COMMENT ON FUNCTION tech2d.buscar_id_turma(text) IS 'Busca sem gravar o ID de uma turma por referência estável da Agenda ou nome do catálogo. Usada nas consultas indexadas do calendário.';
COMMENT ON FUNCTION tech2d.resolver_turma(text,boolean) IS 'Reutiliza a turma existente por referência, nome ou correspondência única normalizada. Cadastra somente nomes novos e registra uma vez a referência da Agenda, quando solicitado. Não concede autorização.';
COMMENT ON FUNCTION tech2d.nome_turma_agenda(bigint) IS 'Reconstrói o identificador textual esperado pela Agenda a partir do ID escolar, mantendo as permissões e os links existentes.';
COMMENT ON FUNCTION tech2d.nome_disciplina_agenda(bigint) IS 'Reconstrói o rótulo da disciplina usando a convenção já compartilhada com Notas, sem duplicar disciplinas para diferenças de exibição.';
COMMENT ON FUNCTION tech2d.resolver_disciplina(text) IS 'Reutiliza disciplinas por nome exato, rótulo de Notas ou correspondência única normalizada. Rejeita ambiguidades; cadastra uma matéria apenas quando ela ainda não existe. Não concede autorização.';
COMMENT ON FUNCTION tech2d.resolver_referencia_entidade(varchar,text) IS 'Converte uma referência externa para o ID de um registro de tipo específico. Ausência de correspondente é erro de relacionamento.';
COMMENT ON FUNCTION tech2d.referencia_entidade(bigint) IS 'Obtém a referência externa a partir da identidade numérica para preservar o contrato dos links e das automações.';
CREATE OR REPLACE FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$

DECLARE tipos varchar[]; revisao varchar(32);

BEGIN

 CASE catalogo

  WHEN 'agenda' THEN tipos:=ARRAY['activities','agendaClasses'];

  WHEN 'updates' THEN tipos:=ARRAY['agendaClasses'];

  WHEN 'schedules' THEN tipos:=ARRAY['schedules'];

  ELSE RAISE EXCEPTION 'Catálogo inválido' USING ERRCODE='22023';

 END CASE;

 SELECT md5(coalesce(string_agg(id_registro::text || ':' || versao::text, ',' ORDER BY id_registro),'')) INTO revisao

 FROM tech2d.registros_aplicacao WHERE tipo=ANY(tipos);

 SELECT md5(revisao||':'||coalesce((SELECT string_agg(id_disciplina::text||':'||nome,',' ORDER BY id_disciplina) FROM tech2d.disciplinas),'')
  ||':'||coalesce((SELECT string_agg(id_turma::text||':'||nome||':'||coalesce(referencia_agenda,''),',' ORDER BY id_turma) FROM tech2d.turmas),'')) INTO revisao;
 RETURN revisao;

END $function$
;
COMMENT ON FUNCTION tech2d.revisao_catalogo_publico(varchar) IS 'Calcula a revisão do catálogo com as versões dos registros e os nomes/referências de disciplinas e turmas; alterações nesses catálogos também invalidam o cache Redis.';
-- As subconsultas usam os privilégios da view, sem conceder SELECT direto nos catálogos.


COMMENT ON SCHEMA tech2d IS 'Dados da Tech-2D. tech2d-schema-version:048_relacionamentos_catalogos';

-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: revisao_catalogo_publico(character varying); Type: FUNCTION; Schema: tech2d; Owner: -
--

CREATE FUNCTION tech2d.revisao_catalogo_publico(catalogo character varying) RETURNS character varying
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE tipos varchar[]; revisao varchar(32);
BEGIN
 CASE catalogo
  WHEN 'agenda' THEN tipos:=ARRAY['activities','agendaClasses'];
  WHEN 'updates' THEN tipos:=ARRAY['agendaClasses'];
  WHEN 'schedules' THEN tipos:=ARRAY['schedules'];
  ELSE RAISE EXCEPTION 'Catálogo inválido' USING ERRCODE='22023';
 END CASE;
 SELECT md5(coalesce(string_agg(id_registro::text || ':' || versao::text, ',' ORDER BY id_registro),'')) INTO revisao
 FROM (
   SELECT id_atividade AS id_registro, versao FROM tech2d.atividades WHERE 'activities'=ANY(tipos)
   UNION ALL SELECT id_turma_agenda, versao FROM tech2d.turmas_agenda WHERE 'agendaClasses'=ANY(tipos)
   UNION ALL SELECT id_horario_interno, versao FROM tech2d.horarios_aula WHERE 'schedules'=ANY(tipos)
 ) entidades;
 SELECT md5(revisao||':'||coalesce((SELECT string_agg(id_disciplina::text||':'||nome,',' ORDER BY id_disciplina) FROM tech2d.disciplinas),'')
  ||':'||coalesce((SELECT string_agg(id_turma::text||':'||nome||':'||coalesce(referencia_agenda,''),',' ORDER BY id_turma) FROM tech2d.turmas),'')) INTO revisao;
 RETURN revisao;
END $$;

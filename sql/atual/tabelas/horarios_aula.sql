-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: horarios_aula; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.horarios_aula (
    id_horario_aula character varying(320) CONSTRAINT school_schedules_id_not_null NOT NULL,
    id_professor bigint CONSTRAINT school_schedules_teacher_id_not_null NOT NULL,
    id_disciplina bigint CONSTRAINT school_schedules_subject_id_not_null NOT NULL,
    id_turma bigint CONSTRAINT school_schedules_class_id_not_null NOT NULL,
    id_faixa_horario bigint CONSTRAINT school_schedules_time_slot_id_not_null NOT NULL,
    dia_semana smallint CONSTRAINT school_schedules_day_of_week_not_null NOT NULL,
    ativo boolean CONSTRAINT school_schedules_active_not_null NOT NULL,
    id_horario_interno bigint DEFAULT nextval('tech2d.ids_entidades'::regclass) CONSTRAINT horarios_aula_id_registro_not_null NOT NULL,
    andar character varying(80),
    sala character varying(500),
    criado_em character varying(40),
    alterado_em character varying(40),
    versao bigint NOT NULL,
    atualizado_em timestamp with time zone NOT NULL,
    CONSTRAINT horarios_aula_versao_check CHECK ((versao > 0)),
    CONSTRAINT school_schedules_day_of_week_check CHECK (((dia_semana >= 0) AND (dia_semana <= 6)))
);

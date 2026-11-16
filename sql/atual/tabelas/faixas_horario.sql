-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: faixas_horario; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.faixas_horario (
    id_faixa_horario bigint CONSTRAINT school_time_slots_id_not_null NOT NULL,
    hora_inicio time(0) without time zone CONSTRAINT school_time_slots_start_time_not_null NOT NULL,
    hora_fim time(0) without time zone CONSTRAINT school_time_slots_end_time_not_null NOT NULL,
    CONSTRAINT school_time_slots_check CHECK ((hora_inicio < hora_fim))
);

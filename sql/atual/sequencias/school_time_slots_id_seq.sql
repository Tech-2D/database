-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: school_time_slots_id_seq; Type: SEQUENCE; Schema: tech2d; Owner: -
--

ALTER TABLE tech2d.faixas_horario ALTER COLUMN id_faixa_horario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tech2d.school_time_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

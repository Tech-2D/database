-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: visitas_aos_sites; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.visitas_aos_sites (
    dia date CONSTRAINT agenda_access_day_not_null NOT NULL,
    intervalo_meia_hora bigint CONSTRAINT agenda_access_half_hour_not_null NOT NULL,
    tipo_visitante character varying(32) CONSTRAINT agenda_access_kind_not_null NOT NULL,
    chave_visitante character varying(128) CONSTRAINT agenda_access_visitor_key_not_null NOT NULL,
    site character varying(32) DEFAULT 'agenda'::text CONSTRAINT agenda_access_site_not_null NOT NULL,
    CONSTRAINT agenda_access_check CHECK (((((tipo_visitante)::text = 'anonymous'::text) AND ((chave_visitante)::text ~ '^[0-9a-f]{64}$'::text)) OR (((tipo_visitante)::text = 'account'::text) AND ((char_length((chave_visitante)::text) >= 1) AND (char_length((chave_visitante)::text) <= 128))))),
    CONSTRAINT agenda_access_kind_check CHECK (((tipo_visitante)::text = ANY (ARRAY['account'::text, 'anonymous'::text]))),
    CONSTRAINT visitas_aos_sites_site_check CHECK (((site)::text = ANY ((ARRAY['agenda'::character varying, 'professores'::character varying, 'pegaki'::character varying, 'kanban'::character varying])::text[])))
);

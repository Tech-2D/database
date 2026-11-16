-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: notas_cadernos; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.notas_cadernos (
    id_usuario character varying(128) NOT NULL,
    ano_letivo smallint NOT NULL,
    ano_serie smallint NOT NULL,
    modo_primeiro character varying(5) NOT NULL,
    modo_segundo character varying(5) NOT NULL,
    versao bigint DEFAULT 0 NOT NULL,
    regra_calculo character varying(32) DEFAULT 'tech-2026-v1'::character varying NOT NULL,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    alterado_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notas_cadernos_ano_letivo_check CHECK (((ano_letivo >= 2020) AND (ano_letivo <= 2100))),
    CONSTRAINT notas_cadernos_ano_serie_check CHECK (((ano_serie >= 1) AND (ano_serie <= 3))),
    CONSTRAINT notas_cadernos_modo_primeiro_check CHECK (((modo_primeiro)::text = ANY ((ARRAY['notas'::character varying, 'media'::character varying])::text[]))),
    CONSTRAINT notas_cadernos_modo_segundo_check CHECK (((modo_segundo)::text = ANY ((ARRAY['notas'::character varying, 'media'::character varying])::text[]))),
    CONSTRAINT notas_cadernos_versao_check CHECK ((versao >= 0))
);

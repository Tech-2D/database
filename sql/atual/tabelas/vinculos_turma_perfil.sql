-- Referência de objeto. Para instalar o conjunto, use sql/instalar.psql na raiz do repositório.

-- Name: vinculos_turma_perfil; Type: TABLE; Schema: tech2d; Owner: -
--

CREATE TABLE tech2d.vinculos_turma_perfil (
    firebase_uid text NOT NULL,
    turma text NOT NULL,
    alterada_em timestamp with time zone NOT NULL,
    pedido_turma text,
    pedido_em timestamp with time zone,
    CONSTRAINT vinculos_turma_perfil_check CHECK (((pedido_turma IS NULL) = (pedido_em IS NULL))),
    CONSTRAINT vinculos_turma_perfil_check1 CHECK (((pedido_turma IS NULL) OR (pedido_turma <> turma))),
    CONSTRAINT vinculos_turma_perfil_pedido_turma_check CHECK (((length(pedido_turma) >= 1) AND (length(pedido_turma) <= 80))),
    CONSTRAINT vinculos_turma_perfil_turma_check CHECK (((length(turma) >= 1) AND (length(turma) <= 80)))
);

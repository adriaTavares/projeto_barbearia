CREATE TABLE IF NOT EXISTS tipos_usuarios (
    id SMALLSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE
);
INSERT INTO tipos_usuarios (nome)
    VALUES 
    ('cliente'),
    ('barbeiro'),
    ('admin'),
    ('master')
ON CONFLICT (nome) DO NOTHING;




CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    email_principal TEXT NOT NULL UNIQUE,
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    tipo_usuario_id SMALLINT NOT NULL
        REFERENCES tipos_usuarios(id) DEFAULT 1,
    data_criacao TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS barbeiros (
    usuario_id UUID PRIMARY KEY
        REFERENCES usuarios(id)
        ON DELETE CASCADE,
    telefone VARCHAR(20) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL CHECK (data_nascimento <= CURRENT_DATE),
    cpf VARCHAR(11) NOT NULL UNIQUE,
    percentual_comissao NUMERIC(5,2) NOT NULL DEFAULT 20
        CHECK (percentual_comissao BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS dias_de_folga_barbeiro (
    barbeiro_id UUID NOT NULL
        REFERENCES barbeiros(usuario_id)
        ON DELETE CASCADE,
    dia_de_folga DATE NOT NULL,
    PRIMARY KEY (barbeiro_id, dia_de_folga)
);






CREATE TABLE IF NOT EXISTS provedores_oauth (
    id SMALLSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE
);

INSERT INTO provedores_oauth (nome)
VALUES 
    ('google'),
    ('github'),
    ('facebook'),
    ('linkedin')
ON CONFLICT (nome) DO NOTHING;


CREATE TABLE IF NOT EXISTS credenciais_oauth (
    usuario_id UUID NOT NULL
        REFERENCES usuarios(id)
        ON DELETE CASCADE,
    provedor_id SMALLINT NOT NULL
        REFERENCES provedores_oauth(id),
    provedor_user_id TEXT NOT NULL,
    PRIMARY KEY (provedor_id, provedor_user_id)
);



CREATE TABLE IF NOT EXISTS credenciais_email(
    usuario_id UUID NOT NULL PRIMARY KEY
        REFERENCES usuarios(id)
        ON DELETE CASCADE,
    senha_hash  TEXT NOT  NULL
);


CREATE TABLE IF NOT EXISTS verificacoes_email (
    usuario_id UUID PRIMARY KEY
        REFERENCES usuarios(id)
        ON DELETE CASCADE,
    codigo_hash TEXT NOT NULL,
    senha_hash TEXT NOT NULL,
    expira_em TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE
);






CREATE TABLE IF NOT EXISTS servicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    descricao TEXT,
    preco NUMERIC(10,2) NOT NULL CHECK (preco >= 0),
    tempo_minutos INTEGER NOT NULL CHECK (tempo_minutos > 0),
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE IF NOT EXISTS status_agendamento (
    id SMALLSERIAL PRIMARY KEY,
    nome TEXT UNIQUE NOT NULL
);

INSERT INTO status_agendamento (nome)
VALUES
    ('agendado'),
    ('finalizado'),
    ('cancelado'),
    ('faltou')
ON CONFLICT DO NOTHING;


CREATE TABLE agendamentos (
    id BIGSERIAL PRIMARY KEY,
    cliente_id UUID NOT NULL
        REFERENCES usuarios(id)
        ON DELETE CASCADE,
    barbeiro_id UUID NOT NULL
        REFERENCES barbeiros(usuario_id)
        ON DELETE CASCADE,
    data_criacao TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_agendada TIMESTAMPTZ NOT NULL,
    data_fim TIMESTAMPTZ NOT NULL,
    valor_total NUMERIC(10,2) NOT NULL CHECK (valor_total >= 0),
    tempo_total INTEGER NOT NULL,
    status_id SMALLINT NOT NULL
        REFERENCES status_agendamento(id) DEFAULT 1,
    CHECK (data_fim > data_agendada),
    UNIQUE(barbeiro_id, data_agendada)
);

CREATE TABLE IF NOT EXISTS agendamento_servico(
    agendamento_id BIGINT NOT NULL 
        REFERENCES agendamentos(id) ON DELETE CASCADE,
    servico_id INTEGER NOT NULL
        REFERENCES servicos(id) ON DELETE CASCADE,
        PRIMARY KEY(agendamento_id,servico_id)
);



--- === Trigges ===

CREATE OR REPLACE FUNCTION atualizar_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN
    NEW.data_atualizacao = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER usuario_update_timestamp
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
EXECUTE FUNCTION atualizar_timestamp();




--- === Indices === 


CREATE INDEX idx_agendamentos_barbeiro_data
ON agendamentos (barbeiro_id, data_agendada);

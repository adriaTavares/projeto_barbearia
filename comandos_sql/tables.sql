CREATE OR REPLACE TYPE STATUS_AGENDAMENTO AS ENUM(
    'agendado',
    'finalizado',
    'cancelado'
);

CREATE TABLE IF NOT EXISTS servicos(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    valor_base NUMERIC(7,2) NOT NULL CHECK(valor_base >= 0),
    tempo_minutos INTEGER NOT NULL CHECK(tempo_minutos > 0),
    ativo BOOLEAN DEFAULT TRUE
);


CREATE TABLE IF NOT EXISTS barbeiros(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL CHECK (data_nascimento <= CURRENT_DATE),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ativo BOOLEAN DEFAULT TRUE,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    percentual_comissao NUMERIC(5,2) NOT NULL 
        CHECK (percentual_comissao BETWEEN 0 AND 100)
        DEFAULT 20
);

CREATE TABLE IF NOT EXISTS dias_de_folga_barbeiro(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    barbeiro_id INTEGER NOT NULL,
    dia_de_folga DATE NOT NULL,
    CONSTRAINT dias_de_folga_barbeiro_fk
        FOREIGN KEY(barbeiro_id)
        REFERENCES barbeiros(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE(barbeiro_id,dia_de_folga)
);


CREATE TABLE IF NOT EXISTS agendamentos(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id UUID NOT NULL,
    barbeiro_id INTEGER NOT NULL,
    servico_id INTEGER NOT NULL,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_agendada TIMESTAMP WITH TIME ZONE NOT NULL CHECK(data_agendada >= NOW()),
    valor_total NUMERIC(10,2) NOT NULL,
    status_atual STATUS_AGENDAMENTO NOT NULL DEFAULT 'agendado',
    CONSTRAINT agendamentos_clientes_id_fk
        FOREIGN KEY(cliente_id)
        REFERENCES clientes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT agendamentos_barbeiros_id_fk
        FOREIGN KEY(barbeiro_id)
        REFERENCES barbeiros(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT agendamentos_servicos_id_fk
        FOREIGN KEY(servico_id)
        REFERENCES servicos(id)
        ON DELETE RESTRICT,
    UNIQUE(barbeiro_id,data_agendada)
);
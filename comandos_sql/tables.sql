-- tipos Enum utilizados por
-- 1. status de agendamento;

--STATUS_AGENDAMENTO

CREATE TABLE IF NOT EXISTS clientes(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefone TEXT,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cliente_email(
    cliente_id INTEGER NOT NULL UNIQUE PRIMARY KEY,
    senha TEXT NOT NULL,
    CONSTRAINT cliente_email_clientes_id_fk
        FOREIGN  KEY(cliente_id)
        REFERENCES clientes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS cliente_google(
    cliente_id INTEGER NOT NULL UNIQUE PRIMARY KEY,
    google_id TEXT NOT NULL UNIQUE,
    CONSTRAINT cliente_google_clientes_id_fk
        FOREIGN KEY(cliente_id)
        REFERENCES clientes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



CREATE TABLE IF NOT EXISTS barbeiros(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL
        CHECK (data_nascimento <= CURRENT_DATE),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ativo BOOLEAN DEFAULT TRUE,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    percentual_comissao NUMERIC(5,2) NOT NULL 
        CHECK (percentual_comissao BETWEEN 0 AND 100)
        DEFAULT 20
);

CREATE TABLE IF NOT EXISTS dias_de_folga_barbeiro(
    barbeiro_id INT NOT NULL PRIMARY KEY,
    dia_de_folga date WITH DATE ZONE NOT NULL,
    CONSTRAINT FOREIGN KEY(barbeiro_id)
        REFERENCES barbeiros(id)
);




CREATE TABLE IF NOT EXISTS agendamentos(
    id GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    barbeiro_id INTEGER NOT NULL,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_agendamento TIMESTAMP WITH TIME ZONE NOT NULL,
    valor_total NUMERIC(10,2),
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
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS servicos(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    valor_base NUMERIC(7,2) NOT NULL
        CHECK(valor_base >=0 ),
    tempo_minutos INTEGER NOT NULL 
        CHECK(tempo_minutos > 0),
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS agendamento_servico(
    agendamento_id INTEGER NOT NULL,
    servico_id INTEGER NOT NULL ,
    CONSTRAINT agendamento_servico_agendamentos_id_fk
        FOREIGN KEY(agendamento_id)
        REFERENCES agendamentos(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT agendamento_servico_servicos_id_fk
        FOREIGN KEY(servico_id)
        REFERENCES servicos(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
        PRIMARY KEY(agendamento_id,servico_id)
);

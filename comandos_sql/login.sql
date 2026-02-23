CREATE TABLE IF NOT EXISTS clientes(
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID() NOT NULL,
    nome VARCHAR(255) NOT NULL,
    email_principal TEXT NOT NULL UNIQUE,
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS credenciais_email(
    id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID() NOT NULL,
    cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
    senha_hash TEXT NOT NULL,
    UNIQUE (cliente_id)
);


CREATE TABLE IF NOT EXISTS verificacao_email(
    id_v UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID() NOT NULL,
    cliente_id_v UUID REFERENCES clientes(id) ON DELETE CASCADE,
    nome_v TEXT NOT NULL,
    email_v TEXT NOT NULL,
    codigo_hash_v TEXT NOT NULL,
    senha_hash_v TEXT NOT NULL,
    tempo_expiracao_v TIMESTAMP NOT NULL,
    usado_v BOOLEAN DEFAULT FALSE,
    UNIQUE (cliente_id_v)
);

CREATE OR REPLACE FUNCTION criar_cliente(
    n_nome TEXT,
    n_email TEXT,
    n_codigo_hash TEXT,
    n_senha_hash TEXT
)
RETURNS UUID AS $$
DECLARE p_id UUID,
    p_email_verificado  BOOLEAN;
BEGIN
    SELECT id, email_verificado
    INTO p_id, p_email_verificado 
    FROM clientes
    WHERE email_principal = n_email;


    IF FOUND THEN
        IF p_email_verificado  THEN 
            RAISE EXCEPTION 'Já existe um usuário com esse e-mail';
        END IF;
            UPDATE clientes
                SET nome = n_nome
                WHERE id = p_id;

            UPDATE verificacao_email
                SET nome_v = n_nome,
                    codigo_hash_v = n_codigo_hash,
                    senha_hash_v = n_senha_hash,
                    tempo_expiracao_v = NOW() + INTERVAL '10 MINUTES'
                WHERE cliente_id_v = p_id;
            RETURN p_id;
    END IF;
    INSERT INTO clientes(nome,email_principal)
    VALUES(n_nome,n_email)
    RETURNING id INTO p_id;

    INSERT INTO verificacao_email(
        cliente_id_v,
        nome_v,
        email_v,
        codigo_hash_v,
        senha_hash_v,
        tempo_expiracao_v
    )
    VALUES(
        p_id,
        n_nome,
        n_email,
        n_codigo_hash,
        n_senha_hash,
        NOW()+INTERVAL '10 MINUTES'
    );
    RETURN p_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION validar_codigo_email(
    n_email TEXT,
    n_codigo_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    p_id_cliente UUID;
    p_codigo_hash TEXT;
    p_senha_hash TEXT;
    p_usado BOOLEAN;
    p_tempo_expiracao TIMESTAMP;
BEGIN
    SELECT cliente_id_v,
           codigo_hash_v,
           senha_hash_v,
           usado_v,
           tempo_expiracao_v
    INTO p_id_cliente,
         p_codigo_hash,
         p_senha_hash,
         p_usado,
         p_tempo_expiracao
    FROM verificacao_email
    WHERE email_v = n_email
    AND usado_v = FALSE
    ORDER BY tempo_expiracao_v DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'E-mail inválido ou sem verificação pendente.';
    END IF;

    IF n_codigo_hash <> p_codigo_hash THEN
        RAISE EXCEPTION 'Código inválido.';
    END IF;

    IF p_usado THEN
        RAISE EXCEPTION 'Código já utilizado.';
    END IF;

    IF p_tempo_expiracao < NOW() THEN
        RAISE EXCEPTION 'Código expirado.';
    END IF;

    
    UPDATE verificacao_email
    SET usado_v = TRUE
    WHERE cliente_id_v = p_id_cliente;

    
    UPDATE clientes
    SET email_verificado = TRUE,
        data_atualizacao = NOW()
    WHERE id = p_id_cliente;

    
    INSERT INTO credenciais_email (
        cliente_id,
        senha_hash
    )
    VALUES (
        p_id_cliente,
        p_senha_hash
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


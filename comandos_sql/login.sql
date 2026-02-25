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
    cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE NOT NULL,
    senha_hash TEXT NOT NULL,
    UNIQUE (cliente_id)
);


CREATE TABLE IF NOT EXISTS verificacao_email(
    id_v UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID() NOT NULL,
    cliente_id_v UUID REFERENCES clientes(id) ON DELETE CASCADE NOT NUll,
    nome_v TEXT NOT NULL,
    codigo_hash_v TEXT NOT NULL,
    senha_hash_v TEXT NOT NULL,
    tempo_expiracao_v TIMESTAMP NOT NULL,
    usado_v BOOLEAN DEFAULT FALSE,
    UNIQUE (cliente_id_v)
);





CREATE OR REPLACE FUNCTION criar_cliente_email(
    n_nome TEXT,
    n_email TEXT,
    n_codigo_hash TEXT,
    n_senha_hash TEXT
)
RETURNS UUID AS $$
DECLARE p_id UUID,
    p_email_verificado  BOOLEAN;
BEGIN
 
    INSERT INTO clientes(nome,email_principal)
    VALUES(n_nome,n_email)
    ON CONFLICT (email_principal)
    DO UPDATE
    SET nome = EXCLUDED.nome,
        data_atualizacao = NOW()
    WHERE email_verificado = FALSE
    RETURNING id, email_verificado
    INTO p_id, p_email_verificado;

    IF p_id IS NULL
        THEN RAISE EXCEPTION 'Já existe um usuário com esse e-mail.';
    END IF;
    INSERT INTO verificacao_email(
        cliente_id_v,
        nome_v,
        codigo_hash_v,
        senha_hash_v,
        tempo_expiracao_v
    )
    VALUES(
        p_id,
        n_nome,
        n_codigo_hash,
        n_senha_hash,
        NOW()+INTERVAL '10 MINUTES'
    )
    ON CONFLICT (cliente_id_v)
    DO UPDATE
        SET nome_v = EXCLUDED.nome_v,
            codigo_hash_v = EXCLUDED.codigo_hash_v,
            senha_hash_v = EXCLUDED.senha_hash_v,
            tempo_expiracao_v = EXCLUDED.tempo_expiracao_v,
            usado_v = FALSE;
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
    p_senha_hash TEXT;
BEGIN
    WITH consulta_cliente AS(
        SELECT id FROM clientes
        WHERE email_principal = n_email
    )
    UPDATE verificacao_email v
    SET usado_v = TRUE
    FROM consulta_cliente c
    WHERE v.cliente_id_v = c.id
    AND v.codigo_hash_v = n_codigo_hash
    AND v.usado_v = FALSE
    AND v.tempo_expiracao_v > NOW()
    RETURNING v.cliente_id_v, v.senha_hash_v
    INTO p_id_cliente, p_senha_hash;


    IF p_id_cliente IS NULL THEN
        RAISE EXCEPTION 'E-mail inválido ou sem verificação pendente.';
    END IF;

    
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
    )
    ON CONFLICT (cliente_id)
    DO UPDATE
    SET senha_hash = EXCLUDED.senha_hash;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;






CREATE OR REPLACE TYPE TIPO_PROVEDOR_OAUTH AS ENUM (
    'google',
    'github'
);



CREATE TABLE IF NOT EXISTS credenciais_oauth(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID NOT NUll,
    provedor TIPO_PROVEDOR_OAUTH NOT NULL,
    provedor_user_id TEXT NOT NULL,
    CONSTRAINT credenciais_oauth_clientes_id_fk
        FOREIGN KEY(cliente_id)
        REFERENCES clientes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE(provedor,provedor_user_id)
);



CREATE OR REPLACE FUNCTION criar_cliente_oauth(
    n_nome TEXT,
    n_email TEXT,
    n_provedor TIPO_PROVEDOR_OAUTH,
    n_provedor_user_id TEXT
)
RETURNS UUID AS $$
DECLARE 
    p_cliente_id UUID;
BEGIN

    SELECT cliente_id 
    INTO p_cliente_id
    FROM credenciais_oauth
    WHERE provedor = n_provedor
      AND provedor_user_id = n_provedor_user_id;

    IF p_cliente_id IS NOT NULL THEN
        RETURN p_cliente_id;
    END IF;

    SELECT id
    INTO p_cliente_id
    FROM clientes
    WHERE email_principal = n_email;

    IF p_cliente_id IS NULL THEN
        INSERT INTO clientes(nome, email_principal, email_verificado)
        VALUES(n_nome, n_email, TRUE)
        ON CONFLICT(email_principal)
        DO UPDATE 
        SET nome = clientes.nome
        RETURNING id INTO p_cliente_id;
    END IF;

    INSERT INTO credenciais_oauth(cliente_id, provedor, provedor_user_id)
    VALUES (p_cliente_id, n_provedor, n_provedor_user_id)
    ON CONFLICT (provedor,provedor_user_id)
    DO UPDATE
    SET cliente_id = EXCLUDED.cliente_id
    RETURNING cliente_id INTO p_cliente_id;

    RETURN p_cliente_id;

END;
$$ LANGUAGE plpgsql;
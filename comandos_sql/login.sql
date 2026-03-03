CREATE OR REPLACE FUNCTION criar_cliente_email(
    p_nome TEXT,
    p_email TEXT,
    p_codigo_hash TEXT,
    p_senha_hash TEXT,
    p_tipo_usuario_id SMALLINT
)
RETURNS UUID AS $$
DECLARE 
    v_usuario_id UUID;
BEGIN

    INSERT INTO usuarios (
        nome,
        email_principal,
        tipo_usuario_id
    )
    VALUES (
        p_nome,
        p_email,
        p_tipo_usuario_id
    )
    ON CONFLICT (email_principal)
    DO UPDATE
        SET nome = EXCLUDED.nome
        WHERE usuarios.email_verificado = FALSE
    RETURNING id INTO v_usuario_id;

    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'E-mail já registrado e verificado.';
    END IF;

    INSERT INTO verificacoes_email (
        usuario_id,
        codigo_hash,
        senha_hash,
        expira_em
    )
    VALUES (
        v_usuario_id,
        p_codigo_hash,
        p_senha_hash,
        NOW() + INTERVAL '30 minutes'
    )
    ON CONFLICT (usuario_id)
    DO UPDATE SET
        codigo_hash = EXCLUDED.codigo_hash,
        senha_hash = EXCLUDED.senha_hash,
        expira_em = EXCLUDED.expira_em,
        usado = FALSE;

    RETURN v_usuario_id;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION validar_codigo_email(
    p_email TEXT,
    p_codigo_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_usuario_id UUID;
    v_senha_hash TEXT;
BEGIN

    UPDATE verificacoes_email v
    SET usado = TRUE
    FROM usuarios u
    WHERE u.email_principal = p_email
      AND v.usuario_id = u.id
      AND v.codigo_hash = p_codigo_hash
      AND v.usado = FALSE
      AND v.expira_em > NOW()
    RETURNING v.usuario_id, v.senha_hash
    INTO v_usuario_id, v_senha_hash;

    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'Código inválido ou expirado.';
    END IF;

    UPDATE usuarios
    SET email_verificado = TRUE
    WHERE id = v_usuario_id;

    INSERT INTO credenciais_email (
        usuario_id,
        senha_hash
    )
    VALUES (
        v_usuario_id,
        v_senha_hash
    )
    ON CONFLICT (usuario_id)
    DO UPDATE
    SET senha_hash = EXCLUDED.senha_hash;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;






CREATE OR REPLACE FUNCTION criar_cliente_oauth(
    p_nome TEXT,
    p_email TEXT,
    p_provedor_id SMALLINT,
    p_provedor_user_id TEXT,
    p_tipo_usuario_id SMALLINT
)
RETURNS UUID AS $$
DECLARE 
    v_usuario_id UUID;
BEGIN

    SELECT usuario_id
    INTO v_usuario_id
    FROM credenciais_oauth
    WHERE provedor_id = p_provedor_id
      AND provedor_user_id = p_provedor_user_id;

    IF v_usuario_id IS NOT NULL THEN
        RETURN v_usuario_id;
    END IF;

    INSERT INTO usuarios (
        nome,
        email_principal,
        email_verificado,
        tipo_usuario_id
    )
    VALUES (
        p_nome,
        p_email,
        TRUE,
        p_tipo_usuario_id
    )
    ON CONFLICT (email_principal)
    DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_usuario_id;

    INSERT INTO credenciais_oauth (
        usuario_id,
        provedor_id,
        provedor_user_id
    )
    VALUES (
        v_usuario_id,
        p_provedor_id,
        p_provedor_user_id
    )
    ON CONFLICT DO NOTHING;

    RETURN v_usuario_id;
END;
$$ LANGUAGE plpgsql;











CREATE OR REPLACE FUNCTION buscar_usuario(
    v_usuario_id
)
RETURNS JSON AS $$
DECLARE v_dados;
BEGIN
    SELECT 1 FROM usuarios
    INTO v_dados
    WHERE id = v_usuario_id;

    RETURN v_dados;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION buscar_barbeiro(
    barbeiro_id
)
RETURNS JSON AS $$
DECLARE v_dados;
BEGIN
    SELECT 1 FROM barbeiros
    INTO v_dados
    WHERE usuario_id = barbeiro_id;

    RETURN v_dados;
END;











/*
cliente = {
    "id":number,
    "nome": string,
    "email":string,
    "data_criacao",
    "ativo"

}

barbeiro = {
    "id":number,
    "nome": string,
    "email":string,
    "data_criacao",
    "ativo",
    "percentual_comissao":number,
    "telefone":string,
    "cpf":string
    "ativo"

}
agendamento = {
    "data_agendada": YYYY-MM-DDTHH:mm:ss,
    "data_criacao": YYYY-MM-DDTHH:mm:ss,
    "data_fim": YYYY-MM-DDTHH:mm:ss,
    "barbeiro":{
        "id": number,
        "nome":string,
        "email": string
    },
    "servico":[{
        "id":number,
        "nome": string,
        "preco":number
        } ...
    ],
    "preco": number
}

*/
CREATE OR REPLACE FUNCTION agendamentos_recentes_usuario(
    p_usuario_id UUID
)
RETURNS JSON AS $$
DECLARE 
    v_dados JSON,
    p_users JSON;
BEGIN
    p_users := JSON_BUILD_OBJECT(
        SELECT * FROM agendamentos
        COALESCE()
    )
    RETURN v_dados;
END;
$$ LANGUAGE plpgsql;

$$ LANGUAGE plpgsql;
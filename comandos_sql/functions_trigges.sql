CREATE OR REPLACE FUNCTION inserir_cliente_base(
    n_nome TEXT,
    n_email TEXT,
    n_telefone TEXT
)
RETURNS INTEGER AS $$
DECLARE 
    id_parcial INTEGER;
BEGIN
    INSERT INTO clientes(
        nome,
        email,
        telefone
    )
    VALUES(
        n_nome,
        n_email,
        n_telefone
    )
    RETURNING id INTO id_parcial;
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION inserir_cliente_google(
   n_nome TEXT,
   n_email TEXT,
   n_telefone TEXT,
   n_google_id TEXT
)
RETURNS INTEGER AS $$
DECLARE 
    id_parcial INTEGER;
BEGIN
    id_parcial := inserir_cliente_base(
        n_nome,
        n_email,
        n_telefone
    );
    INSERT INTO cliente_google(
        cliente_id,
        google_id
    )
    VALUES(
        id_parcial,
        n_google_id
    );
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION inserir_cliente_email(
    n_nome TEXT,
    n_email TEXT,
    n_telefone TEXT,
    n_senha TEXT
)
RETURNS INTEGER AS $$
DECLARE id_parcial INTEGER;
BEGIN
   id_parcial := inserir_cliente_base(
        n_nome,
        n_email,
        n_telefone
    );
    INSERT INTO cliente_email(
        cliente_id,
        senha
    )
    VALUES(
        id_parcial,
        n_senha
    );
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;






CREATE OR REPLACE FUNCTION inserir_barbeiro(
    n_nome TEXT,
    n_email TEXT,
    n_telefone TEXT,
    n_data_nascimento DATE,
    n_cpf TEXT,
    n_percentual_comissao NUMERIC
)
RETURNS INTEGER AS $$
DECLARE id_parcial INTEGER;
BEGIN
    INSERT INTO barbeiros(
        nome,
        email,
        telefone,
        data_nascimento,
        cpf,
        percentual_comissao
    )
    VALUES(
        n_nome,
        n_email,
        n_telefone,
        n_data_nascimento,
        n_cpf,
        n_percentual_comissao
    )
    RETURNING id INTO id_parcial;
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;






CREATE OR REPLACE FUNCTION criar_agendamento(
    n_cliente_id INTEGER,
    n_barbeiro_id INTEGER,
    n_data_agendamento TIMESTAMP,
    n_valor_total NUMERIC,
    n_servicos INT[]
)
RETURNS INTEGER AS $$
DECLARE
    id_parcial INTEGER;
    valor_total_parcial NUMERIC
BEGIN
    INSERT INTO agendamentos(
        cliente_id,
        barbeiro_id,
        data_agendamento
    )
    VALUES(
        n_cliente_id,
        n_barbeiro_id,
        n_data_agendamento
    )
    RETURNING id INTO id_parcial;


    INSERT INTO agendamento_servico(
        agendamento_id,
        servico_id
    )
        SELECT id_parcial, id
        FROM servicos
        WHERE id = ANY(n_servicos);

    SELECT SUM(valor_base)
    INTO valor_total_parcial
    FROM servicos
    WHERE id = ANY(n_servicos);

    UPDATE agendamentos
    SET valor_total = valor_total_parcial
    WHERE id = id_parcial;
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;





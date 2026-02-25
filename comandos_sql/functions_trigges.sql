
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
    n_servico_id INTEGER,
    n_data_agendamento TIMESTAMP WITH TIME ZONE
)
RETURNS INTEGER AS $$
DECLARE
    id_parcial INTEGER;
    n_valor_total NUMERIC(10,2);
BEGIN

    SELECT valor_base
    INTO n_valor_total
    FROM servicos
    WHERE id = n_servico_id;

    IF n_valor_total IS NULL THEN
        RAISE EXCEPTION 'Serviço não encontrado';
    END IF;

    INSERT INTO agendamentos(
        cliente_id,
        barbeiro_id,
        servico_id,
        valor_total,
        data_agendamento
    )
    VALUES(
        n_cliente_id,
        n_barbeiro_id,
        n_servico_id,
        n_valor_total,
        n_data_agendamento
    )
    RETURNING id INTO id_parcial;

    RETURN id_parcial;

END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION inserir_barbeiro(
    n_usuario_id UUID,
    n_telefone TEXT,
    n_data_nascimento DATE,
    n_cpf TEXT,
    n_percentual_comissao NUMERIC
)
RETURNS INTEGER AS $$
DECLARE id_parcial INTEGER;
BEGIN
    INSERT INTO barbeiros(
        usuario_id,
        telefone,
        data_nascimento,
        cpf,
        percentual_comissao
    )
    VALUES(
        n_usuario_id,
        n_telefone,
        n_data_nascimento,
        n_cpf,
        n_percentual_comissao
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO id_parcial;

    IF id_parcial IS NULL THEN
        RAISE EXCEPTION 'Barbeiro já existe!'
    END IF;
    RETURN id_parcial;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION buscar_usuario(
    v_usuario_id UUID
)
RETURNS JSON AS $$
DECLARE v_dados JSON;
BEGIN
    SELECT ROW_TO_JSON(U) FROM usuarios U
    INTO v_dados
    WHERE id = v_usuario_id;

    RETURN v_dados;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION buscar_barbeiro(
    barbeiro_id UUID
)
RETURNS JSON AS $$
DECLARE v_dados JSON;
BEGIN
    SELECT ROW_TO_JSON(B) FROM barbeiros B
    INTO v_dados
    WHERE usuario_id = barbeiro_id;

    RETURN v_dados;
END;



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
    CHECK (data_fim > data_agendada)
);


CREATE OR REPLACE FUNCTION criar_agendamento( 
    n_cliente_id UUID,
    n_barbeiro_id UUID,
    n_servicos INTEGER[],
    n_data_agendada TIMESTAMPTZ
)
RETURNS BIGINT AS $$
DECLARE
    v_agendamento_id BIGINT;
    v_valor_total NUMERIC(10,2);
    v_tempo_total INTEGER;
BEGIN

    SELECT 
        SUM(preco), 
        SUM(tempo_minutos)
    INTO 
        v_valor_total, 
        v_tempo_total
    FROM servicos
    WHERE id = ANY(n_servicos)
      AND ativo = TRUE;

    IF v_valor_total IS NULL THEN
        RAISE EXCEPTION 'Serviços inválidos';
    END IF;

    INSERT INTO agendamentos(
        cliente_id,
        barbeiro_id,
        data_agendada,
        valor_total,
        tempo_total,
        data_fim
    )
    VALUES(
        n_cliente_id,
        n_barbeiro_id,
        n_data_agendada,
        v_valor_total,
        v_tempo_total,
        n_data_agendada + MAKE_INTERVAL(mins => v_tempo_total)
    )
    RETURNING id INTO v_agendamento_id;

    INSERT INTO agendamento_servico(agendamento_id, servico_id)
    SELECT v_agendamento_id, unnest(n_servicos);

    RETURN v_agendamento_id;

END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION mostrar_agendamentos(
    v_usuario_id UUID
)
RETURNS JSON AS $$
DECLARE p_dados JSON;
BEGIN
    SELECT COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'cliente',ROW_TO_JSON(C),
                'barbeiro',ROW_TO_JSON(B),
                'servicos',
                    (SELECT JSON_AGG(S)
                    FROM agendamento_servico asv
                    JOIN servicos S ON S.id = asv.servico_id
                    WHERE asv.agendamento_id = A.id
                    ),
                'data_criacao', A.data_criacao,
                'data_agendada', A.data_agendada,
                'data_fim', A.data_fim,
                'valor_total',A.valor_total,
                'tempo_total',A.tempo_total
            )
        ),
        '{}'::JSON
    )
    INTO p_dados
    FROM agendamentos A
    INNER JOIN usuarios C on C.id = A.cliente_id
    INNER JOIN usuarios B on B.id = A.barbeiro_id
    WHERE A.barbeiro_id = v_usuario_id OR A.cliente_id = v_usuario_id;

    RETURN p_dados;
END;
$$ LANGUAGE plpgsql;
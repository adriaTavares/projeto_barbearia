CREATE OR REPLACE TYPE STATUS_AGENDAMENTO AS ENUM(
    'agendado',
    'finalizado',
    'faltou',
    'cancelado'
);
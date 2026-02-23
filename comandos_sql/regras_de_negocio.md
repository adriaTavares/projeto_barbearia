# 📘 Documento de Regras de Negócio – Sistema de Barbearia

## 1. Objetivo do Sistema

O sistema tem como objetivo controlar o fluxo de agendamentos de uma barbearia, garantindo organização, controle operacional e aplicação automática das regras de negócio.

O sistema deve assegurar:

- Organização dos horários
- Controle operacional por cliente e barbeiro
- Prevenção de conflitos de horário
- Cumprimento dos limites estabelecidos

---

# 2. Entidades do Sistema

O sistema gerencia quatro entidades principais:

- Clientes
- Barbeiros
- Serviços
- Agendamentos

---

# 3. Informações Armazenadas

## 3.1 Clientes

Para cada cliente, o sistema deve armazenar:

- Nome completo
- Data de criação do cadastro
- Telefone
- E-mail
- Situação (ativo ou inativo)
- Tipo de autenticação (Google ou cadastro tradicional)

---

## 3.2 Barbeiros

Para cada barbeiro, o sistema deve armazenar:

- Nome completo
- Data de criação do cadastro
- Telefone
- E-mail
- CPF
- Percentual de comissão
- Data de nascimento
- Situação (ativo ou inativo)
- Dias de folga

---

## 3.3 Serviços

Para cada serviço disponibilizado, o sistema deve armazenar:

- Nome do serviço
- Valor base
- Tempo estimado em minutos
- Situação (ativo ou inativo)

Cada agendamento possui apenas **um serviço associado**.

---

## 3.4 Agendamentos

Para cada agendamento, o sistema deve armazenar:

- Cliente responsável
- Barbeiro responsável
- Serviço escolhido
- Data e horário do atendimento
- Data de criação
- Valor total
- Status atual

### Status possíveis:

- Agendado
- Finalizado
- Cancelado

---

# 4. Regras de Negócio

## 4.1 Regras para Clientes

1. Um cliente pode possuir no máximo **3 agendamentos futuros ativos**.
2. Um agendamento deve ser feito com no mínimo **1 dia de antecedência**.
3. Não é permitido criar agendamentos no passado.
4. O cliente pode cancelar um agendamento até **2 horas antes do horário marcado**.
5. Apenas clientes ativos podem criar agendamentos.

---

## 4.2 Regras para Barbeiros

1. Cada barbeiro pode ter no máximo **15 agendamentos por dia**.
2. O barbeiro pode cancelar um agendamento até **2 horas antes do horário marcado**.
3. Não é permitido agendar atendimento em dias de folga.
4. Apenas barbeiros ativos podem receber agendamentos.

---

## 4.3 Regras de Horário

1. Não pode haver dois agendamentos no mesmo horário para o mesmo barbeiro.
2. Deve existir um intervalo mínimo de **10 minutos entre agendamentos consecutivos**.
3. Não pode haver sobreposição considerando o tempo do serviço.
4. O sistema deve impedir agendamentos fora do horário de funcionamento da barbearia.

---

# 5. Regras Gerais

1. O valor total do agendamento deve corresponder ao valor base do serviço.
2. O status deve seguir fluxo lógico (ex: não pode finalizar algo cancelado).
3. O sistema deve garantir integridade referencial entre todas as entidades.

---
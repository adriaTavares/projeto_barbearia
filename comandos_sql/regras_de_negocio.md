# 📄 Sistema de Gerenciamento para Barbearia

A barbearia deseja um sistema completo para gerenciamento de usuários, autenticação, serviços e agendamentos, com controle de permissões e integridade de dados.

O sistema foi modelado com separação de papéis de usuário e autenticação híbrida (email/senha + OAuth).

---

# 👥 1. Usuários

Todos os usuários do sistema ficam na tabela `usuarios`.

## Estrutura Base

- id (UUID)
- nome
- email_principal (único)
- email_verificado
- ativo
- tipo_usuario_id
- data_criacao
- data_atualizacao

## Tipos de Usuário

Tabela: `tipos_usuarios`

Tipos existentes:

- cliente
- barbeiro
- admin
- master

### 📌 Regras

- Email principal deve ser único.
- Usuário pode estar ativo ou inativo.
- Todo usuário possui um tipo.
- Atualização de usuário atualiza automaticamente `data_atualizacao` via trigger.

---

# ✂️ 2. Barbeiros

Barbeiro é uma especialização de usuário.

Tabela: `barbeiros`

- usuario_id (PK e FK para usuarios)
- telefone (único)
- data_nascimento
- cpf (único)
- percentual_comissao (0 a 100)

## 📌 Regras

- Só usuários do tipo "barbeiro" devem existir nessa tabela.
- Exclusão do usuário remove automaticamente o barbeiro (ON DELETE CASCADE).
- Comissão deve estar entre 0 e 100.
- Data de nascimento não pode ser futura.

---

# 🗓 3. Dias de Folga

Tabela: `dias_de_folga_barbeiro`

- barbeiro_id
- dia_de_folga

## 📌 Regras

- Não pode haver duplicidade de folga no mesmo dia.
- Ao excluir barbeiro, remove suas folgas automaticamente.

---

# 🔐 4. Autenticação

O sistema suporta:

## 4.1 Email e Senha

Tabela: `credenciais_email`

- usuario_id
- senha_hash

## 4.2 OAuth

Tabela: `provedores_oauth`
- google
- github
- facebook
- linkedin

Tabela: `credenciais_oauth`
- usuario_id
- provedor_id
- provedor_user_id

## 4.3 Verificação de Email

Tabela: `verificacoes_email`

- usuario_id
- codigo_hash
- senha_hash
- expira_em
- usado

---

# 💈 5. Serviços

Tabela: `servicos`

- id
- nome (único)
- descricao
- preco
- tempo_minutos
- ativo

## 📌 Regras

- Preço ≥ 0
- Tempo > 0
- Serviço inativo não pode ser usado em novos agendamentos.

---

# 📅 6. Agendamentos

Tabela: `agendamentos`

- id
- cliente_id (usuario)
- barbeiro_id
- data_criacao
- data_agendada
- data_fim
- valor_total
- tempo_total
- status_id

## Status possíveis

Tabela: `status_agendamento`

- agendado
- finalizado
- cancelado
- faltou

---

## 📌 Regras de Agendamento

### 🔹 Horário de Funcionamento

- Segunda a sábado
- 07:00 às 12:00
- 14:00 às 20:00
- Não pode domingo
- Não pode no passado

---

### 🔹 Integridade Temporal

- `data_fim` deve ser maior que `data_agendada`
- Tempo_total deve corresponder à soma dos serviços
- Valor_total deve corresponder à soma dos serviços


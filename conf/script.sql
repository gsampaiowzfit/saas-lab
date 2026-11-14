-- ===================================================================
-- Script de Configuração do Banco de Dados - SaaS Lab
-- Banco de dados: enterprise
-- Usuário da aplicação: saas
-- ===================================================================

-- 1. Criação do usuário de banco com privilégios locais
CREATE USER IF NOT EXISTS 'saas'@'localhost' IDENTIFIED BY 'saas';

-- 2. Criação da base de dados do sistema multi-inquilino
CREATE DATABASE IF NOT EXISTS enterprise 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- 3. Concessão de todas as permissões ao usuário da aplicação
GRANT ALL PRIVILEGES ON enterprise.* TO 'saas'@'localhost';
FLUSH PRIVILEGES;

USE enterprise;

-- 4. Tabela de Autenticação e Sessão (Pilar de Segurança do SaaS)
CREATE TABLE IF NOT EXISTS autenticacaoMais (
  id INT NOT NULL AUTO_INCREMENT,
  usuario VARCHAR(50) NOT NULL UNIQUE,
  senha VARCHAR(64) NOT NULL,
  tokenvigente VARCHAR(128) DEFAULT NULL,
  ultimo_acesso DATETIME DEFAULT NULL,
  PRIMARY KEY (id)
);

-- Carga inicial de usuários com senhas em hash MD5
-- Credenciais de teste:
-- 1. admin / admin
-- 2. saas / saas
-- 3. medico / 123456
INSERT INTO autenticacaoMais (usuario, senha) VALUES
  ('admin', MD5('admin')),
  ('saas', MD5('saas')),
  ('medico', MD5('123456'))
ON DUPLICATE KEY UPDATE senha = VALUES(senha);

-- 5. Tabelas do Domínio do Sistema (Agendamento Médico)
CREATE TABLE IF NOT EXISTS medicos (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  crm VARCHAR(20) NOT NULL,
  especialidade VARCHAR(50) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS pacientes (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  cpf VARCHAR(20) NOT NULL,
  data_nascimento DATE NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS consultas (
  id INT NOT NULL AUTO_INCREMENT,
  medico_id INT NOT NULL,
  paciente_id INT NOT NULL,
  data_consulta DATETIME NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (medico_id) REFERENCES medicos(id),
  FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
);

-- Carga de exemplo para médicos e pacientes
INSERT INTO medicos (nome, crm, especialidade) VALUES 
  ('Dr. Carlos Eduardo', 'CRM/SP 123456', 'Cardiologia'),
  ('Dra. Mariana Costa', 'CRM/SP 654321', 'Dermatologia')
ON DUPLICATE KEY UPDATE nome = VALUES(nome);

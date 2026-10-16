CREATE USER 'saas'@'localhost' identified by 'saas';

CREATE DATABASE SUSBOM

GRANT ALL PRIVILEGES ON SUSBOM .* TO 'saas'@'localhost';

FLUSH PRIVILEGES;

USE SUSBOM

CREATE TABLE medicos (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  crm VARCHAR(20) NOT NULL,
  especialidade VARCHAR(50) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE pacientes (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  cpf VARCHAR(20) NOT NULL,
  data_nascimento DATE NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE consultas (
  id INT NOT NULL AUTO_INCREMENT,
  medico_id INT NOT NULL,
  paciente_id INT NOT NULL,
  data_consulta DATETIME NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (medico_id) REFERENCES medicos(id),
  FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
);
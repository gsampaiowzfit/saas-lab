# SaaS Lab - Sistema de Autenticação e Agendamento

Este projeto faz parte do laboratório prático de infraestrutura e arquitetura de software para ambiente multi-inquilino / SaaS (Software as a Service), evoluindo de uma interface estática para uma aplicação dinâmica com **Apache Tomcat**, **JSP (JavaServer Pages)** e **MySQL**.

---

## 🏛️ Arquitetura da Solução

O fluxo de autenticação segura e controle de sessão é fundamentado em três pilares:

```
+----------------+          +-----------------+          +-----------------+
|   index.jsp    |  POST    |    login.jsp    | Sucesso  |   autorizo.jsp  |
| (Formulário &  | -------> |   (Validação,   | -------> | (Área Restrita  |
| Checagem Anti- |          |   MD5, Token e  |          |  com Validação  |
|     Cache)     |          |  Banco MySQL)   |          |    de Sessão)   |
+----------------+          +-----------------+          +-----------------+
        ^                                                         |
        |                  Falha / Sessão Inválida                |
        +---------------------------------------------------------+
```

1. **`index.jsp` (Frontend / Entrada):**
   - Desabilita cache HTTP (`Cache-Control: no-cache, no-store`).
   - Verifica se o cliente já possui uma sessão ativa com token válido: se sim, redireciona diretamente para `autorizo.jsp`.
   - Provê formulário de login com método POST direcionado para `login.jsp`.

2. **`login.jsp` (Motor de Autenticação):**
   - Desabilita cache.
   - Conecta ao MySQL via JDBC (`java.sql.*`).
   - Valida as credenciais com hashing MD5.
   - Ao autenticar com sucesso, captura o `session.getId()` e registra o token na coluna `tokenvigente` e o timestamp de acesso no banco de dados.
   - Armazena os atributos na sessão Java e direciona para o sistema.

3. **`autorizo.jsp` (Área Restrita do Sistema):**
   - Valida a integridade da sessão comparando os atributos de sessão com `session.getId()`.
   - Se for nulo ou inválido, bloqueia o acesso e redireciona de volta para `index.jsp`.

---

## 🚀 Roteiro de Execução e Deploy

| Passo | Descrição | Status |
| :--- | :--- | :---: |
| **Passo 1** | Conversão de `index.html` para `index.jsp` com anti-cache e verificação de sessão | 🟢 Concluído |
| **Passo 2** | Construção do backend de autenticação (`login.jsp`) com JDBC e MD5 | 🟢 Concluído |
| **Passo 3** | Criação da página restrita (`autorizo.jsp`) com barreira de sessão | 🟡 Pendente |
| **Passo 4** | Preparação do banco de dados na VM (`enterprise` / `autenticacaoMais`) | ⚪ A Fazer |
| **Passo 5** | Deploy dos arquivos na pasta de aplicações web do Tomcat | ⚪ A Fazer |
| **Passo 6** | Configuração do pool de conexões/threads e testes no Tomcat Manager | ⚪ A Fazer |

---

## 🛠️ Ambiente de Referência

- **SO da VM:** Ubuntu Server
- **Servidor Web / Servlet Container:** Apache Tomcat
- **Banco de Dados:** MySQL 8.x
- **Linguagem / Framework:** JSP / Java EE

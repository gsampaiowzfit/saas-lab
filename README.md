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
| **Passo 3** | Criação da página restrita (`autorizo.jsp`) com barreira de sessão | 🟢 Concluído |
| **Passo 4** | Preparação do banco de dados na VM (`enterprise` / `autenticacaoMais`) | 🟢 Concluído |
| **Passo 5** | Deploy dos arquivos na pasta de aplicações web do Tomcat | 🟢 Concluído |
| **Passo 6** | Configuração do pool de conexões/threads e testes no Tomcat Manager | 🟡 Pendente |

---

## 🚀 Transferência de Arquivos e Deploy no Tomcat (Passo 5)

Existem duas formas simples de transferir os arquivos do seu computador para a VM:

### Opção A: Clonar diretamente via Git na VM (Recomendado)
Na VM (via SSH):
```bash
# Clone ou navegue até o repositório
git clone <URL_DO_SEU_REPOSITORIO> saas-lab
cd saas-lab
git checkout feat/deploy-tomcat-vm

# Execute o script automatizado de deploy
chmod +x deploy.sh
./deploy.sh
```

### Opção B: Transferir via SCP pelo Windows (PowerShell)
No seu terminal local (Windows):
```powershell
# Transferir os arquivos da aplicação para a pasta home do usuário na VM
scp -r index.jsp login.jsp autorizo.jsp WEB-INF deploy.sh conf usuario@IP_DA_VM:~/saas-lab/
```

Em seguida, na VM (via SSH):
```bash
cd ~/saas-lab
chmod +x deploy.sh
./deploy.sh
```

### Localização Padrão no Tomcat:
A aplicação é instalada em:
```text
/var/lib/tomcat9/webapps/saas-lab/
  ├── index.jsp
  ├── login.jsp
  ├── autorizo.jsp
  └── WEB-INF/
        └── web.xml
```

> [!IMPORTANT]
> **Driver JDBC do MySQL:** Para que o `login.jsp` consiga se conectar ao MySQL, o Tomcat precisa ter o arquivo `.jar` do conector JDBC em sua pasta `lib` (ex: `/var/lib/tomcat9/lib/` ou `/opt/tomcat/lib/`). O script `deploy.sh` verifica e instala automaticamente se necessário (`sudo apt install libmysql-java`).

---

## 🗄️ Execução do Script SQL na VM (Passo 4)

Para preparar a base de dados na Máquina Virtual via SSH:

1. **Acessar a VM:**
   ```bash
   ssh seu_usuario@IP_DA_VM
   ```

2. **Executar o script SQL:**
   ```bash
   sudo mysql < conf/script.sql
   # ou interativamente:
   sudo mysql -u root -p < conf/script.sql
   ```

3. **Verificar a criação:**
   ```bash
   mysql -u saas -psaas enterprise -e "SELECT id, usuario, tokenvigente, ultimo_acesso FROM autenticacaoMais;"
   ```

### Usuários de Teste Pré-Configurados
* **Usuário:** `admin` | **Senha:** `admin`
* **Usuário:** `saas` | **Senha:** `saas`
* **Usuário:** `medico` | **Senha:** `123456`

---

## 🛠️ Ambiente de Referência

- **SO da VM:** Ubuntu Server
- **Servidor Web / Servlet Container:** Apache Tomcat
- **Banco de Dados:** MySQL 8.x
- **Linguagem / Framework:** JSP / Java EE

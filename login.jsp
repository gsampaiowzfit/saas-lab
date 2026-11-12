<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.security.MessageDigest" %>
<%
    // Desabilitar o cache do navegador e proxies
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Dados de conexão com o MySQL
    String dbHost = "localhost";
    String dbPort = "3306";
    String dbName = "enterprise";
    String dbUser = "saas";
    String dbPass = "saas";
    String dbUrl = "jdbc:mysql://" + dbHost + ":" + dbPort + "/" + dbName + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    // Obtenção dos parâmetros do formulário
    String usuario = request.getParameter("user");
    String senha = request.getParameter("pass");

    boolean autenticado = false;
    String mensagemErro = null;

    if (usuario == null || senha == null || usuario.trim().isEmpty() || senha.trim().isEmpty()) {
        mensagemErro = "Por favor, preencha o nome de usuário e a senha.";
    } else {
        Connection conn = null;
        PreparedStatement stmtSelect = null;
        PreparedStatement stmtUpdate = null;
        ResultSet rs = null;

        try {
            // Conversão da senha para MD5
            MessageDigest md = MessageDigest.getInstance("MD5");
            md.update(senha.getBytes("UTF-8"));
            byte[] digest = md.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            String senhaMD5 = sb.toString();

            // Carregamento do driver JDBC
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

            // Validação de credenciais (suporta hash MD5 ou texto)
            String sqlSelect = "SELECT * FROM autenticacaoMais WHERE usuario = ? AND (senha = ? OR senha = MD5(?))";
            stmtSelect = conn.prepareStatement(sqlSelect);
            stmtSelect.setString(1, usuario);
            stmtSelect.setString(2, senhaMD5);
            stmtSelect.setString(3, senha);

            rs = stmtSelect.executeQuery();

            if (rs.next()) {
                autenticado = true;
                String tokenSessao = session.getId();

                // Atualização do tokenvigente e da hora de acesso no banco de dados
                String sqlUpdate = "UPDATE autenticacaoMais SET tokenvigente = ?, ultimo_acesso = NOW() WHERE usuario = ?";
                stmtUpdate = conn.prepareStatement(sqlUpdate);
                stmtUpdate.setString(1, tokenSessao);
                stmtUpdate.setString(2, usuario);
                stmtUpdate.executeUpdate();

                // Criação das variáveis de sessão na memória do Tomcat
                session.setAttribute("usuario", usuario);
                session.setAttribute("token", tokenSessao);
            } else {
                mensagemErro = "Usuário ou senha inválidos.";
            }

        } catch (ClassNotFoundException e) {
            mensagemErro = "Erro interno: Driver MySQL JDBC não encontrado no Tomcat. (" + e.getMessage() + ")";
        } catch (SQLException e) {
            mensagemErro = "Erro ao conectar com o banco de dados: " + e.getMessage();
        } catch (Exception e) {
            mensagemErro = "Erro inesperado: " + e.getMessage();
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignored) {}
            if (stmtSelect != null) try { stmtSelect.close(); } catch (Exception ignored) {}
            if (stmtUpdate != null) try { stmtUpdate.close(); } catch (Exception ignored) {}
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }
%>
<!doctype html>
<html lang="pt-br">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Autenticação</title>
    <style>
      body {
        min-height: 100vh;
        margin: 0;
        display: flex;
        justify-content: center;
        align-items: center;
        font-family: Arial;
      }
      .tabela {
        width: 440px;
        color: rgb(102, 101, 101);
        border: 1px solid;
        padding: 20px;
        text-align: center;
      }
      .sucesso {
        color: #2e7d32;
        font-size: 16pt;
        font-weight: bold;
        margin-bottom: 15px;
      }
      .erro {
        color: #c62828;
        font-size: 14pt;
        font-weight: bold;
        margin-bottom: 15px;
      }
      .info {
        font-size: 12pt;
        color: #555;
        margin-bottom: 20px;
        word-break: break-all;
      }
      .btn {
        display: inline-block;
        font-size: 14pt;
        color: white;
        background-color: #1976d2;
        padding: 10px 20px;
        text-decoration: none;
        border-radius: 4px;
      }
      .btn:hover {
        background-color: #1565c0;
      }
      .btn-voltar {
        background-color: #757575;
      }
      .btn-voltar:hover {
        background-color: #616161;
      }
    </style>
  </head>
  <body>
    <div class="tabela">
      <% if (autenticado) { %>
        <div class="sucesso">✓ Autenticação realizada com sucesso!</div>
        <div class="info">
          <strong>Usuário:</strong> <%= usuario %><br />
          <strong>Token Vigente (Session ID):</strong> <%= session.getId() %>
        </div>
        <div>
          <a class="btn" href="autorizo.jsp">ACESSAR SISTEMA RESTRITO</a>
        </div>
      <% } else { %>
        <div class="erro">✕ Falha na Autenticação</div>
        <div class="info"><%= mensagemErro %></div>
        <div>
          <a class="btn btn-voltar" href="index.jsp">VOLTAR AO LOGIN</a>
        </div>
      <% } %>
    </div>
  </body>
</html>

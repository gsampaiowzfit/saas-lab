<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Desabilitar o cache do navegador e proxies
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Tratamento de encerramento de sessão (Logout)
    String logoutParam = request.getParameter("logout");
    if ("true".equals(logoutParam)) {
        session.removeAttribute("usuario");
        session.removeAttribute("token");
        session.invalidate();
        response.sendRedirect("index.jsp");
        return;
    }

    // Validação de Sessão: verifica se a sessão é nula ou diferente de session.getId()
    String tokenSessao = (String) session.getAttribute("token");
    String usuarioLogado = (String) session.getAttribute("usuario");

    if (tokenSessao == null || !tokenSessao.equals(session.getId())) {
        // Redireciona forçadamente para a tela de login caso tente acessar sem autenticação
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!doctype html>
<html lang="pt-br">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Área Restrita - SaaS Lab</title>
    <style>
      body {
        margin: 0;
        font-family: Arial, sans-serif;
        background-color: #f4f6f8;
        color: #333;
      }
      .navbar {
        background-color: #1976d2;
        color: white;
        padding: 15px 30px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .navbar h1 {
        margin: 0;
        font-size: 20px;
      }
      .navbar .user-info {
        font-size: 14px;
      }
      .navbar .btn-logout {
        background-color: #d32f2f;
        color: white;
        text-decoration: none;
        padding: 8px 16px;
        border-radius: 4px;
        font-weight: bold;
        margin-left: 15px;
      }
      .navbar .btn-logout:hover {
        background-color: #b71c1c;
      }
      .container {
        max-width: 900px;
        margin: 40px auto;
        padding: 20px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      }
      .status-badge {
        display: inline-block;
        background-color: #e8f5e9;
        color: #2e7d32;
        padding: 6px 14px;
        border-radius: 20px;
        font-weight: bold;
        font-size: 13px;
        margin-bottom: 20px;
      }
      .card-info {
        background-color: #f9fafb;
        border-left: 4px solid #1976d2;
        padding: 15px 20px;
        margin-bottom: 25px;
        border-radius: 0 4px 4px 0;
      }
      .card-info p {
        margin: 8px 0;
        font-size: 14px;
      }
      .card-info code {
        background-color: #e5e7eb;
        padding: 2px 6px;
        border-radius: 3px;
        font-family: Consolas, monospace;
        color: #111;
      }
      .actions {
        display: flex;
        gap: 15px;
        margin-top: 30px;
      }
      .btn-action {
        background-color: #1976d2;
        color: white;
        text-decoration: none;
        padding: 12px 20px;
        border-radius: 4px;
        font-size: 14px;
        text-align: center;
      }
      .btn-action:hover {
        background-color: #1565c0;
      }
    </style>
  </head>
  <body>
    <header class="navbar">
      <h1>SaaS Lab - Painel Administrativo</h1>
      <div class="user-info">
        Olá, <strong><%= usuarioLogado %></strong>
        <a class="btn-logout" href="autorizo.jsp?logout=true">Encerrar Sessão</a>
      </div>
    </header>

    <main class="container">
      <div class="status-badge">● SESSÃO AUTORIZADA E ATIVA</div>
      
      <h2>Bem-vindo à Área Restrita do Sistema</h2>
      <p>Você acessou o sistema com controle de sessão gerenciado em memória pelo Apache Tomcat e validado contra o banco de dados MySQL.</p>

      <section class="card-info">
        <h3>Detalhes da Sessão Vigente</h3>
        <p><strong>Usuário Autenticado:</strong> <code><%= usuarioLogado %></code></p>
        <p><strong>Session ID (Memória Tomcat):</strong> <code><%= session.getId() %></code></p>
        <p><strong>Token de Sessão:</strong> <code><%= tokenSessao %></code></p>
        <p><strong>Hora da Criação da Sessão:</strong> <code><%= new java.util.Date(session.getCreationTime()) %></code></p>
        <p><strong>Último Acesso Registrado:</strong> <code><%= new java.util.Date(session.getLastAccessedTime()) %></code></p>
      </section>

      <section>
        <h3>Recursos do Sistema SaaS</h3>
        <p>A arquitetura de 3 pilares garante que qualquer tentativa de navegação direta sem token ativo redirecione para a tela de autenticação.</p>
        <div class="actions">
          <a class="btn-action" href="autorizo.jsp">Recarregar Página (Manter Sessão)</a>
          <a class="btn-action" style="background-color: #455a64;" href="autorizo.jsp?logout=true">Efetuar Logout Seguro</a>
        </div>
      </section>
    </main>
  </body>
</html>

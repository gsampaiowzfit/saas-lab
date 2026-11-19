<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%
    request.setCharacterEncoding("UTF-8");

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
        response.sendRedirect("index.jsp");
        return;
    }

    // Configuração de conexão com o MySQL
    String dbUrl = "jdbc:mysql://localhost:3306/enterprise?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    String dbUser = "saas";
    String dbPass = "saas";

    String mensagemSucesso = (String) session.getAttribute("flashSucesso");
    String mensagemErro = (String) session.getAttribute("flashErro");
    session.removeAttribute("flashSucesso");
    session.removeAttribute("flashErro");

    List<Map<String, String>> listaMedicos = new ArrayList<>();
    List<Map<String, String>> listaConsultas = new ArrayList<>();

    boolean redirecionar = false;
    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // 1. Cancelamento de consulta (via GET ?cancelar=ID)
        String cancelarId = request.getParameter("cancelar");
        if (cancelarId != null && !cancelarId.trim().isEmpty()) {
            try (PreparedStatement psDel = conn.prepareStatement("DELETE FROM consultas WHERE id = ?")) {
                psDel.setInt(1, Integer.parseInt(cancelarId));
                int removidos = psDel.executeUpdate();
                if (removidos > 0) {
                    session.setAttribute("flashSucesso", "Consulta #" + cancelarId + " cancelada com sucesso.");
                }
            }
            redirecionar = true;
        }

        // 2. Agendamento de nova consulta (via POST)
        if (!redirecionar && "POST".equalsIgnoreCase(request.getMethod()) && "agendar".equals(request.getParameter("acao"))) {
            String medicoIdStr = request.getParameter("medico_id");
            String pacienteNome = request.getParameter("paciente_nome");
            String pacienteCpf = request.getParameter("paciente_cpf");
            String pacienteNasc = request.getParameter("paciente_nasc");
            String dataConsulta = request.getParameter("data_consulta");

            if (medicoIdStr == null || pacienteNome == null || pacienteCpf == null || pacienteNasc == null || dataConsulta == null ||
                medicoIdStr.trim().isEmpty() || pacienteNome.trim().isEmpty() || pacienteCpf.trim().isEmpty() || pacienteNasc.trim().isEmpty() || dataConsulta.trim().isEmpty()) {
                session.setAttribute("flashErro", "Preencha todos os campos para agendar a consulta.");
            } else {
                String cpfDigitos = pacienteCpf.replaceAll("\\D", "");
                if (cpfDigitos.length() != 11) {
                    session.setAttribute("flashErro", "Informe um CPF válido com 11 dígitos.");
                } else {
                    String cpfFormatado = cpfDigitos.replaceFirst("(\\d{3})(\\d{3})(\\d{3})(\\d{2})", "$1.$2.$3-$4");
                    int medicoId = Integer.parseInt(medicoIdStr);

                    // Converte formato HTML datetime-local (YYYY-MM-DDTHH:MM) para MySQL (YYYY-MM-DD HH:MM:SS)
                    String dataFormatada = dataConsulta.replace("T", " ");
                    if (dataFormatada.length() == 16) {
                        dataFormatada += ":00";
                    }

                    // Verifica conflito de horário para o mesmo médico
                    boolean conflitoHorario = false;
                    try (PreparedStatement psConflito = conn.prepareStatement(
                            "SELECT id FROM consultas WHERE medico_id = ? AND data_consulta = ? LIMIT 1")) {
                        psConflito.setInt(1, medicoId);
                        psConflito.setString(2, dataFormatada);
                        try (ResultSet rsConflito = psConflito.executeQuery()) {
                            if (rsConflito.next()) {
                                conflitoHorario = true;
                            }
                        }
                    }

                    if (conflitoHorario) {
                        session.setAttribute("flashErro", "Este médico já possui uma consulta agendada para esta data e horário.");
                    } else {
                        int pacienteId = -1;

                        // Verifica se o paciente já existe pelo CPF
                        try (PreparedStatement psBuscaPac = conn.prepareStatement("SELECT id FROM pacientes WHERE cpf = ? LIMIT 1")) {
                            psBuscaPac.setString(1, cpfFormatado);
                            try (ResultSet rsPac = psBuscaPac.executeQuery()) {
                                if (rsPac.next()) {
                                    pacienteId = rsPac.getInt("id");
                                }
                            }
                        }

                        // Se não existir, cadastra o paciente automaticamente
                        if (pacienteId == -1) {
                            try (PreparedStatement psInsPac = conn.prepareStatement(
                                    "INSERT INTO pacientes (nome, cpf, data_nascimento) VALUES (?, ?, ?)",
                                    Statement.RETURN_GENERATED_KEYS)) {
                                psInsPac.setString(1, pacienteNome.trim());
                                psInsPac.setString(2, cpfFormatado);
                                psInsPac.setString(3, pacienteNasc.trim());
                                psInsPac.executeUpdate();
                                try (ResultSet rsKeys = psInsPac.getGeneratedKeys()) {
                                    if (rsKeys.next()) {
                                        pacienteId = rsKeys.getInt(1);
                                    }
                                }
                            }
                        }

                        try (PreparedStatement psInsCons = conn.prepareStatement(
                                "INSERT INTO consultas (medico_id, paciente_id, data_consulta) VALUES (?, ?, ?)")) {
                            psInsCons.setInt(1, medicoId);
                            psInsCons.setInt(2, pacienteId);
                            psInsCons.setString(3, dataFormatada);
                            psInsCons.executeUpdate();
                            session.setAttribute("flashSucesso", "Consulta agendada com sucesso para " + pacienteNome.trim() + "!");
                        }
                    }
                }
            }
            redirecionar = true;
        }

        if (!redirecionar) {
            // 3. Carrega lista de médicos para o select
            try (PreparedStatement psMed = conn.prepareStatement("SELECT id, nome, especialidade FROM medicos ORDER BY nome");
                 ResultSet rsMed = psMed.executeQuery()) {
                while (rsMed.next()) {
                    Map<String, String> med = new HashMap<>();
                    med.put("id", rsMed.getString("id"));
                    med.put("nome", rsMed.getString("nome"));
                    med.put("especialidade", rsMed.getString("especialidade"));
                    listaMedicos.add(med);
                }
            }

            // 4. Carrega consultas agendadas com JOIN
            String sqlConsultas =
                "SELECT c.id, m.nome AS medico, m.especialidade, p.nome AS paciente, p.cpf, " +
                "DATE_FORMAT(c.data_consulta, '%d/%m/%Y %H:%i') AS data_formatada " +
                "FROM consultas c " +
                "JOIN medicos m ON c.medico_id = m.id " +
                "JOIN pacientes p ON c.paciente_id = p.id " +
                "ORDER BY c.data_consulta ASC";
            try (PreparedStatement psCons = conn.prepareStatement(sqlConsultas);
                 ResultSet rsCons = psCons.executeQuery()) {
                while (rsCons.next()) {
                    Map<String, String> cons = new HashMap<>();
                    cons.put("id", rsCons.getString("id"));
                    cons.put("medico", rsCons.getString("medico"));
                    cons.put("especialidade", rsCons.getString("especialidade"));
                    cons.put("paciente", rsCons.getString("paciente"));
                    cons.put("cpf", rsCons.getString("cpf"));
                    cons.put("data_formatada", rsCons.getString("data_formatada"));
                    listaConsultas.add(cons);
                }
            }
        }
    } catch (Exception e) {
        if ("POST".equalsIgnoreCase(request.getMethod()) || request.getParameter("cancelar") != null) {
            session.setAttribute("flashErro", "Erro ao acessar o banco de dados: " + e.getMessage());
            redirecionar = true;
        } else {
            mensagemErro = "Erro ao acessar o banco de dados: " + e.getMessage();
        }
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    if (redirecionar) {
        response.sendRedirect("autorizo.jsp");
        return;
    }
%>
<!doctype html>
<html lang="pt-br">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Agendamento de Consultas - SaaS Lab</title>
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
        max-width: 960px;
        margin: 30px auto;
        padding: 25px;
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
        font-size: 12px;
        margin-bottom: 15px;
      }
      .card-info {
        background-color: #f9fafb;
        border-left: 4px solid #1976d2;
        padding: 12px 18px;
        margin-bottom: 25px;
        border-radius: 0 4px 4px 0;
        font-size: 13px;
      }
      .card-info p {
        margin: 5px 0;
      }
      .card-info code {
        background-color: #e5e7eb;
        padding: 2px 6px;
        border-radius: 3px;
        font-family: Consolas, monospace;
      }
      .alert-success {
        background-color: #e8f5e9;
        color: #2e7d32;
        border: 1px solid #a5d6a7;
        padding: 12px 16px;
        border-radius: 4px;
        margin-bottom: 20px;
        font-size: 14px;
      }
      .alert-error {
        background-color: #ffebee;
        color: #c62828;
        border: 1px solid #ef9a9a;
        padding: 12px 16px;
        border-radius: 4px;
        margin-bottom: 20px;
        font-size: 14px;
      }
      .form-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
        background-color: #fafafa;
        padding: 20px;
        border: 1px solid #e0e0e0;
        border-radius: 6px;
        margin-bottom: 30px;
      }
      .form-group {
        display: flex;
        flex-direction: column;
      }
      .form-group label {
        font-size: 13px;
        font-weight: bold;
        margin-bottom: 6px;
        color: #444;
      }
      .form-group input,
      .form-group select {
        padding: 8px 10px;
        border: 1px solid #ccc;
        border-radius: 4px;
        font-size: 14px;
      }
      .btn-submit {
        grid-column: 1 / -1;
        background-color: #1976d2;
        color: white;
        border: none;
        padding: 12px;
        border-radius: 4px;
        font-size: 15px;
        font-weight: bold;
        cursor: pointer;
      }
      .btn-submit:hover {
        background-color: #1565c0;
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 10px;
        font-size: 14px;
      }
      th, td {
        padding: 12px 10px;
        border-bottom: 1px solid #e0e0e0;
        text-align: left;
      }
      th {
        background-color: #f1f5f9;
        color: #333;
      }
      .btn-cancelar {
        color: #d32f2f;
        text-decoration: none;
        font-weight: bold;
        font-size: 13px;
      }
      .btn-cancelar:hover {
        text-decoration: underline;
      }
      .empty-state {
        text-align: center;
        color: #777;
        padding: 25px;
        background-color: #fafafa;
        border: 1px dashed #ccc;
        border-radius: 6px;
      }
    </style>
  </head>
  <body>
    <header class="navbar">
      <h1>SaaS Lab — Agendamento de Consultas</h1>
      <div class="user-info">
        Olá, <strong><%= usuarioLogado %></strong>
        <a class="btn-logout" href="autorizo.jsp?logout=true">Encerrar Sessão</a>
      </div>
    </header>

    <main class="container">
      <div class="status-badge">● SESSÃO AUTORIZADA E ATIVA</div>

      <section class="card-info">
        <p><strong>Usuário:</strong> <code><%= usuarioLogado %></code> | <strong>Session ID (Tomcat):</strong> <code><%= session.getId() %></code></p>
      </section>

      <% if (mensagemSucesso != null) { %>
        <div class="alert-success">✓ <%= mensagemSucesso %></div>
      <% } %>
      <% if (mensagemErro != null) { %>
        <div class="alert-error">✕ <%= mensagemErro %></div>
      <% } %>

      <h2>Agendar Nova Consulta</h2>
      <form class="form-grid" action="autorizo.jsp" method="post">
        <input type="hidden" name="acao" value="agendar" />

        <div class="form-group">
          <label for="medico_id">Médico</label>
          <select id="medico_id" name="medico_id" required>
            <option value="">Selecione um médico...</option>
            <% for (Map<String, String> m : listaMedicos) { %>
              <option value="<%= m.get("id") %>"><%= m.get("nome") %> (<%= m.get("especialidade") %>)</option>
            <% } %>
          </select>
        </div>

        <div class="form-group">
          <label for="paciente_nome">Nome do Paciente</label>
          <input id="paciente_nome" type="text" name="paciente_nome" placeholder="Ex: João da Silva" required />
        </div>

        <div class="form-group">
          <label for="paciente_cpf">CPF do Paciente</label>
          <input id="paciente_cpf" type="text" name="paciente_cpf" placeholder="000.000.000-00" maxlength="14" inputmode="numeric" pattern="\d{3}\.\d{3}\.\d{3}-\d{2}" title="Digite um CPF no formato 000.000.000-00" required />
        </div>

        <div class="form-group">
          <label for="paciente_nasc">Data de Nascimento</label>
          <input id="paciente_nasc" type="date" name="paciente_nasc" required />
        </div>

        <div class="form-group">
          <label for="data_consulta">Data e Hora da Consulta</label>
          <input id="data_consulta" type="datetime-local" name="data_consulta" required />
        </div>

        <button type="submit" class="btn-submit">+ AGENDAR CONSULTA</button>
      </form>

      <h2>Consultas Agendadas</h2>
      <% if (listaConsultas.isEmpty()) { %>
        <div class="empty-state">Nenhuma consulta agendada até o momento.</div>
      <% } else { %>
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Data / Hora</th>
              <th>Paciente</th>
              <th>CPF</th>
              <th>Médico</th>
              <th>Especialidade</th>
              <th>Ação</th>
            </tr>
          </thead>
          <tbody>
            <% for (Map<String, String> c : listaConsultas) { %>
              <tr>
                <td><%= c.get("id") %></td>
                <td><strong><%= c.get("data_formatada") %></strong></td>
                <td><%= c.get("paciente") %></td>
                <td><%= c.get("cpf") %></td>
                <td><%= c.get("medico") %></td>
                <td><%= c.get("especialidade") %></td>
                <td>
                  <a class="btn-cancelar" href="autorizo.jsp?cancelar=<%= c.get("id") %>" onclick="return confirm('Deseja cancelar esta consulta?');">Cancelar</a>
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </main>
    <script>
      (function () {
        var cpfInput = document.getElementById("paciente_cpf");
        if (!cpfInput) return;

        function aplicarMascaraCpf(valor) {
          var digitos = valor.replace(/\D/g, "").slice(0, 11);
          digitos = digitos.replace(/(\d{3})(\d)/, "$1.$2");
          digitos = digitos.replace(/(\d{3})(\d)/, "$1.$2");
          digitos = digitos.replace(/(\d{3})(\d{1,2})$/, "$1-$2");
          return digitos;
        }

        cpfInput.addEventListener("input", function (e) {
          e.target.value = aplicarMascaraCpf(e.target.value);
        });
      })();
    </script>
  </body>
</html>

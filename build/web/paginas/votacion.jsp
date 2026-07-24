<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List, java.util.Map"%>
<%
    String paso = (String) request.getAttribute("paso");
    if (paso == null) paso = "1";
    Map<String, Object> comunero = (Map<String, Object>) request.getAttribute("comunero");
    List<Map<String, Object>> candidatos = (List<Map<String, Object>>) request.getAttribute("candidatos");
    Map<String, Object> eleccion = (Map<String, Object>) request.getAttribute("eleccion");
    String errorVotacion = (String) request.getAttribute("error");
    if (candidatos == null) candidatos = java.util.Collections.emptyList();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Votación - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/public.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0f172a, #1a237e, #283593); min-height: 100vh; padding: 20px; font-family: 'Segoe UI', system-ui, sans-serif; }
    </style>
</head>
<body>
    <% if ("1".equals(paso)) { %>
    <div class="login-card">
        <div class="login-header">
            <h1><i class="bi bi-check2-square me-2"></i>Votación</h1>
            <p>Ingrese sus credenciales electorales</p>
        </div>
        <div class="login-body">
            <% if (errorVotacion != null && !errorVotacion.isEmpty()) { %>
            <div class="alert alert-danger d-flex align-items-center" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i><div><%= errorVotacion %></div>
            </div>
            <% } %>
            <form method="POST" action="VotacionServlet">
                <input type="hidden" name="paso" value="2">
                <div class="mb-3">
                    <label class="form-label fw-semibold"><i class="bi bi-card-text me-1"></i>DNI</label>
                    <input type="text" class="form-control" name="dni" placeholder="Número de DNI" required autofocus>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold"><i class="bi bi-key me-1"></i>Código Personal</label>
                    <input type="text" class="form-control" name="codigo" placeholder="Código de comunero" required>
                </div>
                <div class="mb-4">
                    <label class="form-label fw-semibold"><i class="bi bi-shield-lock me-1"></i>Clave de Votación (6 dígitos)</label>
                    <input type="password" class="form-control" name="clave" placeholder="******" maxlength="6" inputmode="numeric" required>
                </div>
                <button type="submit" class="btn-ingresar">
                    <i class="bi bi-arrow-right me-2"></i>Verificar e Ingresar
                </button>
            </form>
            <footer>
                <i class="bi bi-shield-fill-check text-success me-1"></i>
                Proceso electoral transparente y seguro
            </footer>
        </div>
    </div>
    <% } else if ("2".equals(paso) && comunero != null) { %>
    <div class="voto-card">
        <div class="voto-header">
            <div class="d-flex align-items-center">
                <div>
                    <h1 class="mb-0 fs-4"><i class="bi bi-check2-square me-2"></i>Seleccione su voto</h1>
                    <p class="mb-0 mt-1">
                        <strong><%= comunero.get("nombres") %> <%= comunero.get("apellidos") %></strong>
                        &middot; <%= comunero.get("dni") %> &middot; <%= comunero.get("caserio") %>
                    </p>
                    <% if (eleccion != null) { %>
                    <small style="opacity:.7"><i class="bi bi-calendar-event me-1"></i><%= eleccion.get("nombre") %></small>
                    <% } %>
                </div>
            </div>
        </div>
        <div class="voto-body">
            <p class="text-muted mb-3 fw-semibold"><i class="bi bi-hand-index me-1"></i>Seleccione un candidato o elija "Voto en Blanco"</p>
            <% if (errorVotacion != null && !errorVotacion.isEmpty()) { %>
            <div class="alert alert-danger"><i class="bi bi-exclamation-triangle-fill me-2"></i><%= errorVotacion %></div>
            <% } %>
            <form id="votoForm" method="POST" action="VotacionServlet">
                <input type="hidden" name="paso" value="confirmar">
                <input type="hidden" name="dni" value="<%= comunero.get("dni") %>">
                <input type="hidden" name="codigo" value="<%= comunero.get("codigo") %>">
                <input type="hidden" name="clave" value="<%= request.getAttribute("claveIngresada") != null ? request.getAttribute("claveIngresada") : "" %>">
                <input type="hidden" name="idCandidato" id="idCandidato" value="">
                <div class="row g-3 mb-3">
                    <% for (Map<String, Object> cand : candidatos) { %>
                    <div class="col-6 col-md-4">
                        <div class="candidato-card text-center" data-id="<%= cand.get("idCandidato") %>" onclick="seleccionar(this)">
                            <% if (cand.get("foto") != null && !String.valueOf(cand.get("foto")).isEmpty()) { %>
                            <img src="<%= cand.get("foto") %>" class="candidato-foto" alt="Foto">
                            <% } else { %>
                            <div class="sin-foto"><i class="bi bi-person"></i></div>
                            <% } %>
                            <div class="fw-bold small"><%= cand.get("nombres") %> <%= cand.get("apellidos") %></div>
                            <div><span class="badge" style="background:<%= cand.get("colorPartido") != null ? cand.get("colorPartido") : "#3949ab" %>;"><%= cand.get("partido") %></span></div>
                            <div class="check-icon"><i class="bi bi-check-circle-fill"></i></div>
                        </div>
                    </div>
                    <% } %>
                    <div class="col-6 col-md-4">
                        <div class="candidato-card text-center" data-id="0" onclick="seleccionar(this)">
                            <div class="sin-foto mx-auto"><i class="bi bi-dash-circle"></i></div>
                            <div class="fw-bold small">Voto en Blanco</div>
                            <div><span class="badge bg-secondary">Ninguno</span></div>
                            <div class="check-icon"><i class="bi bi-check-circle-fill"></i></div>
                        </div>
                    </div>
                </div>
                <button type="submit" class="btn-ingresar" id="btnVotar" disabled>
                    <i class="bi bi-check2-square me-2"></i>Emitir Voto
                </button>
            </form>
            <footer>
                <i class="bi bi-shield-fill-check text-success me-1"></i>
                Su voto es secreto y seguro
            </footer>
        </div>
    </div>
    <script>
        let seleccionado = null;
        function seleccionar(el) {
            document.querySelectorAll('.candidato-card').forEach(c => c.classList.remove('selected'));
            el.classList.add('selected');
            document.getElementById('idCandidato').value = el.dataset.id;
            document.getElementById('btnVotar').disabled = false;
        }
    </script>
    <% } else if ("confirmado".equals(paso)) { %>
    <div class="voto-card">
        <div class="voto-header text-center">
            <div style="font-size:3rem;color:#43a047;"><i class="bi bi-check-circle-fill"></i></div>
            <h1 class="fs-4 mt-2">Voto Registrado Exitosamente</h1>
            <p>Su voto ha sido emitido de forma segura y confidencial.</p>
        </div>
        <div class="voto-body text-center">
            <div class="mb-3">
                <i class="bi bi-shield-check" style="font-size:4rem;color:#3949ab;opacity:.5;"></i>
            </div>
            <p class="text-muted">Gracias por participar en el proceso electoral.</p>
            <a href="VotacionServlet" class="btn btn-primary btn-custom"><i class="bi bi-arrow-left me-1"></i>Nuevo Voto</a>
            <a href="index.html" class="btn btn-outline-secondary btn-custom ms-2"><i class="bi bi-house me-1"></i>Inicio</a>
        </div>
    </div>
    <% } %>
</body>
</html>

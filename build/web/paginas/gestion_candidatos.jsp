<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page session="true" %>
<%@ page import="dto.CandidatoDTO, java.util.List" %>
<%
    String usuarioNombre = (String) session.getAttribute("usuarioNombre");
    String usuarioRol = (String) session.getAttribute("usuarioRol");
    if (usuarioNombre == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<CandidatoDTO> candidatos = (List<CandidatoDTO>) request.getAttribute("candidatos");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SVE CCSPM - Candidatos</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --primary-dark: #1a237e; --primary: #3949ab; --primary-light: #7986cb; --sidebar-width: 260px; }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f2f8; min-height: 100vh; display: flex; }
        .sidebar { width: var(--sidebar-width); height: 100vh; position: fixed; top: 0; left: 0; background: linear-gradient(180deg, var(--primary-dark) 0%, #151c5c 100%); color: #fff; z-index: 1030; overflow-y: auto; display: flex; flex-direction: column; box-shadow: 4px 0 20px rgba(0,0,0,0.15); }
        .sidebar-brand { padding: 1.5rem 1.25rem; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.1); }
        .sidebar-brand h4 { margin: 0; font-weight: 700; font-size: 1.15rem; color: #fff; }
        .sidebar-brand small { opacity: 0.7; font-size: 0.75rem; }
        .sidebar-user { padding: 1rem 1.25rem; border-bottom: 1px solid rgba(255,255,255,0.1); display: flex; align-items: center; gap: 0.75rem; }
        .sidebar-user .user-avatar { width: 40px; height: 40px; border-radius: 50%; background: rgba(255,255,255,0.2); display: flex; align-items: center; justify-content: center; font-size: 1.2rem; flex-shrink: 0; }
        .sidebar-user .user-info { overflow: hidden; }
        .sidebar-user .user-name { font-weight: 600; font-size: 0.85rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .sidebar-user .user-role { font-size: 0.7rem; opacity: 0.7; }
        .sidebar-nav { flex: 1; padding: 0.75rem 0; }
        .sidebar-nav .nav-label { padding: 0.5rem 1.25rem; font-size: 0.7rem; text-transform: uppercase; letter-spacing: 1.5px; opacity: 0.5; font-weight: 600; }
        .sidebar-nav .nav-item { list-style: none; }
        .sidebar-nav .nav-link { display: flex; align-items: center; gap: 0.75rem; padding: 0.65rem 1.25rem; color: rgba(255,255,255,0.75); text-decoration: none; font-size: 0.875rem; transition: all 0.2s ease; border-left: 3px solid transparent; }
        .sidebar-nav .nav-link:hover { background: rgba(255,255,255,0.08); color: #fff; border-left-color: var(--primary-light); }
        .sidebar-nav .nav-link.active { background: rgba(255,255,255,0.12); color: #fff; border-left-color: #fff; font-weight: 600; }
        .sidebar-nav .nav-link i { font-size: 1.1rem; width: 22px; text-align: center; }
        .main-content { margin-left: var(--sidebar-width); flex: 1; display: flex; flex-direction: column; min-height: 100vh; }
        .topbar { background: #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.05); padding: 0.75rem 1.5rem; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 1020; }
        .topbar .page-title { font-weight: 700; font-size: 1.2rem; color: var(--primary-dark); }
        .content-area { flex: 1; padding: 1.5rem; }
        .card-custom { background: #fff; border: none; border-radius: 0.75rem; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .table-custom { margin-bottom: 0; }
        .table-custom thead th { background: #f8f9fc; border-bottom: 2px solid #e0e4f0; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.5px; color: #555; font-weight: 700; white-space: nowrap; }
        .table-custom tbody td { vertical-align: middle; font-size: 0.875rem; }
        .badge-status { font-size: 0.72rem; padding: 0.3em 0.7em; border-radius: 2rem; font-weight: 600; }
        .btn-primary-custom { background: var(--primary); border-color: var(--primary); color: #fff; }
        .btn-primary-custom:hover { background: var(--primary-dark); border-color: var(--primary-dark); color: #fff; }
        .btn-outline-primary-custom { color: var(--primary); border-color: var(--primary); }
        .btn-outline-primary-custom:hover { background: var(--primary); color: #fff; }
        .footer { text-align: center; padding: 1rem 1.5rem; color: #999; font-size: 0.8rem; border-top: 1px solid #e0e0e0; }
        @media (max-width: 768px) { .sidebar { transform: translateX(-100%); } .sidebar.show { transform: translateX(0); } .main-content { margin-left: 0; } }
    </style>
</head>
<body>
    <aside class="sidebar"><div class="sidebar-brand"><h4><i class="bi bi-flag-fill me-1"></i>SVE CCSPM</h4><small>Sistema de Votaciones</small></div>
        <div class="sidebar-user"><div class="user-avatar"><i class="bi bi-person-fill"></i></div><div class="user-info"><div class="user-name"><%= usuarioNombre %></div><div class="user-role"><%= usuarioRol != null ? usuarioRol : "Administrador" %></div></div></div>
        <nav><ul class="sidebar-nav">
            <li class="nav-label">Principal</li><li class="nav-item"><a href="DashboardServlet" class="nav-link"><i class="bi bi-speedometer2"></i>Dashboard</a></li>
            <li class="nav-label mt-2">Gestión</li>
            <li class="nav-item"><a href="GestionUsuariosServlet" class="nav-link"><i class="bi bi-people"></i>Gestión de Usuarios</a></li>
            <li class="nav-item"><a href="GestionComunerosServlet" class="nav-link"><i class="bi bi-person-check"></i>Gestión de Comuneros</a></li>
            <li class="nav-item"><a href="GestionEleccionesServlet" class="nav-link"><i class="bi bi-calendar-event"></i>Gestión de Elecciones</a></li>
            <li class="nav-item"><a href="GestionPartidosServlet" class="nav-link"><i class="bi bi-flag"></i>Partidos y Candidatos</a></li>
            <li class="nav-item"><a href="GestionCaseriosServlet" class="nav-link"><i class="bi bi-geo-alt"></i>Gestión de Caseríos</a></li>
            <li class="nav-item"><a href="GestionLocalesServlet" class="nav-link"><i class="bi bi-building"></i>Locales de Votación</a></li>
            <li class="nav-item"><a href="GestionMesasServlet" class="nav-link"><i class="bi bi-grid-3x3"></i>Mesas de Sufragio</a></li>
            <li class="nav-item"><a href="GestionMiembrosMesaServlet" class="nav-link"><i class="bi bi-person-badge"></i>Miembros de Mesa</a></li>
            <li class="nav-label mt-2">Reportes</li>
            <li class="nav-item"><a href="ResultadosServlet" class="nav-link"><i class="bi bi-bar-chart"></i>Resultados</a></li>
            <li class="nav-item"><a href="AuditoriaServlet" class="nav-link"><i class="bi bi-shield-check"></i>Auditoría</a></li>
            <li class="nav-label mt-2">Cuenta</li>
            <li class="nav-item"><a href="CerrarSesionServlet" class="nav-link"><i class="bi bi-box-arrow-right text-danger"></i>Cerrar Sesión</a></li>
        </ul></nav>
    </aside>
    <main class="main-content">
        <div class="topbar"><span class="page-title">Candidatos</span><span>Bienvenido, <strong><%= usuarioNombre %></strong></span></div>
        <div class="content-area">
            <% if (request.getAttribute("mensaje") != null) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert"><i class="bi bi-check-circle-fill me-2"></i>${mensaje}<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
            <% } %>
            <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert"><i class="bi bi-exclamation-triangle-fill me-2"></i>${error}<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
            <% } %>
            <div class="card-custom mb-4"><div class="card-body"><div class="d-flex justify-content-between align-items-center"><h6 class="fw-bold mb-0">Listado de Candidatos</h6>
                <div><a href="GestionPartidosServlet" class="btn btn-outline-primary-custom me-2"><i class="bi bi-flag me-1"></i>Ver Partidos</a>
                <button class="btn btn-primary-custom" data-bs-toggle="modal" data-bs-target="#modalCandidato" onclick="limpiarForm()"><i class="bi bi-plus-circle me-1"></i>Nuevo Candidato</button></div>
            </div></div></div>
            <div class="card-custom"><div class="table-responsive"><table class="table table-custom table-hover mb-0"><thead><tr><th>Nombres</th><th>Partido</th><th>Cargo</th><th>Activo</th><th class="text-center">Acciones</th></tr></thead><tbody>
            <% if (candidatos != null && !candidatos.isEmpty()) { for (CandidatoDTO c : candidatos) { %>
            <tr>
                <td><strong><%= c.getNombres() %> <%= c.getApellidos() != null ? c.getApellidos() : "" %></strong></td>
                <td><span class="badge" style="background:<%= c.getColorPartido() != null ? c.getColorPartido() : "#6c757d" %>; color:#fff;"><%= c.getNombrePartido() != null ? c.getNombrePartido() : "-" %></span></td>
                <td><%= c.getCargo() != null ? c.getCargo() : "-" %></td>
                <td><span class="badge-status bg-<%= c.isActivo() ? "success" : "danger" %>"><%= c.isActivo() ? "Activo" : "Inactivo" %></span></td>
                <td class="text-center">
                    <button class="btn btn-sm btn-outline-primary-custom me-1" title="Editar" onclick="editarCandidato(<%= c.getIdCandidato() %>, '<%= c.getNombres() %>', '<%= c.getApellidos() != null ? c.getApellidos() : "" %>', '<%= c.getCargo() != null ? c.getCargo() : "" %>', '<%= c.getIntegrantes() != null ? c.getIntegrantes() : "" %>', <%= c.getIdPartido() %>)"><i class="bi bi-pencil"></i></button>
                    <% if (c.isActivo()) { %><a href="GestionCandidatosServlet?action=desactivar&id=<%= c.getIdCandidato() %>" class="btn btn-sm btn-outline-warning" title="Desactivar"><i class="bi bi-toggle-on"></i></a>
                    <% } else { %><a href="GestionCandidatosServlet?action=activar&id=<%= c.getIdCandidato() %>" class="btn btn-sm btn-outline-success" title="Activar"><i class="bi bi-toggle-off"></i></a><% } %>
                </td>
            </tr>
            <% } } else { %>
            <tr><td colspan="5" class="text-center py-4 text-muted"><i class="bi bi-person-badge fs-3 d-block mb-2"></i>No se encontraron candidatos.</td></tr>
            <% } %>
            </tbody></table></div></div>
        </div>
        <div class="footer"><p class="mb-0">&copy; 2026 CCSPM - Comunidad Campesina San Pedro de Mórrope. Todos los derechos reservados.</p></div>
    </main>

    <div class="modal fade" id="modalCandidato" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
        <div class="modal-header" style="background: linear-gradient(135deg, var(--primary-dark), var(--primary)); color: #fff;"><h5 class="modal-title" id="modalCandidatoLabel"><i class="bi bi-person-plus me-2"></i>Nuevo Candidato</h5><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
        <form action="GestionCandidatosServlet" method="post">
            <input type="hidden" name="action" id="formAction" value="nuevo">
            <input type="hidden" name="id" id="candidatoId">
            <div class="modal-body"><div class="row g-3">
                <div class="col-md-6"><label class="form-label fw-semibold">Nombres <span class="text-danger">*</span></label><input type="text" class="form-control" id="nombres" name="nombres" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Apellidos</label><input type="text" class="form-control" id="apellidos" name="apellidos"></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Cargo <span class="text-danger">*</span></label><input type="text" class="form-control" id="cargo" name="cargo" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">ID Partido <span class="text-danger">*</span></label><input type="number" class="form-control" id="idPartido" name="idPartido" required></div>
                <div class="col-md-12"><label class="form-label fw-semibold">Integrantes</label><textarea class="form-control" id="integrantes" name="integrantes" rows="2"></textarea></div>
            </div></div>
            <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button><button type="submit" class="btn btn-primary-custom"><i class="bi bi-check-circle me-1"></i><span id="btnSubmitText">Guardar</span></button></div>
        </form>
    </div></div></div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function limpiarForm() {
            document.getElementById('modalCandidatoLabel').innerHTML = '<i class="bi bi-person-plus me-2"></i>Nuevo Candidato';
            document.getElementById('formAction').value = 'nuevo'; document.getElementById('candidatoId').value = '';
            document.getElementById('nombres').value = ''; document.getElementById('apellidos').value = '';
            document.getElementById('cargo').value = ''; document.getElementById('idPartido').value = '';
            document.getElementById('integrantes').value = ''; document.getElementById('btnSubmitText').textContent = 'Guardar';
        }
        function editarCandidato(id, nombres, apellidos, cargo, integrantes, idPartido) {
            document.getElementById('modalCandidatoLabel').innerHTML = '<i class="bi bi-pencil me-2"></i>Editar Candidato';
            document.getElementById('formAction').value = 'editar'; document.getElementById('candidatoId').value = id;
            document.getElementById('nombres').value = nombres; document.getElementById('apellidos').value = apellidos;
            document.getElementById('cargo').value = cargo; document.getElementById('integrantes').value = integrantes;
            document.getElementById('idPartido').value = idPartido; document.getElementById('btnSubmitText').textContent = 'Actualizar';
            new bootstrap.Modal(document.getElementById('modalCandidato')).show();
        }
    </script>
</body>
</html>

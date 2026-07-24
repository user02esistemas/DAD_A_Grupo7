<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page session="true" %>
<%
    String usuarioNombre = (String) session.getAttribute("usuarioNombre");
    String usuarioRol = (String) session.getAttribute("usuarioRol");
    if (usuarioNombre == null) { response.sendRedirect("IniciarSesionServlet"); return; }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SVE CCSPM - Resultados</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        .stat-card-small { background: #fff; border-radius: 0.75rem; padding: 1rem; text-align: center; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .stat-card-small .stat-value-small { font-size: 1.6rem; font-weight: 700; color: var(--primary-dark); }
        .stat-card-small .stat-label-small { font-size: 0.78rem; color: #888; }
        .chart-card { background: #fff; border-radius: 0.75rem; padding: 1.25rem; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .chart-card h6 { font-weight: 700; color: var(--primary-dark); margin-bottom: 1rem; }
        .table-results { background: #fff; border-radius: 0.75rem; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
        .table-results thead th { background: var(--primary); color: #fff; font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600; border: none; padding: 0.75rem 1rem; }
        .table-results tbody td { vertical-align: middle; padding: 0.75rem 1rem; font-size: 0.9rem; }
        .progress-thin { height: 8px; border-radius: 4px; }
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
            <li class="nav-item"><a href="ResultadosServlet" class="nav-link active"><i class="bi bi-bar-chart"></i>Resultados</a></li>
            <li class="nav-item"><a href="AuditoriaServlet" class="nav-link"><i class="bi bi-shield-check"></i>Auditoría</a></li>
            <li class="nav-label mt-2">Cuenta</li>
            <li class="nav-item"><a href="CerrarSesionServlet" class="nav-link"><i class="bi bi-box-arrow-right text-danger"></i>Cerrar Sesión</a></li>
        </ul></nav>
    </aside>
    <main class="main-content">
        <div class="topbar"><span class="page-title">Resultados Electorales</span><span>Bienvenido, <strong><%= usuarioNombre %></strong></span></div>
        <div class="content-area">
            <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert"><i class="bi bi-exclamation-triangle-fill me-2"></i>${error}<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
            <% } %>

            <div class="election-banner bg-white p-3 rounded-3 shadow-sm mb-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
                <div><h5 class="fw-bold mb-1" style="color:var(--primary-dark);">${eleccionNombre != null ? eleccionNombre : "Elección General"}</h5>
                <small class="text-muted"><i class="bi bi-calendar3 me-1"></i>${eleccionFechaInicio != null ? eleccionFechaInicio : "N/D"} - ${eleccionFechaFin != null ? eleccionFechaFin : "N/D"}</small></div>
                <div><span class="badge bg-${eleccionEstado == 'ACTIVA' ? 'success' : (eleccionEstado == 'FINALIZADA' ? 'secondary' : 'warning')} fs-6">${eleccionEstado != null ? eleccionEstado : "SIN DATOS"}</span></div>
            </div>

            <div class="row g-3 mb-4">
                <div class="col-md-4"><div class="stat-card-small"><div class="stat-value-small">${totalVotos != null ? totalVotos : 0}</div><div class="stat-label-small">Votos Totales</div></div></div>
                <div class="col-md-4"><div class="stat-card-small"><div class="stat-value-small">${votosBlanco != null ? votosBlanco : 0}</div><div class="stat-label-small">Votos en Blanco</div></div></div>
                <div class="col-md-4"><div class="stat-card-small"><div class="stat-value-small">${porcentajeParticipacion != null ? porcentajeParticipacion : 0}%</div><div class="stat-label-small">Participación</div></div></div>
            </div>

            <div class="row g-3 mb-4">
                <div class="col-lg-8"><div class="chart-card"><h6><i class="bi bi-bar-chart-fill me-2"></i>Votos por Candidato</h6><canvas id="chartCandidatos" height="300"></canvas></div></div>
                <div class="col-lg-4"><div class="chart-card"><h6><i class="bi bi-pie-chart-fill me-2"></i>Votos por Caserío</h6><canvas id="chartCaserios" height="300"></canvas></div></div>
            </div>

            <div class="table-results"><table class="table table-hover mb-0"><thead><tr><th>#</th><th>Candidato</th><th>Partido</th><th>Votos</th><th>%</th><th>Progreso</th></tr></thead><tbody>
            <%
                java.util.List resultadosList = (java.util.List) request.getAttribute("resultados");
                int totalV = (Integer) (request.getAttribute("totalVotos") != null ? request.getAttribute("totalVotos") : 0);
                if (resultadosList != null && !resultadosList.isEmpty()) {
                    int pos = 1;
                    for (Object obj : resultadosList) {
                        Object[] r = (Object[]) obj;
                        String nombre = (String) r[0];
                        String partido = (String) r[1];
                        Number votosNum = (Number) r[2];
                        int votos = votosNum != null ? votosNum.intValue() : 0;
                        String color = r.length > 3 && r[3] != null ? (String) r[3] : "#3949ab";
                        double porcentaje = totalV > 0 ? (votos * 100.0 / totalV) : 0;
            %>
                <tr><td><strong><%= pos++ %></strong></td><td><strong><%= nombre %></strong></td><td><span class="badge" style="background:<%= color %>;"><%= partido %></span></td><td><strong><%= votos %></strong></td><td><%= String.format("%.1f", porcentaje) %>%</td><td><div class="progress progress-thin"><div class="progress-bar" style="width:<%= porcentaje %>%; background:<%= color %>;"></div></div></td></tr>
            <% } } else { %>
                <tr><td colspan="6" class="text-center py-4 text-muted"><i class="bi bi-bar-chart fs-3 d-block mb-2"></i>Aún no hay resultados disponibles.</td></tr>
            <% } %>
            </tbody></table></div>
        </div>
        <div class="footer"><p class="mb-0">&copy; 2026 CCSPM - Comunidad Campesina San Pedro de Mórrope. Todos los derechos reservados.</p></div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var chartLabels = [], chartData = [], chartColors = [];
            <% if (resultadosList != null) { for (Object obj : resultadosList) { Object[] r = (Object[]) obj; String nombre = (String) r[0]; Number votosNum = (Number) r[2]; int votos = votosNum != null ? votosNum.intValue() : 0; String color = r.length > 3 && r[3] != null ? (String) r[3] : "#3949ab"; %>
            chartLabels.push('<%= nombre.replace("'", "\\'") %>'); chartData.push(<%= votos %>); chartColors.push('<%= color %>');
            <% } } %>

            var ctx1 = document.getElementById('chartCandidatos').getContext('2d');
            new Chart(ctx1, { type: 'bar', data: { labels: chartLabels, datasets: [{ label: 'Votos', data: chartData, backgroundColor: chartColors, borderRadius: 8, borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { stepSize: 1, callback: function(v) { return Math.floor(v); } } } } } });

            var caserioLabels = [], caserioData = [];
            <% java.util.List caseriosResultados = (java.util.List) request.getAttribute("resultadosCaserios"); if (caseriosResultados != null) { for (Object obj : caseriosResultados) { Object[] r = (Object[]) obj; %>
            caserioLabels.push('<%= ((String) r[0]).replace("'", "\\'") %>'); caserioData.push(<%= ((Number) r[1]).intValue() %>);
            <% } } %>

            var ctx2 = document.getElementById('chartCaserios').getContext('2d');
            new Chart(ctx2, { type: 'doughnut', data: { labels: caserioLabels.length > 0 ? caserioLabels : ['Sin datos'], datasets: [{ data: caserioData.length > 0 ? caserioData : [1], backgroundColor: ['#3949ab','#43a047','#fb8c00','#e53935','#8e24aa','#00acc1','#6d4c41','#546e7a','#c0ca33','#f4511e'], borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 10, font: { size: 10 } } } } } });
        });
    </script>
</body>
</html>

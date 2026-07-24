<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    Integer totalComuneros = (Integer) request.getAttribute("totalComuneros");
    Integer comunerosActivos = (Integer) request.getAttribute("comunerosActivos");
    Integer totalCaserios = (Integer) request.getAttribute("totalCaserios");
    Integer totalMesas = (Integer) request.getAttribute("totalMesas");
    Integer totalLocales = (Integer) request.getAttribute("totalLocales");
    Integer totalUsuarios = (Integer) request.getAttribute("totalUsuarios");
    Integer totalVotos = (Integer) request.getAttribute("totalVotos");
    Integer votosBlancos = (Integer) request.getAttribute("votosBlancos");
    String eleccionActiva = (String) request.getAttribute("eleccionActiva");
    String porcentajeParticipacion = (String) request.getAttribute("porcentajeParticipacion");
    String chartLabels = (String) request.getAttribute("chartLabels");
    String chartData = (String) request.getAttribute("chartData");
    String chartColors = (String) request.getAttribute("chartColors");
    String caserioLabels = (String) request.getAttribute("caserioLabels");
    String caserioData = (String) request.getAttribute("caserioData");
    String caserioColors = (String) request.getAttribute("caserioColors");
    String jsessionid = session.getId();
    if (totalComuneros == null) totalComuneros = 0;
    if (comunerosActivos == null) comunerosActivos = 0;
    if (totalCaserios == null) totalCaserios = 0;
    if (totalMesas == null) totalMesas = 0;
    if (totalLocales == null) totalLocales = 0;
    if (totalUsuarios == null) totalUsuarios = 0;
    if (totalVotos == null) totalVotos = 0;
    if (votosBlancos == null) votosBlancos = 0;
    if (eleccionActiva == null) eleccionActiva = "Ninguna";
    if (porcentajeParticipacion == null) porcentajeParticipacion = "0.0";
    if (chartLabels == null) chartLabels = "[]";
    if (chartData == null) chartData = "[]";
    if (chartColors == null) chartColors = "[]";
    if (caserioLabels == null) caserioLabels = "[]";
    if (caserioData == null) caserioData = "[]";
    if (caserioColors == null) caserioColors = "[]";
    int habilitados = totalComuneros;
    int noVotaron = Math.max(0, habilitados - totalVotos);
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Electoral - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Dashboard Electoral</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-3"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
            <div>
                <span class="badge bg-primary bg-opacity-10 text-primary p-3 px-4 rounded-pill fs-6">
                    <%= eleccionActiva %>
                </span>
            </div>
        </div>

        <div class="row g-3 mb-3">
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100" style="border-left-color:#43a047;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Comuneros</div>
                                <div class="stat-value" style="color:#2e7d32;"><%= habilitados %></div>
                            </div>
                            <div class="stat-icon" style="color:#43a047;"><i class="bi bi-people-fill"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100" style="border-left-color:#00838f;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Caser&iacute;os</div>
                                <div class="stat-value" style="color:#00838f;"><%= totalCaserios %></div>
                            </div>
                            <div class="stat-icon" style="color:#00838f;"><i class="bi bi-geo-alt-fill"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Votos Emitidos</div>
                                <div class="stat-value"><%= totalVotos %></div>
                            </div>
                            <div class="stat-icon"><i class="bi bi-check2-square"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100" style="border-left-color:#f57c00;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Votos Blancos</div>
                                <div class="stat-value" style="color:#e65100;"><%= votosBlancos %></div>
                            </div>
                            <div class="stat-icon" style="color:#f57c00;"><i class="bi bi-file-earmark"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100" style="border-left-color:#e65100;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Mesas / Locales</div>
                                <div class="stat-value" style="color:#e65100;font-size:1rem;"><%= totalMesas %> / <%= totalLocales %></div>
                            </div>
                            <div class="stat-icon" style="color:#e65100;"><i class="bi bi-grid-3x3-gap-fill"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-2">
                <div class="card stat-card h-100" style="border-left-color:#1565c0;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Usuarios</div>
                                <div class="stat-value" style="color:#1565c0;"><%= totalUsuarios %></div>
                            </div>
                            <div class="stat-icon" style="color:#1565c0;"><i class="bi bi-people-fill"></i></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <h5 class="fw-bold mb-3" style="color:#1a237e">Participaci&oacute;n Electoral</h5>

        <div class="row g-3 mb-4">
            <div class="col-6 col-md-6">
                <div class="card stat-card h-100" style="border-left-color:#7b1fa2;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Comuneros Activos</div>
                                <div class="stat-value" style="color:#7b1fa2;"><%= comunerosActivos %></div>
                            </div>
                            <div class="stat-icon" style="color:#7b1fa2;"><i class="bi bi-person-check-fill"></i></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-6">
                <div class="card stat-card h-100" style="border-left-color:#00acc1;">
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-label">Participaci&oacute;n</div>
                                <div class="stat-value" style="color:#00838f;"><%= porcentajeParticipacion %>%</div>
                            </div>
                            <div class="stat-icon" style="color:#00acc1;"><i class="bi bi-graph-up-arrow"></i></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row justify-content-center">
            <div class="col-lg-10 col-xl-8 mb-4">
                <div class="card">
                    <div class="card-header text-center"><i class="bi bi-bar-chart-fill me-2"></i>Votos por Candidato</div>
                    <div class="card-body">
                        <canvas id="graficoVotos" class="w-100" style="max-height:300px;min-height:200px"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <div class="row justify-content-center">
            <div class="col-lg-10 col-xl-8 mb-4">
                <div class="card">
                    <div class="card-header text-center"><i class="bi bi-pie-chart-fill me-2"></i>Votos por Caser&iacute;o</div>
                    <div class="card-body text-center">
                        <canvas id="graficoParticipacion" class="w-100" style="max-width:400px;max-height:400px;min-height:250px;margin:0 auto"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <footer>
            <i class="bi bi-shield-fill-check text-success me-1"></i>
            SVE CCSPM &middot; Comunidad Campesina San Pedro de Mórrope &middot; Todos los derechos reservados
        </footer>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="frontend/js/admin.js"></script>
    <script>
        var candidatosLabels = <%= chartLabels %>;
        var candidatosData = <%= chartData %>;
        var candidatosColors = <%= chartColors %>;
        var caseriosLabels = <%= caserioLabels %>;
        var caseriosData = <%= caserioData %>;
        var caseriosColors = <%= caserioColors %>;
        var ctx1 = document.getElementById('graficoVotos');
        if (ctx1) {
            new Chart(ctx1, {
                type: 'bar',
                data: {
                    labels: candidatosLabels,
                    datasets: [{
                        label: 'Votos',
                        data: candidatosData,
                        backgroundColor: candidatosColors.length > 0 ? candidatosColors : ['#3949ab','#43a047','#f57c00','#00acc1','#e53935','#8e24aa','#6d4c41'],
                        borderColor: candidatosColors.length > 0 ? candidatosColors : ['#3949ab','#43a047','#f57c00','#00acc1','#e53935','#8e24aa','#6d4c41'],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } }
                }
            });
        }

        var ctx2 = document.getElementById('graficoParticipacion');
        if (ctx2 && caseriosLabels.length > 0) {
            new Chart(ctx2, {
                type: 'doughnut',
                data: {
                    labels: caseriosLabels,
                    datasets: [{
                        data: caseriosData,
                        backgroundColor: caseriosColors,
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } }
                    }
                }
            });
        } else if (ctx2) {
            ctx2.parentNode.innerHTML = '<div class="alert alert-secondary text-center">No hay votos registrados en ning\u00fan caser\u00edo.</div>';
        }
    </script>
</body>
</html>
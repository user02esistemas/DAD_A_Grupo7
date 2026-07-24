<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*, com.google.gson.Gson"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    Map<String, Object> eleccion = (Map<String, Object>) request.getAttribute("eleccion");
    Object candidatosObj = request.getAttribute("candidatos");
    Object caseriosVotosObj = request.getAttribute("caseriosVotos");
    List<Map<String, Object>> caseriosList = (List<Map<String, Object>>) request.getAttribute("caseriosList");
    String error = (String) request.getAttribute("error");
    if (caseriosList == null) caseriosList = new ArrayList<>();
    Gson gson = new Gson();
    String candidatosJson = candidatosObj != null ? gson.toJson(candidatosObj) : "[]";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultados Generales - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
    <link rel="stylesheet" href="frontend/css/public.css">
    <style>
        body{background:linear-gradient(135deg,#0f172a 0%,#1e3a5f 50%,#1d4ed8 100%);min-height:100vh;font-family:'Segoe UI',system-ui,sans-serif}
    </style>
</head>
<body>
    <div style="min-height:100vh;display:flex;align-items:center;padding:20px">
        <div class="main-card">
            <div class="header">
                <h1><i class="bi bi-bar-chart me-2"></i><%= eleccion != null ? eleccion.get("nombreEleccion") : "" %></h1>
                <p><i class="bi bi-geo-alt me-1"></i>Comunidad Campesina San Pedro de M&oacute;rrope - Lambayeque, Per&uacute;</p>
            </div>
            <div class="body">
                <div class="d-flex justify-content-end mb-3">
                    <a href="index.html" class="btn btn-outline-primary btn-sm"><i class="bi bi-arrow-left me-1"></i>Volver al inicio</a>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-warning text-center py-4">
                    <i class="bi bi-exclamation-triangle" style="font-size:2rem;display:block;margin-bottom:8px"></i>
                    <strong><%= error %></strong>
                </div>
                <% } else if (eleccion == null) { %>
                <div class="alert alert-warning text-center py-4">
                    <i class="bi bi-exclamation-triangle" style="font-size:2rem;display:block;margin-bottom:8px"></i>
                    <strong>No hay elecciones registradas.</strong><br>
                    <span class="text-muted">Los resultados estar&aacute;n disponibles cuando se registre una elecci&oacute;n.</span>
                </div>
                <% } else {
                    int totalVotos = ((Number) eleccion.get("totalVotos")).intValue();
                    int votosBlanco = ((Number) eleccion.get("votosBlanco")).intValue();
                    double porcentajeParticipacion = ((Number) eleccion.get("porcentajeParticipacion")).doubleValue();
                %>

                <div class="text-center mb-4">
                    <div><strong>Estado:</strong> <%= eleccion.get("estado") %></div>
                </div>

                <div class="row justify-content-center mb-4">
                    <div class="col-lg-10 col-xl-8">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <div class="card text-center p-3 bg-light">
                                    <div class="stat-value"><%= totalVotos %></div>
                                    <div class="stat-label">Total votos</div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="card text-center p-3 bg-light">
                                    <div class="stat-value text-warning"><%= votosBlanco %></div>
                                    <div class="stat-label">Votos blancos</div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="card text-center p-3 bg-light">
                                    <div class="stat-value"><%= String.format("%.1f", porcentajeParticipacion) %>%</div>
                                    <div class="stat-label">Participaci&oacute;n</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (candidatosObj != null) {
                    List<Map<String, Object>> candidatos = gson.fromJson(candidatosJson, List.class);
                %>
                <div class="row justify-content-center">
                    <div class="col-lg-10 col-xl-8 mb-4">
                        <div class="card">
                            <div class="card-header">Resultados por Candidato</div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead><tr><th>Candidato</th><th>Partido</th><th>Votos</th><th>%</th></tr></thead>
                                        <tbody>
                                            <% for (Map<String, Object> f : candidatos) {
                                                int v = ((Number) f.get("totalVotos")).intValue();
                                                double pct = ((Number) f.get("porcentaje")).doubleValue();
                                                String color = f.get("color") != null ? (String) f.get("color") : "#3949ab";
                                                String nombre = (String) f.get("nombreCandidato");
                                                boolean esBlanco = "VOTOS EN BLANCO".equals(nombre);
                                            %>
                                            <tr<%= esBlanco ? " class='text-muted'" : "" %>>
                                                <td><strong><%= esBlanco ? "<em>" + nombre + "</em>" : nombre %></strong></td>
                                                <td><% if (!esBlanco) { %><span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:<%= color %>;margin-right:4px;vertical-align:middle"></span><%= f.get("nombrePartido") != null ? f.get("nombrePartido") : "" %><% } else { %>&mdash;<% } %></td>
                                                <td><%= v %></td>
                                                <td><%= String.format("%.1f", pct) %>%</td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-10 col-xl-8 mb-4">
                        <div class="card">
                            <div class="card-header">Gr&aacute;fico</div>
                            <div class="card-body">
                                <canvas id="chartResultados" class="w-100" style="max-height:300px;min-height:200px"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (caseriosVotosObj != null) {
                    List<Map<String, Object>> caseriosVotos = gson.fromJson(gson.toJson(caseriosVotosObj), List.class);
                    List<Map<String, Object>> caseriosConVotos = new ArrayList<>();
                    for (Map<String, Object> f : caseriosVotos) {
                        if (((Number) f.get("votosEmitidos")).intValue() > 0) caseriosConVotos.add(f);
                    }
                %>
                <div class="row justify-content-center">
                    <div class="col-lg-10 col-xl-8 mb-4">
                        <div class="card">
                            <div class="card-header">Votos por Caser&iacute;o</div>
                            <div class="card-body text-center">
                                <canvas id="chartCaserio" class="w-100" style="max-width:400px;max-height:400px;min-height:250px;margin:0 auto"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row justify-content-center">
                    <div class="col-lg-10 col-xl-8 mb-4">
                        <div class="card" id="resultadosCaserioCard">
                            <div class="card-header">Resultados por Caser&iacute;o</div>
                            <div class="card-body">
                                <form class="row g-2 mb-3" onsubmit="return false">
                                    <div class="col-md-6">
                                        <select class="form-select" name="idCaserio" onchange="cargarResultadosCaserio(this.value, '0')">
                                            <option value="0">-- Seleccione caser&iacute;o --</option>
                                            <% for (Map<String, Object> cs : caseriosList) { %>
                                            <option value="<%= ((Number) cs.get("idCaserio")).intValue() %>"><%= cs.get("nombreCaserio") %></option>
                                            <% } %>
                                        </select>
                                    </div>
                                    <div class="col-md-4" id="mesaFilterContainer" style="display:none">
                                        <select class="form-select" name="idMesa" onchange="cargarResultadosCaserio(document.querySelector('select[name=idCaserio]').value, this.value)">
                                            <option value="0">-- Todas las mesas --</option>
                                        </select>
                                    </div>
                                </form>
                                <div id="resultadosCaserioContent">
                                    <div class="alert alert-secondary">Seleccione un caser&iacute;o para ver los resultados.</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <% } %>
                <% } %>
                <% } %>
            </div>
            <footer>
                <i class="bi bi-info-circle me-1"></i>Resultados electorales p&uacute;blicos y transparentes
            </footer>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        var candidatosData = <%= candidatosJson %>;
        if (candidatosData.length > 0) {
            var labels = [];
            var data = [];
            var colors = [];
            for (var i = 0; i < candidatosData.length; i++) {
                labels.push(candidatosData[i].nombreCandidato);
                data.push(candidatosData[i].totalVotos);
                colors.push(candidatosData[i].color || '#6c757d');
            }
            new Chart(document.getElementById('chartResultados'), {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{ label: 'Votos', data: data, backgroundColor: colors, borderColor: colors, borderWidth: 1 }]
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
            });

            var caseriosData = <%= caseriosVotosObj != null ? gson.toJson(caseriosVotosObj) : "[]" %>;
            var conVotos = caseriosData.filter(function(f) { return f.votosEmitidos > 0; });
            if (conVotos.length > 0) {
                var paleta = ['#1565c0','#2e7d32','#f9a825','#e65100','#6a1b9a','#00838f','#ad1457','#283593','#4e342e','#558b2f','#ef6c00','#00695c','#c62828','#4527a0','#00897b','#bf360c','#303f9f','#1b5e20','#f57f17','#d84315','#7b1fa2','#00838f','#c51162','#3949ab','#3e2723','#33691e','#ff6f00','#004d40','#b71c1c','#311b92','#00796b','#dd2c00'];
                var cols = [];
                for (var i = 0; i < conVotos.length; i++) cols.push(paleta[i % paleta.length]);
                new Chart(document.getElementById('chartCaserio'), {
                    type: 'doughnut',
                    data: {
                        labels: conVotos.map(function(f) { return f.nombreCaserio; }),
                        datasets: [{ data: conVotos.map(function(f) { return f.votosEmitidos; }), backgroundColor: cols, borderWidth: 0 }]
                    },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } } } }
                });
            }
        }

        var chartCaserioCandidatosInstance = null;

        function cargarResultadosCaserio(idCaserio, idMesa) {
            var content = document.getElementById('resultadosCaserioContent');
            var mesaContainer = document.getElementById('mesaFilterContainer');

            if (!idCaserio || idCaserio === '0') {
                content.innerHTML = '<div class="alert alert-secondary">Seleccione un caser\u00edo para ver los resultados.</div>';
                mesaContainer.style.display = 'none';
                return;
            }

            cargarMesasCaserio(idCaserio, idMesa);
            cargarResultadosAjax(idCaserio, idMesa);
        }

        function cargarMesasCaserio(idCaserio, idMesaSeleccionada) {
            var mesaContainer = document.getElementById('mesaFilterContainer');
            var xhrMesas = new XMLHttpRequest();
            xhrMesas.open('GET', 'ResultadosPublicoServlet?action=cargarMesas&idCaserio=' + idCaserio, true);
            xhrMesas.onreadystatechange = function() {
                if (xhrMesas.readyState === 4 && xhrMesas.status === 200) {
                    try {
                        var mesas = JSON.parse(xhrMesas.responseText);
                        var sel = mesaContainer.querySelector('select');
                        sel.innerHTML = '<option value="0">-- Todas las mesas --</option>';
                        for (var i = 0; i < mesas.length; i++) {
                            sel.innerHTML += '<option value="' + mesas[i].idMesaSufragio + '">' + mesas[i].codigoMesa + '</option>';
                        }
                        if (idMesaSeleccionada > 0) sel.value = idMesaSeleccionada;
                        mesaContainer.style.display = mesas.length > 0 ? 'block' : 'none';
                    } catch (e) {
                        mesaContainer.style.display = 'none';
                    }
                }
            };
            xhrMesas.send();
        }

        function cargarResultadosAjax(idCaserio, idMesa) {
            var content = document.getElementById('resultadosCaserioContent');
            var xhr = new XMLHttpRequest();
            xhr.open('GET', 'ResultadosPublicoServlet?ajax=1&idCaserio=' + idCaserio + '&idMesa=' + (idMesa || 0), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data && data.length > 0) {
                            renderResultadosCaserio(content, data);
                        } else {
                            if (chartCaserioCandidatosInstance) { chartCaserioCandidatosInstance.destroy(); chartCaserioCandidatosInstance = null; }
                            content.innerHTML = '<div class="alert alert-secondary text-center">Sin votos en este caser\u00edo.</div>';
                        }
                    } catch (e) {
                        content.innerHTML = '<div class="alert alert-danger">Error al cargar resultados.</div>';
                    }
                }
            };
            xhr.send();
        }

        function renderResultadosCaserio(container, datos) {
            if (datos.length === 0) {
                if (chartCaserioCandidatosInstance) { chartCaserioCandidatosInstance.destroy(); chartCaserioCandidatosInstance = null; }
                container.innerHTML = '<div class="alert alert-secondary text-center">Sin votos registrados en este caser\u00edo.</div>';
                return;
            }

            var total = 0;
            for (var i = 0; i < datos.length; i++) {
                total += datos[i].totalVotos || 0;
            }

            container.innerHTML = '<canvas id="chartCaserioCandidatos" style="width:100%;max-height:350px;min-height:280px"></canvas>';

            if (chartCaserioCandidatosInstance) {
                chartCaserioCandidatosInstance.destroy();
                chartCaserioCandidatosInstance = null;
            }

            var labels = [];
            var data = [];
            var colors = [];
            for (var i = 0; i < datos.length; i++) {
                labels.push(datos[i].nombreCandidato);
                data.push(datos[i].totalVotos || 0);
                var c = datos[i].color || '#3949ab';
                if (datos[i].nombreCandidato === 'VOTOS EN BLANCO') c = '#6c757d';
                colors.push(c);
            }
            var ctx = document.getElementById('chartCaserioCandidatos');
            if (ctx) {
                chartCaserioCandidatosInstance = new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: 'Votos',
                            data: data,
                            backgroundColor: colors,
                            borderColor: colors,
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        var pct = total > 0 ? (context.raw / total * 100) : 0;
                                        return context.raw + ' votos (' + pct.toFixed(1) + '%)';
                                    }
                                }
                            }
                        },
                        scales: {
                            y: { beginAtZero: true, title: { display: true, text: 'Votos' } },
                            x: { title: { display: false } }
                        }
                    }
                });
            }
        }
    </script>
</body>
</html>

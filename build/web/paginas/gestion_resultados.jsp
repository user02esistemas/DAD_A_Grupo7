<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="dto.CaserioDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@page import="com.google.gson.Gson"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    Map<String, Object> eleccion = (Map<String, Object>) request.getAttribute("eleccion");
    Object candidatosObj = request.getAttribute("candidatos");
    Object caseriosVotosObj = request.getAttribute("caseriosVotos");
    List<CaserioDTO> caserios = (List<CaserioDTO>) request.getAttribute("caserios");
    String error = (String) request.getAttribute("error");
    if (caserios == null) caserios = new ArrayList<>();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new Date());
    Gson gson = new Gson();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultados - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Resultados Electorales</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert alert-danger"><i class="bi bi-exclamation-triangle me-2"></i><%= error %></div>
        <% } else if (eleccion == null) { %>
        <div class="alert alert-warning"><i class="bi bi-exclamation-triangle me-2"></i>No existe elecci&oacute;n activa o finalizada para mostrar resultados.</div>
        <% } else { %>
        <%
            int totalVotos = ((Number) eleccion.get("totalVotos")).intValue();
            int votosBlanco = ((Number) eleccion.get("votosBlanco")).intValue();
            int totalHabilitados = ((Number) eleccion.get("totalHabilitados")).intValue();
            double participacion = ((Number) eleccion.get("porcentajeParticipacion")).doubleValue();
        %>

        <div class="text-center mb-4">
            <div><strong>Estado:</strong> <%= eleccion.get("estado") %></div>
        </div>

        <div class="row justify-content-center mb-4">
            <div class="col-lg-10 col-xl-8">
                <div class="row g-3">
                    <div class="col-md-4">
                        <div class="card text-center p-3 bg-light">
                            <div class="stat-value"><%= ((Number) eleccion.get("totalVotos")).intValue() %></div>
                            <div class="stat-label">Total votos</div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card text-center p-3 bg-light">
                            <div class="stat-value text-warning"><%= ((Number) eleccion.get("votosBlanco")).intValue() %></div>
                            <div class="stat-label">Votos blancos</div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card text-center p-3 bg-light">
                            <div class="stat-value"><%= String.format("%.1f", eleccion.get("porcentajeParticipacion")) %>%</div>
                            <div class="stat-label">Participaci&oacute;n</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <% if (candidatosObj != null) { %>
        <%
            String candidatosJson = gson.toJson(candidatosObj);
            List<Map<String, Object>> candidatos = gson.fromJson(candidatosJson, List.class);
        %>
        <div class="row justify-content-center">
            <div class="col-lg-10 col-xl-8 mb-4">
                <div class="card">
                    <div class="card-header">
                        Resultados por Candidato
                        <a class="btn btn-danger btn-sm float-end" href="ExportarResultadosCandidatoServlet" target="_blank">
                            <i class="bi bi-filetype-pdf me-1"></i>Exportar PDF
                        </a>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead><tr><th>Candidato</th><th>Partido</th><th>Votos</th><th>%</th></tr></thead>
                                <tbody>
                                    <% for (Map<String, Object> f : candidatos) {
                                        int votos = ((Number) f.get("totalVotos")).intValue();
                                        double pct = ((Number) f.get("porcentaje")).doubleValue();
                                        String color = f.get("color") != null ? (String) f.get("color") : "#3949ab";
                                    %>
                                    <tr>
                                        <td><strong><%= f.get("nombreCandidato") %></strong></td>
                                        <td><span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:<%= color %>;margin-right:4px;vertical-align:middle"></span><%= f.get("nombrePartido") != null ? f.get("nombrePartido") : "" %></td>
                                        <td><%= votos %></td>
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

        <% if (caseriosVotosObj != null) { %>
        <%
            String caseriosVotosJson = gson.toJson(caseriosVotosObj);
            List<Map<String, Object>> caseriosVotos = gson.fromJson(caseriosVotosJson, List.class);
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
        <% } %>

        <div class="row justify-content-center">
            <div class="col-lg-10 col-xl-8 mb-4">
                <div class="card" id="resultadosCaserioCard">
                    <div class="card-header">
                        Resultados por Caser&iacute;o
                        <div class="float-end">
                            <a class="btn btn-danger btn-sm me-1" href="ExportarResultadosGeneralServlet" target="_blank"><i class="bi bi-filetype-pdf me-1"></i>Exportar resultado general</a>
                            <a class="btn btn-danger btn-sm" href="ExportarResultadosCaserioServlet?idCaserio=0" target="_blank" id="btnExportCaserio"><i class="bi bi-filetype-pdf me-1"></i>Exportar resultado por caser&iacute;o PDF</a>
                        </div>
                    </div>
                    <div class="card-body">
                        <form class="row g-2 mb-3" onsubmit="return false">
                            <div class="col-md-6">
                                <select class="form-select" name="idCaserio" onchange="cargarResultadosCaserio(this.value, '0')">
                                    <option value="0">-- Seleccione caser&iacute;o --</option>
                                    <% for (CaserioDTO cs : caserios) { %>
                                    <option value="<%= cs.getIdCaserio() %>"><%= cs.getNombreCaserio() %></option>
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

        <footer class="mt-4">
            <p class="mb-0">&copy; 2026 CCSPM - Comunidad Campesina San Pedro de M&oacute;rrope. Todos los derechos reservados.</p>
        </footer>
    </div>
    <% } %>

    <div id="mesasDataStore" style="display:none"></div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        <% if (candidatosObj != null) {
            String candidatosJson = gson.toJson(candidatosObj);
            List<Map<String, Object>> candidatos = gson.fromJson(candidatosJson, List.class);
        %>
        var ctx = document.getElementById('chartResultados');
        if (ctx) {
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: [
                        <% for (int i = 0; i < candidatos.size(); i++) {
                            Map<String, Object> f = candidatos.get(i);
                            if (i > 0) out.print(",");
                            out.print("'" + ((String) f.get("nombreCandidato")).replace("'", "\\'") + "'");
                        } %>
                    ],
                    datasets: [{
                        label: 'Votos',
                        data: [
                            <% for (int i = 0; i < candidatos.size(); i++) {
                                Map<String, Object> f = candidatos.get(i);
                                if (i > 0) out.print(",");
                                out.print(f.get("totalVotos"));
                            } %>
                        ],
                        backgroundColor: [
                            <% for (int i = 0; i < candidatos.size(); i++) {
                                Map<String, Object> f = candidatos.get(i);
                                if (i > 0) out.print(",");
                                String color = f.get("color") != null ? (String) f.get("color") : "#3949ab";
                                out.print("'" + color + "'");
                            } %>
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } }
                }
            });
        }
        <% } %>

        <% if (caseriosVotosObj != null) {
            String caseriosVotosJson = gson.toJson(caseriosVotosObj);
            List<Map<String, Object>> caseriosVotos = gson.fromJson(caseriosVotosJson, List.class);
            List<Map<String, Object>> caseriosConVotos = new ArrayList<>();
            for (Map<String, Object> f : caseriosVotos) {
                int votos = ((Number) f.get("votosEmitidos")).intValue();
                if (votos > 0) caseriosConVotos.add(f);
            }
        %>
        var labelsCaserio = [
            <% for (int i = 0; i < caseriosConVotos.size(); i++) {
                Map<String, Object> f = caseriosConVotos.get(i);
                if (i > 0) out.print(",");
                out.print("'" + ((String) f.get("nombreCaserio")).replace("'", "\\'") + "'");
            } %>
        ];
        var dataCaserio = [
            <% for (int i = 0; i < caseriosConVotos.size(); i++) {
                Map<String, Object> f = caseriosConVotos.get(i);
                if (i > 0) out.print(",");
                out.print(f.get("votosEmitidos"));
            } %>
        ];
        var paletaCaserio = [
            '#1565c0','#2e7d32','#f9a825','#e65100','#6a1b9a','#00838f','#ad1457','#283593',
            '#4e342e','#558b2f','#ef6c00','#00695c','#c62828','#4527a0','#00897b','#bf360c',
            '#303f9f','#1b5e20','#f57f17','#d84315','#7b1fa2','#00838f','#c51162','#3949ab',
            '#3e2723','#33691e','#ff6f00','#004d40','#b71c1c','#311b92','#00796b','#dd2c00'
        ];
        var coloresCaserio = [];
        for (var i = 0; i < labelsCaserio.length; i++) {
            coloresCaserio.push(paletaCaserio[i % paletaCaserio.length]);
        }
        var ctx2 = document.getElementById('chartCaserio');
        if (ctx2 && labelsCaserio.length > 0) {
            new Chart(ctx2, {
                type: 'doughnut',
                data: {
                    labels: labelsCaserio,
                    datasets: [{
                        data: dataCaserio,
                        backgroundColor: coloresCaserio,
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: { boxWidth: 12, padding: 10, font: { size: 11 } }
                        }
                    }
                }
            });
        } else if (ctx2) {
            ctx2.parentNode.innerHTML = '<div class="alert alert-secondary text-center">No hay votos registrados en ning\u00fan caser\u00edo.</div>';
        }
        <% } %>

        function cargarResultadosCaserio(idCaserio, idMesa) {
            var content = document.getElementById('resultadosCaserioContent');
            var mesaContainer = document.getElementById('mesaFilterContainer');
            var btnExport = document.getElementById('btnExportCaserio');

            if (!idCaserio || idCaserio === '0') {
                content.innerHTML = '<div class="alert alert-secondary">Seleccione un caser\u00edo para ver los resultados.</div>';
                mesaContainer.style.display = 'none';
                btnExport.href = 'ExportarResultadosCaserioServlet?idCaserio=0';
                return;
            }

            btnExport.href = 'ExportarResultadosCaserioServlet?idCaserio=' + idCaserio + (idMesa > 0 ? '&idMesa=' + idMesa : '');

            cargarMesasCaserio(idCaserio, idMesa);
            cargarResultadosAjax(idCaserio, idMesa);
        }

        function cargarMesasCaserio(idCaserio, idMesaSeleccionada) {
            var mesaContainer = document.getElementById('mesaFilterContainer');
            var xhrMesas = new XMLHttpRequest();
            xhrMesas.open('GET', 'GestionResultadosServlet?action=cargarMesas&idCaserio=' + idCaserio, true);
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
            xhr.open('GET', 'GestionResultadosServlet?ajax=1&idCaserio=' + idCaserio + '&idMesa=' + (idMesa || 0), true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data.exito && data.datos) {
                            renderResultadosCaserio(content, data.datos);
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

        var chartCaserioCandidatosInstance = null;

        function renderResultadosCaserio(container, datos) {
            if (datos.length === 0) {
                if (chartCaserioCandidatosInstance) { chartCaserioCandidatosInstance.destroy(); chartCaserioCandidatosInstance = null; }
                container.innerHTML = '<div class="alert alert-secondary text-center">No hay votos registrados en este caser\u00edo.</div>';
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

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.MesaSufragioDTO"%>
<%@page import="dto.CaserioDTO"%>
<%@page import="dto.LocalVotacionDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<MesaSufragioDTO> mesas = (List<MesaSufragioDTO>) request.getAttribute("mesas");
    List<CaserioDTO> caserios = (List<CaserioDTO>) request.getAttribute("caserios");
    List<LocalVotacionDTO> locales = (List<LocalVotacionDTO>) request.getAttribute("locales");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    String nextCode = (String) request.getAttribute("nextCode");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    if (mesas == null) mesas = new java.util.ArrayList<>();
    if (caserios == null) caserios = new java.util.ArrayList<>();
    if (locales == null) locales = new java.util.ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (totalRegistros == null) totalRegistros = 0;
    if (porPagina == null) porPagina = 20;
    if (nextCode == null) nextCode = "MESA-001";
    if (busqueda == null) busqueda = "";
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mesas de Sufragio - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Mesas de Sufragio</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-body">
                <div class="row g-2 align-items-center">
                    <div class="col-md-6">
                        <form method="get" action="GestionMesasServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar por c&oacute;digo de mesa o nombre del caser&iacute;o..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="GestionMesasServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg me-1"></i>Restablecer</a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-6 text-md-end">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#mesaModal" onclick="abrirNuevo()">
                            <i class="bi bi-plus-lg me-1"></i>Nueva Mesa
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <% if (mensaje != null) { %>
        <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show"><i class="bi bi-exclamation-triangle me-2"></i><%= error %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>

        <div class="card">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>C&oacute;digo</th>
                                <th>Caser&iacute;o</th>
                                <th>Local</th>
                                <th>Capacidad</th>
                                <th>Estado</th>
                                <th class="text-center" style="width:100px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (mesas.isEmpty()) { %>
                            <tr><td colspan="6" class="text-center py-4 text-muted"><i class="bi bi-grid-3x3 fs-2 d-block mb-2"></i>No se encontraron mesas de sufragio.</td></tr>
                            <% } else { for (MesaSufragioDTO m : mesas) { %>
                            <tr>
                                <td class="fw-semibold"><%= m.getCodigoMesa() %></td>
                                <td><%= m.getNombreCaserio() != null ? m.getNombreCaserio() : "-" %></td>
                                <td><%= m.getNombreLocal() != null ? m.getNombreLocal() : "-" %></td>
                                <td><%= m.getCapacidadMaxima() %></td>
                                <td><span class="badge bg-<%= m.isActivo() ? "success" : "secondary" %>"><%= m.isActivo() ? "Activo" : "Inactivo" %></span></td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-primary me-1" title="Editar" onclick="abrirEditar(<%= m.getIdMesaSufragio() %>, '<%= m.getCodigoMesa() %>', <%= m.getIdLocalVotacion() %>, <%= m.getIdCaserio() %>, <%= m.getCapacidadMaxima() %>)">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <% if (m.isActivo()) { %>
                                    <button class="btn btn-sm btn-outline-danger" title="Desactivar" onclick="confirmarEstado(<%= m.getIdMesaSufragio() %>, 'desactivarMesa', '<%= m.getCodigoMesa() %>')"><i class="bi bi-x-lg"></i></button>
                                    <% } else { %>
                                    <button class="btn btn-sm btn-outline-success" title="Activar" onclick="confirmarEstado(<%= m.getIdMesaSufragio() %>, 'activarMesa', '<%= m.getCodigoMesa() %>')"><i class="bi bi-check-lg"></i></button>
                                    <% } %>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="card-footer d-flex justify-content-between align-items-center">
                <div>
                    <small class="text-muted">Total de registros: <strong><%= totalRegistros %></strong></small>
                    <br>
                    <small class="text-muted">
                        Registros por p&aacute;gina:
                        <select class="form-select form-select-sm d-inline-block" style="width:auto" onchange="cambiarPorPagina(this.value)">
                            <option value="20" <%= porPagina == 20 ? "selected" : "" %>>20</option>
                            <option value="50" <%= porPagina == 50 ? "selected" : "" %>>50</option>
                            <option value="100" <%= porPagina == 100 ? "selected" : "" %>>100</option>
                        </select>
                    </small>
                </div>
                <% if (totalPages > 1) { %>
                <nav>
                    <ul class="pagination pagination-sm mb-0">
                        <li class="page-item <%= currentPage <= 1 ? "disabled" : "" %>">
                            <a class="page-link" href="GestionMesasServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>">&laquo;</a>
                        </li>
                        <% for (int i = 1; i <= totalPages; i++) { %>
                        <li class="page-item <%= i == currentPage ? "active" : "" %>">
                            <a class="page-link" href="GestionMesasServlet?page=<%= i %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>"><%= i %></a>
                        </li>
                        <% } %>
                        <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                            <a class="page-link" href="GestionMesasServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>">&raquo;</a>
                        </li>
                    </ul>
                </nav>
                <% } %>
            </div>
        </div>

        <footer class="mt-4">
            <p class="mb-0">&copy; 2026 CCSPM - Comunidad Campesina San Pedro de M&oacute;rrope. Todos los derechos reservados.</p>
        </footer>
    </div>

    <div class="modal fade" id="mesaModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header" style="background:linear-gradient(135deg,#1a237e,#3949ab);color:#fff">
                    <h5 class="modal-title" id="mesaModalLabel"><i class="bi bi-grid-plus me-2"></i>Nueva Mesa de Sufragio</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form action="GestionMesasServlet" method="post">
                    <input type="hidden" name="action" id="formAction" value="nuevo">
                    <input type="hidden" name="id" id="mesaId">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">C&oacute;digo de mesa <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="codigoMesa" name="codigoMesa" readonly style="background-color:#f0f0f0">
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Caser&iacute;o <span class="text-danger">*</span></label>
                            <select class="form-select" id="caserioSelect" name="idCaserio" onchange="filtrarLocales()" required>
                                <option value="">Seleccione un caser&iacute;o</option>
                                <% for (CaserioDTO c : caserios) { %>
                                <option value="<%= c.getIdCaserio() %>"><%= c.getNombreCaserio() %></option>
                                <% } %>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Local de votaci&oacute;n <span class="text-danger">*</span></label>
                            <select class="form-select" id="idLocalVotacion" name="idLocalVotacion" required>
                                <option value="">Primero seleccione un caser&iacute;o</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Capacidad m&aacute;xima <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="capacidadMaxima" name="capacidadMaxima" min="1" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary" id="btnSubmit"><i class="bi bi-check-circle me-1"></i>Guardar</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="estadoModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-warning fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold" id="estadoModalTitle">&iquest;Desactivar mesa?</h6>
                    <p class="small text-muted mb-0" id="estadoModalText">Se desactivar&aacute; la mesa seleccionada</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <a class="btn btn-warning btn-sm" id="estadoEnlace" href="#"><i class="bi bi-check-lg me-1"></i><span id="estadoBtnText">Desactivar</span></a>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function confirmarEstado(id, action, codigo) {
            if (action === 'desactivarMesa') {
                document.getElementById('estadoModalTitle').textContent = '\u00bfDesactivar mesa ' + codigo + '?';
                document.getElementById('estadoModalText').textContent = 'Se desactivar\u00e1 la mesa ' + codigo;
                document.getElementById('estadoEnlace').className = 'btn btn-danger btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionMesasServlet?action=desactivarMesa&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Desactivar';
            } else {
                document.getElementById('estadoModalTitle').textContent = '\u00bfActivar mesa ' + codigo + '?';
                document.getElementById('estadoModalText').textContent = 'Se activar\u00e1 la mesa ' + codigo;
                document.getElementById('estadoEnlace').className = 'btn btn-success btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionMesasServlet?action=activarMesa&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Activar';
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('estadoModal')).show();
        }

        var localesData = [
            <% for (LocalVotacionDTO l : locales) { %>
            { id: <%= l.getIdLocalVotacion() %>, idCaserio: <%= l.getIdCaserio() %>, nombre: '<%= l.getNombreLocal().replace("'", "\\'") %>' },
            <% } %>
        ];

        function filtrarLocales() {
            var idCaserio = parseInt(document.getElementById('caserioSelect').value);
            var sel = document.getElementById('idLocalVotacion');
            sel.innerHTML = '<option value="">Seleccione un local</option>';
            if (!idCaserio) return;
            for (var i = 0; i < localesData.length; i++) {
                if (localesData[i].idCaserio === idCaserio) {
                    var opt = document.createElement('option');
                    opt.value = localesData[i].id;
                    opt.textContent = localesData[i].nombre;
                    sel.appendChild(opt);
                }
            }
        }

        function abrirNuevo() {
            document.getElementById('mesaModalLabel').innerHTML = '<i class="bi bi-grid-plus me-2"></i>Nueva Mesa de Sufragio';
            document.getElementById('formAction').value = 'nuevo';
            document.getElementById('mesaId').value = '';
            document.getElementById('codigoMesa').value = '<%= nextCode %>';
            document.getElementById('caserioSelect').value = '';
            document.getElementById('idLocalVotacion').innerHTML = '<option value="">Primero seleccione un caser\u00edo</option>';
            document.getElementById('capacidadMaxima').value = '';
            document.getElementById('btnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
        }

        function abrirEditar(id, codigo, idLocal, idCaserio, capacidad) {
            document.getElementById('mesaModalLabel').innerHTML = '<i class="bi bi-pencil me-2"></i>Editar Mesa de Sufragio';
            document.getElementById('formAction').value = 'editar';
            document.getElementById('mesaId').value = id;
            document.getElementById('codigoMesa').value = codigo;
            document.getElementById('caserioSelect').value = idCaserio;
            document.getElementById('capacidadMaxima').value = capacidad;
            document.getElementById('btnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
            filtrarLocales();
            if (document.querySelector('#idLocalVotacion option[value="' + idLocal + '"]')) {
                document.getElementById('idLocalVotacion').value = idLocal;
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('mesaModal')).show();
        }

        function cambiarPorPagina(val) {
            var url = new URL(window.location.href);
            url.searchParams.set('por_pagina', val);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }
    </script>
</body>
</html>

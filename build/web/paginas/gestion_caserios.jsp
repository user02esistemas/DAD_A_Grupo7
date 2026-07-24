<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.CaserioDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<CaserioDTO> caserios = (List<CaserioDTO>) request.getAttribute("caserios");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    if (caserios == null) caserios = new java.util.ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (totalRegistros == null) totalRegistros = 0;
    if (porPagina == null) porPagina = 20;
    if (busqueda == null) busqueda = "";
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gesti&oacute;n de Caser&iacute;os - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Gesti&oacute;n de Caser&iacute;os</h4>
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
                        <form method="get" action="GestionCaseriosServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar por nombre..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="GestionCaseriosServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg me-1"></i>Restablecer</a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-6 text-md-end">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#caserioModal" onclick="limpiarForm()">
                            <i class="bi bi-plus-lg me-1"></i>Nuevo Caser&iacute;o
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
                                <th>Nombre</th>
                                <th>Descripci&oacute;n</th>
                                <th>Estado</th>
                                <th class="text-center" style="width:100px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (caserios.isEmpty()) { %>
                            <tr><td colspan="4" class="text-center py-4 text-muted"><i class="bi bi-geo-alt fs-2 d-block mb-2"></i>No se encontraron caser&iacute;os.</td></tr>
                            <% } else { for (CaserioDTO c : caserios) { %>
                            <tr>
                                <td class="fw-semibold"><%= c.getNombreCaserio() %></td>
                                <td><%= c.getDescripcion() != null && !c.getDescripcion().isEmpty() ? c.getDescripcion() : "-" %></td>
                                <td><span class="badge bg-<%= c.isActivo() ? "success" : "secondary" %>"><%= c.isActivo() ? "Activo" : "Inactivo" %></span></td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-primary me-1" title="Editar" onclick="editarCaserio(<%= c.getIdCaserio() %>, '<%= c.getNombreCaserio().replace("'", "\\'") %>', '<%= c.getDescripcion() != null ? c.getDescripcion().replace("'", "\\'") : "" %>')">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <% if (c.isActivo()) { %>
                                    <button class="btn btn-sm btn-outline-danger" title="Desactivar" onclick="confirmarEstado(<%= c.getIdCaserio() %>, 'desactivarCaserio', '<%= c.getNombreCaserio().replace("'", "\\'") %>')"><i class="bi bi-x-lg"></i></button>
                                    <% } else { %>
                                    <button class="btn btn-sm btn-outline-success" title="Activar" onclick="confirmarEstado(<%= c.getIdCaserio() %>, 'activarCaserio', '<%= c.getNombreCaserio().replace("'", "\\'") %>')"><i class="bi bi-check-lg"></i></button>
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
                    <small class="text-muted">Total de registro: <strong><%= totalRegistros %></strong></small>
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
                            <a class="page-link" href="GestionCaseriosServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>">&laquo;</a>
                        </li>
                        <% for (int i = 1; i <= totalPages; i++) { %>
                        <li class="page-item <%= i == currentPage ? "active" : "" %>">
                            <a class="page-link" href="GestionCaseriosServlet?page=<%= i %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>"><%= i %></a>
                        </li>
                        <% } %>
                        <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                            <a class="page-link" href="GestionCaseriosServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %>">&raquo;</a>
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

    <div class="modal fade" id="caserioModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header" style="background:linear-gradient(135deg,#1a237e,#3949ab);color:#fff">
                    <h5 class="modal-title" id="caserioModalLabel"><i class="bi bi-geo-alt-plus me-2"></i>Nuevo Caser&iacute;o</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form action="GestionCaseriosServlet" method="post">
                    <input type="hidden" name="action" id="formAction" value="nuevo">
                    <input type="hidden" name="id" id="caserioId">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Nombre del caser&iacute;o <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="nombreCaserio" name="nombreCaserio" placeholder="Nombre del caser&iacute;o" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Descripci&oacute;n</label>
                            <textarea class="form-control" id="descripcion" name="descripcion" rows="3" placeholder="Informaci&oacute;n adicional sobre el caser&iacute;o"></textarea>
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
                    <h6 class="fw-bold" id="estadoModalTitle">&iquest;Desactivar caser&iacute;o?</h6>
                    <p class="small text-muted mb-0" id="estadoModalText">Se desactivar&aacute; el caser&iacute;o seleccionado</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <a class="btn btn-danger btn-sm" id="estadoEnlace" href="#"><i class="bi bi-check-lg me-1"></i><span id="estadoBtnText">Desactivar</span></a>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        function confirmarEstado(id, action, nombre) {
            if (action === 'desactivarCaserio') {
                document.getElementById('estadoModalTitle').textContent = '\u00bfDesactivar caser\u00edo ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se desactivar\u00e1 el caser\u00edo ' + nombre;
                document.getElementById('estadoEnlace').className = 'btn btn-danger btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionCaseriosServlet?action=desactivarCaserio&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Desactivar';
            } else {
                document.getElementById('estadoModalTitle').textContent = '\u00bfActivar caser\u00edo ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se activar\u00e1 el caser\u00edo ' + nombre;
                document.getElementById('estadoEnlace').className = 'btn btn-success btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionCaseriosServlet?action=activarCaserio&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Activar';
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('estadoModal')).show();
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function limpiarForm() {
            document.getElementById('caserioModalLabel').innerHTML = '<i class="bi bi-geo-alt-plus me-2"></i>Nuevo Caser\u00edo';
            document.getElementById('formAction').value = 'nuevo';
            document.getElementById('caserioId').value = '';
            document.getElementById('nombreCaserio').value = '';
            document.getElementById('descripcion').value = '';
            document.getElementById('btnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
        }

        function editarCaserio(id, nombre, desc) {
            document.getElementById('caserioModalLabel').innerHTML = '<i class="bi bi-pencil me-2"></i>Editar Caser\u00edo';
            document.getElementById('formAction').value = 'editar';
            document.getElementById('caserioId').value = id;
            document.getElementById('nombreCaserio').value = nombre;
            document.getElementById('descripcion').value = desc;
            document.getElementById('btnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('caserioModal')).show();
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

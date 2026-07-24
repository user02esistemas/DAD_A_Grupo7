<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.AuditoriaDTO"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<AuditoriaDTO> auditorias = (List<AuditoriaDTO>) request.getAttribute("auditorias");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    if (auditorias == null) auditorias = new java.util.ArrayList<>();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (porPagina == null) porPagina = 20;
    if (totalRegistros == null) totalRegistros = 0;
    if (busqueda == null) busqueda = "";
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auditor&iacute;a - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Auditor&iacute;a</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-3"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <% if (mensaje != null) { %>
        <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show"><i class="bi bi-exclamation-triangle me-2"></i><%= error %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>

        <div class="card">
            <div class="card-body">
                <div class="row g-2 align-items-center mb-3">
                    <div class="col-md-5">
                        <form method="get" action="AuditoriaServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar usuario, m&oacute;dulo o acci&oacute;n..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="AuditoriaServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-7 text-md-end">
                        <span class="text-muted small">Registros encontrados: <strong><%= totalRegistros %></strong></span>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                            <tr>
                                <th>Usuario</th>
                                <th>Acci&oacute;n</th>
                                <th>M&oacute;dulo</th>
                                <th>Detalle</th>
                                <th>Fecha</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (auditorias.isEmpty()) { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">No se encontraron registros de auditor&iacute;a</td></tr>
                            <% } else { for (AuditoriaDTO a : auditorias) { %>
                            <tr>
                                <td><strong><%= a.getNombreUsuario() != null ? a.getNombreUsuario() : "-" %></strong></td>
                                <td><span class="badge bg-info"><%= a.getAccion() != null ? a.getAccion() : "-" %></span></td>
                                <td><%= a.getModulo() != null ? a.getModulo() : "-" %></td>
                                <td style="max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="<%= a.getDetalle() != null ? a.getDetalle() : "" %>"><%= a.getDetalle() != null ? a.getDetalle() : "-" %></td>
                                <td><small><%= a.getFechaEvento() != null ? a.getFechaEvento() : "-" %></small></td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>

                <div class="d-flex justify-content-between align-items-center mt-3">
                    <div>
                        <small class="text-muted">Registros por p&aacute;gina:
                        <select class="form-select form-select-sm d-inline-block" style="width:auto" onchange="cambiarPagina(this.value)">
                            <option value="20" <%= porPagina == 20 ? "selected" : "" %>>20</option>
                            <option value="50" <%= porPagina == 50 ? "selected" : "" %>>50</option>
                            <option value="100" <%= porPagina == 100 ? "selected" : "" %>>100</option>
                        </select>
                        </small>
                    </div>
                    <nav>
                        <ul class="pagination pagination-sm mb-0">
                            <li class="page-item <%= currentPage <= 1 ? "disabled" : "" %>">
                                <a class="page-link" href="AuditoriaServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Anterior</a>
                            </li>
                            <% for (int i = 1; i <= totalPages; i++) { %>
                            <li class="page-item <%= i == currentPage ? "active" : "" %>">
                                <a class="page-link" href="AuditoriaServlet?page=<%= i %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>"><%= i %></a>
                            </li>
                            <% } %>
                            <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                                <a class="page-link" href="AuditoriaServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Siguiente</a>
                            </li>
                        </ul>
                    </nav>
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
        function cambiarPagina(valor) {
            var url = new URL(window.location.href);
            url.searchParams.set('por_pagina', valor);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }
    </script>
</body>
</html>
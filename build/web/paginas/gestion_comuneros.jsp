<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.ComuneroDTO"%>
<%@page import="dto.CaserioDTO"%>
<%@page import="dto.MesaSufragioDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    Boolean esEditar = (Boolean) request.getAttribute("esEditar");
    if (esEditar == null) esEditar = false;
    ComuneroDTO comuneroEdit = (ComuneroDTO) request.getAttribute("comunero");
    List<ComuneroDTO> comuneros = (List<ComuneroDTO>) request.getAttribute("comuneros");
    List<CaserioDTO> caserios = (List<CaserioDTO>) request.getAttribute("caserios");
    List<MesaSufragioDTO> mesas = (List<MesaSufragioDTO>) request.getAttribute("mesas");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    String idCaserioFiltroParam = request.getParameter("idCaserioFiltro");
    int idCaserioFiltro = 0;
    if (idCaserioFiltroParam != null && !idCaserioFiltroParam.isEmpty()) {
        try { idCaserioFiltro = Integer.parseInt(idCaserioFiltroParam); } catch (NumberFormatException e) {}
    }
    if (comuneros == null) comuneros = new java.util.ArrayList<>();
    if (caserios == null) caserios = new java.util.ArrayList<>();
    if (mesas == null) mesas = new java.util.ArrayList<>();
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
    <title>Gesti&oacute;n de Comuneros - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
<% if (esEditar && comuneroEdit != null) { %>
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Editar Comunero</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
            <a href="GestionComunerosServlet" class="btn btn-outline-secondary btn-sm"><i class="bi bi-arrow-left me-1"></i>Volver</a>
        </div>

        <div class="card">
            <div class="card-header"><i class="bi bi-pencil me-2"></i>Datos del Comunero - DNI: <%= comuneroEdit.getDni() %></div>
            <div class="card-body">
                <% if (mensaje != null) { %>
                <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
                <% } %>
                <form method="post" action="GestionComunerosServlet" class="row g-3">
                    <input type="hidden" name="action" value="editar">
                    <input type="hidden" name="id" value="<%= comuneroEdit.getIdComunero() %>">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">DNI</label>
                        <input type="text" class="form-control" value="<%= comuneroEdit.getDni() %>" disabled>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Nombres <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" name="nombres" value="<%= comuneroEdit.getNombres() != null ? comuneroEdit.getNombres() : "" %>" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Apellidos <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" name="apellidos" value="<%= comuneroEdit.getApellidos() != null ? comuneroEdit.getApellidos() : "" %>" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Fecha nacimiento</label>
                        <input type="date" class="form-control" name="fechaNacimiento" value="<%= comuneroEdit.getFechaNacimiento() != null ? comuneroEdit.getFechaNacimiento() : "" %>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Sexo</label>
                        <select class="form-select" name="sexo">
                            <option value="M" <%= "M".equals(comuneroEdit.getSexo()) ? "selected" : "" %>>Masculino</option>
                            <option value="F" <%= "F".equals(comuneroEdit.getSexo()) ? "selected" : "" %>>Femenino</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Tel&eacute;fono</label>
                        <input type="text" class="form-control" name="telefono" maxlength="9" value="<%= comuneroEdit.getTelefono() != null ? comuneroEdit.getTelefono() : "" %>">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Direcci&oacute;n</label>
                        <input type="text" class="form-control" name="direccion" value="<%= comuneroEdit.getDireccion() != null ? comuneroEdit.getDireccion() : "" %>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Caser&iacute;o <span class="text-danger">*</span></label>
                        <select class="form-select" name="idCaserio" id="selCaserioEdit" onchange="filtrarMesasEdit()" required>
                            <option value="">-- Seleccione --</option>
                            <% for (CaserioDTO cs : caserios) { %>
                            <option value="<%= cs.getIdCaserio() %>" <%= cs.getIdCaserio() == comuneroEdit.getIdCaserio() ? "selected" : "" %>><%= cs.getNombreCaserio() %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Mesa de Sufragio</label>
                        <select class="form-select" name="idMesaSufragio" id="selMesaEdit">
                            <option value="">-- Seleccione mesa --</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Estado</label>
                        <select class="form-select" name="estado">
                            <option value="1" <%= comuneroEdit.getEstado() == 1 ? "selected" : "" %>>Activo</option>
                            <option value="0" <%= comuneroEdit.getEstado() == 0 ? "selected" : "" %>>Inactivo</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Nueva clave de votaci&oacute;n (6 d&iacute;gitos)</label>
                        <input type="password" class="form-control" name="claveVotacion" maxlength="6" placeholder="Dejar vac&iacute;o para mantener la actual" inputmode="numeric">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Repetir clave</label>
                        <input type="password" class="form-control" name="repetirClave" maxlength="6" inputmode="numeric">
                    </div>
                    <div class="col-12">
                        <button type="submit" class="btn btn-primary"><i class="bi bi-save me-1"></i>Guardar Cambios</button>
                        <a href="GestionComunerosServlet" class="btn btn-secondary">Cancelar</a>
                    </div>
                </form>
            </div>
        </div>

        <script>
            var mesasData = [
                <% for (MesaSufragioDTO m : mesas) { %>
                { id: <%= m.getIdMesaSufragio() %>, idCaserio: <%= m.getIdCaserio() %>, codigo: '<%= m.getCodigoMesa() != null ? m.getCodigoMesa().replace("'", "\\'") : "" %>' },
                <% } %>
            ];
            function filtrarMesasEdit() {
                var idCaserio = parseInt(document.getElementById('selCaserioEdit').value);
                var sel = document.getElementById('selMesaEdit');
                sel.innerHTML = '<option value="">-- Seleccione mesa --</option>';
                if (!idCaserio) return;
                for (var i = 0; i < mesasData.length; i++) {
                    if (mesasData[i].idCaserio === idCaserio) {
                        var selected = (mesasData[i].id === <%= comuneroEdit.getIdMesaSufragio() %>) ? 'selected' : '';
                        sel.innerHTML += '<option value="' + mesasData[i].id + '" ' + selected + '>' + mesasData[i].codigo + '</option>';
                    }
                }
            }
            document.addEventListener('DOMContentLoaded', filtrarMesasEdit);
        </script>

<% } else { %>

        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Gesti&oacute;n de Comuneros</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-body">
                <div class="row g-2 align-items-center">
                    <div class="col-md-4">
                        <form method="get" action="GestionComunerosServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar por DNI, nombres o c&oacute;digo..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="GestionComunerosServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg me-1"></i>Restablecer</a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-3">
                        <select class="form-select" name="idCaserioFiltro" onchange="filtrarCaserio(this.value)">
                            <option value="0">Todos los caser&iacute;os</option>
                            <% for (CaserioDTO cs : caserios) { %>
                            <option value="<%= cs.getIdCaserio() %>" <%= cs.getIdCaserio() == idCaserioFiltro ? "selected" : "" %>><%= cs.getNombreCaserio() %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-md-5 text-md-end">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#comuneroModal" onclick="limpiarForm()">
                            <i class="bi bi-plus-lg me-1"></i>Nuevo Comunero
                        </button>
                        <button class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#exportarModal">
                            <i class="bi bi-filetype-pdf me-1"></i>Exportar
                        </button>
                        <button class="btn btn-warning" onclick="confirmarResetPadron()"><i class="bi bi-arrow-counterclockwise me-1"></i>Reset Padr&oacute;n</button><br>
                        <br>
                        <button class="btn btn-success" onclick="confirmarActivarPadron()"><i class="bi bi-check-all me-1"></i>Activar Padr&oacute;n</button>
                        <form id="formResetPadron" method="post" action="GestionComunerosServlet" style="display:none">
                            <input type="hidden" name="action" value="limpiarPadron">
                        </form>
                        <form id="formActivarPadron" method="post" action="GestionComunerosServlet" style="display:none">
                            <input type="hidden" name="action" value="activarPadron">
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <% if (mensaje != null) { %>
        <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>
        <div class="card">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>DNI</th>
                                <th>Nombres y Apellidos</th>
                                <th>C&oacute;digo</th>
                                <th>Caser&iacute;o</th>
                                <th>Mesa Sufragio</th>
                                <th>Estado</th>
                                <th class="text-center" style="width:100px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (comuneros.isEmpty()) { %>
                            <tr><td colspan="7" class="text-center py-4 text-muted"><i class="bi bi-person-check fs-2 d-block mb-2"></i>No se encontraron comuneros.</td></tr>
                            <% } else { for (ComuneroDTO c : comuneros) { %>
                            <tr>
                                <td><%= c.getDni() %></td>
                                <td class="fw-semibold"><%= c.getNombres() != null ? c.getNombres() : "" %> <%= c.getApellidos() != null ? c.getApellidos() : "" %></td>
                                <td><span class="badge bg-light text-dark"><%= c.getCodigoPersonal() != null ? c.getCodigoPersonal() : "-" %></span></td>
                                <td><%= c.getNombreCaserio() != null ? c.getNombreCaserio() : "-" %></td>
                                <td><%= c.getCodigoMesa() != null ? c.getCodigoMesa() : "-" %></td>
                                <td><span class="badge bg-<%= c.isActivo() ? "success" : "danger" %>"><%= c.isActivo() ? "Activo" : "Inactivo" %></span></td>
                                <td class="text-center">
                                    <a class="btn btn-sm btn-outline-primary me-1" title="Editar" href="GestionComunerosServlet?action=editar&id=<%= c.getIdComunero() %>">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <% if (c.isActivo()) { %>
                                    <button class="btn btn-sm btn-outline-danger" title="Desactivar" onclick="confirmarEstado(<%= c.getIdComunero() %>, 'desactivarComunero', '<%= c.getDni() %>')"><i class="bi bi-x-lg"></i></button>
                                    <% } else { %>
                                    <button class="btn btn-sm btn-outline-success" title="Activar" onclick="confirmarEstado(<%= c.getIdComunero() %>, 'activarComunero', '<%= c.getDni() %>')"><i class="bi bi-check-lg"></i></button>
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
                            <a class="page-link" href="GestionComunerosServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %><%= idCaserioFiltro > 0 ? "&idCaserioFiltro=" + idCaserioFiltro : "" %>">&laquo;</a>
                        </li>
                        <% for (int i = 1; i <= totalPages; i++) { %>
                        <li class="page-item <%= i == currentPage ? "active" : "" %>">
                            <a class="page-link" href="GestionComunerosServlet?page=<%= i %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %><%= idCaserioFiltro > 0 ? "&idCaserioFiltro=" + idCaserioFiltro : "" %>"><%= i %></a>
                        </li>
                        <% } %>
                        <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                            <a class="page-link" href="GestionComunerosServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %><%= !busqueda.isEmpty() ? "&search=" + java.net.URLEncoder.encode(busqueda, "UTF-8") : "" %><%= idCaserioFiltro > 0 ? "&idCaserioFiltro=" + idCaserioFiltro : "" %>">&raquo;</a>
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

    <div class="modal fade" id="comuneroModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header" style="background:linear-gradient(135deg,#1a237e,#3949ab);color:#fff">
                    <h5 class="modal-title" id="comuneroModalLabel"><i class="bi bi-person-plus me-2"></i>Nuevo Comunero</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form action="GestionComunerosServlet" method="post" onsubmit="return validarFormulario()">
                    <input type="hidden" name="action" value="nuevo">
                    <div class="modal-body">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">DNI <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="dni" maxlength="8" placeholder="12345678" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Nombres <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="nombres" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Apellidos <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="apellidos" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Fecha nacimiento</label>
                                <input type="date" class="form-control" name="fechaNacimiento">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Sexo</label>
                                <select class="form-select" name="sexo">
                                    <option value="">-- Seleccione --</option>
                                    <option value="M">Masculino</option>
                                    <option value="F">Femenino</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Tel&eacute;fono</label>
                                <input type="text" class="form-control" name="telefono" maxlength="9" placeholder="999888777">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Clave de votaci&oacute;n (6 d&iacute;gitos)</label>
                                <input type="password" class="form-control" name="claveVotacion" maxlength="6" placeholder="Si se deja vac&iacute;o, se genera autom&aacute;ticamente" inputmode="numeric">
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Direcci&oacute;n</label>
                                <input type="text" class="form-control" name="direccion" placeholder="Direcci&oacute;n del comunero">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Caser&iacute;o <span class="text-danger">*</span></label>
                                <select class="form-select" name="idCaserio" id="selCaserioCrear" onchange="filtrarMesasCrear()" required>
                                    <option value="">-- Seleccione --</option>
                                    <% for (CaserioDTO cs : caserios) { %>
                                    <option value="<%= cs.getIdCaserio() %>"><%= cs.getNombreCaserio() %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Mesa de Sufragio <span class="text-danger">*</span></label>
                                <select class="form-select" name="idMesaSufragio" id="selMesaCrear" required>
                                    <option value="">-- Seleccione mesa --</option>
                                </select>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-circle me-1"></i>Registrar</button>
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
                    <h6 class="fw-bold" id="estadoModalTitle">&iquest;Desactivar comunero?</h6>
                    <p class="small text-muted mb-0" id="estadoModalText">Se desactivar&aacute; el comunero seleccionado</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <a class="btn btn-danger btn-sm" id="estadoEnlace" href="#"><i class="bi bi-check-lg me-1"></i><span id="estadoBtnText">Desactivar</span></a>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="resetModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-warning fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold">&iquest;Resetear todo el padr&oacute;n?</h6>
                    <p class="small text-muted mb-0">Se desactivar&aacute;n todos los comuneros y se limpiar&aacute;n las claves de votaci&oacute;n para la pr&oacute;xima elecci&oacute;n.</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-warning btn-sm" onclick="document.getElementById('formResetPadron').submit()"><i class="bi bi-check-lg me-1"></i>Resetear</button>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="activarPadronModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-check-circle text-success fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold">&iquest;Activar todo el padr&oacute;n?</h6>
                    <p class="small text-muted mb-0">Se activar&aacute;n todos los comuneros inactivos.</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-success btn-sm" onclick="document.getElementById('formActivarPadron').submit()"><i class="bi bi-check-lg me-1"></i>Activar</button>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="exportarModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-md">
            <div class="modal-content">
                <div class="modal-header bg-danger text-white">
                    <h5 class="modal-title"><i class="bi bi-filetype-pdf me-2"></i>Exportar listado de comuneros</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="text-center mb-4 pb-3 border-bottom">
                        <i class="bi bi-printer" style="font-size:2.5rem;color:#b71c1c"></i>
                        <h5 class="mt-2">Generar listado general de comuneros por caser&iacute;o</h5>
                        <p class="text-muted small">Todos los comuneros ordenados por caser&iacute;o. Columnas: N&deg;, DNI, Nombres y Apellidos, Mesa de Sufragio, Caser&iacute;o.</p>
                        <button type="button" class="btn btn-danger" onclick="exportarPDF('ExportarComunerosServlet')"><i class="bi bi-file-earmark-pdf me-1"></i>Generar PDF general</button>
                    </div>
                    <div class="text-center">
                        <i class="bi bi-funnel" style="font-size:2.5rem;color:#b71c1c"></i>
                        <h5 class="mt-2">Generar listado de comuneros por caser&iacute;o a escoger</h5>
                        <p class="text-muted small">Seleccione un caser&iacute;o para generar el listado solo de esa zona.</p>
                        <div class="d-flex gap-2 justify-content-center">
                            <select class="form-select w-auto" id="caserioExportar">
                                <option value="">Seleccione un caser&iacute;o</option>
                                <% for (CaserioDTO cs : caserios) { %>
                                <option value="<%= cs.getIdCaserio() %>"><%= cs.getNombreCaserio() %></option>
                                <% } %>
                            </select>
                            <button type="button" class="btn btn-danger" onclick="exportarPorCaserio()"><i class="bi bi-file-earmark-pdf me-1"></i>Generar PDF</button>
                        </div>
                    </div>
                </div>
                <div class="modal-footer justify-content-center">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        var mesasData = [
            <% for (MesaSufragioDTO m : mesas) { %>
            { id: <%= m.getIdMesaSufragio() %>, idCaserio: <%= m.getIdCaserio() %>, codigo: '<%= m.getCodigoMesa() != null ? m.getCodigoMesa().replace("'", "\\'") : "" %>' },
            <% } %>
        ];

        function filtrarCaserio(val) {
            var url = new URL(window.location.href);
            url.searchParams.set('idCaserioFiltro', val);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }

        function mostrarMensaje(texto) {
            document.getElementById('mensajeModalText').textContent = texto;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal')).show();
        }

        function validarFormulario() {
            var dni = document.querySelector('input[name="dni"]').value;
            if (!/^\d{8}$/.test(dni)) { mostrarMensaje('El DNI debe tener exactamente 8 d\u00edgitos num\u00e9ricos'); return false; }
            var tel = document.querySelector('input[name="telefono"]').value;
            if (tel && !/^\d{9}$/.test(tel)) { mostrarMensaje('El tel\u00e9fono debe tener 9 d\u00edgitos'); return false; }
            var clave = document.querySelector('input[name="claveVotacion"]').value;
            if (clave && !/^\d{6}$/.test(clave)) { mostrarMensaje('La clave de votaci\u00f3n debe tener 6 d\u00edgitos num\u00e9ricos'); return false; }
            var fn = document.querySelector('input[name="fechaNacimiento"]').value;
            if (fn) {
                var parts = fn.split('-');
                var nac = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                var hoy = new Date();
                var edad = hoy.getFullYear() - nac.getFullYear();
                var m = hoy.getMonth() - nac.getMonth();
                if (m < 0 || (m === 0 && hoy.getDate() < nac.getDate())) edad--;
                if (edad < 18) { mostrarMensaje('El comunero debe ser mayor de 18 a\u00f1os'); return false; }
            }
            return true;
        }

        function limpiarForm() {
            document.getElementById('comuneroModalLabel').innerHTML = '<i class="bi bi-person-plus me-2"></i>Nuevo Comunero';
            var form = document.querySelector('#comuneroModal form');
            form.reset();
            document.getElementById('selMesaCrear').innerHTML = '<option value="">-- Seleccione mesa --</option>';
        }

        function filtrarMesasCrear() {
            var idCaserio = parseInt(document.getElementById('selCaserioCrear').value);
            var sel = document.getElementById('selMesaCrear');
            sel.innerHTML = '<option value="">-- Seleccione mesa --</option>';
            if (!idCaserio) return;
            for (var i = 0; i < mesasData.length; i++) {
                if (mesasData[i].idCaserio === idCaserio) {
                    sel.innerHTML += '<option value="' + mesasData[i].id + '">' + mesasData[i].codigo + '</option>';
                }
            }
        }

        function confirmarEstado(id, action, dni) {
            if (action === 'desactivarComunero') {
                document.getElementById('estadoModalTitle').textContent = '\u00bfDesactivar comunero DNI ' + dni + '?';
                document.getElementById('estadoModalText').textContent = 'Se desactivar\u00e1 el comunero DNI ' + dni;
                document.getElementById('estadoEnlace').className = 'btn btn-danger btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionComunerosServlet?action=desactivarComunero&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Desactivar';
            } else {
                document.getElementById('estadoModalTitle').textContent = '\u00bfActivar comunero DNI ' + dni + '?';
                document.getElementById('estadoModalText').textContent = 'Se activar\u00e1 el comunero DNI ' + dni;
                document.getElementById('estadoEnlace').className = 'btn btn-success btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionComunerosServlet?action=activarComunero&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Activar';
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('estadoModal')).show();
        }

        function confirmarResetPadron() {
            bootstrap.Modal.getOrCreateInstance(document.getElementById('resetModal')).show();
        }

        function confirmarActivarPadron() {
            bootstrap.Modal.getOrCreateInstance(document.getElementById('activarPadronModal')).show();
        }

        function cambiarPorPagina(val) {
            var url = new URL(window.location.href);
            url.searchParams.set('por_pagina', val);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }

        function exportarPDF(url) {
            var w = window.open(url, '_blank');
            if (w) w.focus();
            bootstrap.Modal.getInstance(document.getElementById('exportarModal')).hide();
        }

        function exportarPorCaserio() {
            var sel = document.getElementById('caserioExportar');
            if (!sel.value) { alert('Seleccione un caser\u00edo'); return; }
            var w = window.open('ExportarComunerosServlet?idCaserio=' + sel.value, '_blank');
            if (w) w.focus();
            bootstrap.Modal.getInstance(document.getElementById('exportarModal')).hide();
        }
    </script>
<% } %>

    <div class="modal fade" id="mensajeModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-danger fs-1 mb-3 d-block"></i>
                    <p class="mb-0" id="mensajeModalText" style="font-size:1.1rem"></p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-primary btn-sm" data-bs-dismiss="modal">Aceptar</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <% if (error != null && !error.isEmpty()) { %>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('mensajeModalText').textContent = '<%= error.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "") %>';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal')).show();
        });
    </script>
    <% } %>
</body>
</html>

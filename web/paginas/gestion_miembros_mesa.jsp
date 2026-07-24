<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.CaserioDTO"%>
<%@page import="dto.ComuneroDTO"%>
<%@page import="dto.MesaSufragioDTO"%>
<%@page import="dto.MiembroMesaDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<CaserioDTO> caserios = (List<CaserioDTO>) request.getAttribute("caserios");
    List<MiembroMesaDTO> miembros = (List<MiembroMesaDTO>) request.getAttribute("miembros");
    List<ComuneroDTO> disponibles = (List<ComuneroDTO>) request.getAttribute("disponibles");
    List<MesaSufragioDTO> mesas = (List<MesaSufragioDTO>) request.getAttribute("mesas");
    Integer totalMiembros = (Integer) request.getAttribute("totalMiembros");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String idCaserioStr = request.getParameter("idCaserio");
    int idCaserio = idCaserioStr != null && !idCaserioStr.isEmpty() ? Integer.parseInt(idCaserioStr) : 0;
    if (caserios == null) caserios = new java.util.ArrayList<>();
    if (miembros == null) miembros = new java.util.ArrayList<>();
    if (disponibles == null) disponibles = new java.util.ArrayList<>();
    if (mesas == null) mesas = new java.util.ArrayList<>();
    if (totalMiembros == null) totalMiembros = 0;
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Miembros de Mesa - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Miembros de Mesa</h4>
                <small class="text-muted">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <% if (mensaje != null) { %>
        <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show"><i class="bi bi-exclamation-triangle me-2"></i><%= error %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>

        <div class="card mb-4">
            <div class="card-body">
                <div class="mb-3">
                    <a class="btn btn-outline-danger" href="ExportarMiembrosMesaServlet" target="_blank"><i class="bi bi-filetype-pdf me-1"></i>Exportar datos generales Mesa</a>
                </div>
                <form class="row g-2" method="get" action="GestionMiembrosMesaServlet">
                    <div class="col-md-5">
                        <select class="form-select" name="idCaserio" onchange="this.form.submit()">
                            <option value="0">-- Seleccione caser&iacute;o --</option>
                            <% for (CaserioDTO c : caserios) { %>
                            <option value="<%= c.getIdCaserio() %>" <%= c.getIdCaserio() == idCaserio ? "selected" : "" %>><%= c.getNombreCaserio() %></option>
                            <% } %>
                        </select>
                    </div>
                    <% if (idCaserio > 0) { %>
                    <div class="col-md-3">
                        <select class="form-select" name="idMesaSufragio" id="selMesaMiembro">
                            <option value="0">-- Seleccione mesa --</option>
                            <% for (MesaSufragioDTO m : mesas) { %>
                            <option value="<%= m.getIdMesaSufragio() %>"><%= m.getCodigoMesa() %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col-auto">
                        <a class="btn btn-primary" id="btnSeleccionar" href="#"><i class="bi bi-shuffle me-1"></i>Seleccionar aleatoriamente</a>
                    </div>
                    <% } %>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-body">
                <% if (idCaserio > 0) { %>
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <p class="text-muted mb-0">Comuneros disponibles en este caser&iacute;o: <strong><%= disponibles.size() %></strong></p>
                    <div class="d-flex gap-2">
                        <a class="btn btn-outline-danger btn-sm" href="ExportarMiembrosMesaServlet?idCaserio=<%= idCaserio %>" target="_blank"><i class="bi bi-filetype-pdf me-1"></i>Exportar PDF</a>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>DNI</th>
                                <th>Nombre</th>
                                <th>Mesa</th>
                                <th>Cargo</th>
                                <th>Fecha asignaci&oacute;n</th>
                                <th class="text-center" style="width:80px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (miembros.isEmpty()) { %>
                            <tr><td colspan="6" class="text-center py-4 text-muted"><i class="bi bi-person-badge fs-2 d-block mb-2"></i>No hay miembros asignados en este caser&iacute;o.</td></tr>
                            <% } else { for (MiembroMesaDTO m : miembros) { %>
                            <tr>
                                <td><%= m.getDniComunero() != null ? m.getDniComunero() : "-" %></td>
                                <td class="fw-semibold"><%= m.getNombreComunero() != null ? m.getNombreComunero() : "-" %></td>
                                <td><%= m.getCodigoMesa() != null ? m.getCodigoMesa() : "-" %></td>
                                <td><span class="badge bg-info text-dark"><%= m.getCargo() != null ? m.getCargo() : "-" %></span></td>
                                <td><small><%= m.getFechaAsignacion() != null ? m.getFechaAsignacion() : "-" %></small></td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-danger" title="Eliminar" onclick="confirmarEliminar(<%= m.getIdMiembroMesa() %>, '<%= m.getNombreComunero() != null ? m.getNombreComunero().replace("'", "\\'") : "" %>')"><i class="bi bi-trash"></i></button>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
                <% } else { %>
                <p class="text-center text-muted py-4 mb-0"><i class="bi bi-hand-index fs-2 d-block mb-2"></i>Seleccione un caser&iacute;o para ver sus miembros de mesa.</p>
                <% } %>
            </div>
        </div>

        <footer class="mt-4">
            <p class="mb-0">&copy; 2026 CCSPM - Comunidad Campesina San Pedro de M&oacute;rrope. Todos los derechos reservados.</p>
        </footer>
    </div>

    <!-- Modal Mensaje -->
    <div class="modal fade" id="mensajeModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-warning fs-1 mb-3 d-block"></i>
                    <p class="mb-0" id="mensajeModalText"></p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-primary btn-sm" data-bs-dismiss="modal">Aceptar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="eliminarModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-danger fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold">&iquest;Eliminar este miembro de mesa?</h6>
                    <p class="small text-muted mb-0" id="eliminarText">Se eliminar&aacute; el miembro seleccionado</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <a class="btn btn-danger btn-sm" id="eliminarEnlace" href="#"><i class="bi bi-trash me-1"></i>Eliminar</a>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="seleccionarModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-shuffle text-primary fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold">&iquest;Seleccionar aleatoriamente PRESIDENTE, SECRETARIO y VOCAL para esta mesa?</h6>
                    <p class="small text-muted mb-0">Se asignar&aacute;n 3 comuneros disponibles de forma aleatoria</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <a class="btn btn-primary btn-sm" id="seleccionarEnlace" href="#"><i class="bi bi-shuffle me-1"></i>Seleccionar</a>
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function confirmarEliminar(id, nombre) {
            document.getElementById('eliminarText').textContent = 'Se eliminar\u00e1 el miembro "' + nombre + '"';
            document.getElementById('eliminarEnlace').href = 'GestionMiembrosMesaServlet?action=eliminar&id=' + id + '&idCaserio=<%= idCaserio %>';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('eliminarModal')).show();
        }

        document.getElementById('btnSeleccionar').addEventListener('click', function() {
            var selMesa = document.getElementById('selMesaMiembro');
            if (!selMesa || selMesa.value === '0') {
                document.getElementById('mensajeModalText').textContent = 'Seleccione una mesa de sufragio';
                bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal')).show();
                return;
            }
            var url = 'GestionMiembrosMesaServlet?action=seleccionarAleatorios&idCaserio=<%= idCaserio %>&idMesaSufragio=' + selMesa.value;
            document.getElementById('seleccionarEnlace').href = url;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('seleccionarModal')).show();
        });
    </script>
</body>
</html>

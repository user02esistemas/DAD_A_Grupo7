<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.EleccionDTO"%>
<%!
    String fmtHora12(String h24) {
        if (h24 == null || h24.isEmpty()) return "";
        String[] p = h24.split(":");
        if (p.length < 2) return h24;
        try {
            int h = Integer.parseInt(p[0]);
            int m = Integer.parseInt(p[1]);
            String ampm = h >= 12 ? "PM" : "AM";
            int h12 = h % 12;
            if (h12 == 0) h12 = 12;
            return h12 + ":" + (m < 10 ? "0" : "") + m + " " + ampm;
        } catch (NumberFormatException e) {
            return h24;
        }
    }
    String opcionesHora() {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 12; i++) sb.append("<option value=\"").append(i).append("\">").append(i).append("</option>");
        return sb.toString();
    }
    String opcionesMinuto() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 60; i++) sb.append("<option value=\"").append(i < 10 ? "0" : "").append(i).append("\">").append(i < 10 ? "0" : "").append(i).append("</option>");
        return sb.toString();
    }
%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<EleccionDTO> elecciones = (List<EleccionDTO>) request.getAttribute("elecciones");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    if (elecciones == null) elecciones = new java.util.ArrayList<>();
    if (busqueda == null) busqueda = "";
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
    if (porPagina == null) porPagina = 20;
    if (totalRegistros == null) totalRegistros = 0;
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestión de Elecciones - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Gesti&oacute;n de Elecciones</h4>
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
                        <form method="get" action="GestionEleccionesServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar elecci&oacute;n..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="GestionEleccionesServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-7 text-md-end">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#eleccionModal" onclick="abrirNuevo()">
                            <i class="bi bi-plus-lg me-1"></i>Nueva Elecci&oacute;n
                        </button>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                            <tr>
                                <th style="min-width:120px">Nombre</th>
                                <th>Inicio insc.</th>
                                <th>Cierre insc.</th>
                                <th>Votaci&oacute;n</th>
                                <th>Horario vot.</th>
                                <th>Estado</th>
                                <th>Activa</th>
                                <th style="width:60px">Acc.</th>
                            </tr>
                        </thead>
                        <tbody id="tablaElecciones">
                            <% if (elecciones.isEmpty()) { %>
                            <tr><td colspan="8" class="text-center text-muted py-4">No se encontraron elecciones</td></tr>
                            <% } else { for (EleccionDTO e : elecciones) {
                                String estadoColor;
                                switch (e.getEstado() != null ? e.getEstado() : "") {
                                    case "PROXIMA": estadoColor = "secondary"; break;
                                    case "INSCRIPCIONES_ABIERTAS": estadoColor = "info"; break;
                                    case "EN_VOTACION": estadoColor = "warning"; break;
                                    case "FINALIZADA": estadoColor = "dark"; break;
                                    default: estadoColor = "secondary";
                                }
                            %>
                            <tr data-id="<%= e.getIdEleccion() %>"
                                data-ini-ins="<%= e.getFechaInicioInscripcion() != null ? e.getFechaInicioInscripcion() : "" %>T<%= e.getHoraInicioInscripcion() != null ? e.getHoraInicioInscripcion() : "00:00" %>"
                                data-fin-ins="<%= e.getFechaCierreInscripcion() != null ? e.getFechaCierreInscripcion() : "" %>T<%= e.getHoraFinInscripcion() != null ? e.getHoraFinInscripcion() : "00:00" %>"
                                data-fec-vot="<%= e.getFechaVotacion() != null ? e.getFechaVotacion() : "" %>T<%= e.getHoraInicioVotacion() != null ? e.getHoraInicioVotacion() : "00:00" %>"
                                data-fin-vot="<%= e.getFechaVotacion() != null ? e.getFechaVotacion() : "" %>T<%= e.getHoraFinVotacion() != null ? e.getHoraFinVotacion() : "00:00" %>"
                                data-estado="<%= e.getEstado() != null ? e.getEstado() : "" %>">
                                <td><strong><%= e.getNombreEleccion() != null ? e.getNombreEleccion() : "" %></strong></td>
                                <td class="ini-ins"><%= e.getFechaInicioInscripcion() != null ? e.getFechaInicioInscripcion() : "" %> <%= fmtHora12(e.getHoraInicioInscripcion()) %></td>
                                <td class="fin-ins"><%= e.getFechaCierreInscripcion() != null ? e.getFechaCierreInscripcion() : "" %> <%= fmtHora12(e.getHoraFinInscripcion()) %></td>
                                <td><%= e.getFechaVotacion() != null ? e.getFechaVotacion() : "" %></td>
                                <td><%= fmtHora12(e.getHoraInicioVotacion()) %> - <%= fmtHora12(e.getHoraFinVotacion()) %></td>
                                <td><span class="badge bg-<%= estadoColor %> bg-opacity-10 text-<%= estadoColor %> estado-badge"><%= e.getEstado() != null ? e.getEstado().replace("_", " ") : "" %></span></td>
                                <td><span class="badge <%= e.isActiva() ? "bg-success" : "bg-danger" %> activa-badge"><%= e.isActiva() ? "S\u00ed" : "No" %></span></td>
                                <td>
                                    <button class="btn btn-sm btn-warning" title="Editar" onclick='editar(<%= new com.google.gson.Gson().toJson(e) %>)'><i class="bi bi-pencil"></i></button>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>

                <div class="d-flex justify-content-between align-items-center mt-3">
                    <div>
                        <small class="text-muted">Total de elecciones: <strong><%= totalRegistros %></strong></small>
                        <br>
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
                                <a class="page-link" href="GestionEleccionesServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Anterior</a>
                            </li>
                            <% for (int i = 1; i <= totalPages; i++) { %>
                            <li class="page-item <%= i == currentPage ? "active" : "" %>">
                                <a class="page-link" href="GestionEleccionesServlet?page=<%= i %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>"><%= i %></a>
                            </li>
                            <% } %>
                            <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                                <a class="page-link" href="GestionEleccionesServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Siguiente</a>
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

    <!-- Modal Mensaje -->
    <div class="modal fade" id="mensajeModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-info-circle text-primary fs-1 mb-3 d-block"></i>
                    <p class="mb-0" id="mensajeModalText"></p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-primary btn-sm" data-bs-dismiss="modal">Aceptar</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Nueva/Editar Eleccion -->
    <div class="modal fade" id="eleccionModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <form id="eleccionForm" method="post" action="GestionEleccionesServlet" onsubmit="return validarForm()">
                    <input type="hidden" name="action" id="action" value="nuevo">
                    <input type="hidden" name="id" id="eleccionId" value="">
                    <input type="hidden" name="horaInicioInscripcion" id="horaInicioInscripcion">
                    <input type="hidden" name="horaFinInscripcion" id="horaFinInscripcion">
                    <input type="hidden" name="horaInicioVotacion" id="horaInicioVotacion">
                    <input type="hidden" name="horaFinVotacion" id="horaFinVotacion">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold" id="modalTitle" style="color:#1a237e">Nueva Elecci&oacute;n</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label small fw-medium">Nombre de la Elecci&oacute;n <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="nombreEleccion" id="nombreEleccion">
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-medium">Descripci&oacute;n</label>
                            <textarea class="form-control" name="descripcion" id="descripcion" rows="2"></textarea>
                        </div>
                        <hr>
                        <h6 class="fw-bold mb-3" style="color:#1a237e">Inscripciones</h6>
                        <div class="row g-2 mb-3 align-items-end">
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Fecha inicio</label>
                                <input type="date" class="form-control" name="fechaInicioInscripcion" id="fechaInicioInscripcion">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Hora inicio</label>
                                <div class="input-group">
                                    <select class="form-select form-select-sm" id="hii_h" style="flex:2"><%= opcionesHora() %></select>
                                    <span class="input-group-text p-0 px-1">:</span>
                                    <select class="form-select form-select-sm" id="hii_m" style="flex:2"><%= opcionesMinuto() %></select>
                                    <select class="form-select form-select-sm" id="hii_a" style="flex:3"><option value="AM">AM</option><option value="PM">PM</option></select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Fecha cierre</label>
                                <input type="date" class="form-control" name="fechaCierreInscripcion" id="fechaCierreInscripcion">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Hora cierre</label>
                                <div class="input-group">
                                    <select class="form-select form-select-sm" id="hfi_h" style="flex:2"><%= opcionesHora() %></select>
                                    <span class="input-group-text p-0 px-1">:</span>
                                    <select class="form-select form-select-sm" id="hfi_m" style="flex:2"><%= opcionesMinuto() %></select>
                                    <select class="form-select form-select-sm" id="hfi_a" style="flex:3"><option value="AM">AM</option><option value="PM">PM</option></select>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <h6 class="fw-bold mb-3" style="color:#1a237e">Votaci&oacute;n</h6>
                        <div class="row g-2 align-items-end">
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Fecha votaci&oacute;n</label>
                                <input type="date" class="form-control" name="fechaVotacion" id="fechaVotacion">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Hora apertura</label>
                                <div class="input-group">
                                    <select class="form-select form-select-sm" id="hiv_h" style="flex:2"><%= opcionesHora() %></select>
                                    <span class="input-group-text p-0 px-1">:</span>
                                    <select class="form-select form-select-sm" id="hiv_m" style="flex:2"><%= opcionesMinuto() %></select>
                                    <select class="form-select form-select-sm" id="hiv_a" style="flex:3"><option value="AM">AM</option><option value="PM">PM</option></select>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-medium">Hora cierre</label>
                                <div class="input-group">
                                    <select class="form-select form-select-sm" id="hfv_h" style="flex:2"><%= opcionesHora() %></select>
                                    <span class="input-group-text p-0 px-1">:</span>
                                    <select class="form-select form-select-sm" id="hfv_m" style="flex:2"><%= opcionesMinuto() %></select>
                                    <select class="form-select form-select-sm" id="hfv_a" style="flex:3"><option value="AM">AM</option><option value="PM">PM</option></select>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <div class="row g-2 mb-3" id="rowEstado">
                            <div class="col-md-6">
                                <label class="form-label small fw-medium">Estado (calculado automáticamente)</label>
                                <input type="hidden" name="estado" id="estado" value="PROXIMA">
                                <input type="text" class="form-control" id="estadoDisplay" value="PRÓXIMA" readonly>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small fw-medium">Activa</label>
                                <select class="form-select" name="activa" id="activa">
                                    <option value="0">No</option>
                                    <option value="1">Sí</option>
                                </select>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Guardar</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="frontend/js/admin.js"></script>
    <script>
        function h24(h, m, a) { var hh = parseInt(h); if (a === 'PM' && hh !== 12) hh += 12; if (a === 'AM' && hh === 12) hh = 0; return (hh < 10 ? '0' : '') + hh + ':' + m + ':00'; }

        function obtenerHora24(prefix) {
            var h = document.getElementById(prefix + '_h').value;
            var m = document.getElementById(prefix + '_m').value;
            var a = document.getElementById(prefix + '_a').value;
            return h24(h, m, a);
        }

        function asignarSelectores(prefix, hora24) {
            if (!hora24) return;
            var p = hora24.split(':');
            if (p.length < 2) return;
            var hh = parseInt(p[0]);
            var mm = p[1];
            var ampm = hh >= 12 ? 'PM' : 'AM';
            var h12 = hh % 12;
            if (h12 === 0) h12 = 12;
            document.getElementById(prefix + '_h').value = h12;
            document.getElementById(prefix + '_m').value = mm;
            document.getElementById(prefix + '_a').value = ampm;
        }

        function mostrarMensaje(texto) {
            var msgModal = bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal'));
            var elecModal = bootstrap.Modal.getInstance(document.getElementById('eleccionModal'));
            document.getElementById('mensajeModalText').textContent = texto;
            if (elecModal) {
                elecModal.hide();
                document.getElementById('mensajeModal').addEventListener('hidden.bs.modal', function () {
                    elecModal.show();
                }, { once: true });
            }
            msgModal.show();
        }

        function validarForm() {
            var fIni = document.getElementById('fechaInicioInscripcion').value;
            var fCie = document.getElementById('fechaCierreInscripcion').value;
            var fVot = document.getElementById('fechaVotacion').value;
            if (!fIni || !fCie || !fVot) {
                mostrarMensaje('Todas las fechas son obligatorias');
                return false;
            }
            if (fIni > fCie || fCie > fVot) {
                mostrarMensaje('Las fechas deben cumplir: inicio inscripci\u00f3n \u2264 cierre inscripci\u00f3n \u2264 fecha votaci\u00f3n');
                return false;
            }
            if (fIni === fVot || fCie === fVot) {
                mostrarMensaje('Las fechas de inscripci\u00f3n y votaci\u00f3n no pueden ser el mismo d\u00eda');
                return false;
            }
            document.getElementById('horaInicioInscripcion').value = obtenerHora24('hii');
            document.getElementById('horaFinInscripcion').value = obtenerHora24('hfi');
            document.getElementById('horaInicioVotacion').value = obtenerHora24('hiv');
            document.getElementById('horaFinVotacion').value = obtenerHora24('hfv');
            return true;
        }

        function abrirNuevo() {
            document.getElementById('modalTitle').textContent = 'Nueva Elecci\u00f3n';
            document.getElementById('action').value = 'nuevo';
            document.getElementById('eleccionForm').reset();
            document.getElementById('eleccionId').value = '';
            document.getElementById('estado').value = 'PROXIMA';
            document.getElementById('estadoDisplay').value = 'PRÓXIMA';
            document.getElementById('activa').value = '1';
            document.getElementById('activa').disabled = false;
            document.getElementById('rowEstado').style.display = 'flex';
            ['hii','hfi','hiv','hfv'].forEach(function(p) {
                document.getElementById(p + '_h').value = 8;
                document.getElementById(p + '_m').value = '00';
                document.getElementById(p + '_a').value = 'AM';
            });
        }

        function editar(e) {
            document.getElementById('modalTitle').textContent = 'Editar Elecci\u00f3n';
            document.getElementById('action').value = 'editar';
            document.getElementById('eleccionId').value = e.idEleccion;
            document.getElementById('nombreEleccion').value = e.nombreEleccion || '';
            document.getElementById('descripcion').value = e.descripcion || '';
            document.getElementById('fechaInicioInscripcion').value = e.fechaInicioInscripcion || '';
            document.getElementById('fechaCierreInscripcion').value = e.fechaCierreInscripcion || '';
            asignarSelectores('hii', e.horaInicioInscripcion);
            asignarSelectores('hfi', e.horaFinInscripcion);
            document.getElementById('fechaVotacion').value = e.fechaVotacion || '';
            asignarSelectores('hiv', e.horaInicioVotacion);
            asignarSelectores('hfv', e.horaFinVotacion);
            document.getElementById('estado').value = e.estado || 'PROXIMA';
            document.getElementById('estadoDisplay').value = (e.estado || 'PROXIMA').replace(/_/g, ' ');
            document.getElementById('activa').value = e.activa ? '1' : '0';
            document.getElementById('rowEstado').style.display = 'flex';
            var modal = new bootstrap.Modal(document.getElementById('eleccionModal'));
            modal.show();
        }

        var ESTADOS = ['PROXIMA', 'INSCRIPCIONES_ABIERTAS', 'EN_VOTACION', 'FINALIZADA'];
        var COLORES = { 'PROXIMA': 'secondary', 'INSCRIPCIONES_ABIERTAS': 'info', 'EN_VOTACION': 'warning', 'FINALIZADA': 'dark' };

        function calcularEstado(row) {
            var ahora = new Date();
            var iniIns = row.getAttribute('data-ini-ins');
            var finIns = row.getAttribute('data-fin-ins');
            var fecVot = row.getAttribute('data-fec-vot');
            var finVot = row.getAttribute('data-fin-vot');
            var dIniIns = iniIns ? new Date(iniIns) : null;
            var dFinIns = finIns ? new Date(finIns) : null;
            var dFecVot = fecVot ? new Date(fecVot) : null;
            var dFinVot = finVot ? new Date(finVot) : null;
            if (dFinVot && ahora >= dFinVot) return 'FINALIZADA';
            if (dFecVot && dFinVot && ahora >= dFecVot && ahora < dFinVot) return 'EN_VOTACION';
            if (dFinIns && dFecVot && ahora >= dFinIns && ahora < dFecVot) return 'PROXIMA';
            if (dIniIns && dFinIns && ahora >= dIniIns && ahora < dFinIns) return 'INSCRIPCIONES_ABIERTAS';
            return 'PROXIMA';
        }

        function actualizarEstados() {
            document.querySelectorAll('#tablaElecciones tr[data-estado]').forEach(function(row) {
                var nuevo = calcularEstado(row);
                var badge = row.querySelector('.estado-badge');
                if (badge && badge.textContent.trim().replace(/ /g, '_') !== nuevo) {
                    badge.textContent = nuevo.replace(/_/g, ' ');
                    badge.className = 'badge bg-' + COLORES[nuevo] + ' bg-opacity-10 text-' + COLORES[nuevo] + ' estado-badge';
                    row.setAttribute('data-estado', nuevo);
                }
            });
        }

        setInterval(actualizarEstados, 30000);

        function cambiarPagina(valor) {
            var url = new URL(window.location.href);
            url.searchParams.set('por_pagina', valor);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }
    </script>
</body>
</html>

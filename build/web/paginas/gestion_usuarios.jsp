<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.UsuarioDTO"%>
<%@page import="dto.RolDTO"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<UsuarioDTO> usuarios = (List<UsuarioDTO>) request.getAttribute("usuarios");
    List<RolDTO> roles = (List<RolDTO>) request.getAttribute("roles");
    List<String> modulos = (List<String>) request.getAttribute("modulos");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer porPagina = (Integer) request.getAttribute("porPagina");
    Integer totalRegistros = (Integer) request.getAttribute("totalRegistros");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String busqueda = request.getParameter("search");
    if (usuarios == null) usuarios = new java.util.ArrayList<>();
    if (roles == null) roles = new java.util.ArrayList<>();
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
    <title>Gestión de Usuarios - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h4 class="fw-bold mb-0" style="color:#1a237e">Gesti&oacute;n de Usuarios</h4>
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
                        <form method="get" action="GestionUsuariosServlet" class="input-group">
                            <input type="text" class="form-control" name="search" placeholder="Buscar por DNI..." value="<%= busqueda %>">
                            <button class="btn btn-outline-primary" type="submit"><i class="bi bi-search me-1"></i>Buscar</button>
                            <% if (!busqueda.isEmpty()) { %>
                            <a href="GestionUsuariosServlet" class="btn btn-outline-secondary"><i class="bi bi-x-lg"></i></a>
                            <% } %>
                        </form>
                    </div>
                    <div class="col-md-7 text-md-end">
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#usuarioModal" onclick="abrirNuevo()">
                            <i class="bi bi-plus-lg me-1"></i>Nuevo Usuario
                        </button>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                            <tr>
                                <th>Usuario</th>
                                <th>Nombres</th>
                                <th>DNI</th>
                                <th>Rol</th>
                                <th>Estado</th>
                                <th style="width:160px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (usuarios.isEmpty()) { %>
                            <tr><td colspan="6" class="text-center text-muted py-4">No se encontraron usuarios</td></tr>
                            <% } else { for (UsuarioDTO u : usuarios) { %>
                            <tr>
                                <td><strong><%= u.getNombreUsuario() %></strong></td>
                                <td><%= u.getNombres() != null ? u.getNombres() : "" %> <%= u.getApellidos() != null ? u.getApellidos() : "" %></td>
                                <td><%= u.getDni() != null ? u.getDni() : "" %></td>
                                <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= u.getNombreRol() != null ? u.getNombreRol() : "" %></span></td>
                                <td><span class="badge <%= "ACTIVO".equals(u.getEstado()) ? "bg-success" : "bg-danger" %> bg-opacity-10 text-<%= "ACTIVO".equals(u.getEstado()) ? "success" : "danger" %>"><%= u.getEstado() != null ? u.getEstado() : "ACTIVO" %></span></td>
                                <td>
                                    <button class="btn btn-sm btn-warning me-1" title="Editar" onclick='abrirEditar(<%= new com.google.gson.Gson().toJson(u) %>)'><i class="bi bi-pencil"></i></button>
                                    <% if ("ACTIVO".equals(u.getEstado())) { %>
                                    <button class="btn btn-sm btn-outline-danger" title="Desactivar" onclick="confirmarEstado(<%= u.getIdUsuario() %>, 'desactivarUsuario', '<%= u.getNombreUsuario().replace("'", "\\'") %>')"><i class="bi bi-x-lg"></i></button>
                                    <% } else { %>
                                    <button class="btn btn-sm btn-outline-success" title="Activar" onclick="confirmarEstado(<%= u.getIdUsuario() %>, 'activarUsuario', '<%= u.getNombreUsuario().replace("'", "\\'") %>')"><i class="bi bi-check-lg"></i></button>
                                    <% } %>
                                    <button class="btn btn-sm btn-outline-danger" title="Eliminar" onclick="confirmarEliminar(<%= u.getIdUsuario() %>, '<%= u.getNombreUsuario().replace("'", "\\'") %>')"><i class="bi bi-trash"></i></button>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>

                <div class="d-flex justify-content-between align-items-center mt-3">
                    <div>
                        <small class="text-muted">Total de usuarios: <strong><%= totalRegistros %></strong></small>
                        <br>
                        <small class="text-muted">Registros por p&aacute;gina:
                        <select class="form-select form-select-sm d-inline-block" style="width:auto" onchange="cambiarPagina(this.value)">
                            <option value="20" <%= porPagina == 20 ? "selected" : "" %>>20 </option>
                            <option value="50" <%= porPagina == 50 ? "selected" : "" %>>50 </option>
                            <option value="100" <%= porPagina == 100 ? "selected" : "" %>>100 </option>
                        </select>
                        </small>
                    </div>
                    <nav>
                        <ul class="pagination pagination-sm mb-0">
                            <li class="page-item <%= currentPage <= 1 ? "disabled" : "" %>">
                                <a class="page-link" href="GestionUsuariosServlet?page=<%= currentPage - 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Anterior</a>
                            </li>
                            <% for (int i = 1; i <= totalPages; i++) { %>
                            <li class="page-item <%= i == currentPage ? "active" : "" %>">
                                <a class="page-link" href="GestionUsuariosServlet?page=<%= i %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>"><%= i %></a>
                            </li>
                            <% } %>
                            <li class="page-item <%= currentPage >= totalPages ? "disabled" : "" %>">
                                <a class="page-link" href="GestionUsuariosServlet?page=<%= currentPage + 1 %>&por_pagina=<%= porPagina %>&search=<%= java.net.URLEncoder.encode(busqueda, "UTF-8") %>">Siguiente</a>
                            </li>
                        </ul>
                    </nav>
                </div>
            </div>
        </div>

        <footer>
            <i class="bi bi-shield-fill-check text-success me-1"></i>
            SVE CCSPM &middot; Comunidad Campesina San Pablo del Monte &middot; Todos los derechos reservados
        </footer>
    </div>

    <!-- Modal Nuevo/Editar Usuario -->
    <div class="modal fade" id="usuarioModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <form id="usuarioForm" method="post" action="GestionUsuariosServlet" onsubmit="return validarFormulario()">
                    <input type="hidden" name="action" id="action" value="nuevo">
                    <input type="hidden" name="id" id="usuarioId" value="">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold" id="modalTitle" style="color:#1a237e">Nuevo Usuario</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Nombre</label>
                                    <input type="text" class="form-control" name="nombres" id="nombres" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Apellidos</label>
                                    <input type="text" class="form-control" name="apellidos" id="apellidos" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">DNI</label>
                                    <input type="text" class="form-control" name="dni" id="dni" maxlength="8" inputmode="numeric">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Tel&eacute;fono</label>
                                    <input type="text" class="form-control" name="telefono" id="telefono" maxlength="9" inputmode="numeric">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Usuario</label>
                                    <input type="text" class="form-control" name="nombreUsuario" id="nombreUsuario" required>
                                </div>
                                <div class="mb-3" id="passwordField">
                                    <label class="form-label small fw-medium">Contrase&ntilde;a</label>
                                    <input type="password" class="form-control" name="contrasena" id="contrasena">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Correo</label>
                                    <input type="email" class="form-control" name="correo" id="correo">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small fw-medium">Rol</label>
                                    <select class="form-select" name="idRol" id="idRol">
                                        <% for (RolDTO r : roles) { %>
                                        <option value="<%= r.getIdRol() %>"><%= r.getNombreRol() %></option>
                                        <% } %>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small fw-medium mb-2">Permisos por m&oacute;dulo</label>
                                <div class="border rounded p-3" style="max-height:380px;overflow-y:auto">
                                    <% for (String m : modulos) { %>
                                    <div class="form-check mb-2">
                                        <input class="form-check-input module-check" type="checkbox" name="modulos" value="<%= m %>" id="mod_<%= m.replaceAll("\\s+", "_").replaceAll("[^a-zA-Z0-9_]", "") %>">
                                        <label class="form-check-label small" for="mod_<%= m.replaceAll("\\s+", "_").replaceAll("[^a-zA-Z0-9_]", "") %>"><%= m %></label>
                                    </div>
                                    <% } %>
                                </div>
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

    <!-- Modal Eliminar -->
    <div class="modal fade" id="eliminarModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-danger fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold" id="eliminarModalTitle">&iquest;Eliminar usuario?</h6>
                    <p class="small text-muted mb-0" id="eliminarModalText">Se eliminar&aacute; el usuario seleccionado</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                    <a id="eliminarModalBtn" class="btn btn-danger btn-sm"><i class="bi bi-trash me-1"></i>Eliminar</a>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Estado -->
    <div class="modal fade" id="estadoModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-sm modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-body text-center py-4">
                    <i class="bi bi-exclamation-triangle text-warning fs-1 mb-3 d-block"></i>
                    <h6 class="fw-bold" id="estadoModalTitle">&iquest;Desactivar usuario?</h6>
                    <p class="small text-muted mb-0" id="estadoModalText">Se desactivar&aacute; el usuario seleccionado</p>
                </div>
                <div class="modal-footer justify-content-center border-0 pt-0">
                    <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancelar</button>
                    <a id="estadoModalBtn" class="btn btn-danger btn-sm"><i class="bi bi-check-lg me-1"></i>Desactivar</a>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="frontend/js/admin.js"></script>
    <script>
        var MODULOS_POR_ROL = {
            1: ["Dashboard", "Gesti\u00f3n de Usuarios", "Gesti\u00f3n de Comuneros",
                "Gesti\u00f3n de Elecciones", "Partidos y Candidatos",
                "Gesti\u00f3n de Caser\u00edos", "Locales de Votaci\u00f3n",
                "Mesas de Sufragio", "Miembros de Mesa",
                "Resultados", "Auditor\u00eda"],
            2: ["Dashboard", "Gesti\u00f3n de Usuarios", "Gesti\u00f3n de Comuneros",
                "Gesti\u00f3n de Elecciones", "Partidos y Candidatos",
                "Gesti\u00f3n de Caser\u00edos", "Locales de Votaci\u00f3n",
                "Mesas de Sufragio", "Miembros de Mesa",
                "Resultados"],
            3: ["Gesti\u00f3n de Comuneros"]
        };

        function seleccionarModulos(rolId) {
            var modulos = MODULOS_POR_ROL[rolId] || [];
            document.querySelectorAll('.module-check').forEach(function(cb) {
                cb.checked = modulos.indexOf(cb.value) !== -1;
            });
        }

        document.getElementById('idRol').addEventListener('change', function() {
            seleccionarModulos(parseInt(this.value));
        });

        function abrirNuevo() {
            document.getElementById('modalTitle').textContent = 'Nuevo Usuario';
            document.getElementById('action').value = 'nuevo';
            document.getElementById('usuarioForm').reset();
            document.getElementById('usuarioId').value = '';
            document.getElementById('passwordField').style.display = 'block';
            document.getElementById('contrasena').required = true;
            var rolSelect = document.getElementById('idRol');
            if (rolSelect.value) seleccionarModulos(parseInt(rolSelect.value));
        }

        function abrirEditar(u) {
            document.getElementById('modalTitle').textContent = 'Editar Usuario';
            document.getElementById('action').value = 'editar';
            document.getElementById('usuarioId').value = u.idUsuario;
            document.getElementById('nombres').value = u.nombres || '';
            document.getElementById('apellidos').value = u.apellidos || '';
            document.getElementById('dni').value = u.dni || '';
            document.getElementById('telefono').value = u.telefono || '';
            document.getElementById('nombreUsuario').value = u.nombreUsuario || '';
            document.getElementById('correo').value = u.correo || '';
            document.getElementById('idRol').value = u.idRol;
            document.getElementById('passwordField').style.display = 'none';
            document.getElementById('contrasena').required = false;
            if (u.modulos && u.modulos.length > 0) {
                document.querySelectorAll('.module-check').forEach(function(cb) {
                    cb.checked = u.modulos.indexOf(cb.value) !== -1;
                });
            } else {
                seleccionarModulos(u.idRol);
            }
            var modal = new bootstrap.Modal(document.getElementById('usuarioModal'));
            modal.show();
        }

        function mostrarMensaje(texto) {
            document.getElementById('mensajeModalText').textContent = texto;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal')).show();
        }

        function validarFormulario() {
            var dni = document.getElementById('dni').value;
            var tel = document.getElementById('telefono').value;
            if (dni && !/^\d{8}$/.test(dni)) { mostrarMensaje('El DNI debe tener exactamente 8 d\u00edgitos num\u00e9ricos'); return false; }
            if (tel && !/^\d{9}$/.test(tel)) { mostrarMensaje('El tel\u00e9fono debe tener 9 d\u00edgitos'); return false; }
            if (document.getElementById('action').value === 'nuevo') {
                var pass = document.getElementById('contrasena').value;
                if (!pass || pass.length < 6) { mostrarMensaje('La contrase\u00f1a debe tener al menos 6 caracteres'); return false; }
            }
            return true;
        }

        function confirmarEliminar(id, nombre) {
            document.getElementById('eliminarModalTitle').textContent = '\u00bfEliminar usuario ' + nombre + '?';
            document.getElementById('eliminarModalText').textContent = 'Se eliminar\u00e1 permanentemente el usuario ' + nombre;
            document.getElementById('eliminarModalBtn').href = 'GestionUsuariosServlet?action=eliminarUsuario&id=' + id;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('eliminarModal')).show();
        }

        function confirmarEstado(id, action, nombre) {
            if (action.indexOf('activar') !== -1) {
                document.getElementById('estadoModalTitle').textContent = '\u00bfActivar usuario ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se activar\u00e1 el usuario ' + nombre;
                document.getElementById('estadoModalBtn').className = 'btn btn-success btn-sm';
                document.getElementById('estadoModalBtn').innerHTML = '<i class="bi bi-check-lg me-1"></i>Activar';
            } else {
                document.getElementById('estadoModalTitle').textContent = '\u00bfDesactivar usuario ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se desactivar\u00e1 el usuario ' + nombre;
                document.getElementById('estadoModalBtn').className = 'btn btn-danger btn-sm';
                document.getElementById('estadoModalBtn').innerHTML = '<i class="bi bi-check-lg me-1"></i>Desactivar';
            }
            document.getElementById('estadoModalBtn').href = 'GestionUsuariosServlet?action=' + action + '&id=' + id;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('estadoModal')).show();
        }

        function cambiarPagina(valor) {
            var url = new URL(window.location.href);
            url.searchParams.set('por_pagina', valor);
            url.searchParams.set('page', '1');
            window.location.href = url.toString();
        }
    </script>
</body>
</html>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="dto.PartidoDTO"%>
<%@page import="dto.CandidatoDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    String rol = (String) session.getAttribute("rol");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    List<PartidoDTO> partidos = (List<PartidoDTO>) request.getAttribute("partidos");
    List<CandidatoDTO> candidatos = (List<CandidatoDTO>) request.getAttribute("candidatos");
    Long idEleccion = (Long) request.getAttribute("idEleccion");
    String nombreEleccion = (String) request.getAttribute("nombreEleccion");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    if (partidos == null) partidos = new java.util.ArrayList<>();
    if (candidatos == null) candidatos = new java.util.ArrayList<>();
    if (idEleccion == null) idEleccion = 1L;
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String fechaHoy = sdf.format(new Date());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Partidos y Candidatos - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
    <style>
        .color-swatch { display: inline-block; width: 16px; height: 16px; border-radius: 50%; border: 1px solid #ddd; vertical-align: middle; margin-right: 6px; }
        .partido-badge { font-size: .75rem; padding: .2em .6em; border-radius: 2rem; color: #fff; font-weight: 600; white-space: nowrap; display: inline-block; }
        .candidato-img { width: 50px; height: 50px; border-radius: 50%; object-fit: cover; border: 2px solid #e9ecef; }
        .candidato-img-placeholder { width: 50px; height: 50px; border-radius: 50%; background: #e9ecef; display: inline-flex; align-items: center; justify-content: center; color: #adb5bd; font-size: 1.3rem; }
        .btn-action { width: 32px; height: 32px; padding: 0; display: inline-flex; align-items: center; justify-content: center; border-radius: 8px; }
        .propuestas-cell { max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #6c757d; font-size: .85rem; }
        .subtitle-badge { background: #e8eaf6; color: #1a237e; padding: 6px 18px; border-radius: 20px; font-size: 1rem; font-weight: 600; display: inline-block; }
        .action-buttons { display: flex; gap: 8px; flex-wrap: wrap; }
        .table-candidato tr { transition: background .15s; }
        .table-candidato tr:hover { background: #f8f9ff; }
        .file-input-wrapper { position: relative; }
        .file-input-wrapper input[type=file] { position: absolute; left: 0; top: 0; width: 100%; height: 100%; opacity: 0; cursor: pointer; }
        .file-input-wrapper .btn { pointer-events: none; }
    </style>
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-start mb-3">
            <div>
                <h4 class="fw-bold mb-1" style="color:#1a237e">Partidos y Candidatos</h4><br>
                <div class="subtitle-badge">
                    <i class="bi bi-calendar-check me-1"></i><%= nombreEleccion.isEmpty() ? "Ninguna Eleccion" : nombreEleccion %>
                    <br>
                </div>
            </div>
            <div class="text-end">
                <small class="text-muted d-block">
                    <i class="bi bi-person-circle me-1"></i><%= nombreUsuario %> (<%= rol %>)
                    <span class="ms-2"><i class="bi bi-calendar3 me-1"></i><%= fechaHoy %></span>
                </small>
            </div>
        </div>

        <div class="action-buttons mb-4">
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#partidoModal" onclick="limpiarPartidoForm()">
                <i class="bi bi-plus-lg me-1"></i>Nuevo Partido
            </button>
            <button class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#candidatoModal" onclick="limpiarCandidatoForm()">
                <i class="bi bi-plus-lg me-1"></i>Nuevo Candidato
            </button>
        </div>

        <% if (mensaje != null) { %>
        <div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><%= mensaje %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
        <% } %>
        <% if (error != null) { %>
        <div style="display:none" id="errorData"><%= error %></div>
        <% } %>

        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="bi bi-flag me-2"></i>Lista de Partidos</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Partido</th>
                                <th>Propuestas</th>
                                <th class="text-center">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (partidos.isEmpty()) { %>
                            <tr><td colspan="3" class="text-center py-4 text-muted"><i class="bi bi-flag fs-2 d-block mb-2"></i>No se encontraron partidos.</td></tr>
                            <% } else { for (PartidoDTO p : partidos) { %>
                            <tr>
                                <td>
                                    <span class="color-swatch" style="background:<%= p.getColor() != null ? p.getColor() : "#6c757d" %>"></span>
                                    <span class="fw-semibold"><%= p.getNombrePartido() %></span>
                                </td>
                                <td class="propuestas-cell"><%= p.getPropuestas() != null && !p.getPropuestas().isEmpty() ? p.getPropuestas() : "-" %></td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-primary btn-action me-1" title="Editar partido" onclick="editarPartido(<%= p.getIdPartido() %>, '<%= p.getNombrePartido().replace("'", "\\'") %>', '<%= p.getDescripcion() != null ? p.getDescripcion().replace("'", "\\'") : "" %>', '<%= p.getPropuestas() != null ? p.getPropuestas().replace("'", "\\'") : "" %>', '<%= p.getColor() != null ? p.getColor() : "" %>', <%= p.getIdEleccion() %>)">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <% if (p.isActivo()) { %>
                                    <button class="btn btn-sm btn-outline-danger btn-action" title="Desactivar partido" onclick="confirmarEstado(<%= p.getIdPartido() %>, 'desactivarPartido', '<%= p.getNombrePartido().replace("'", "\\'") %>')"><i class="bi bi-x-lg"></i></button>
                                    <% } else { %>
                                    <button class="btn btn-sm btn-outline-success btn-action" title="Activar partido" onclick="confirmarEstado(<%= p.getIdPartido() %>, 'activarPartido', '<%= p.getNombrePartido().replace("'", "\\'") %>')"><i class="bi bi-check-lg"></i></button>
                                    <% } %>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="bi bi-person-badge me-2"></i>Lista de Candidatos</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0 table-candidato">
                        <thead>
                            <tr>
                                <th style="width:60px">Foto</th>
                                <th>Candidato</th>
                                <th>Cargo</th>
                                <th class="text-center" style="width:100px">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (candidatos.isEmpty()) { %>
                            <tr><td colspan="4" class="text-center py-4 text-muted"><i class="bi bi-person-badge fs-2 d-block mb-2"></i>No se encontraron candidatos para esta elecci&oacute;n.</td></tr>
                            <% } else { for (CandidatoDTO c : candidatos) { %>
                            <tr>
                                <td>
                                    <% if (c.getImagen() != null && !c.getImagen().isEmpty()) { 
                                        String imgSrc = c.getImagen();
                                        if (!imgSrc.startsWith("data:")) {
                                            imgSrc = "data:image/png;base64," + imgSrc;
                                        }
                                    %>
                                    <img src="<%= imgSrc %>" alt="Foto" class="candidato-img">
                                    <% } else { %>
                                    <span class="candidato-img-placeholder"><i class="bi bi-person"></i></span>
                                    <% } %>
                                </td>
                                <td>
                                    <span class="fw-semibold"><%= c.getNombres() %> <%= c.getApellidos() != null ? c.getApellidos() : "" %></span>
                                    <span class="partido-badge ms-2" style="background:<%= c.getColorPartido() != null ? c.getColorPartido() : "#6c757d" %>"><%= c.getNombrePartido() != null ? c.getNombrePartido() : "-" %></span>
                                </td>
                                <td><%= c.getCargo() != null ? c.getCargo() : "-" %></td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-primary btn-action me-1" title="Editar candidato" onclick="editarCandidato(<%= c.getIdCandidato() %>, '<%= c.getNombres().replace("'", "\\'") %>', '<%= c.getApellidos() != null ? c.getApellidos().replace("'", "\\'") : "" %>', <%= c.getIdPartido() %>, '<%= c.getCargo() != null ? c.getCargo().replace("'", "\\'") : "" %>', '<%= c.getIntegrantes() != null ? c.getIntegrantes().replace("'", "\\'") : "" %>')">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <% if (c.isActivo()) { %>
                                    <a href="GestionPartidosCandidatosServlet?action=desactivarCandidato&id=<%= c.getIdCandidato() %>" class="btn btn-sm btn-outline-danger btn-action" title="Desactivar candidato" onclick="return confirm('Desactivar candidato <%= c.getNombres().replace("'", "\\'") %>?')"><i class="bi bi-x-lg"></i></a>
                                    <% } else { %>
                                    <a href="GestionPartidosCandidatosServlet?action=activarCandidato&id=<%= c.getIdCandidato() %>" class="btn btn-sm btn-outline-success btn-action" title="Activar candidato" onclick="return confirm('Activar candidato <%= c.getNombres().replace("'", "\\'") %>?')"><i class="bi bi-check-lg"></i></a>
                                    <% } %>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
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

    <div class="modal fade" id="partidoModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header" style="background:linear-gradient(135deg,#1a237e,#3949ab);color:#fff">
                    <h5 class="modal-title" id="partidoModalLabel"><i class="bi bi-flag-plus me-2"></i>Nuevo Partido</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form action="GestionPartidosCandidatosServlet" method="post">
                    <input type="hidden" name="action" id="partidoAction" value="nuevoPartido">
                    <input type="hidden" name="id" id="partidoId" value="">
                    <input type="hidden" name="idEleccion" id="partidoIdEleccion" value="<%= idEleccion %>">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Nombre del partido <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="partidoNombre" name="nombrePartido" placeholder="Ej. Lista Azul" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Color del partido</label>
                            <input type="color" class="form-control form-control-color" id="partidoColor" name="color" value="#3949ab" style="width:60px;height:38px;padding:3px">
                            <small class="text-muted">Este color identificar&aacute; al partido en gr&aacute;ficos y reportes.</small>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Descripci&oacute;n</label>
                            <textarea class="form-control" id="partidoDesc" name="descripcion" rows="2" placeholder="Ideolog&iacute;a, historia, etc."></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Propuestas</label>
                            <textarea class="form-control" id="partidoProp" name="propuestas" rows="2" placeholder="Plan de gobierno o promesas electorales"></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary" id="partidoBtnSubmit"><i class="bi bi-check-circle me-1"></i>Guardar</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="candidatoModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header" style="background:linear-gradient(135deg,#1a237e,#3949ab);color:#fff">
                    <h5 class="modal-title" id="candidatoModalLabel"><i class="bi bi-person-plus me-2"></i>Nuevo Candidato</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <form action="GestionPartidosCandidatosServlet" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="action" id="candidatoAction" value="nuevoCandidato">
                    <input type="hidden" name="id" id="candidatoId" value="">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Partido <span class="text-danger">*</span></label>
                            <select class="form-select" id="candidatoIdPartido" name="idPartido" required>
                                <option value="">Seleccionar partido...</option>
                                <% for (PartidoDTO p : partidos) { %>
                                <option value="<%= p.getIdPartido() %>"><%= p.getNombrePartido() %></option>
                                <% } %>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Cargo <span class="text-danger">*</span></label>
                            <select class="form-select" id="candidatoCargo" name="cargo" required>
                                <option value="">Seleccionar cargo...</option>
                                <option value="Presidente">Presidente</option>
                               
                            </select>
                        </div>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Nombres <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="candidatoNombres" name="nombres" placeholder="Nombres" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Apellidos</label>
                                <input type="text" class="form-control" id="candidatoApellidos" name="apellidos" placeholder="Apellidos">
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Integrantes</label>
                            <textarea class="form-control" id="candidatoIntegrantes" name="integrantes" rows="2" placeholder="Planilla completa (ej. candidato a alcalde + regidores)"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Imagen (foto del candidato o logo del partido)</label>
                            <input type="file" class="form-control" id="candidatoImagen" name="imagen" accept="image/png,image/jpeg" onchange="previewImagen(this)">
                            <small class="text-muted">Formatos permitidos: PNG, JPG. Tama&ntilde;o m&aacute;ximo: 5 MB.</small>
                            <div id="imagenPreviewContainer" class="mt-2 text-center" style="display:none">
                                <img id="imagenPreview" src="" alt="Vista previa" style="max-width:500px;max-height:500px;border-radius:8px;border:2px solid #e0e0e0;padding:4px">
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary" id="candidatoBtnSubmit"><i class="bi bi-check-circle me-1"></i>Guardar</button>
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
                    <h6 class="fw-bold" id="estadoModalTitle">&iquest;Desactivar partido?</h6>
                    <p class="small text-muted mb-0" id="estadoModalText">Se desactivar&aacute; el partido seleccionado</p>
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
            if (action === 'desactivarPartido') {
                document.getElementById('estadoModalTitle').textContent = '\u00bfDesactivar partido ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se desactivar\u00e1 el partido ' + nombre;
                document.getElementById('estadoEnlace').className = 'btn btn-danger btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionPartidosCandidatosServlet?action=desactivarPartido&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Desactivar';
            } else {
                document.getElementById('estadoModalTitle').textContent = '\u00bfActivar partido ' + nombre + '?';
                document.getElementById('estadoModalText').textContent = 'Se activar\u00e1 el partido ' + nombre;
                document.getElementById('estadoEnlace').className = 'btn btn-success btn-sm';
                document.getElementById('estadoEnlace').href = 'GestionPartidosCandidatosServlet?action=activarPartido&id=' + id;
                document.getElementById('estadoBtnText').textContent = 'Activar';
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('estadoModal')).show();
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function limpiarPartidoForm() {
            document.getElementById('partidoModalLabel').innerHTML = '<i class="bi bi-flag-plus me-2"></i>Nuevo Partido';
            document.getElementById('partidoAction').value = 'nuevoPartido';
            document.getElementById('partidoId').value = '';
            document.getElementById('partidoNombre').value = '';
            document.getElementById('partidoDesc').value = '';
            document.getElementById('partidoProp').value = '';
            document.getElementById('partidoColor').value = '#3949ab';
            document.getElementById('partidoBtnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
        }

        function editarPartido(id, nombre, desc, prop, color) {
            document.getElementById('partidoModalLabel').innerHTML = '<i class="bi bi-pencil me-2"></i>Editar Partido';
            document.getElementById('partidoAction').value = 'editarPartido';
            document.getElementById('partidoId').value = id;
            document.getElementById('partidoNombre').value = nombre;
            document.getElementById('partidoDesc').value = desc;
            document.getElementById('partidoProp').value = prop;
            if (color) document.getElementById('partidoColor').value = color;
            document.getElementById('partidoBtnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('partidoModal')).show();
        }

        function limpiarCandidatoForm() {
            document.getElementById('candidatoModalLabel').innerHTML = '<i class="bi bi-person-plus me-2"></i>Nuevo Candidato';
            document.getElementById('candidatoAction').value = 'nuevoCandidato';
            document.getElementById('candidatoId').value = '';
            document.getElementById('candidatoIdPartido').value = '';
            document.getElementById('candidatoCargo').value = '';
            document.getElementById('candidatoNombres').value = '';
            document.getElementById('candidatoApellidos').value = '';
            document.getElementById('candidatoIntegrantes').value = '';
            document.getElementById('candidatoImagen').value = '';
            document.getElementById('candidatoBtnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
        }

        function editarCandidato(id, nombres, apellidos, idPartido, cargo, integrantes) {
            document.getElementById('candidatoModalLabel').innerHTML = '<i class="bi bi-pencil me-2"></i>Editar Candidato';
            document.getElementById('candidatoAction').value = 'editarCandidato';
            document.getElementById('candidatoId').value = id;
            document.getElementById('candidatoNombres').value = nombres;
            document.getElementById('candidatoApellidos').value = apellidos;
            document.getElementById('candidatoIdPartido').value = idPartido;
            document.getElementById('candidatoCargo').value = cargo;
            document.getElementById('candidatoIntegrantes').value = integrantes;
            document.getElementById('candidatoImagen').value = '';
            ocultarPreview();
            document.getElementById('candidatoBtnSubmit').innerHTML = '<i class="bi bi-check-circle me-1"></i>Guardar';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('candidatoModal')).show();
        }

        function previewImagen(input) {
            var container = document.getElementById('imagenPreviewContainer');
            var img = document.getElementById('imagenPreview');
            if (input.files && input.files[0]) {
                var reader = new FileReader();
                reader.onload = function(e) {
                    img.src = e.target.result;
                    container.style.display = 'block';
                };
                reader.readAsDataURL(input.files[0]);
            } else {
                ocultarPreview();
            }
        }

        function ocultarPreview() {
            document.getElementById('imagenPreviewContainer').style.display = 'none';
            document.getElementById('imagenPreview').src = '';
        }

        window.onload = function () {
            var el = document.getElementById('errorData');
            if (el) {
                document.getElementById('mensajeModalText').textContent = el.textContent;
                bootstrap.Modal.getOrCreateInstance(document.getElementById('mensajeModal')).show();
            }
        };
    </script>
</body>
</html>

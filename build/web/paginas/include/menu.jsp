<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%!
    boolean tieneModulo(Set<String> modulos, String m) { return modulos.contains(m); }
%>
<%
    String usuarioNombre = (String) session.getAttribute("nombreUsuario");
    String usuarioRol = (String) session.getAttribute("rol");
    String currentPage = request.getRequestURI();
    Integer idRol = (Integer) session.getAttribute("idRol");
    List<String> modulosUsuario = (List<String>) session.getAttribute("modulosUsuario");
    if (idRol == null) idRol = 1;
    if (modulosUsuario == null) modulosUsuario = new ArrayList<>();

    Set<String> modulosPermitidos = new HashSet<>();
    if (!modulosUsuario.isEmpty()) {
        modulosPermitidos.addAll(modulosUsuario);
    } else {
        switch (idRol) {
            case 3:
                modulosPermitidos.add("Gesti\u00f3n de Comuneros");
                break;
            case 2:
                modulosPermitidos.addAll(Arrays.asList("Dashboard", "Gesti\u00f3n de Usuarios",
                    "Gesti\u00f3n de Comuneros", "Gesti\u00f3n de Elecciones", "Partidos y Candidatos",
                    "Gesti\u00f3n de Caser\u00edos", "Locales de Votaci\u00f3n",
                    "Mesas de Sufragio", "Miembros de Mesa", "Resultados"));
                break;
            default:
                modulosPermitidos.addAll(Arrays.asList("Dashboard", "Gesti\u00f3n de Usuarios",
                    "Gesti\u00f3n de Comuneros", "Gesti\u00f3n de Elecciones", "Partidos y Candidatos",
                    "Gesti\u00f3n de Caser\u00edos", "Locales de Votaci\u00f3n",
                    "Mesas de Sufragio", "Miembros de Mesa", "Resultados", "Auditor\u00eda"));
                break;
        }
    }
%>
<!-- Sidebar -->
<div class="sidebar d-none d-md-flex">
    <div class="p-3 text-white text-center border-bottom border-white border-opacity-10">
        <h5 class="mb-0 fw-bold"><i class="bi bi-shield-check me-2"></i>SVE CCSPM</h5>
        <small style="color:rgba(255,255,255,.6)"><%= usuarioNombre != null ? usuarioNombre : "" %></small>
    </div>
    <div class="menu-scroll">
        <div class="sidebar-heading">Principal</div>
        <a href="DashboardServlet" class="nav-link <%= currentPage.contains("Dashboard") ? "active" : "" %>"><i class="bi bi-speedometer2"></i>Dashboard</a>

        <div class="sidebar-heading">Gesti&oacute;n</div>
        <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Usuarios")) { %><a href="GestionUsuariosServlet" class="nav-link"><i class="bi bi-people"></i>Gesti&oacute;n de Usuarios</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Comuneros")) { %><a href="GestionComunerosServlet" class="nav-link"><i class="bi bi-person-check"></i>Gesti&oacute;n de Comuneros</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Elecciones")) { %><a href="GestionEleccionesServlet" class="nav-link"><i class="bi bi-calendar-event"></i>Gesti&oacute;n de Elecciones</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Partidos y Candidatos")) { %><a href="GestionPartidosCandidatosServlet" class="nav-link"><i class="bi bi-flag"></i>Partidos y Candidatos</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Caser\u00edos")) { %><a href="GestionCaseriosServlet" class="nav-link"><i class="bi bi-geo-alt"></i>Gesti&oacute;n de Caser&iacute;os</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Locales de Votaci\u00f3n")) { %><a href="GestionLocalesServlet" class="nav-link"><i class="bi bi-building"></i>Locales de Votaci&oacute;n</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Mesas de Sufragio")) { %><a href="GestionMesasServlet" class="nav-link"><i class="bi bi-grid-3x3"></i>Mesas de Sufragio</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Miembros de Mesa")) { %><a href="GestionMiembrosMesaServlet" class="nav-link"><i class="bi bi-person-badge"></i>Miembros de Mesa</a><% } %>

        <div class="sidebar-heading">Reportes</div>
        <% if (tieneModulo(modulosPermitidos, "Resultados")) { %><a href="GestionResultadosServlet" class="nav-link"><i class="bi bi-bar-chart"></i>Resultados</a><% } %>
        <% if (tieneModulo(modulosPermitidos, "Auditor\u00eda")) { %><a href="AuditoriaServlet" class="nav-link"><i class="bi bi-shield-check"></i>Auditor&iacute;a</a><% } %>

        <div class="sidebar-heading">Cuenta</div>
        <a href="CerrarSesionServlet" class="nav-link text-danger"><i class="bi bi-box-arrow-right"></i>Cerrar Sesi&oacute;n</a>
    </div>
</div>

<!-- Top navbar for mobile -->
<nav class="navbar navbar-side d-md-none">
    <div class="container-fluid">
        <span class="navbar-brand text-white fw-bold"><i class="bi bi-shield-check me-2"></i>SVE CCSPM</span>
        <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#menuColapsable">
            <i class="bi bi-list text-white fs-3"></i>
        </button>
    </div>
    <div class="collapse" id="menuColapsable">
        <div class="p-2">
            <div class="sidebar-heading">Principal</div>
            <a href="DashboardServlet" class="nav-link"><i class="bi bi-speedometer2"></i>Dashboard</a>

            <div class="sidebar-heading">Gesti&oacute;n</div>
            <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Usuarios")) { %><a href="GestionUsuariosServlet" class="nav-link"><i class="bi bi-people"></i>Gesti&oacute;n de Usuarios</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Comuneros")) { %><a href="GestionComunerosServlet" class="nav-link"><i class="bi bi-person-check"></i>Gesti&oacute;n de Comuneros</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Elecciones")) { %><a href="GestionEleccionesServlet" class="nav-link"><i class="bi bi-calendar-event"></i>Gesti&oacute;n de Elecciones</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Partidos y Candidatos")) { %><a href="GestionPartidosCandidatosServlet" class="nav-link"><i class="bi bi-flag"></i>Partidos y Candidatos</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Gesti\u00f3n de Caser\u00edos")) { %><a href="GestionCaseriosServlet" class="nav-link"><i class="bi bi-geo-alt"></i>Gesti&oacute;n de Caser&iacute;os</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Locales de Votaci\u00f3n")) { %><a href="GestionLocalesServlet" class="nav-link"><i class="bi bi-building"></i>Locales de Votaci&oacute;n</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Mesas de Sufragio")) { %><a href="GestionMesasServlet" class="nav-link"><i class="bi bi-grid-3x3"></i>Mesas de Sufragio</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Miembros de Mesa")) { %><a href="GestionMiembrosMesaServlet" class="nav-link"><i class="bi bi-person-badge"></i>Miembros de Mesa</a><% } %>

            <div class="sidebar-heading">Reportes</div>
            <% if (tieneModulo(modulosPermitidos, "Resultados")) { %><a href="GestionResultadosServlet" class="nav-link"><i class="bi bi-bar-chart"></i>Resultados</a><% } %>
            <% if (tieneModulo(modulosPermitidos, "Auditor\u00eda")) { %><a href="AuditoriaServlet" class="nav-link"><i class="bi bi-shield-check"></i>Auditor&iacute;a</a><% } %>

            <hr class="border-white border-opacity-10">
            <a href="CerrarSesionServlet" class="nav-link text-danger"><i class="bi bi-box-arrow-right"></i>Cerrar Sesi&oacute;n</a>
        </div>
    </div>
</nav>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String nombreUsuario = (String) session.getAttribute("nombreUsuario");
    if (nombreUsuario == null) { response.sendRedirect("IniciarSesionServlet"); return; }
    String titulo = (String) request.getAttribute("titulo");
    if (titulo == null) titulo = "M\u00f3dulo";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= titulo %> - SVE CCSPM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/admin.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="include/menu.jsp" />
    <div class="main-content">
        <div class="d-flex align-items-center mb-4">
            <h4 class="fw-bold mb-0" style="color:#1a237e"><%= titulo %></h4>
        </div>
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="bi bi-tools" style="font-size:3rem;color:#c0c0c0;"></i>
                <p class="text-muted mt-3 mb-0">M&oacute;dulo en construcci&oacute;n</p>
            </div>
        </div>
        <footer>
            <i class="bi bi-shield-fill-check text-success me-1"></i>
            SVE CCSPM &middot; Comunidad Campesina San Pedro de Mórrope &middot; Todos los derechos reservados
        </footer>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="frontend/js/admin.js"></script>
</body>
</html>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SVE CCSPM - Inicio de Sesión</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="frontend/css/login.css" rel="stylesheet">
    <link href="frontend/css/public.css" rel="stylesheet">
    <style>
        body { background: #0f172a url('<%= request.getContextPath() %>/imagenes/ccspm.png') center 30% / cover no-repeat fixed !important; }
        body::before { content: ''; position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 0; pointer-events: none; }
        .login-card { position: relative; z-index: 1; }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="login-header">
            <h1><i class="bi bi-shield-check me-2"></i>SVE CCSPM</h1>
            <p>Ingrese sus credenciales para acceder al sistema</p>
        </div>
        <div class="login-body">
            <% if (error != null && !error.isEmpty()) { %>
            <div class="alert alert-danger d-flex align-items-center" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i>
                <div><%= error %></div>
            </div>
            <% } %>
            <form action="IniciarSesionServlet" method="POST">
                <div class="mb-3">
                    <label for="usuario" class="form-label fw-semibold">
                        <i class="bi bi-person me-1"></i>Usuario
                    </label>
                    <input type="text" class="form-control" id="usuario" name="usuario"
                           placeholder="Ingrese su usuario" required autofocus>
                </div>
                <div class="mb-4">
                    <label for="contrasena" class="form-label fw-semibold">
                        <i class="bi bi-lock me-1"></i>Contraseña
                    </label>
                    <input type="password" class="form-control" id="contrasena" name="contrasena"
                           placeholder="Ingrese su contraseña" required>
                </div>
                <button type="submit" class="btn-ingresar">
                    <i class="bi bi-box-arrow-in-right me-2"></i>Ingresar
                </button>
            </form>
            <footer class="mt-4">
                <i class="bi bi-shield-fill-check text-success me-1"></i>
                Proceso electoral transparente y seguro
            </footer>
        </div>
    </div>
</body>
</html>

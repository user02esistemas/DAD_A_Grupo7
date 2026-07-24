package servlet;

import com.google.gson.Gson;
import dto.RespuestaApiDTO;
import dto.RolDTO;
import dto.UsuarioDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.*;
import servicio.UsuarioServicio;

@WebServlet("/GestionUsuariosServlet")
public class GestionUsuariosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final UsuarioServicio usuarioService = new UsuarioServicio();
    private final Gson gson = new Gson();
    private static final List<String> MODULOS = Arrays.asList(
        "Dashboard", "Gesti\u00f3n de Usuarios", "Gesti\u00f3n de Comuneros",
        "Gesti\u00f3n de Elecciones", "Partidos y Candidatos",
        "Gesti\u00f3n de Caser\u00edos", "Locales de Votaci\u00f3n",
        "Mesas de Sufragio", "Miembros de Mesa",
        "Resultados", "Auditor\u00eda"
    );

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");
        if (token == null || token.isEmpty()) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        String action = req.getParameter("action");
        try {
            if ("activarUsuario".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = usuarioService.cambiarEstado(id, true, token);
                String msg = (respApi != null && respApi.isExito()) ? "Usuario activado" : "Error al activar usuario";
                resp.sendRedirect("GestionUsuariosServlet?mensaje=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            } else if ("desactivarUsuario".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = usuarioService.cambiarEstado(id, false, token);
                String msg = (respApi != null && respApi.isExito()) ? "Usuario desactivado" : "Error al desactivar usuario";
                resp.sendRedirect("GestionUsuariosServlet?mensaje=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            } else if ("eliminarUsuario".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = usuarioService.eliminarUsuario(id, token);
                String msg = (respApi != null && respApi.isExito()) ? "Usuario eliminado" : "Error al eliminar usuario";
                String tipo = (respApi != null && respApi.isExito()) ? "mensaje" : "error";
                resp.sendRedirect("GestionUsuariosServlet?" + tipo + "=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            }

            int pagina = 1;
            String pageStr = req.getParameter("page");
            if (pageStr != null && !pageStr.isEmpty()) {
                try { pagina = Integer.parseInt(pageStr); } catch (NumberFormatException e) { }
            }
            int porPagina = 20;
            String ppStr = req.getParameter("por_pagina");
            if (ppStr != null && !ppStr.isEmpty()) {
                try { porPagina = Integer.parseInt(ppStr); } catch (NumberFormatException e) { }
            }

            String busqueda = req.getParameter("search");
            if (busqueda != null && busqueda.trim().isEmpty()) busqueda = null;

            List<UsuarioDTO> usuarios = usuarioService.listarUsuarios(token, pagina, porPagina, busqueda);
            RespuestaApiDTO pagResp = usuarioService.obtenerPaginacion(token, pagina, porPagina, busqueda);

            List<RolDTO> roles = usuarioService.listarRoles(token);

            req.setAttribute("usuarios", usuarios);
            req.setAttribute("roles", roles);
            req.setAttribute("modulos", MODULOS);
            req.setAttribute("currentPage", pagResp != null ? pagResp.getPagina() : pagina);
            req.setAttribute("totalPages", pagResp != null ? pagResp.getTotalPaginas() : 1);
            req.setAttribute("porPagina", pagResp != null ? pagResp.getPorPagina() : porPagina);
            req.setAttribute("totalRegistros", pagResp != null ? pagResp.getTotal() : 0);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);

            String usuarioJson = req.getParameter("usuarioJson");
            if (usuarioJson != null) {
                req.setAttribute("usuarioEditar", gson.fromJson(java.net.URLDecoder.decode(usuarioJson, "UTF-8"), UsuarioDTO.class));
            }
        } catch (Exception e) {
            System.out.println("Error en GestionUsuariosServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar usuarios");
        }
        req.getRequestDispatcher("paginas/gestion_usuarios.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");
        if (token == null || token.isEmpty()) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        String action = req.getParameter("action");
        try {
            if ("nuevo".equals(action)) {
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                datos.put("dni", req.getParameter("dni"));
                datos.put("telefono", req.getParameter("telefono"));
                datos.put("correo", req.getParameter("correo"));
                datos.put("nombreUsuario", req.getParameter("nombreUsuario"));
                datos.put("contrasena", req.getParameter("contrasena"));
                datos.put("idRol", Integer.parseInt(req.getParameter("idRol")));
                datos.put("modulos", obtenerModulosSeleccionados(req));
                RespuestaApiDTO respApi = usuarioService.crearUsuario(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionUsuariosServlet?mensaje="
                            + java.net.URLEncoder.encode("Usuario creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear usuario";
                    resp.sendRedirect("GestionUsuariosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                datos.put("dni", req.getParameter("dni"));
                datos.put("telefono", req.getParameter("telefono"));
                datos.put("correo", req.getParameter("correo"));
                datos.put("idRol", Integer.parseInt(req.getParameter("idRol")));
                datos.put("modulos", obtenerModulosSeleccionados(req));
                RespuestaApiDTO respApi = usuarioService.actualizarUsuario(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionUsuariosServlet?mensaje="
                            + java.net.URLEncoder.encode("Usuario actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar usuario";
                    resp.sendRedirect("GestionUsuariosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("cambiarPassword".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("contrasenaActual", req.getParameter("contrasenaActual"));
                datos.put("nuevaContrasena", req.getParameter("nuevaContrasena"));
                RespuestaApiDTO respApi = usuarioService.cambiarContrasena(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionUsuariosServlet?mensaje="
                            + java.net.URLEncoder.encode("Contrase\u00f1a cambiada exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al cambiar contrase\u00f1a";
                    resp.sendRedirect("GestionUsuariosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionUsuariosServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionUsuariosServlet?error="
                    + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionUsuariosServlet");
    }

    private List<String> obtenerModulosSeleccionados(HttpServletRequest req) {
        String[] modulos = req.getParameterValues("modulos");
        if (modulos == null) return new ArrayList<>();
        return Arrays.asList(modulos);
    }
}

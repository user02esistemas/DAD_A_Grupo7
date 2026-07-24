package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.lang.reflect.Type;
import java.util.Map;
import servicio.AutenticacionServicio;

@WebServlet("/IniciarSesionServlet")
public class IniciarSesionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final AutenticacionServicio authService = new AutenticacionServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("paginas/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String usuario = req.getParameter("usuario");
        String contrasena = req.getParameter("contrasena");
        try {
            System.out.println("[LOGIN] Attempting login for user: " + usuario);
            RespuestaApiDTO response = authService.iniciarSesion(usuario, contrasena);
            System.out.println("[LOGIN] API response: exito=" + (response != null ? response.isExito() : "null")
                    + ", mensaje=" + (response != null ? response.getMensaje() : "null"));
            if (response != null && response.isExito() && response.getDatos() != null) {
                String datosJson = gson.toJson(response.getDatos());
                Type mapType = new TypeToken<Map<String, Object>>() {}.getType();
                Map<String, Object> datosMap = gson.fromJson(datosJson, mapType);
                String token = (String) datosMap.get("token");
                Object usuarioObj = datosMap.get("usuario");
                String nombre = "";
                String rol = "";
                java.util.List<String> modulos = new java.util.ArrayList<>();
                Number idRol = 1;
                if (usuarioObj instanceof Map) {
                    Map<String, Object> usuarioMap = (Map<String, Object>) usuarioObj;
                    String nombres = (String) usuarioMap.get("nombres");
                    String apellidos = (String) usuarioMap.get("apellidos");
                    nombre = (nombres != null ? nombres : "") + (apellidos != null ? " " + apellidos : "");
                    nombre = nombre.trim();
                    if (nombre.isEmpty()) nombre = (String) usuarioMap.get("nombreUsuario");
                    rol = (String) usuarioMap.get("nombreRol");
                    if (usuarioMap.get("idRol") instanceof Number) {
                        idRol = (Number) usuarioMap.get("idRol");
                    }
                    Object mods = usuarioMap.get("modulos");
                    if (mods instanceof java.util.List) {
                        for (Object m : (java.util.List<?>) mods) {
                            if (m instanceof String) modulos.add((String) m);
                        }
                    }
                }
                if (rol == null || rol.isEmpty()) rol = "Administrador";
                HttpSession session = req.getSession();
                session.setAttribute("token", token);
                session.setAttribute("usuarioNombre", nombre);
                session.setAttribute("usuarioRol", rol);
                session.setAttribute("nombreUsuario", nombre);
                session.setAttribute("rol", rol);
                session.setAttribute("idRol", idRol.intValue());
                session.setAttribute("modulosUsuario", modulos);
                System.out.println("[LOGIN] Success: user=" + nombre + ", role=" + rol + ", session=" + session.getId());
                resp.sendRedirect("DashboardServlet");
            } else {
                String msg = (response != null && response.getMensaje() != null)
                        ? response.getMensaje() : "Credenciales inv\u00e1lidas";
                req.setAttribute("error", msg);
                req.getRequestDispatcher("paginas/login.jsp").forward(req, resp);
            }
        } catch (IOException e) {
            String errorMsg = "Error de conexi\u00f3n: " + e.getClass().getSimpleName();
            if (e.getMessage() != null) errorMsg += " - " + e.getMessage();
            System.out.println("[LOGIN] IOException: " + errorMsg);
            e.printStackTrace();
            req.setAttribute("error", errorMsg);
            req.getRequestDispatcher("paginas/login.jsp").forward(req, resp);
        } catch (Exception e) {
            String errorMsg = "Error interno: " + e.getClass().getSimpleName();
            if (e.getMessage() != null) errorMsg += " - " + e.getMessage();
            System.out.println("[LOGIN] Exception: " + errorMsg);
            e.printStackTrace();
            req.setAttribute("error", errorMsg);
            req.getRequestDispatcher("paginas/login.jsp").forward(req, resp);
        }
    }
}

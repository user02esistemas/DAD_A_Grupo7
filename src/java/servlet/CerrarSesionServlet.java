package servlet;

import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import servicio.AutenticacionServicio;

@WebServlet("/CerrarSesionServlet")
public class CerrarSesionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final AutenticacionServicio authService = new AutenticacionServicio();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null) {
            String token = (String) session.getAttribute("token");
            if (token != null && !token.isEmpty()) {
                try {
                    RespuestaApiDTO respApi = authService.cerrarSesion(token);
                    System.out.println("Cierre de sesion: " + (respApi != null ? respApi.getMensaje() : "sin respuesta"));
                } catch (Exception e) {
                    System.out.println("Error al cerrar sesion en API: " + e.getMessage());
                }
            }
            session.invalidate();
        }
        resp.sendRedirect("IniciarSesionServlet");
    }
}

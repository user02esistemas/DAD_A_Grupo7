package servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet({
    "/PartidosServlet", "/LocalesVotacionServlet",
    "/MesasSufragioServlet", "/MiembrosMesaServlet"
})
public class ModuloServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Map<String, String> TITULOS = new HashMap<>();
    static {
        TITULOS.put("/PartidosServlet", "Partidos y Candidatos");
        TITULOS.put("/LocalesVotacionServlet", "Locales de Votaci\u00f3n");
        TITULOS.put("/MesasSufragioServlet", "Mesas de Sufragio");
        TITULOS.put("/MiembrosMesaServlet", "Miembros de Mesa");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("token") == null) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        String path = req.getServletPath();
        String titulo = TITULOS.getOrDefault(path, "M\u00f3dulo");
        req.setAttribute("titulo", titulo);
        req.getRequestDispatcher("paginas/modulo.jsp").forward(req, resp);
    }
}

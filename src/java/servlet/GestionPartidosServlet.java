package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.PartidoDTO;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.lang.reflect.Type;
import java.util.*;
import servicio.ApiCliente;
import servicio.PartidoServicio;

@WebServlet("/GestionPartidosServlet")
public class GestionPartidosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final PartidoServicio partidoService = new PartidoServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");
        if (token == null || token.isEmpty()) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        try {
            RespuestaApiDTO respApi = partidoService.listar(token);
            List<PartidoDTO> partidos = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<PartidoDTO>>() {}.getType();
                partidos = gson.fromJson(json, listType);
            }
            req.setAttribute("partidos", partidos);
            if (req.getParameter("mensaje") != null) {
                req.setAttribute("mensaje", req.getParameter("mensaje"));
            }
            if (req.getParameter("error") != null) {
                req.setAttribute("error", req.getParameter("error"));
            }
        } catch (Exception e) {
            System.out.println("Error en GestionPartidosServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar partidos");
        }
        req.getRequestDispatcher("paginas/gestion_partidos.jsp").forward(req, resp);
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
                datos.put("nombrePartido", req.getParameter("nombrePartido"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("propuestas", req.getParameter("propuestas"));
                datos.put("color", req.getParameter("color"));
                datos.put("idEleccion", Long.parseLong(req.getParameter("idEleccion")));
                RespuestaApiDTO respApi = partidoService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosServlet?mensaje="
                            + java.net.URLEncoder.encode("Partido creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear partido";
                    resp.sendRedirect("GestionPartidosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombrePartido", req.getParameter("nombrePartido"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("propuestas", req.getParameter("propuestas"));
                datos.put("color", req.getParameter("color"));
                datos.put("idEleccion", Long.parseLong(req.getParameter("idEleccion")));
                RespuestaApiDTO respApi = partidoService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosServlet?mensaje="
                            + java.net.URLEncoder.encode("Partido actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar partido";
                    resp.sendRedirect("GestionPartidosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("activar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = partidoService.cambiarEstado(id, true, token);
                String msg = (respApi != null && respApi.isExito()) ? "Partido activado" : "Error al activar partido";
                resp.sendRedirect("GestionPartidosServlet?mensaje="
                        + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            } else if ("desactivar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = partidoService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosServlet?mensaje=" + java.net.URLEncoder.encode("Partido desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar partido";
                    if (msg.contains("votaci\u00f3n")) msg = "Error al desactivar por motivos de votaci\u00f3n";
                    resp.sendRedirect("GestionPartidosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionPartidosServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionPartidosServlet?error="
                    + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionPartidosServlet");
    }
}

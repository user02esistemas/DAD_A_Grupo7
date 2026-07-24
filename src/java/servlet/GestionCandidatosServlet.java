package servlet;

import com.google.gson.Gson;
import dto.CandidatoDTO;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.*;
import servicio.ApiCliente;
import servicio.CandidatoServicio;

@WebServlet("/GestionCandidatosServlet")
public class GestionCandidatosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final CandidatoServicio candidatoService = new CandidatoServicio();
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
            long idEleccion = 0;
            String elStr = req.getParameter("idEleccion");
            if (elStr != null && !elStr.isEmpty()) {
                try { idEleccion = Long.parseLong(elStr); } catch (NumberFormatException e) { }
            }
            if (idEleccion == 0) {
                idEleccion = 1;
            }
            List<CandidatoDTO> candidatos = candidatoService.listarPorEleccion(idEleccion, token);
            req.setAttribute("candidatos", candidatos);
            req.setAttribute("idEleccion", idEleccion);
            if (req.getParameter("mensaje") != null) {
                req.setAttribute("mensaje", req.getParameter("mensaje"));
            }
            if (req.getParameter("error") != null) {
                req.setAttribute("error", req.getParameter("error"));
            }
        } catch (Exception e) {
            System.out.println("Error en GestionCandidatosServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar candidatos");
        }
        req.getRequestDispatcher("paginas/gestion_candidatos.jsp").forward(req, resp);
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
                datos.put("cargo", req.getParameter("cargo"));
                datos.put("integrantes", req.getParameter("integrantes"));
                datos.put("idPartido", Long.parseLong(req.getParameter("idPartido")));
                RespuestaApiDTO respApi = candidatoService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionCandidatosServlet?mensaje="
                            + java.net.URLEncoder.encode("Candidato creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear candidato";
                    resp.sendRedirect("GestionCandidatosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                datos.put("cargo", req.getParameter("cargo"));
                datos.put("integrantes", req.getParameter("integrantes"));
                datos.put("idPartido", Long.parseLong(req.getParameter("idPartido")));
                RespuestaApiDTO respApi = candidatoService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionCandidatosServlet?mensaje="
                            + java.net.URLEncoder.encode("Candidato actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar candidato";
                    resp.sendRedirect("GestionCandidatosServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("activar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = candidatoService.cambiarEstado(id, true, token);
                String msg = (respApi != null && respApi.isExito()) ? "Candidato activado" : "Error al activar candidato";
                resp.sendRedirect("GestionCandidatosServlet?mensaje="
                        + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            } else if ("desactivar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = candidatoService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Candidato desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar candidato";
                    if (msg.contains("votaci\u00f3n")) msg = "Error al desactivar por motivos de votaci\u00f3n";
                    resp.sendRedirect("GestionCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionCandidatosServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionCandidatosServlet?error="
                    + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionCandidatosServlet");
    }
}

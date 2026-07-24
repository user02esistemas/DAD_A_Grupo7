package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.util.*;
import servicio.*;

@MultipartConfig(maxFileSize = 5242880, maxRequestSize = 10485760)
@WebServlet("/GestionPartidosCandidatosServlet")
public class GestionPartidosCandidatosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final PartidoServicio partidoService = new PartidoServicio();
    private final CandidatoServicio candidatoService = new CandidatoServicio();
    private final EleccionServicio eleccionService = new EleccionServicio();
    private final Gson gson = new Gson();

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
            if ("activarPartido".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = partidoService.cambiarEstado(id, true, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Partido activado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar partido";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("desactivarPartido".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = partidoService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Partido desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar partido";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("activarCandidato".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = candidatoService.cambiarEstado(id, true, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Candidato activado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar candidato";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("desactivarCandidato".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                RespuestaApiDTO respApi = candidatoService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Candidato desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar candidato";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }

            long idEleccion = 0;
            String nombreEleccion = "";
            try {
                EleccionDTO act = eleccionService.obtenerEleccionActiva();
                if (act != null) {
                    idEleccion = act.getIdEleccion();
                    nombreEleccion = act.getNombreEleccion();
                } else {
                    req.setAttribute("partidos", new ArrayList<>());
                    req.setAttribute("candidatos", new ArrayList<>());
                    req.setAttribute("idEleccion", 0L);
                    req.setAttribute("nombreEleccion", "");
                    req.setAttribute("error", "No hay una elecci\u00f3n activa");
                    req.getRequestDispatcher("paginas/gestion_partidos_candidatos.jsp").forward(req, resp);
                    return;
                }
            } catch (Exception e) {
                System.out.println("No active election: " + e.getMessage());
                req.setAttribute("partidos", new ArrayList<>());
                req.setAttribute("candidatos", new ArrayList<>());
                req.setAttribute("idEleccion", 0L);
                req.setAttribute("nombreEleccion", "");
                req.setAttribute("error", "No hay una elecci\u00f3n activa");
                req.getRequestDispatcher("paginas/gestion_partidos_candidatos.jsp").forward(req, resp);
                return;
            }

            List<PartidoDTO> partidos = partidoService.listarPorEleccion(idEleccion, token);
            req.setAttribute("partidos", partidos);

            List<CandidatoDTO> candidatos = candidatoService.listarPorEleccion(idEleccion, token);
            req.setAttribute("candidatos", candidatos);
            req.setAttribute("idEleccion", idEleccion);
            req.setAttribute("nombreEleccion", nombreEleccion);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error GestionPartidosCandidatosServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar datos");
        }
        req.getRequestDispatcher("paginas/gestion_partidos_candidatos.jsp").forward(req, resp);
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
            if ("nuevoPartido".equals(action)) {
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombrePartido", req.getParameter("nombrePartido"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("propuestas", req.getParameter("propuestas"));
                datos.put("color", req.getParameter("color"));
                datos.put("idEleccion", Long.parseLong(req.getParameter("idEleccion")));
                RespuestaApiDTO respApi = partidoService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Partido creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Este lista ya existe";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editarPartido".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombrePartido", req.getParameter("nombrePartido"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("propuestas", req.getParameter("propuestas"));
                datos.put("color", req.getParameter("color"));
                datos.put("idEleccion", Long.parseLong(req.getParameter("idEleccion")));
                RespuestaApiDTO respApi = partidoService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Partido actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar partido";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("nuevoCandidato".equals(action)) {
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                datos.put("cargo", req.getParameter("cargo"));
                datos.put("integrantes", req.getParameter("integrantes"));
                datos.put("idPartido", Long.parseLong(req.getParameter("idPartido")));
                Part filePart = req.getPart("imagen");
                if (filePart != null && filePart.getSize() > 0) {
                    datos.put("imagen", leerImagenBase64(filePart));
                }
                RespuestaApiDTO respApi = candidatoService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Candidato creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear candidato";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editarCandidato".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                datos.put("cargo", req.getParameter("cargo"));
                datos.put("integrantes", req.getParameter("integrantes"));
                datos.put("idPartido", Long.parseLong(req.getParameter("idPartido")));
                Part filePart = req.getPart("imagen");
                if (filePart != null && filePart.getSize() > 0) {
                    datos.put("imagen", leerImagenBase64(filePart));
                }
                RespuestaApiDTO respApi = candidatoService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionPartidosCandidatosServlet?mensaje=" + java.net.URLEncoder.encode("Candidato actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar candidato";
                    resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error GestionPartidosCandidatosServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionPartidosCandidatosServlet?error=" + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionPartidosCandidatosServlet");
    }

    private String leerImagenBase64(Part filePart) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int read;
        try (InputStream is = filePart.getInputStream()) {
            while ((read = is.read(buffer)) != -1) {
                baos.write(buffer, 0, read);
            }
        }
        return Base64.getEncoder().encodeToString(baos.toByteArray());
    }
}

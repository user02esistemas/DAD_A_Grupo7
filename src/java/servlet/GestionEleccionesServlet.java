package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.EleccionDTO;
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
import servicio.EleccionServicio;

@WebServlet("/GestionEleccionesServlet")
public class GestionEleccionesServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
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
        try {
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

            String endpoint = "/api/elecciones?pagina=" + pagina + "&por_pagina=" + porPagina;
            if (busqueda != null && !busqueda.isEmpty()) {
                endpoint += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
            }
            RespuestaApiDTO respApi = eleccionService.listarElecciones(token, pagina, busqueda);
            List<EleccionDTO> elecciones = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<EleccionDTO>>() {}.getType();
                elecciones = gson.fromJson(json, listType);
            }
            req.setAttribute("elecciones", elecciones);
            req.setAttribute("currentPage", respApi != null ? respApi.getPagina() : pagina);
            req.setAttribute("totalPages", respApi != null ? respApi.getTotalPaginas() : 1);
            req.setAttribute("porPagina", respApi != null ? respApi.getPorPagina() : porPagina);
            req.setAttribute("totalRegistros", respApi != null ? respApi.getTotal() : 0);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error en GestionEleccionesServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar elecciones");
        }
        req.getRequestDispatcher("paginas/gestion_elecciones.jsp").forward(req, resp);
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
                String fIni = req.getParameter("fechaInicioInscripcion");
                String fCie = req.getParameter("fechaCierreInscripcion");
                String fVot = req.getParameter("fechaVotacion");
                if (fIni == null || fCie == null || fVot == null
                        || fIni.compareTo(fCie) > 0 || fCie.compareTo(fVot) > 0) {
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode("Fechas inv\u00e1lidas: debe cumplir inicio inscripci\u00f3n \u2264 cierre inscripci\u00f3n \u2264 fecha votaci\u00f3n", "UTF-8"));
                    return;
                }
                if (fIni.equals(fVot) || fCie.equals(fVot)) {
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode("Las fechas de inscripci\u00f3n y votaci\u00f3n no pueden ser el mismo d\u00eda", "UTF-8"));
                    return;
                }
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombreEleccion", req.getParameter("nombreEleccion"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("fechaInicioInscripcion", fIni);
                datos.put("fechaCierreInscripcion", fCie);
                datos.put("horaInicioInscripcion", req.getParameter("horaInicioInscripcion"));
                datos.put("horaFinInscripcion", req.getParameter("horaFinInscripcion"));
                datos.put("fechaVotacion", fVot);
                datos.put("horaInicioVotacion", req.getParameter("horaInicioVotacion"));
                datos.put("horaFinVotacion", req.getParameter("horaFinVotacion"));
                datos.put("activa", "1");
                RespuestaApiDTO respApi = eleccionService.crearEleccion(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionEleccionesServlet?mensaje="
                            + java.net.URLEncoder.encode("Elecci\u00f3n creada exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear elecci\u00f3n";
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                String fIni = req.getParameter("fechaInicioInscripcion");
                String fCie = req.getParameter("fechaCierreInscripcion");
                String fVot = req.getParameter("fechaVotacion");
                if (fIni == null || fCie == null || fVot == null
                        || fIni.compareTo(fCie) > 0 || fCie.compareTo(fVot) > 0) {
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode("Fechas inv\u00e1lidas: debe cumplir inicio inscripci\u00f3n \u2264 cierre inscripci\u00f3n \u2264 fecha votaci\u00f3n", "UTF-8"));
                    return;
                }
                if (fIni.equals(fVot) || fCie.equals(fVot)) {
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode("Las fechas de inscripci\u00f3n y votaci\u00f3n no pueden ser el mismo d\u00eda", "UTF-8"));
                    return;
                }
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombreEleccion", req.getParameter("nombreEleccion"));
                datos.put("descripcion", req.getParameter("descripcion"));
                datos.put("fechaInicioInscripcion", fIni);
                datos.put("fechaCierreInscripcion", fCie);
                datos.put("horaInicioInscripcion", req.getParameter("horaInicioInscripcion"));
                datos.put("horaFinInscripcion", req.getParameter("horaFinInscripcion"));
                datos.put("fechaVotacion", fVot);
                datos.put("horaInicioVotacion", req.getParameter("horaInicioVotacion"));
                datos.put("horaFinVotacion", req.getParameter("horaFinVotacion"));
                datos.put("activa", req.getParameter("activa"));
                RespuestaApiDTO respApi = eleccionService.actualizarEleccion(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionEleccionesServlet?mensaje="
                            + java.net.URLEncoder.encode("Elecci\u00f3n actualizada exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar elecci\u00f3n";
                    resp.sendRedirect("GestionEleccionesServlet?error="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionEleccionesServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionEleccionesServlet?error="
                    + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionEleccionesServlet");
    }
}

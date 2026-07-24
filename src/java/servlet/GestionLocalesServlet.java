package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CaserioDTO;
import dto.LocalVotacionDTO;
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
import servicio.CaserioServicio;
import servicio.LocalVotacionServicio;

@WebServlet("/GestionLocalesServlet")
public class GestionLocalesServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final LocalVotacionServicio localService = new LocalVotacionServicio();
    private final CaserioServicio caserioService = new CaserioServicio();
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
            if ("activarLocal".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = localService.cambiarEstado(id, true, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionLocalesServlet?mensaje=" + java.net.URLEncoder.encode("Local activado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar local";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionLocalesServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("desactivarLocal".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = localService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionLocalesServlet?mensaje=" + java.net.URLEncoder.encode("Local desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar local";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionLocalesServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
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

            RespuestaApiDTO respApi = localService.listar(token, pagina, porPagina, busqueda);
            List<LocalVotacionDTO> locales = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<LocalVotacionDTO>>() {}.getType();
                locales = gson.fromJson(json, listType);
            }
            req.setAttribute("locales", locales);
            req.setAttribute("currentPage", respApi != null ? respApi.getPagina() : pagina);
            req.setAttribute("totalPages", respApi != null ? respApi.getTotalPaginas() : 1);
            req.setAttribute("totalRegistros", respApi != null ? respApi.getTotal() : 0);
            req.setAttribute("porPagina", respApi != null ? respApi.getPorPagina() : porPagina);

            List<CaserioDTO> caserios = caserioService.listarCaseriosActivos(token);
            req.setAttribute("caserios", caserios);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error en GestionLocalesServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar locales de votaci\u00f3n");
        }
        req.getRequestDispatcher("paginas/gestion_locales.jsp").forward(req, resp);
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
                datos.put("nombreLocal", req.getParameter("nombreLocal"));
                datos.put("direccion", req.getParameter("direccion"));
                datos.put("referencia", req.getParameter("referencia"));
                datos.put("idCaserio", Integer.parseInt(req.getParameter("idCaserio")));
                RespuestaApiDTO respApi = localService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionLocalesServlet?mensaje=" + java.net.URLEncoder.encode("Local creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear local";
                    resp.sendRedirect("GestionLocalesServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("nombreLocal", req.getParameter("nombreLocal"));
                datos.put("direccion", req.getParameter("direccion"));
                datos.put("referencia", req.getParameter("referencia"));
                datos.put("idCaserio", Integer.parseInt(req.getParameter("idCaserio")));
                RespuestaApiDTO respApi = localService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionLocalesServlet?mensaje=" + java.net.URLEncoder.encode("Local actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar local";
                    resp.sendRedirect("GestionLocalesServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionLocalesServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionLocalesServlet?error=" + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionLocalesServlet");
    }
}

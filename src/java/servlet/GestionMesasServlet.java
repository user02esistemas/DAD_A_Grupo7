package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CaserioDTO;
import dto.LocalVotacionDTO;
import dto.MesaSufragioDTO;
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
import servicio.MesaSufragioServicio;

@WebServlet("/GestionMesasServlet")
public class GestionMesasServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final MesaSufragioServicio mesaService = new MesaSufragioServicio();
    private final CaserioServicio caserioService = new CaserioServicio();
    private final LocalVotacionServicio localService = new LocalVotacionServicio();
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
            if ("activarMesa".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = mesaService.cambiarEstado(id, true, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMesasServlet?mensaje=" + java.net.URLEncoder.encode("Mesa activada", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar mesa";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionMesasServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("desactivarMesa".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = mesaService.cambiarEstado(id, false, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMesasServlet?mensaje=" + java.net.URLEncoder.encode("Mesa desactivada", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar mesa";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionMesasServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
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

            RespuestaApiDTO respApi = mesaService.listar(token, pagina, porPagina, busqueda);
            List<MesaSufragioDTO> mesas = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<MesaSufragioDTO>>() {}.getType();
                mesas = gson.fromJson(json, listType);
            }
            req.setAttribute("mesas", mesas);
            req.setAttribute("currentPage", respApi != null ? respApi.getPagina() : pagina);
            req.setAttribute("totalPages", respApi != null ? respApi.getTotalPaginas() : 1);
            req.setAttribute("totalRegistros", respApi != null ? respApi.getTotal() : 0);
            req.setAttribute("porPagina", respApi != null ? respApi.getPorPagina() : porPagina);

            List<CaserioDTO> caserios = caserioService.listarCaseriosActivos(token);
            req.setAttribute("caserios", caserios);

            List<LocalVotacionDTO> locales = localService.listarActivos(token, 0);
            req.setAttribute("locales", locales);

            String nextCode = generarSiguienteCodigo(token);
            req.setAttribute("nextCode", nextCode);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error en GestionMesasServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar mesas de sufragio");
        }
        req.getRequestDispatcher("paginas/gestion_mesas.jsp").forward(req, resp);
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
                String codigoMesa = req.getParameter("codigoMesa");
                if (codigoMesa == null || codigoMesa.isEmpty()) {
                    codigoMesa = generarSiguienteCodigo(token);
                }
                Map<String, Object> datos = new HashMap<>();
                datos.put("codigoMesa", codigoMesa);
                datos.put("idCaserio", Integer.parseInt(req.getParameter("idCaserio")));
                datos.put("idLocalVotacion", Integer.parseInt(req.getParameter("idLocalVotacion")));
                datos.put("capacidadMaxima", Integer.parseInt(req.getParameter("capacidadMaxima")));
                RespuestaApiDTO respApi = mesaService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMesasServlet?mensaje=" + java.net.URLEncoder.encode("Mesa creada exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear mesa";
                    resp.sendRedirect("GestionMesasServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                int idLocalVotacion = Integer.parseInt(req.getParameter("idLocalVotacion"));
                int capacidadMaxima = Integer.parseInt(req.getParameter("capacidadMaxima"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("codigoMesa", req.getParameter("codigoMesa"));
                datos.put("idCaserio", idCaserio);
                datos.put("idLocalVotacion", idLocalVotacion);
                datos.put("capacidadMaxima", capacidadMaxima);
                RespuestaApiDTO respApi = mesaService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMesasServlet?mensaje=" + java.net.URLEncoder.encode("Mesa actualizada exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar mesa";
                    resp.sendRedirect("GestionMesasServlet?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionMesasServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionMesasServlet?error=" + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionMesasServlet");
    }

    private String generarSiguienteCodigo(String token) throws IOException {
        try {
            RespuestaApiDTO respApi = mesaService.listar(token, 1, 10000, null);
            List<MesaSufragioDTO> mesas = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<MesaSufragioDTO>>() {}.getType();
                mesas = gson.fromJson(json, listType);
            }
            int maxNum = 0;
            for (MesaSufragioDTO m : mesas) {
                String code = m.getCodigoMesa();
                if (code != null && code.startsWith("MESA-")) {
                    try {
                        int num = Integer.parseInt(code.substring(5));
                        if (num > maxNum) maxNum = num;
                    } catch (NumberFormatException e) { }
                }
            }
            return String.format("MESA-%03d", maxNum + 1);
        } catch (Exception e) {
            return "MESA-001";
        }
    }
}

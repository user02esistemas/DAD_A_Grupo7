package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.AuditoriaDTO;
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
import servicio.AuditoriaServicio;

@WebServlet("/AuditoriaServlet")
public class AuditoriaServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final AuditoriaServicio auditoriaService = new AuditoriaServicio();
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

            RespuestaApiDTO respApi = auditoriaService.listar(token, pagina, porPagina, busqueda);
            List<AuditoriaDTO> auditorias = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<AuditoriaDTO>>() {}.getType();
                auditorias = gson.fromJson(json, listType);
            }
            req.setAttribute("auditorias", auditorias);
            req.setAttribute("currentPage", respApi != null ? respApi.getPagina() : pagina);
            req.setAttribute("totalPages", respApi != null ? respApi.getTotalPaginas() : 1);
            req.setAttribute("porPagina", respApi != null ? respApi.getPorPagina() : porPagina);
            req.setAttribute("totalRegistros", respApi != null ? respApi.getTotal() : 0);
            if (req.getParameter("mensaje") != null) {
                req.setAttribute("mensaje", req.getParameter("mensaje"));
            }
            if (req.getParameter("error") != null) {
                req.setAttribute("error", req.getParameter("error"));
            }
        } catch (Exception e) {
            System.out.println("Error en AuditoriaServlet: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar auditor\u00eda");
        }
        req.getRequestDispatcher("paginas/auditoria.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");
        if (token == null || token.isEmpty()) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        resp.sendRedirect("AuditoriaServlet");
    }
}

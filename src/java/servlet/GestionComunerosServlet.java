package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CaserioDTO;
import dto.ComuneroDTO;
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
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.*;
import servicio.CaserioServicio;
import servicio.ComuneroServicio;
import servicio.MesaSufragioServicio;

@WebServlet("/GestionComunerosServlet")
public class GestionComunerosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ComuneroServicio comuneroService = new ComuneroServicio();
    private final CaserioServicio caserioService = new CaserioServicio();
    private final MesaSufragioServicio mesaService = new MesaSufragioServicio();
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
            if ("activarComunero".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = comuneroService.cambiarEstado(id, 1, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Comunero activado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar comunero";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("desactivarComunero".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = comuneroService.cambiarEstado(id, 0, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Comunero desactivado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al desactivar comunero";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                RespuestaApiDTO respApi = comuneroService.obtener(token, id);
                ComuneroDTO comunero = null;
                if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                    String json = gson.toJson(respApi.getDatos());
                    comunero = gson.fromJson(json, ComuneroDTO.class);
                }
                if (comunero == null) {
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("Comunero no encontrado", "UTF-8"));
                    return;
                }
                String errorParam = req.getParameter("error");
                if (errorParam != null) req.setAttribute("error", errorParam);
                List<CaserioDTO> caserios = caserioService.listarCaseriosActivos(token);
                List<MesaSufragioDTO> mesas = mesaService.listarActivas(token, 0);
                req.setAttribute("comunero", comunero);
                req.setAttribute("caserios", caserios);
                req.setAttribute("mesas", mesas);
                req.setAttribute("esEditar", true);
                req.getRequestDispatcher("paginas/gestion_comuneros.jsp").forward(req, resp);
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
            int idCaserioFiltro = 0;
            String idCaserioStr = req.getParameter("idCaserioFiltro");
            if (idCaserioStr != null && !idCaserioStr.isEmpty()) {
                try { idCaserioFiltro = Integer.parseInt(idCaserioStr); } catch (NumberFormatException e) { }
            }

            RespuestaApiDTO respApi = comuneroService.listar(token, pagina, porPagina, busqueda, idCaserioFiltro);
            List<ComuneroDTO> comuneros = new ArrayList<>();
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type listType = new TypeToken<List<ComuneroDTO>>() {}.getType();
                comuneros = gson.fromJson(json, listType);
            }
            req.setAttribute("comuneros", comuneros);
            req.setAttribute("currentPage", respApi != null ? respApi.getPagina() : pagina);
            req.setAttribute("totalPages", respApi != null ? respApi.getTotalPaginas() : 1);
            req.setAttribute("totalRegistros", respApi != null ? respApi.getTotal() : 0);
            req.setAttribute("porPagina", respApi != null ? respApi.getPorPagina() : porPagina);

            List<CaserioDTO> caserios = caserioService.listarCaseriosActivos(token);
            req.setAttribute("caserios", caserios);

            List<MesaSufragioDTO> mesas = mesaService.listarActivas(token, 0);
            req.setAttribute("mesas", mesas);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error en GestionComunerosServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar comuneros");
        }
        req.getRequestDispatcher("paginas/gestion_comuneros.jsp").forward(req, resp);
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
                String dni = req.getParameter("dni");
                if (dni == null || !dni.matches("\\d{8}")) {
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("El DNI debe tener 8 d\u00edgitos num\u00e9ricos", "UTF-8"));
                    return;
                }

                String clave = req.getParameter("claveVotacion");
                if (clave != null && !clave.isEmpty() && !clave.matches("\\d{6}")) {
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("La clave de votaci\u00f3n debe tener 6 d\u00edgitos num\u00e9ricos", "UTF-8"));
                    return;
                }

                String telefono = req.getParameter("telefono");
                if (telefono != null && !telefono.isEmpty() && !telefono.matches("\\d{9}")) {
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("El tel\u00e9fono debe tener 9 d\u00edgitos", "UTF-8"));
                    return;
                }

                String fechaNac = req.getParameter("fechaNacimiento");
                if (fechaNac != null && !fechaNac.isEmpty()) {
                    try {
                        LocalDate fn = LocalDate.parse(fechaNac, DateTimeFormatter.ISO_LOCAL_DATE);
                        if (Period.between(fn, LocalDate.now()).getYears() < 18) {
                            resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("El comunero debe ser mayor de 18 a\u00f1os", "UTF-8"));
                            return;
                        }
                    } catch (Exception e) {
                        resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("Fecha de nacimiento inv\u00e1lida", "UTF-8"));
                        return;
                    }
                }

                Map<String, Object> datos = new HashMap<>();
                datos.put("dni", dni);
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                if (fechaNac != null && !fechaNac.isEmpty()) datos.put("fechaNacimiento", fechaNac);
                String sexo = req.getParameter("sexo");
                if (sexo != null && !sexo.isEmpty()) datos.put("sexo", sexo);
                if (telefono != null && !telefono.isEmpty()) datos.put("telefono", telefono);
                String direccion = req.getParameter("direccion");
                if (direccion != null && !direccion.isEmpty()) datos.put("direccion", direccion);
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                datos.put("idCaserio", idCaserio);
                int idMesa = Integer.parseInt(req.getParameter("idMesaSufragio"));
                datos.put("idMesaSufragio", idMesa);
                if (clave != null && !clave.isEmpty()) datos.put("claveVotacion", clave);

                RespuestaApiDTO respApi = comuneroService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Comunero creado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al crear comunero";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("editar".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));

                String telefono = req.getParameter("telefono");
                if (telefono != null && !telefono.isEmpty() && !telefono.matches("\\d{9}")) {
                    resp.sendRedirect("GestionComunerosServlet?action=editar&id=" + id + "&error=" + URLEncoder.encode("El tel\u00e9fono debe tener 9 d\u00edgitos", "UTF-8"));
                    return;
                }

                String fechaNac = req.getParameter("fechaNacimiento");
                if (fechaNac != null && !fechaNac.isEmpty()) {
                    try {
                        LocalDate fn = LocalDate.parse(fechaNac, DateTimeFormatter.ISO_LOCAL_DATE);
                        if (Period.between(fn, LocalDate.now()).getYears() < 18) {
                            resp.sendRedirect("GestionComunerosServlet?action=editar&id=" + id + "&error=" + URLEncoder.encode("El comunero debe ser mayor de 18 a\u00f1os", "UTF-8"));
                            return;
                        }
                    } catch (Exception e) {
                        resp.sendRedirect("GestionComunerosServlet?action=editar&id=" + id + "&error=" + URLEncoder.encode("Fecha de nacimiento inv\u00e1lida", "UTF-8"));
                        return;
                    }
                }

                String clave = req.getParameter("claveVotacion");
                if (clave != null && !clave.isEmpty()) {
                    if (!clave.matches("\\d{6}")) {
                        resp.sendRedirect("GestionComunerosServlet?action=editar&id=" + id + "&error=" + URLEncoder.encode("La clave de votaci\u00f3n debe tener 6 d\u00edgitos num\u00e9ricos", "UTF-8"));
                        return;
                    }
                    String repetir = req.getParameter("repetirClave");
                    if (repetir == null || !repetir.equals(clave)) {
                        resp.sendRedirect("GestionComunerosServlet?action=editar&id=" + id + "&error=" + URLEncoder.encode("Las claves no coinciden", "UTF-8"));
                        return;
                    }
                }

                Map<String, Object> datos = new HashMap<>();
                datos.put("nombres", req.getParameter("nombres"));
                datos.put("apellidos", req.getParameter("apellidos"));
                if (fechaNac != null && !fechaNac.isEmpty()) datos.put("fechaNacimiento", fechaNac);
                String sexo = req.getParameter("sexo");
                if (sexo != null && !sexo.isEmpty()) datos.put("sexo", sexo);
                if (telefono != null && !telefono.isEmpty()) datos.put("telefono", telefono);
                String direccion = req.getParameter("direccion");
                if (direccion != null && !direccion.isEmpty()) datos.put("direccion", direccion);
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                datos.put("idCaserio", idCaserio);
                int idMesa = Integer.parseInt(req.getParameter("idMesaSufragio"));
                datos.put("idMesaSufragio", idMesa);
                datos.put("estado", Integer.parseInt(req.getParameter("estado")));
                if (clave != null && !clave.isEmpty()) datos.put("claveVotacion", clave);

                RespuestaApiDTO respApi = comuneroService.actualizar(id, datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Comunero actualizado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al actualizar comunero";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("limpiarPadron".equals(action)) {
                RespuestaApiDTO respApi = comuneroService.desactivarTodos(token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Padr\u00f3n reseteado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al resetear padr\u00f3n";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("activarPadron".equals(action)) {
                RespuestaApiDTO respApi = comuneroService.activarTodos(token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionComunerosServlet?mensaje=" + URLEncoder.encode("Padr\u00f3n activado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al activar padr\u00f3n";
                    resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionComunerosServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionComunerosServlet?error=" + URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionComunerosServlet");
    }
}

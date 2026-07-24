package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CaserioDTO;
import dto.ComuneroDTO;
import dto.MesaSufragioDTO;
import dto.MiembroMesaDTO;
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
import servicio.MesaSufragioServicio;
import servicio.MiembroMesaServicio;

@WebServlet("/GestionMiembrosMesaServlet")
public class GestionMiembrosMesaServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final MiembroMesaServicio miembroService = new MiembroMesaServicio();
    private final CaserioServicio caserioService = new CaserioServicio();
    private final MesaSufragioServicio mesaService = new MesaSufragioServicio();
    private final Gson gson = new Gson();

    private static final String[] CARGOS = {"PRESIDENTE", "SECRETARIO", "VOCAL"};

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
            if ("eliminar".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                RespuestaApiDTO respApi = miembroService.eliminar(id, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&mensaje=" + java.net.URLEncoder.encode("Miembro eliminado", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al eliminar miembro";
                    if (msg.contains("votación")) msg = "Error al desactivar por motivos de votación";
                    resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } else if ("seleccionarAleatorios".equals(action)) {
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                RespuestaApiDTO elecResp = ApiCliente.get("/api/elecciones/activa", token);
                if (elecResp != null && elecResp.isExito() && elecResp.getDatos() != null) {
                    Map<String, Object> elec = gson.fromJson(gson.toJson(elecResp.getDatos()), Map.class);
                    if ("EN_VOTACION".equals(elec.get("estado"))) {
                        resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&error=" + java.net.URLEncoder.encode("Miembros de mesa no seleccionados por motivos de votaci\u00f3n", "UTF-8"));
                        return;
                    }
                }
                int idMesaSufragio = Integer.parseInt(req.getParameter("idMesaSufragio"));
                List<ComuneroDTO> disponibles = miembroService.listarComunerosDisponibles(token, idCaserio);
                if (disponibles.size() < 3) {
                    resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&error=" + java.net.URLEncoder.encode("No hay suficientes comuneros disponibles en este caser\u00edo (m\u00ednimo 3)", "UTF-8"));
                    return;
                }
                Random rnd = new Random();
                int insertados = 0;
                for (int i = 0; i < 3; i++) {
                    int idx = rnd.nextInt(disponibles.size());
                    ComuneroDTO c = disponibles.remove(idx);
                    Map<String, Object> datos = new HashMap<>();
                    datos.put("idComunero", c.getIdComunero());
                    datos.put("idCaserio", idCaserio);
                    datos.put("idMesaSufragio", idMesaSufragio);
                    datos.put("cargo", CARGOS[i]);
                    RespuestaApiDTO respApi = miembroService.crear(datos, token);
                    if (respApi != null && respApi.isExito()) insertados++;
                }
                resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&mensaje=" + java.net.URLEncoder.encode(insertados + " miembros seleccionados aleatoriamente para la mesa", "UTF-8"));
                return;
            }

            int idCaserio = 0;
            String csStr = req.getParameter("idCaserio");
            if (csStr != null && !csStr.isEmpty()) {
                try { idCaserio = Integer.parseInt(csStr); } catch (NumberFormatException e) { }
            }

            List<CaserioDTO> caserios = caserioService.listarCaseriosActivos(token);
            req.setAttribute("caserios", caserios);

            List<MiembroMesaDTO> miembros = new ArrayList<>();
            List<ComuneroDTO> disponibles = new ArrayList<>();
            List<MesaSufragioDTO> mesas = new ArrayList<>();
            int total = 0;

            if (idCaserio > 0) {
                miembros = miembroService.listar(token, idCaserio);
                disponibles = miembroService.listarComunerosDisponibles(token, idCaserio);
                mesas = mesaService.listarActivas(token, idCaserio);
                total = miembroService.conteo(token, idCaserio);
            }
            req.setAttribute("miembros", miembros);
            req.setAttribute("disponibles", disponibles);
            req.setAttribute("mesas", mesas);
            req.setAttribute("totalMiembros", total);

            String mensaje = req.getParameter("mensaje");
            if (mensaje != null) req.setAttribute("mensaje", mensaje);
            String error = req.getParameter("error");
            if (error != null) req.setAttribute("error", error);
        } catch (Exception e) {
            System.out.println("Error en GestionMiembrosMesaServlet GET: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar miembros de mesa");
        }
        req.getRequestDispatcher("paginas/gestion_miembros_mesa.jsp").forward(req, resp);
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
                int idCaserio = Integer.parseInt(req.getParameter("idCaserio"));
                Map<String, Object> datos = new HashMap<>();
                datos.put("idComunero", Long.parseLong(req.getParameter("idComunero")));
                datos.put("idCaserio", idCaserio);
                datos.put("cargo", req.getParameter("cargo"));
                String idMesa = req.getParameter("idMesaSufragio");
                if (idMesa != null && !idMesa.isEmpty()) {
                    datos.put("idMesaSufragio", Integer.parseInt(idMesa));
                }
                RespuestaApiDTO respApi = miembroService.crear(datos, token);
                if (respApi != null && respApi.isExito()) {
                    resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&mensaje=" + java.net.URLEncoder.encode("Miembro asignado exitosamente", "UTF-8"));
                } else {
                    String msg = respApi != null ? respApi.getMensaje() : "Error al asignar miembro";
                    resp.sendRedirect("GestionMiembrosMesaServlet?idCaserio=" + idCaserio + "&error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            }
        } catch (Exception e) {
            System.out.println("Error en GestionMiembrosMesaServlet POST: " + e.getMessage());
            e.printStackTrace();
            resp.sendRedirect("GestionMiembrosMesaServlet?error=" + java.net.URLEncoder.encode("Error en la operaci\u00f3n", "UTF-8"));
            return;
        }
        resp.sendRedirect("GestionMiembrosMesaServlet");
    }
}

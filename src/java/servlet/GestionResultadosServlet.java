package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CaserioDTO;
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
import servicio.CaserioServicio;
import servicio.ResultadoServicio;

@WebServlet(name = "GestionResultadosServlet", urlPatterns = {"/GestionResultadosServlet"})
public class GestionResultadosServlet extends HttpServlet {

    private final ResultadoServicio resultadoService = new ResultadoServicio();
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

        String ajax = req.getParameter("ajax");
        String action = req.getParameter("action");

        if ("cargarMesas".equals(action)) {
            int idCaserio = 0;
            String csStr = req.getParameter("idCaserio");
            if (csStr != null && !csStr.isEmpty()) {
                try { idCaserio = Integer.parseInt(csStr); } catch (NumberFormatException e) {}
            }
            List<MesaSufragioDTO> mesas = resultadoService.listarMesasPorCaserio(token, idCaserio);
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print(gson.toJson(mesas));
            return;
        }

        try {
            RespuestaApiDTO respActiva = resultadoService.obtenerActiva(token);
            if (respActiva == null || !respActiva.isExito() || respActiva.getDatos() == null) {
                req.setAttribute("error", "No hay elecci\u00f3n activa para mostrar resultados");
                req.getRequestDispatcher("paginas/gestion_resultados.jsp").forward(req, resp);
                return;
            }

            Map<String, Object> eleccion = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Double) eleccion.get("idEleccion")).intValue();

            if ("1".equals(ajax)) {
                int idCaserio = 0;
                int idMesa = 0;
                String csStr = req.getParameter("idCaserio");
                if (csStr != null && !csStr.isEmpty()) {
                    try { idCaserio = Integer.parseInt(csStr); } catch (NumberFormatException e) {}
                }
                String mesaStr = req.getParameter("idMesa");
                if (mesaStr != null && !mesaStr.isEmpty()) {
                    try { idMesa = Integer.parseInt(mesaStr); } catch (NumberFormatException e) {}
                }

                RespuestaApiDTO respCandidatos;
                if (idMesa > 0) {
                    respCandidatos = resultadoService.obtenerPorCandidatoYCaserioYMesa(idEleccion, idCaserio, idMesa, token);
                } else if (idCaserio > 0) {
                    respCandidatos = resultadoService.obtenerPorCandidatoYCaserio(idEleccion, idCaserio, token);
                } else {
                    respCandidatos = resultadoService.obtenerPorCandidato(idEleccion, token);
                }

                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print(gson.toJson(respCandidatos));
                return;
            }

            RespuestaApiDTO respCandidatos = resultadoService.obtenerPorCandidato(idEleccion, token);
            RespuestaApiDTO respCaserios = resultadoService.obtenerPorCaserio(idEleccion, token);
            List<CaserioDTO> caseriosActivos = caserioService.listarCaseriosActivos(token);

            req.setAttribute("eleccion", eleccion);
            req.setAttribute("candidatos", respCandidatos != null ? respCandidatos.getDatos() : null);
            req.setAttribute("caseriosVotos", respCaserios != null ? respCaserios.getDatos() : null);
            req.setAttribute("caserios", caseriosActivos);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar resultados");
        }
        req.getRequestDispatcher("paginas/gestion_resultados.jsp").forward(req, resp);
    }
}

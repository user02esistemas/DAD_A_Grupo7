package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.MesaSufragioDTO;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Type;
import java.util.*;
import servicio.ResultadoServicio;

@WebServlet(name = "ResultadosPublicoServlet", urlPatterns = {"/ResultadosPublicoServlet"})
public class ResultadosPublicoServlet extends HttpServlet {

    private final ResultadoServicio resultadoService = new ResultadoServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if ("cargarMesas".equals(action)) {
            int idCaserio = 0;
            try { idCaserio = Integer.parseInt(req.getParameter("idCaserio")); } catch (Exception e) {}
            List<MesaSufragioDTO> mesas = resultadoService.listarMesasPorCaserio(null, idCaserio);
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print(gson.toJson(mesas));
            return;
        }

        String ajax = req.getParameter("ajax");
        if ("1".equals(ajax)) {
            manejarAjax(req, resp);
            return;
        }

        try {
            RespuestaApiDTO respActiva = resultadoService.obtenerActiva(null);
            if (respActiva == null || !respActiva.isExito() || respActiva.getDatos() == null) {
                req.setAttribute("error", "No hay resultados disponibles");
                req.getRequestDispatcher("paginas/resultados_publico.jsp").forward(req, resp);
                return;
            }

            Map<String, Object> eleccion = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Number) eleccion.get("idEleccion")).intValue();

            String estado = (String) eleccion.get("estado");
            if (!"FINALIZADO".equals(estado)) {
                req.setAttribute("error", "Resultados no disponibles");
                req.getRequestDispatcher("paginas/resultados_publico.jsp").forward(req, resp);
                return;
            }

            RespuestaApiDTO respCandidatos = resultadoService.obtenerPorCandidato(idEleccion, null);
            RespuestaApiDTO respCaserios = resultadoService.obtenerPorCaserio(idEleccion, null);

            List<Map<String, Object>> caseriosList = new ArrayList<>();
            if (respCaserios != null && respCaserios.isExito() && respCaserios.getDatos() != null) {
                String json = gson.toJson(respCaserios.getDatos());
                Type listType = new TypeToken<List<Map<String, Object>>>() {}.getType();
                caseriosList = gson.fromJson(json, listType);
            }

            req.setAttribute("eleccion", eleccion);
            req.setAttribute("candidatos", respCandidatos != null ? respCandidatos.getDatos() : null);
            req.setAttribute("caseriosVotos", respCaserios != null ? respCaserios.getDatos() : null);
            req.setAttribute("caseriosList", caseriosList);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar resultados");
        }
        req.getRequestDispatcher("paginas/resultados_publico.jsp").forward(req, resp);
    }

    private void manejarAjax(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int idCaserio = 0;
        int idMesa = 0;
        try { idCaserio = Integer.parseInt(req.getParameter("idCaserio")); } catch (Exception e) {}
        try { idMesa = Integer.parseInt(req.getParameter("idMesa")); } catch (Exception e) {}

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        try {
            RespuestaApiDTO respActiva = resultadoService.obtenerActiva(null);
            if (respActiva == null || !respActiva.isExito() || respActiva.getDatos() == null) {
                out.print("[]");
                return;
            }
            Map<String, Object> eleccion = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Number) eleccion.get("idEleccion")).intValue();

            String estado = (String) eleccion.get("estado");
            if (!"FINALIZADO".equals(estado)) {
                out.print("[]");
                return;
            }

            RespuestaApiDTO respCandidatos;
            if (idMesa > 0) {
                respCandidatos = resultadoService.obtenerPorCandidatoYCaserioYMesa(idEleccion, idCaserio, idMesa, null);
            } else if (idCaserio > 0) {
                respCandidatos = resultadoService.obtenerPorCandidatoYCaserio(idEleccion, idCaserio, null);
            } else {
                respCandidatos = resultadoService.obtenerPorCandidato(idEleccion, null);
            }

            if (respCandidatos != null && respCandidatos.isExito() && respCandidatos.getDatos() != null) {
                out.print(gson.toJson(respCandidatos.getDatos()));
            } else {
                out.print("[]");
            }
        } catch (Exception e) {
            out.print("[]");
        }
    }
}

package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
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
import servicio.ResultadoServicio;

@WebServlet("/ResultadosServlet")
public class ResultadosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ResultadoServicio resultadoService = new ResultadoServicio();
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
            RespuestaApiDTO respApi = resultadoService.obtenerActiva(token);
            if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
                String json = gson.toJson(respApi.getDatos());
                Type mapType = new TypeToken<Map<String, Object>>() {}.getType();
                Map<String, Object> data = gson.fromJson(json, mapType);

                String eleccionNombre = (String) data.getOrDefault("eleccionNombre", "Elecci\u00f3n General");
                String eleccionFechaInicio = (String) data.getOrDefault("eleccionFechaInicio", "N/D");
                String eleccionFechaFin = (String) data.getOrDefault("eleccionFechaFin", "N/D");
                String eleccionEstado = (String) data.getOrDefault("eleccionEstado", "SIN DATOS");
                Object totalVotosObj = data.getOrDefault("totalVotos", 0);
                int totalVotos = totalVotosObj instanceof Number ? ((Number) totalVotosObj).intValue() : 0;
                Object votosBlancoObj = data.getOrDefault("votosBlanco", 0);
                int votosBlanco = votosBlancoObj instanceof Number ? ((Number) votosBlancoObj).intValue() : 0;
                Object participacionObj = data.getOrDefault("porcentajeParticipacion", 0);
                double porcentajeParticipacion = participacionObj instanceof Number ? ((Number) participacionObj).doubleValue() : 0.0;

                List<Object[]> resultados = new ArrayList<>();
                Object candidatosObj = data.get("candidatos");
                if (candidatosObj instanceof List) {
                    String candidatosJson = gson.toJson(candidatosObj);
                    Type listType = new TypeToken<List<Map<String, Object>>>() {}.getType();
                    List<Map<String, Object>> candidatos = gson.fromJson(candidatosJson, listType);
                    for (Map<String, Object> c : candidatos) {
                        String nombre = (String) c.getOrDefault("nombre", "Sin nombre");
                        String partido = (String) c.getOrDefault("partido", "Independiente");
                        Number votosNum = (Number) c.getOrDefault("votos", 0);
                        String color = (String) c.getOrDefault("color", "#3949ab");
                        resultados.add(new Object[]{nombre, partido, votosNum, color});
                    }
                }

                List<Object[]> resultadosCaserios = new ArrayList<>();
                Object caseriosObj = data.get("caserios");
                if (caseriosObj instanceof List) {
                    String caseriosJson = gson.toJson(caseriosObj);
                    Type listType2 = new TypeToken<List<Map<String, Object>>>() {}.getType();
                    List<Map<String, Object>> caserios = gson.fromJson(caseriosJson, listType2);
                    for (Map<String, Object> cs : caserios) {
                        String nombre = (String) cs.getOrDefault("nombre", "Sin nombre");
                        Number votosNum = (Number) cs.getOrDefault("votos", 0);
                        resultadosCaserios.add(new Object[]{nombre, votosNum});
                    }
                }

                req.setAttribute("eleccionNombre", eleccionNombre);
                req.setAttribute("eleccionFechaInicio", eleccionFechaInicio);
                req.setAttribute("eleccionFechaFin", eleccionFechaFin);
                req.setAttribute("eleccionEstado", eleccionEstado);
                req.setAttribute("totalVotos", totalVotos);
                req.setAttribute("votosBlanco", votosBlanco);
                req.setAttribute("porcentajeParticipacion", String.format("%.1f", porcentajeParticipacion));
                req.setAttribute("resultados", resultados);
                req.setAttribute("resultadosCaserios", resultadosCaserios);
            } else {
                String msg = respApi != null ? respApi.getMensaje() : "Sin datos de resultados";
                req.setAttribute("error", msg);
            }
        } catch (Exception e) {
            System.out.println("Error en ResultadosServlet: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Error al cargar resultados");
        }
        req.getRequestDispatcher("paginas/resultados.jsp").forward(req, resp);
    }
}

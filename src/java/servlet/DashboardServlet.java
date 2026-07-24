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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import servicio.DashboardServicio;
import servicio.ResultadoServicio;

@WebServlet("/DashboardServlet")
public class DashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final DashboardServicio dashboardService = new DashboardServicio();
    private final ResultadoServicio resultadoService = new ResultadoServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        procesarDashboard(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        procesarDashboard(req, resp);
    }

    private void procesarDashboard(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("token") == null) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }
        String token = (String) session.getAttribute("token");

        try {
            RespuestaApiDTO kpiResp = dashboardService.obtenerKpis(token);
            if (kpiResp != null && kpiResp.isExito() && kpiResp.getDatos() != null) {
                String json = gson.toJson(kpiResp.getDatos());
                Type mapType = new TypeToken<Map<String, Object>>() {}.getType();
                Map<String, Object> data = gson.fromJson(json, mapType);

                Number totalCom = (Number) data.getOrDefault("totalComuneros", 0);
                req.setAttribute("totalComuneros", totalCom.intValue());

                Number comAct = (Number) data.getOrDefault("comunerosActivos", 0);
                req.setAttribute("comunerosActivos", comAct.intValue());

                Number totalCas = (Number) data.getOrDefault("totalCaserios", 0);
                req.setAttribute("totalCaserios", totalCas.intValue());

                Number totalM = (Number) data.getOrDefault("totalMesas", 0);
                req.setAttribute("totalMesas", totalM.intValue());

                Number totalL = (Number) data.getOrDefault("totalLocales", 0);
                req.setAttribute("totalLocales", totalL.intValue());

                Number totalU = (Number) data.getOrDefault("totalUsuarios", 0);
                req.setAttribute("totalUsuarios", totalU.intValue());

                Number totalV = (Number) data.getOrDefault("votosEmitidos", 0);
                req.setAttribute("totalVotos", totalV.intValue());

                Number pct = (Number) data.getOrDefault("porcentajeParticipacion", 0);
                req.setAttribute("porcentajeParticipacion", String.valueOf(pct.doubleValue()));

                Object elec = data.get("eleccionActiva");
                if (elec != null && elec instanceof Map) {
                    Map<?, ?> elecMap = (Map<?, ?>) elec;
                    req.setAttribute("eleccionActiva", String.valueOf(elecMap.get("nombreEleccion")));
                    Number idElec = (Number) elecMap.get("idEleccion");
                    if (idElec != null) {
                        req.setAttribute("idEleccion", idElec.longValue());
                    }
                } else {
                    req.setAttribute("eleccionActiva", "Ninguna");
                }
            }

            Long idEleccion = (Long) req.getAttribute("idEleccion");
            if (idEleccion != null) {
                int idElec = idEleccion.intValue();

                RespuestaApiDTO activaResp = resultadoService.obtenerActiva(token);
                if (activaResp != null && activaResp.isExito() && activaResp.getDatos() != null) {
                    String json = gson.toJson(activaResp.getDatos());
                    Type mapType = new TypeToken<Map<String, Object>>() {}.getType();
                    Map<String, Object> data = gson.fromJson(json, mapType);
                    Number vb = (Number) data.getOrDefault("votosBlanco", 0);
                    req.setAttribute("votosBlancos", vb.intValue());
                }

                RespuestaApiDTO candResp = resultadoService.obtenerPorCandidato(idElec, token);
                if (candResp != null && candResp.isExito() && candResp.getDatos() != null) {
                    String json = gson.toJson(candResp.getDatos());
                    Type listType = new TypeToken<List<Map<String, Object>>>() {}.getType();
                    List<Map<String, Object>> candList = gson.fromJson(json, listType);

                    List<String> labels = new ArrayList<>();
                    List<Integer> values = new ArrayList<>();
                    List<String> colors = new ArrayList<>();

                    for (Map<String, Object> item : candList) {
                        labels.add(String.valueOf(item.get("nombreCandidato")));
                        values.add(((Number) item.getOrDefault("totalVotos", 0)).intValue());
                        colors.add(String.valueOf(item.getOrDefault("color", "#6c757d")));
                    }

                    req.setAttribute("chartLabels", gson.toJson(labels));
                    req.setAttribute("chartData", gson.toJson(values));
                    req.setAttribute("chartColors", gson.toJson(colors));
                }

                RespuestaApiDTO casResp = resultadoService.obtenerPorCaserio(idElec, token);
                if (casResp != null && casResp.isExito() && casResp.getDatos() != null) {
                    String json = gson.toJson(casResp.getDatos());
                    Type listType = new TypeToken<List<Map<String, Object>>>() {}.getType();
                    List<Map<String, Object>> caserioList = gson.fromJson(json, listType);

                    List<String> labels = new ArrayList<>();
                    List<Integer> values = new ArrayList<>();
                    List<String> colors = new ArrayList<>();

                    String[] palette = {"#1565c0","#2e7d32","#f9a825","#e65100","#6a1b9a","#00838f","#ad1457","#283593",
                        "#4e342e","#558b2f","#ef6c00","#00695c","#c62828","#4527a0","#00897b","#bf360c",
                        "#303f9f","#1b5e20","#f57f17","#d84315","#7b1fa2","#00838f","#c51162","#3949ab",
                        "#3e2723","#33691e","#ff6f00","#004d40","#b71c1c","#311b92","#00796b","#dd2c00"};

                    int idx = 0;
                    for (Map<String, Object> item : caserioList) {
                        int votos = ((Number) item.getOrDefault("votosEmitidos", 0)).intValue();
                        if (votos > 0) {
                            labels.add(String.valueOf(item.get("nombreCaserio")));
                            values.add(votos);
                            colors.add(palette[idx % palette.length]);
                            idx++;
                        }
                    }

                    req.setAttribute("caserioLabels", gson.toJson(labels));
                    req.setAttribute("caserioData", gson.toJson(values));
                    req.setAttribute("caserioColors", gson.toJson(colors));
                }
            }
        } catch (Exception e) {
            System.out.println("ERROR DASHBOARD: " + e.getClass().getName() + ": " + e.getMessage());
            req.setAttribute("error", "Error al cargar dashboard: " + e.getClass().getSimpleName());
        }
        req.getRequestDispatcher("paginas/dashboard.jsp").forward(req, resp);
    }
}

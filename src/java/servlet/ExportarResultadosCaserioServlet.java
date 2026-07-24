package servlet;

import com.google.gson.Gson;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;
import servicio.CaserioServicio;
import servicio.ResultadoServicio;
import dto.CaserioDTO;

@WebServlet(name = "ExportarResultadosCaserioServlet", urlPatterns = {"/ExportarResultadosCaserioServlet"})
public class ExportarResultadosCaserioServlet extends HttpServlet {

    private final ResultadoServicio resultadoService = new ResultadoServicio();
    private final CaserioServicio caserioService = new CaserioServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");

        int idCaserio = 0;
        int idMesa = 0;
        String csParam = req.getParameter("idCaserio");
        if (csParam != null && !csParam.isBlank()) {
            try { idCaserio = Integer.parseInt(csParam); } catch (NumberFormatException ignored) {}
        }
        String mesaParam = req.getParameter("idMesa");
        if (mesaParam != null && !mesaParam.isBlank()) {
            try { idMesa = Integer.parseInt(mesaParam); } catch (NumberFormatException ignored) {}
        }

        resp.setContentType("text/html;charset=UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.println("<!DOCTYPE html><html lang='es'>");
            out.println("<head><meta charset='UTF-8'>");
            out.println("<title>Resultados por Caser\u00edo</title>");
            out.println("<style>");
            out.println("@page{size:A4 portrait;margin:18mm 15mm}");
            out.println("body{font-family:'Times New Roman',Times,serif;font-size:16px;color:#1a1a1a;text-align:center;margin:0;padding:15px}");
            out.println("h1{font-size:20px;margin-bottom:2px;text-align:center;color:#000;font-weight:bold;text-transform:uppercase;letter-spacing:1px}");
            out.println("h2{font-size:16px;font-weight:bold;color:#222;margin-top:0;margin-bottom:2px;text-align:center}");
            out.println(".total{font-size:15px;color:#000;margin:8px 0 16px 0;text-align:center;font-weight:bold}");
            out.println("table{margin:0 auto;border-collapse:collapse;min-width:50%}");
            out.println("th{border-bottom:2px solid #000;padding:8px 12px;font-size:14px;text-align:center;font-weight:bold}");
            out.println("td{padding:7px 10px;border-bottom:1px solid #ccc;font-size:15px;text-align:center}");
            out.println("tr:nth-child(even){background:#f2f2f2}");
            out.println("tr:last-child td{border-bottom:2px solid #000}");
            out.println("tr.total-row td{font-weight:bold;border-top:2px solid #000}");
            out.println(".color-dot{display:inline-block;width:13px;height:13px;border-radius:50%;margin-right:4px;vertical-align:middle}");
            out.println(".footer{text-align:center;margin-top:18px;font-size:12px;color:#888}");
            out.println(".separador{margin:20px auto;border:none;border-top:1px solid #999;width:50%}");
            out.println("@media print{");
            out.println("body{font-size:15px;padding:5px}");
            out.println("th{font-size:13px;padding:6px 8px}");
            out.println("td{font-size:14px;padding:5px 7px}");
            out.println("h1{font-size:18px}");
            out.println("h2{font-size:15px}");
            out.println("}");
            out.println("</style></head><body>");
            out.println("<h1>COMUNIDAD CAMPESINA SAN PEDRO DE M\u00d3RROPE</h1>");

            RespuestaApiDTO respActiva = resultadoService.obtenerActiva(token);
            if (respActiva == null || !respActiva.isExito()) {
                out.println("<h2>Resultados por Caser\u00edo</h2>");
                out.println("<p style='color:#999;margin-top:40px'>No existe elecci\u00f3n activa o finalizada.</p>");
                out.println("</body></html>");
                return;
            }

            Map<String, Object> activa = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Double) activa.get("idEleccion")).intValue();

            if (idCaserio <= 0) {
                out.println("<h2>Resultados por Caser\u00edo</h2>");
                out.println("<p style='color:#999;margin-top:40px'>Seleccione un caser\u00edo para exportar.</p>");
                out.println("</body></html>");
                return;
            }

            CaserioDTO cs = caserioService.obtener(token, idCaserio);
            String nombreCaserio = (cs != null && cs.getNombreCaserio() != null) ? cs.getNombreCaserio() : "Caser\u00edo #" + idCaserio;
            String subtitulo = "Resultados - " + nombreCaserio;

            out.println("<h2>" + e(subtitulo) + "</h2>");
            out.println("<h3>" + e((String) activa.get("nombreEleccion")) + "</h3>");

            if (idMesa > 0) {
                RespuestaApiDTO respMesa = resultadoService.obtenerPorCandidatoYCaserioYMesa(idEleccion, idCaserio, idMesa, token);
                if (respMesa != null && respMesa.isExito() && respMesa.getDatos() != null) {
                    String json = gson.toJson(respMesa.getDatos());
                    List<Map<String, Object>> resultados = gson.fromJson(json, List.class);
                    int totalMesa = 0;
                    for (Map<String, Object> f : resultados) {
                        totalMesa += ((Double) f.get("totalVotos")).intValue();
                    }
                    out.println("<div class='total'>Total de votos en la mesa: " + totalMesa + "</div>");
                    out.println("<table><thead><tr><th style='width:40px'>N\u00b0</th><th>Candidato</th><th>Votos</th></tr></thead><tbody>");
                    int cont = 0;
                    for (Map<String, Object> fila : resultados) {
                        cont++;
                        String color = fila.get("color") != null ? (String) fila.get("color") : "#3949ab";
                        String nombre = (String) fila.get("nombreCandidato");
                        String partido = (String) fila.get("nombrePartido");
                        out.println("<tr><td>" + cont + "</td><td><strong>" + e(nombre) + "</strong><br><span style='font-size:13px;color:#666'><span class='color-dot' style='background:" + color + "'></span>" + e(partido) + "</span></td><td>" + fila.get("totalVotos") + "</td></tr>");
                    }
                    out.println("<tr class='total-row'><td></td><td><strong>Total</strong></td><td><strong>" + totalMesa + "</strong></td></tr>");
                    out.println("</tbody></table>");
                } else {
                    out.println("<p style='color:#999;margin-top:30px'>Sin votos en esta mesa.</p>");
                }
            } else {
                RespuestaApiDTO respCaserio = resultadoService.obtenerPorCandidatoYCaserio(idEleccion, idCaserio, token);
                if (respCaserio != null && respCaserio.isExito() && respCaserio.getDatos() != null) {
                    String json = gson.toJson(respCaserio.getDatos());
                    List<Map<String, Object>> resultados = gson.fromJson(json, List.class);
                    int totalCaserio = 0;
                    for (Map<String, Object> f : resultados) {
                        totalCaserio += ((Double) f.get("totalVotos")).intValue();
                    }
                    out.println("<div class='total'>Total de votos en el caser\u00edo: " + totalCaserio + "</div>");
                    out.println("<table><thead><tr><th style='width:40px'>N\u00b0</th><th>Candidato</th><th>Votos</th></tr></thead><tbody>");
                    int cont = 0;
                    for (Map<String, Object> fila : resultados) {
                        cont++;
                        String color = fila.get("color") != null ? (String) fila.get("color") : "#3949ab";
                        String nombre = (String) fila.get("nombreCandidato");
                        String partido = (String) fila.get("nombrePartido");
                        out.println("<tr><td>" + cont + "</td><td><strong>" + e(nombre) + "</strong><br><span style='font-size:13px;color:#666'><span class='color-dot' style='background:" + color + "'></span>" + e(partido) + "</span></td><td>" + fila.get("totalVotos") + "</td></tr>");
                    }
                    out.println("<tr class='total-row'><td></td><td><strong>Total</strong></td><td><strong>" + totalCaserio + "</strong></td></tr>");
                    out.println("</tbody></table>");

                    RespuestaApiDTO respDesglose = resultadoService.obtenerPorMesaCaserio(idEleccion, idCaserio, token);
                    if (respDesglose != null && respDesglose.isExito() && respDesglose.getDatos() != null) {
                        String json2 = gson.toJson(respDesglose.getDatos());
                        List<Map<String, Object>> porMesa = gson.fromJson(json2, List.class);
                        if (!porMesa.isEmpty()) {
                            Set<String> mesasSet = new LinkedHashSet<>();
                            Set<String> candidatosSet = new LinkedHashSet<>();
                            for (Map<String, Object> f : porMesa) {
                                mesasSet.add((String) f.get("codigoMesa"));
                                candidatosSet.add((String) f.get("nombreCandidato"));
                            }
                            out.println("<hr class='separador'>");
                            out.println("<div class='total'>Desglose por Mesa de Sufragio</div>");
                            out.println("<table><thead><tr><th style='width:40px'>N\u00b0</th><th>Mesa</th>");
                            for (String cand : candidatosSet) {
                                out.println("<th>" + e(cand) + "</th>");
                            }
                            out.println("<th>Total</th>");
                            out.println("</tr></thead><tbody>");
                            int mi = 0;
                            for (String mesa : mesasSet) {
                                mi++;
                                int totalMesa = 0;
                                out.println("<tr><td>" + mi + "</td><td><strong>" + e(mesa) + "</strong></td>");
                                for (String cand : candidatosSet) {
                                    int v = 0;
                                    for (Map<String, Object> f : porMesa) {
                                        if (mesa.equals(f.get("codigoMesa")) && cand.equals(f.get("nombreCandidato"))) {
                                            v = ((Double) f.get("totalVotos")).intValue();
                                            break;
                                        }
                                    }
                                    totalMesa += v;
                                    out.println("<td>" + v + "</td>");
                                }
                                out.println("<td><strong>" + totalMesa + "</strong></td></tr>");
                            }
                            out.println("</tbody></table>");
                        }
                    }
                } else {
                    out.println("<p style='color:#999;margin-top:30px'>Sin votos en este caser\u00edo.</p>");
                }
            }

            out.println("<div class='footer'>Generado el " + java.time.LocalDate.now() + " - SVE Comunidad Campesina San Pedro de M\u00f3rrope</div>");
            out.println("<script>window.onload=function(){window.print();}</script>");
            out.println("</body></html>");
        }
    }

    private String e(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}

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
import servicio.ResultadoServicio;

@WebServlet(name = "ExportarResultadosGeneralServlet", urlPatterns = {"/ExportarResultadosGeneralServlet"})
public class ExportarResultadosGeneralServlet extends HttpServlet {

    private final ResultadoServicio resultadoService = new ResultadoServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");

        resp.setContentType("text/html;charset=UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.println("<!DOCTYPE html><html lang='es'>");
            out.println("<head><meta charset='UTF-8'>");
            out.println("<title>Resultados Generales</title>");
            out.println("<style>");
            out.println("@page{size:A4 landscape;margin:15mm 20mm}");
            out.println("body{font-family:'Times New Roman',Times,serif;font-size:16px;color:#1a1a1a;text-align:center;margin:0;padding:10px}");
            out.println("h1{font-size:22px;margin-bottom:2px;text-align:center;color:#000;font-weight:bold;text-transform:uppercase;letter-spacing:1px}");
            out.println("h2{font-size:17px;font-weight:bold;color:#222;margin-top:0;margin-bottom:15px;text-align:center}");
            out.println(".caserio-group{font-size:17px;font-weight:bold;color:#000;margin:0;padding:5px 0 4px 0;text-align:left;border-bottom:2px solid #000}");
            out.println("table{width:100%;margin:6px 0 16px 0;border-collapse:collapse}");
            out.println("th{border-bottom:2px solid #000;padding:7px 10px;font-size:14px;text-align:center;font-weight:bold;color:#000}");
            out.println("td{padding:5px 10px;border-bottom:1px solid #ccc;font-size:14px;text-align:center;color:#000}");
            out.println("tr:nth-child(even){background:#f2f2f2}");
            out.println("tr.total-row td{font-weight:bold;border-top:2px solid #000;background:#e6e6e6}");
            out.println(".footer{text-align:center;margin-top:15px;font-size:10px;color:#888}");
            out.println("@media print{");
            out.println("body{font-size:14px;padding:5px 20px}");
            out.println("th{font-size:13px;padding:5px 8px}");
            out.println("td{font-size:13px;padding:4px 8px}");
            out.println("h1{font-size:18px}");
            out.println("h2{font-size:15px}");
            out.println("}");
            out.println("</style></head><body>");
            out.println("<h1>COMUNIDAD CAMPESINA SAN PEDRO DE M\u00d3RROPE</h1>");

            RespuestaApiDTO respActiva = resultadoService.obtenerActiva(token);
            if (respActiva == null || !respActiva.isExito()) {
                out.println("<h2>Resultados Generales</h2>");
                out.println("<p style='color:#999;margin-top:40px'>No existe elecci\u00f3n activa o finalizada.</p>");
                out.println("</body></html>");
                return;
            }

            Map<String, Object> activa = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Double) activa.get("idEleccion")).intValue();

            RespuestaApiDTO respGeneral = resultadoService.obtenerGeneralCompleto(idEleccion, token);

            out.println("<h2>Resultados Generales - " + e((String) activa.get("nombreEleccion")) + "</h2>");

            if (respGeneral != null && respGeneral.isExito() && respGeneral.getDatos() != null) {
                String json = gson.toJson(respGeneral.getDatos());
                List<Map<String, Object>> datos = gson.fromJson(json, List.class);

                if (!datos.isEmpty()) {
                    Set<String> candidatosGlobal = new LinkedHashSet<>();
                    for (Map<String, Object> f : datos) {
                        candidatosGlobal.add((String) f.get("nombreCandidato"));
                    }

                    String caserioActual = null;
                    String mesaActual = null;
                    int nMesa = 0;

                    for (int i = 0; i < datos.size(); i++) {
                        Map<String, Object> f = datos.get(i);
                        String cs = (String) f.get("nombreCaserio");
                        String mesa = (String) f.get("codigoMesa");

                        if (!cs.equals(caserioActual)) {
                            if (caserioActual != null) {
                                int totalCaserio = 0;
                                for (Map<String, Object> fx : datos) {
                                    if (caserioActual.equals(fx.get("nombreCaserio")))
                                        totalCaserio += ((Double) fx.get("totalVotos")).intValue();
                                }
                                out.println("<tr class='total-row'><td></td><td>Total caser\u00edo</td>");
                                for (String cand : candidatosGlobal) {
                                    int v = 0;
                                    for (Map<String, Object> fx : datos) {
                                        if (caserioActual.equals(fx.get("nombreCaserio")) && cand.equals(fx.get("nombreCandidato")))
                                            v += ((Double) fx.get("totalVotos")).intValue();
                                    }
                                    out.println("<td>" + v + "</td>");
                                }
                                out.println("<td><strong>" + totalCaserio + "</strong></td></tr>");
                                out.println("</tbody></table></div>");
                            }
                            caserioActual = cs;
                            mesaActual = null;
                            nMesa = 0;
                            out.println("<div style='margin:0 auto;width:fit-content;text-align:left'>");
                            out.println("<div class='caserio-group'>" + e(cs) + "</div>");
                            out.println("<table><thead><tr><th style='width:40px'>N\u00b0</th><th>Mesa</th>");
                            for (String cand : candidatosGlobal) {
                                out.println("<th>" + e(cand) + "</th>");
                            }
                            out.println("<th>Total</th></tr></thead><tbody>");
                        }

                        if (!mesa.equals(mesaActual)) {
                            mesaActual = mesa;
                            nMesa++;
                            out.println("<tr><td>" + nMesa + "</td><td><strong>" + e(mesa) + "</strong></td>");
                            int totalMesa = 0;
                            for (String cand : candidatosGlobal) {
                                int v = 0;
                                for (Map<String, Object> fx : datos) {
                                    if (cs.equals(fx.get("nombreCaserio")) && mesa.equals(fx.get("codigoMesa")) && cand.equals(fx.get("nombreCandidato")))
                                        v = ((Double) fx.get("totalVotos")).intValue();
                                }
                                totalMesa += v;
                                out.println("<td>" + v + "</td>");
                            }
                            out.println("<td><strong>" + totalMesa + "</strong></td></tr>");
                        }
                    }

                    if (caserioActual != null) {
                        int totalCaserio = 0;
                        for (Map<String, Object> fx : datos) {
                            if (caserioActual.equals(fx.get("nombreCaserio")))
                                totalCaserio += ((Double) fx.get("totalVotos")).intValue();
                        }
                        out.println("<tr class='total-row'><td></td><td>Total caser\u00edo</td>");
                        for (String cand : candidatosGlobal) {
                            int v = 0;
                            for (Map<String, Object> fx : datos) {
                                if (caserioActual.equals(fx.get("nombreCaserio")) && cand.equals(fx.get("nombreCandidato")))
                                    v += ((Double) fx.get("totalVotos")).intValue();
                            }
                            out.println("<td>" + v + "</td>");
                        }
                        out.println("<td><strong>" + totalCaserio + "</strong></td></tr>");
                        out.println("</tbody></table></div>");
                    }
                } else {
                    out.println("<p style='color:#999;margin-top:30px'>No hay resultados disponibles.</p>");
                }
            } else {
                out.println("<p style='color:#999;margin-top:30px'>No hay resultados disponibles.</p>");
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

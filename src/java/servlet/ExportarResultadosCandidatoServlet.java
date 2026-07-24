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

@WebServlet(name = "ExportarResultadosCandidatoServlet", urlPatterns = {"/ExportarResultadosCandidatoServlet"})
public class ExportarResultadosCandidatoServlet extends HttpServlet {

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
            out.println("<title>Resultados por Candidato</title>");
            out.println("<style>");
            out.println("@page{size:A4 portrait;margin:18mm 15mm}");
            out.println("body{font-family:'Times New Roman',Times,serif;font-size:16px;color:#1a1a1a;text-align:center;margin:0;padding:15px}");
            out.println("h1{font-size:20px;margin-bottom:2px;text-align:center;color:#000;font-weight:bold;text-transform:uppercase;letter-spacing:1px}");
            out.println("h2{font-size:16px;font-weight:bold;color:#222;margin-top:0;margin-bottom:2px;text-align:center}");
            out.println(".total{font-size:15px;color:#000;margin:8px 0 16px 0;text-align:center;font-weight:bold}");
            out.println("table{margin:0 auto;border-collapse:collapse;min-width:65%}");
            out.println("th{border-bottom:2px solid #000;padding:8px 12px;font-size:14px;text-align:center;font-weight:bold;color:#000}");
            out.println("td{padding:7px 10px;border-bottom:1px solid #999;font-size:15px;text-align:center;color:#000}");
            out.println("tr:nth-child(even){background:#f2f2f2}");
            out.println("tr:last-child td{border-bottom:2px solid #000}");
            out.println(".color-dot{display:inline-block;width:13px;height:13px;border-radius:50%;margin-right:4px;vertical-align:middle}");
            out.println(".footer{text-align:center;margin-top:18px;font-size:12px;color:#888}");
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
                out.println("<h2>Resultados por Candidato</h2>");
                out.println("<p style='color:#999;margin-top:40px'>No existe elecci\u00f3n activa o finalizada.</p>");
                out.println("</body></html>");
                return;
            }

            Map<String, Object> activa = gson.fromJson(gson.toJson(respActiva.getDatos()), Map.class);
            int idEleccion = ((Double) activa.get("idEleccion")).intValue();
            int totalVotos = ((Double) activa.get("totalVotos")).intValue();
            int votosBlancos = ((Double) activa.get("votosBlanco")).intValue();

            RespuestaApiDTO respCandidatos = resultadoService.obtenerPorCandidato(idEleccion, token);

            out.println("<h2>Resultados por Candidato - " + e((String) activa.get("nombreEleccion")) + "</h2>");
            out.println("<div class='total'>Total de votos: <strong>" + totalVotos + "</strong> &nbsp;|&nbsp; Votos blancos: <strong>" + votosBlancos + "</strong></div>");

            if (respCandidatos != null && respCandidatos.isExito() && respCandidatos.getDatos() != null) {
                String json = gson.toJson(respCandidatos.getDatos());
                List<Map<String, Object>> resultados = gson.fromJson(json, List.class);

                if (!resultados.isEmpty()) {
                    out.println("<table><thead><tr><th style='width:40px'>N\u00b0</th><th>Candidato</th><th>Partido</th><th>Votos</th><th>%</th></tr></thead><tbody>");
                    int cont = 0;
                    for (Map<String, Object> fila : resultados) {
                        cont++;
                        int votos = ((Double) fila.get("totalVotos")).intValue();
                        double pct = totalVotos > 0 ? (double) votos / totalVotos * 100 : 0;
                        String color = fila.get("color") != null ? (String) fila.get("color") : "#3949ab";
                        out.println("<tr><td>" + cont + "</td><td><strong>" + e((String) fila.get("nombreCandidato")) + "</strong></td><td><span class='color-dot' style='background:" + color + "'></span>" + e((String) fila.get("nombrePartido")) + "</td><td>" + votos + "</td><td>" + String.format("%.1f", pct) + "%</td></tr>");
                    }
                    out.println("<tr class='total-row' style='background:#d9d9d9;font-weight:bold;border-top:2px solid #000'><td></td><td><strong>Total</strong></td><td></td><td><strong>" + totalVotos + "</strong></td><td><strong>100%</strong></td></tr>");
                    out.println("</tbody></table>");
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

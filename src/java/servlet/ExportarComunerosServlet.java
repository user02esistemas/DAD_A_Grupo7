package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.ComuneroDTO;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Type;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import servicio.ComuneroServicio;

@WebServlet("/ExportarComunerosServlet")
public class ExportarComunerosServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ComuneroServicio comuneroService = new ComuneroServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String token = (String) session.getAttribute("token");
        if (token == null || token.isEmpty()) {
            resp.sendRedirect("IniciarSesionServlet");
            return;
        }

        int idCaserio = 0;
        String idParam = req.getParameter("idCaserio");
        String titulo = "Listado General de Comuneros por Caser\u00edo";
        if (idParam != null && !idParam.isBlank()) {
            try { idCaserio = Integer.parseInt(idParam); } catch (NumberFormatException ignored) {}
        }

        RespuestaApiDTO respApi = comuneroService.listar(token, 1, 9999, null, idCaserio);
        List<ComuneroDTO> comuneros = new ArrayList<>();
        if (respApi != null && respApi.isExito() && respApi.getDatos() != null) {
            String json = gson.toJson(respApi.getDatos());
            Type listType = new TypeToken<List<ComuneroDTO>>() {}.getType();
            comuneros = gson.fromJson(json, listType);
        }

        if (idCaserio > 0 && !comuneros.isEmpty()) {
            String cs = comuneros.get(0).getNombreCaserio();
            if (cs != null && !cs.isEmpty()) titulo = "Listado de Comuneros - " + cs;
        }

        resp.setContentType("text/html;charset=UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.println("<!DOCTYPE html><html lang='es'>");
            out.println("<head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'>");
            out.println("<title>" + titulo + "</title>");
            out.println("<style>");
            out.println("@page{size:A4 landscape;margin:15mm}");
            out.println("body{font-family:'Times New Roman',Times,serif;font-size:15px;color:#1a1a1a;text-align:center;margin:0;padding:10px}");
            out.println("h1{font-size:20px;margin-bottom:2px;text-align:center;color:#000;font-weight:bold;text-transform:uppercase;letter-spacing:1px}");
            out.println("h2{font-size:16px;font-weight:bold;color:#222;margin-top:0;margin-bottom:15px;text-align:center}");
            out.println("table{border-collapse:collapse;margin:0;width:100%;table-layout:fixed}");
            out.println("th{border-bottom:2px solid #000;padding:8px 10px;font-size:14px;text-align:left;font-weight:bold;color:#000;vertical-align:middle}");
            out.println("td{padding:6px 10px;border-bottom:1px solid #ccc;font-size:14px;text-align:left;color:#000;vertical-align:middle}");
            out.println("tr:nth-child(even){background:#f2f2f2}");
            out.println(".footer{text-align:center;margin-top:18px;font-size:11px;color:#888}");
            out.println("@media print{");
            out.println("body{font-size:14px;padding:5px}");
            out.println("th{font-size:13px;padding:6px 8px}");
            out.println("td{font-size:13px;padding:5px 8px}");
            out.println("h1{font-size:18px}");
            out.println("h2{font-size:15px}");
            out.println("}");
            out.println("</style></head><body>");
            out.println("<h1>COMUNIDAD CAMPESINA SAN PEDRO DE M\u00d3RROPE</h1>");
            out.println("<h2>" + e(titulo) + "</h2>");
            out.println("<div style='margin:0 auto;width:750px;text-align:left'>");

            if (comuneros.isEmpty()) {
                out.println("<p style='color:#999;margin-top:30px'>No hay comuneros registrados</p>");
            } else {
                String caserioActual = "";
                int contador = 0;
                int grupoCaserio = 0;
                for (ComuneroDTO c : comuneros) {
                    String cs = c.getNombreCaserio() != null ? c.getNombreCaserio() : "Sin caser\u00edo";
                    if (!cs.equals(caserioActual)) {
                        if (!caserioActual.isEmpty()) {
                            out.println("</tbody></table>");
                        }
                        caserioActual = cs;
                        grupoCaserio++;
                        out.println("<div style='font-size:15px;font-weight:bold;margin:14px 0 4px 0;border-bottom:2px solid #000;padding:4px 0'>" + grupoCaserio + ". " + e(cs) + "</div>");
                        out.println("<table><thead><tr>");
                        out.println("<th style='width:40px;text-align:center'>N\u00b0</th><th style='width:100px'>DNI</th><th>Nombres y Apellidos</th><th style='width:140px'>Mesa de Sufragio</th><th style='width:140px'>Caser\u00edo</th>");
                        out.println("</tr></thead><tbody>");
                    }
                    contador++;
                    String mesa = c.getCodigoMesa() != null ? c.getCodigoMesa() : "-";
                    out.println("<tr>");
                    out.println("<td style='text-align:center'>" + contador + "</td>");
                    out.println("<td>" + e(c.getDni()) + "</td>");
                    out.println("<td>" + e(c.getNombres() + " " + c.getApellidos()) + "</td>");
                    out.println("<td>" + e(mesa) + "</td>");
                    out.println("<td>" + e(cs) + "</td>");
                    out.println("</tr>");
                }
                if (!comuneros.isEmpty()) {
                    out.println("</tbody></table>");
                }
            }

            out.println("</div>");
            out.println("<div class='footer'>Generado el " + LocalDate.now() + " - SVE Comunidad Campesina San Pedro de M\u00f3rrope</div>");
            out.println("<script>window.onload=function(){window.print();}</script>");
            out.println("</body></html>");
        }
    }

    private String e(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}

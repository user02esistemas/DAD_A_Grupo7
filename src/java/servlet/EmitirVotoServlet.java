package servlet;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;
import servicio.VotacionServicio;

@WebServlet("/EmitirVotoServlet")
public class EmitirVotoServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final VotacionServicio votacionService = new VotacionServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            StringBuilder sb = new StringBuilder();
            BufferedReader reader = req.getReader();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            String body = sb.toString();
            Type mapType = new TypeToken<Map<String, Object>>() {}.getType();
            Map<String, Object> params = gson.fromJson(body, mapType);

            long idComunero = ((Number) params.get("idComunero")).longValue();
            Number idCandidatoNum = (Number) params.get("idCandidato");
            Long idCandidato = idCandidatoNum != null ? idCandidatoNum.longValue() : null;
            boolean esVotoBlanco = Boolean.TRUE.equals(params.get("esVotoBlanco"));

            RespuestaApiDTO respApi = votacionService.emitirVoto(idComunero, idCandidato, esVotoBlanco);
            Map<String, Object> jsonResponse = new HashMap<>();
            if (respApi != null && respApi.isExito()) {
                jsonResponse.put("success", true);
                jsonResponse.put("mensaje", respApi.getMensaje() != null ? respApi.getMensaje() : "Voto emitido exitosamente");
            } else {
                jsonResponse.put("success", false);
                jsonResponse.put("mensaje", respApi != null ? respApi.getMensaje() : "Error al emitir voto");
            }
            out.print(gson.toJson(jsonResponse));
        } catch (Exception e) {
            System.out.println("Error en EmitirVotoServlet: " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> errorResp = new HashMap<>();
            errorResp.put("success", false);
            errorResp.put("mensaje", "Error de conexi\u00f3n");
            out.print(gson.toJson(errorResp));
        }
        out.flush();
    }
}

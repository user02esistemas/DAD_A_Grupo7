package servicio;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.CandidatoDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.lang.reflect.Type;
import java.util.*;

public class VotacionServicio {

    private final Gson gson = new Gson();
    
    public RespuestaApiDTO obtenerActiva() throws IOException {
        return ApiCliente.get("/api/resultados/activa", null);
    }
    
    public RespuestaApiDTO verificarVotante(String dni, String codigoPersonal, String claveVotacion) throws IOException {
        Map<String, String> body = new HashMap<>();
        body.put("dni", dni);
        body.put("codigoPersonal", codigoPersonal);
        body.put("claveVotacion", claveVotacion);
        return ApiCliente.post("/api/votacion/verificar", body, null);
    }
    
    public RespuestaApiDTO emitirVoto(long idComunero, Long idCandidato, boolean esBlanco) throws IOException {
        Map<String, Object> body = new HashMap<>();
        body.put("idComunero", idComunero);
        body.put("esVotoBlanco", esBlanco);
        if (!esBlanco && idCandidato != null) body.put("idCandidato", idCandidato);
        return ApiCliente.post("/api/votacion/emitir", body, null);
    }
    
    public List<CandidatoDTO> listarCandidatos(long idEleccion) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/votacion/candidatos/" + idEleccion, null);
        if (resp != null && resp.isExito() && resp.getDatos() != null) {
            Type listType = new TypeToken<List<CandidatoDTO>>() {}.getType();
            String json = gson.toJson(resp.getDatos());
            return gson.fromJson(json, listType);
        }
        return new ArrayList<>();
    }
    
    public Map<String, Object> parsearMapa(RespuestaApiDTO resp) {
        if (resp == null || resp.getDatos() == null) return new HashMap<>();
        String json = gson.toJson(resp.getDatos());
        return gson.fromJson(json, Map.class);
    }
}

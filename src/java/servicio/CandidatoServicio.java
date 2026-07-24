package servicio;

import dto.CandidatoDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class CandidatoServicio {
    
    public List<CandidatoDTO> listarPorEleccion(long idEleccion, String token) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/candidatos?idEleccion=" + idEleccion, token);
        return ApiCliente.parsearLista(resp, CandidatoDTO.class);
    }
    
    public RespuestaApiDTO obtener(long id, String token) throws IOException {
        return ApiCliente.get("/api/candidatos/" + id, token);
    }
    
    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/candidatos", datos, token);
    }
    
    public RespuestaApiDTO actualizar(long id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/candidatos/" + id, datos, token);
    }
    
    public RespuestaApiDTO cambiarEstado(long id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("activo", activo);
        return ApiCliente.post("/api/candidatos/" + id + "/estado", m, token);
    }
}

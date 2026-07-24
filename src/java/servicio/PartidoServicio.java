package servicio;

import dto.PartidoDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class PartidoServicio {
    
    public List<PartidoDTO> listarPorEleccion(long idEleccion, String token) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/partidos?idEleccion=" + idEleccion, token);
        return ApiCliente.parsearLista(resp, PartidoDTO.class);
    }
    
    public RespuestaApiDTO listar(String token) throws IOException {
        return ApiCliente.get("/api/partidos", token);
    }
    
    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/partidos", datos, token);
    }
    
    public RespuestaApiDTO actualizar(long id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/partidos/" + id, datos, token);
    }
    
    public RespuestaApiDTO cambiarEstado(long id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("activo", activo);
        return ApiCliente.post("/api/partidos/" + id + "/estado", m, token);
    }
}

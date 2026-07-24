package servicio;

import dto.ComuneroDTO;
import dto.MiembroMesaDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class MiembroMesaServicio {

    public List<MiembroMesaDTO> listar(String token, int idCaserio) throws IOException {
        String ep = "/api/miembros-mesa";
        if (idCaserio > 0) ep += "?idCaserio=" + idCaserio;
        RespuestaApiDTO resp = ApiCliente.get(ep, token);
        return ApiCliente.parsearLista(resp, MiembroMesaDTO.class);
    }

    public List<ComuneroDTO> listarComunerosDisponibles(String token, int idCaserio) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/miembros-mesa/comuneros-disponibles/" + idCaserio, token);
        return ApiCliente.parsearLista(resp, ComuneroDTO.class);
    }

    public int conteo(String token, int idCaserio) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/miembros-mesa/conteo/" + idCaserio, token);
        if (resp != null && resp.getDatos() != null) {
            Map<String, Object> m = (Map<String, Object>) resp.getDatos();
            Object t = m.get("total");
            if (t instanceof Number) return ((Number) t).intValue();
        }
        return 0;
    }

    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/miembros-mesa", datos, token);
    }

    public RespuestaApiDTO eliminar(long id, String token) throws IOException {
        return ApiCliente.delete("/api/miembros-mesa/" + id, token);
    }
}

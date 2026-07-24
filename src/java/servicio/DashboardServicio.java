package servicio;

import dto.RespuestaApiDTO;
import java.io.IOException;

public class DashboardServicio {
    
    public RespuestaApiDTO obtenerKpis(String token) throws IOException {
        return ApiCliente.get("/api/dashboard", token);
    }
    
    public RespuestaApiDTO datosParticipacion(String token) throws IOException {
        return ApiCliente.get("/api/dashboard/participacion", token);
    }
}

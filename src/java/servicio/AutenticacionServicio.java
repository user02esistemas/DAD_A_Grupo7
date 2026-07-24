package servicio;

import com.google.gson.Gson;
import dto.RespuestaApiDTO;
import dto.UsuarioDTO;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class AutenticacionServicio {
    private static final Gson gson = new Gson();
    
    public RespuestaApiDTO iniciarSesion(String nombreUsuario, String contrasena) throws IOException {
        Map<String, String> body = new HashMap<>();
        body.put("nombreUsuario", nombreUsuario);
        body.put("contrasena", contrasena);
        return ApiCliente.post("/api/autenticacion/iniciar-sesion", body, null);
    }
    
    public RespuestaApiDTO cerrarSesion(String token) throws IOException {
        return ApiCliente.post("/api/autenticacion/cerrar-sesion", null, token);
    }
    
    public RespuestaApiDTO verificarToken(String token) throws IOException {
        return ApiCliente.get("/api/autenticacion/verificar", token);
    }
}

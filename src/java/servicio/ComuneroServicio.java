package servicio;

import dto.ComuneroDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class ComuneroServicio {

    public RespuestaApiDTO listar(String token, int pagina, int porPagina, String busqueda, int idCaserio) throws IOException {
        String ep = "/api/comuneros?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty())
            ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        if (idCaserio > 0)
            ep += "&idCaserio=" + idCaserio;
        return ApiCliente.get(ep, token);
    }

    public RespuestaApiDTO obtener(String token, int id) throws IOException {
        return ApiCliente.get("/api/comuneros/" + id, token);
    }

    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/comuneros", datos, token);
    }

    public RespuestaApiDTO actualizar(int id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/comuneros/" + id, datos, token);
    }

    public RespuestaApiDTO cambiarEstado(int id, int estado, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("estado", estado);
        return ApiCliente.post("/api/comuneros/" + id + "/estado", m, token);
    }

    public RespuestaApiDTO desactivarTodos(String token) throws IOException {
        return ApiCliente.post("/api/comuneros/desactivar-todos", Collections.emptyMap(), token);
    }

    public RespuestaApiDTO activarTodos(String token) throws IOException {
        return ApiCliente.post("/api/comuneros/activar-todos", Collections.emptyMap(), token);
    }
}

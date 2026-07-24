package servicio;

import dto.LocalVotacionDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class LocalVotacionServicio {
    
    public List<LocalVotacionDTO> listarActivos(String token, int idCaserio) throws IOException {
        String ep = "/api/locales-votacion/activos";
        if (idCaserio > 0) ep += "?idCaserio=" + idCaserio;
        RespuestaApiDTO resp = ApiCliente.get(ep, token);
        return ApiCliente.parsearLista(resp, LocalVotacionDTO.class);
    }
    
    public RespuestaApiDTO listar(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String ep = "/api/locales-votacion?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(ep, token);
    }
    
    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/locales-votacion", datos, token);
    }
    
    public RespuestaApiDTO actualizar(int id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/locales-votacion/" + id, datos, token);
    }
    
    public RespuestaApiDTO cambiarEstado(int id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("activo", activo);
        return ApiCliente.post("/api/locales-votacion/" + id + "/estado", m, token);
    }
}

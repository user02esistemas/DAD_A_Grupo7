package servicio;

import dto.MesaSufragioDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class MesaSufragioServicio {
    
    public List<MesaSufragioDTO> listarActivas(String token, int idCaserio) throws IOException {
        String ep = "/api/mesas-sufragio/activas";
        if (idCaserio > 0) ep += "?idCaserio=" + idCaserio;
        RespuestaApiDTO resp = ApiCliente.get(ep, token);
        return ApiCliente.parsearLista(resp, MesaSufragioDTO.class);
    }
    
    public RespuestaApiDTO listar(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String ep = "/api/mesas-sufragio?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(ep, token);
    }
    
    public RespuestaApiDTO crear(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/mesas-sufragio", datos, token);
    }
    
    public RespuestaApiDTO actualizar(int id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/mesas-sufragio/" + id, datos, token);
    }
    
    public RespuestaApiDTO cambiarEstado(int id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("activo", activo);
        return ApiCliente.post("/api/mesas-sufragio/" + id + "/estado", m, token);
    }
}

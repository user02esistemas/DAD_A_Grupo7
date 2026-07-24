package servicio;

import dto.CaserioDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class CaserioServicio {
    
    public List<CaserioDTO> listarCaseriosActivos(String token) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/caserios/activos", token);
        return ApiCliente.parsearLista(resp, CaserioDTO.class);
    }
    
    public RespuestaApiDTO listarCaserios(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String ep = "/api/caserios?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(ep, token);
    }
    
    public RespuestaApiDTO crearCaserio(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/caserios", datos, token);
    }
    
    public RespuestaApiDTO actualizarCaserio(int id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/caserios/" + id, datos, token);
    }
    
    public CaserioDTO obtener(String token, int id) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/caserios/" + id, token);
        return ApiCliente.parsearObjeto(resp, CaserioDTO.class);
    }

    public RespuestaApiDTO cambiarEstado(int id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("activo", activo);
        return ApiCliente.post("/api/caserios/" + id + "/estado", m, token);
    }
}

package servicio;

import dto.EleccionDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class EleccionServicio {

    public RespuestaApiDTO listarElecciones(String token, int pagina, String busqueda) throws IOException {
        String ep = "/api/elecciones?pagina=" + pagina + "&por_pagina=20";
        if (busqueda != null && !busqueda.isEmpty()) ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(ep, token);
    }

    public EleccionDTO obtenerEleccionActiva() throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/elecciones/activa", null);
        return ApiCliente.parsearObjeto(resp, EleccionDTO.class);
    }

    public RespuestaApiDTO obtenerEleccion(long id, String token) throws IOException {
        return ApiCliente.get("/api/elecciones/" + id, token);
    }

    public RespuestaApiDTO crearEleccion(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/elecciones", datos, token);
    }

    public RespuestaApiDTO actualizarEleccion(long id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/elecciones/" + id, datos, token);
    }
}

package servicio;

import dto.RespuestaApiDTO;
import java.io.IOException;

public class AuditoriaServicio {

    public RespuestaApiDTO listar(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String ep = "/api/auditoria?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) ep += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(ep, token);
    }
}

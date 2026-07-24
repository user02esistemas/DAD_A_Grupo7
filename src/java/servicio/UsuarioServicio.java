package servicio;

import dto.RespuestaApiDTO;
import dto.RolDTO;
import dto.UsuarioDTO;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class UsuarioServicio {
    
    public List<UsuarioDTO> listarUsuarios(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String endpoint = "/api/usuarios?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) endpoint += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        RespuestaApiDTO resp = ApiCliente.get(endpoint, token);
        return ApiCliente.parsearLista(resp, UsuarioDTO.class);
    }
    
    public RespuestaApiDTO obtenerPaginacion(String token, int pagina, int porPagina, String busqueda) throws IOException {
        String endpoint = "/api/usuarios?pagina=" + pagina + "&por_pagina=" + porPagina;
        if (busqueda != null && !busqueda.isEmpty()) endpoint += "&busqueda=" + java.net.URLEncoder.encode(busqueda, "UTF-8");
        return ApiCliente.get(endpoint, token);
    }
    
    public RespuestaApiDTO obtenerUsuario(long id, String token) throws IOException {
        return ApiCliente.get("/api/usuarios/" + id, token);
    }
    
    public RespuestaApiDTO crearUsuario(Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/usuarios", datos, token);
    }
    
    public RespuestaApiDTO actualizarUsuario(long id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.put("/api/usuarios/" + id, datos, token);
    }
    
    public RespuestaApiDTO cambiarContrasena(long id, Map<String, Object> datos, String token) throws IOException {
        return ApiCliente.post("/api/usuarios/" + id + "/cambiar-contrasena", datos, token);
    }
    
    public RespuestaApiDTO eliminarUsuario(long id, String token) throws IOException {
        return ApiCliente.delete("/api/usuarios/" + id, token);
    }

    public RespuestaApiDTO cambiarEstado(long id, boolean activo, String token) throws IOException {
        Map<String, Object> m = new HashMap<>();
        m.put("estado", activo ? "ACTIVO" : "INACTIVO");
        return ApiCliente.put("/api/usuarios/" + id, m, token);
    }

    public List<RolDTO> listarRoles(String token) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/roles", token);
        return ApiCliente.parsearLista(resp, RolDTO.class);
    }
}

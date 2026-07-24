package servicio;

import dto.MesaSufragioDTO;
import dto.RespuestaApiDTO;
import java.io.IOException;
import java.util.*;

public class ResultadoServicio {

    public RespuestaApiDTO obtenerActiva(String token) throws IOException {
        return ApiCliente.get("/api/resultados/activa", token);
    }

    public RespuestaApiDTO obtenerPorCandidato(int idEleccion, String token) throws IOException {
        return ApiCliente.get("/api/resultados/por-candidato/" + idEleccion, token);
    }

    public RespuestaApiDTO obtenerPorCandidatoYCaserio(int idEleccion, int idCaserio, String token) throws IOException {
        return ApiCliente.get("/api/resultados/por-candidato/" + idEleccion + "?idCaserio=" + idCaserio, token);
    }

    public RespuestaApiDTO obtenerPorCandidatoYCaserioYMesa(int idEleccion, int idCaserio, int idMesa, String token) throws IOException {
        return ApiCliente.get("/api/resultados/por-candidato/" + idEleccion + "?idCaserio=" + idCaserio + "&idMesa=" + idMesa, token);
    }

    public RespuestaApiDTO obtenerPorCaserio(int idEleccion, String token) throws IOException {
        return ApiCliente.get("/api/resultados/por-caserio/" + idEleccion, token);
    }

    public RespuestaApiDTO obtenerGeneralCompleto(int idEleccion, String token) throws IOException {
        return ApiCliente.get("/api/resultados/general-completo/" + idEleccion, token);
    }

    public RespuestaApiDTO obtenerPorMesaCaserio(int idEleccion, int idCaserio, String token) throws IOException {
        return ApiCliente.get("/api/resultados/por-mesa-caserio/" + idEleccion + "/" + idCaserio, token);
    }

    public List<MesaSufragioDTO> listarMesasPorCaserio(String token, int idCaserio) throws IOException {
        RespuestaApiDTO resp = ApiCliente.get("/api/mesas-sufragio/activas?idCaserio=" + idCaserio, token);
        if (resp != null && resp.isExito() && resp.getDatos() != null) {
            return ApiCliente.parsearLista(resp, MesaSufragioDTO.class);
        }
        return new ArrayList<>();
    }
}

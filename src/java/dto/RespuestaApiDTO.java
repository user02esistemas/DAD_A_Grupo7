package dto;

import com.google.gson.annotations.SerializedName;

public class RespuestaApiDTO {

    private boolean exito;
    private String mensaje;
    private Object datos;
    private int total;
    private int pagina;

    @SerializedName("por_pagina")
    private int porPagina;

    @SerializedName("total_paginas")
    private int totalPaginas;

    public boolean isExito() {
        return exito;
    }

    public void setExito(boolean exito) {
        this.exito = exito;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public Object getDatos() {
        return datos;
    }

    public void setDatos(Object datos) {
        this.datos = datos;
    }

    public int getTotal() {
        return total;
    }

    public void setTotal(int total) {
        this.total = total;
    }

    public int getPagina() {
        return pagina;
    }

    public void setPagina(int pagina) {
        this.pagina = pagina;
    }

    public int getPorPagina() {
        return porPagina;
    }

    public void setPorPagina(int porPagina) {
        this.porPagina = porPagina;
    }

    public int getTotalPaginas() {
        return totalPaginas;
    }

    public void setTotalPaginas(int totalPaginas) {
        this.totalPaginas = totalPaginas;
    }
}

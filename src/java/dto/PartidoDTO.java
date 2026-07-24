package dto;

public class PartidoDTO {

    private long idPartido;
    private long idEleccion;
    private String nombreEleccion;
    private String nombrePartido;
    private String descripcion;
    private String propuestas;
    private String color;
    private boolean activo;

    public long getIdPartido() {
        return idPartido;
    }

    public void setIdPartido(long idPartido) {
        this.idPartido = idPartido;
    }

    public long getIdEleccion() {
        return idEleccion;
    }

    public void setIdEleccion(long idEleccion) {
        this.idEleccion = idEleccion;
    }

    public String getNombreEleccion() {
        return nombreEleccion;
    }

    public void setNombreEleccion(String nombreEleccion) {
        this.nombreEleccion = nombreEleccion;
    }

    public String getNombrePartido() {
        return nombrePartido;
    }

    public void setNombrePartido(String nombrePartido) {
        this.nombrePartido = nombrePartido;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getPropuestas() {
        return propuestas;
    }

    public void setPropuestas(String propuestas) {
        this.propuestas = propuestas;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

package dto;

public class CaserioDTO {

    private int idCaserio;
    private String nombreCaserio;
    private String descripcion;
    private boolean activo;

    public int getIdCaserio() {
        return idCaserio;
    }

    public void setIdCaserio(int idCaserio) {
        this.idCaserio = idCaserio;
    }

    public String getNombreCaserio() {
        return nombreCaserio;
    }

    public void setNombreCaserio(String nombreCaserio) {
        this.nombreCaserio = nombreCaserio;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

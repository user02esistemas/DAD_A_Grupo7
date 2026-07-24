package dto;

public class LocalVotacionDTO {

    private int idLocalVotacion;
    private int idCaserio;
    private String nombreCaserio;
    private String nombreLocal;
    private String direccion;
    private String referencia;
    private boolean activo;

    public int getIdLocalVotacion() {
        return idLocalVotacion;
    }

    public void setIdLocalVotacion(int idLocalVotacion) {
        this.idLocalVotacion = idLocalVotacion;
    }

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

    public String getNombreLocal() {
        return nombreLocal;
    }

    public void setNombreLocal(String nombreLocal) {
        this.nombreLocal = nombreLocal;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }

    public String getReferencia() {
        return referencia;
    }

    public void setReferencia(String referencia) {
        this.referencia = referencia;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

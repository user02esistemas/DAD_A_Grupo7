package dto;

public class MiembroMesaDTO {

    private long idMiembroMesa;
    private long idComunero;
    private String dniComunero;
    private String nombreComunero;
    private int idCaserio;
    private String nombreCaserio;
    private Integer idMesaSufragio;
    private String codigoMesa;
    private String nombreLocal;
    private String cargo;
    private boolean activo;
    private String fechaAsignacion;

    public long getIdMiembroMesa() {
        return idMiembroMesa;
    }

    public void setIdMiembroMesa(long idMiembroMesa) {
        this.idMiembroMesa = idMiembroMesa;
    }

    public long getIdComunero() {
        return idComunero;
    }

    public void setIdComunero(long idComunero) {
        this.idComunero = idComunero;
    }

    public String getDniComunero() {
        return dniComunero;
    }

    public void setDniComunero(String dniComunero) {
        this.dniComunero = dniComunero;
    }

    public String getNombreComunero() {
        return nombreComunero;
    }

    public void setNombreComunero(String nombreComunero) {
        this.nombreComunero = nombreComunero;
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

    public Integer getIdMesaSufragio() {
        return idMesaSufragio;
    }

    public void setIdMesaSufragio(Integer idMesaSufragio) {
        this.idMesaSufragio = idMesaSufragio;
    }

    public String getCodigoMesa() {
        return codigoMesa;
    }

    public void setCodigoMesa(String codigoMesa) {
        this.codigoMesa = codigoMesa;
    }

    public String getNombreLocal() {
        return nombreLocal;
    }

    public void setNombreLocal(String nombreLocal) {
        this.nombreLocal = nombreLocal;
    }

    public String getCargo() {
        return cargo;
    }

    public void setCargo(String cargo) {
        this.cargo = cargo;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public String getFechaAsignacion() {
        return fechaAsignacion;
    }

    public void setFechaAsignacion(String fechaAsignacion) {
        this.fechaAsignacion = fechaAsignacion;
    }
}

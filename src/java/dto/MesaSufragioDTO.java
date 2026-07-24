package dto;

public class MesaSufragioDTO {

    private int idMesaSufragio;
    private String codigoMesa;
    private int idLocalVotacion;
    private String nombreLocal;
    private int idCaserio;
    private String nombreCaserio;
    private String horaApertura;
    private String horaCierre;
    private int capacidadMaxima;
    private boolean activo;

    public int getIdMesaSufragio() {
        return idMesaSufragio;
    }

    public void setIdMesaSufragio(int idMesaSufragio) {
        this.idMesaSufragio = idMesaSufragio;
    }

    public String getCodigoMesa() {
        return codigoMesa;
    }

    public void setCodigoMesa(String codigoMesa) {
        this.codigoMesa = codigoMesa;
    }

    public int getIdLocalVotacion() {
        return idLocalVotacion;
    }

    public void setIdLocalVotacion(int idLocalVotacion) {
        this.idLocalVotacion = idLocalVotacion;
    }

    public String getNombreLocal() {
        return nombreLocal;
    }

    public void setNombreLocal(String nombreLocal) {
        this.nombreLocal = nombreLocal;
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

    public String getHoraApertura() {
        return horaApertura;
    }

    public void setHoraApertura(String horaApertura) {
        this.horaApertura = horaApertura;
    }

    public String getHoraCierre() {
        return horaCierre;
    }

    public void setHoraCierre(String horaCierre) {
        this.horaCierre = horaCierre;
    }

    public int getCapacidadMaxima() {
        return capacidadMaxima;
    }

    public void setCapacidadMaxima(int capacidadMaxima) {
        this.capacidadMaxima = capacidadMaxima;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

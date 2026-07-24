package dto;

public class EleccionDTO {

    private long idEleccion;
    private String nombreEleccion;
    private String fechaInicioInscripcion;
    private String fechaCierreInscripcion;
    private String horaInicioInscripcion;
    private String horaFinInscripcion;
    private String fechaVotacion;
    private String horaInicioVotacion;
    private String horaFinVotacion;
    private String estado;
    private boolean activa;
    private String descripcion;

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

    public String getFechaInicioInscripcion() {
        return fechaInicioInscripcion;
    }

    public void setFechaInicioInscripcion(String fechaInicioInscripcion) {
        this.fechaInicioInscripcion = fechaInicioInscripcion;
    }

    public String getFechaCierreInscripcion() {
        return fechaCierreInscripcion;
    }

    public void setFechaCierreInscripcion(String fechaCierreInscripcion) {
        this.fechaCierreInscripcion = fechaCierreInscripcion;
    }

    public String getHoraInicioInscripcion() {
        return horaInicioInscripcion;
    }

    public void setHoraInicioInscripcion(String horaInicioInscripcion) {
        this.horaInicioInscripcion = horaInicioInscripcion;
    }

    public String getHoraFinInscripcion() {
        return horaFinInscripcion;
    }

    public void setHoraFinInscripcion(String horaFinInscripcion) {
        this.horaFinInscripcion = horaFinInscripcion;
    }

    public String getFechaVotacion() {
        return fechaVotacion;
    }

    public void setFechaVotacion(String fechaVotacion) {
        this.fechaVotacion = fechaVotacion;
    }

    public String getHoraInicioVotacion() {
        return horaInicioVotacion;
    }

    public void setHoraInicioVotacion(String horaInicioVotacion) {
        this.horaInicioVotacion = horaInicioVotacion;
    }

    public String getHoraFinVotacion() {
        return horaFinVotacion;
    }

    public void setHoraFinVotacion(String horaFinVotacion) {
        this.horaFinVotacion = horaFinVotacion;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public boolean isActiva() {
        return activa;
    }

    public void setActiva(boolean activa) {
        this.activa = activa;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }
}

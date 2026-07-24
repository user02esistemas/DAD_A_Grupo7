package dto;

public class CandidatoDTO {

    private long idCandidato;
    private long idPartido;
    private String nombrePartido;
    private String colorPartido;
    private String nombres;
    private String apellidos;
    private String cargo;
    private String integrantes;
    private String imagen;
    private boolean activo;

    public long getIdCandidato() {
        return idCandidato;
    }

    public void setIdCandidato(long idCandidato) {
        this.idCandidato = idCandidato;
    }

    public long getIdPartido() {
        return idPartido;
    }

    public void setIdPartido(long idPartido) {
        this.idPartido = idPartido;
    }

    public String getNombrePartido() {
        return nombrePartido;
    }

    public void setNombrePartido(String nombrePartido) {
        this.nombrePartido = nombrePartido;
    }

    public String getColorPartido() {
        return colorPartido;
    }

    public void setColorPartido(String colorPartido) {
        this.colorPartido = colorPartido;
    }

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres;
    }

    public String getApellidos() {
        return apellidos;
    }

    public void setApellidos(String apellidos) {
        this.apellidos = apellidos;
    }

    public String getCargo() {
        return cargo;
    }

    public void setCargo(String cargo) {
        this.cargo = cargo;
    }

    public String getIntegrantes() {
        return integrantes;
    }

    public void setIntegrantes(String integrantes) {
        this.integrantes = integrantes;
    }

    public String getImagen() {
        return imagen;
    }

    public void setImagen(String imagen) {
        this.imagen = imagen;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}

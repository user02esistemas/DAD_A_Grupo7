package dto;

public class ComuneroDTO {

    private int idComunero;
    private String dni;
    private String nombres;
    private String apellidos;
    private String fechaNacimiento;
    private String sexo;
    private String telefono;
    private String direccion;
    private int idCaserio;
    private String nombreCaserio;
    private int idLocalVotacion;
    private int idMesaSufragio;
    private String codigoMesa;
    private int estado;
    private String codigoPersonal;

    public int getIdComunero() { return idComunero; }
    public void setIdComunero(int idComunero) { this.idComunero = idComunero; }

    public String getDni() { return dni; }
    public void setDni(String dni) { this.dni = dni; }

    public String getNombres() { return nombres; }
    public void setNombres(String nombres) { this.nombres = nombres; }

    public String getApellidos() { return apellidos; }
    public void setApellidos(String apellidos) { this.apellidos = apellidos; }

    public String getFechaNacimiento() { return fechaNacimiento; }
    public void setFechaNacimiento(String fechaNacimiento) { this.fechaNacimiento = fechaNacimiento; }

    public String getSexo() { return sexo; }
    public void setSexo(String sexo) { this.sexo = sexo; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getDireccion() { return direccion; }
    public void setDireccion(String direccion) { this.direccion = direccion; }

    public int getIdCaserio() { return idCaserio; }
    public void setIdCaserio(int idCaserio) { this.idCaserio = idCaserio; }

    public String getNombreCaserio() { return nombreCaserio; }
    public void setNombreCaserio(String nombreCaserio) { this.nombreCaserio = nombreCaserio; }

    public int getIdLocalVotacion() { return idLocalVotacion; }
    public void setIdLocalVotacion(int idLocalVotacion) { this.idLocalVotacion = idLocalVotacion; }

    public int getIdMesaSufragio() { return idMesaSufragio; }
    public void setIdMesaSufragio(int idMesaSufragio) { this.idMesaSufragio = idMesaSufragio; }

    public String getCodigoMesa() { return codigoMesa; }
    public void setCodigoMesa(String codigoMesa) { this.codigoMesa = codigoMesa; }

    public int getEstado() { return estado; }
    public void setEstado(int estado) { this.estado = estado; }

    public String getCodigoPersonal() { return codigoPersonal; }
    public void setCodigoPersonal(String codigoPersonal) { this.codigoPersonal = codigoPersonal; }

    public boolean isActivo() { return estado == 1; }
}

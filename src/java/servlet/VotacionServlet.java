package servlet;

import com.google.gson.Gson;
import dto.CandidatoDTO;
import dto.RespuestaApiDTO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import servicio.VotacionServicio;

@WebServlet(name = "VotacionServlet", urlPatterns = {"/VotacionServlet"})
public class VotacionServlet extends HttpServlet {

    private final VotacionServicio votacionService = new VotacionServicio();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.removeAttribute("votanteAutenticado");

        try {
            RespuestaApiDTO respActiva = votacionService.obtenerActiva();
            if (respActiva == null || !respActiva.isExito() || respActiva.getDatos() == null) {
                renderizar(resp, "No hay una elecci\u00f3n activa en este momento.", true, null, null, null, req);
                return;
            }
            Map<String, Object> eleccion = votacionService.parsearMapa(respActiva);
            String estado = (String) eleccion.get("estado");
            if ("FINALIZADA".equalsIgnoreCase(estado)) {
                String fechaVot = (String) eleccion.getOrDefault("fechaVotacion", "");
                String horaIni = formatearHora12((String) eleccion.get("horaInicioVotacion"));
                String horaFin = formatearHora12((String) eleccion.get("horaFinVotacion"));
                renderizar(resp, "La votaci\u00f3n ya finaliz\u00f3 el " + fechaVot
                        + " desde las " + horaIni + " hasta las " + horaFin + ".", true, null, null, null, req);
                return;
            }
            renderizar(resp, "", false, eleccion, null, null, req);
        } catch (Exception e) {
            renderizar(resp, "Error al cargar la votaci\u00f3n", true, null, null, null, req);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String paso = req.getParameter("paso");
        if ("autenticar".equals(paso)) {
            autenticarVotante(req, resp);
        } else if ("emitir".equals(paso)) {
            emitirVoto(req, resp);
        } else {
            renderizar(resp, "Acci\u00f3n inv\u00e1lida", true, null, null, null, req);
        }
    }

    private void autenticarVotante(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            RespuestaApiDTO respActiva = votacionService.obtenerActiva();
            if (respActiva == null || !respActiva.isExito() || respActiva.getDatos() == null) {
                renderizar(resp, "No hay una elecci\u00f3n activa.", true, null, null, null, req);
                return;
            }
            Map<String, Object> eleccion = votacionService.parsearMapa(respActiva);
            String estado = (String) eleccion.get("estado");
            if (!"EN_VOTACION".equalsIgnoreCase(estado)) {
                String fechaVot = (String) eleccion.getOrDefault("fechaVotacion", "");
                String horaIni = formatearHora12((String) eleccion.get("horaInicioVotacion"));
                String horaFin = formatearHora12((String) eleccion.get("horaFinVotacion"));
                renderizar(resp, "La votaci\u00f3n no est\u00e1 en horario de votaci\u00f3n ("
                        + horaIni + " - " + horaFin + "). Fecha: " + fechaVot, true, null, null, null, req);
                return;
            }

            String dni = req.getParameter("dni");
            String codigoPersonal = req.getParameter("codigoPersonal");
            String clavePersonal = req.getParameter("clavePersonal");

            if (dni == null || codigoPersonal == null || clavePersonal == null) {
                renderizar(resp, "Todos los campos son requeridos", true, eleccion, null, null, req);
                return;
            }

            RespuestaApiDTO respVerif = votacionService.verificarVotante(dni, codigoPersonal, clavePersonal);
            if (respVerif == null || !respVerif.isExito()) {
                String msg = respVerif != null ? respVerif.getMensaje() : "Error de conexi\u00f3n con el servidor";
                renderizar(resp, msg, true, eleccion, null, null, req);
                return;
            }

            Map<String, Object> datosVotante = votacionService.parsearMapa(respVerif);
            int idEleccion = ((Number) eleccion.get("idEleccion")).intValue();
            List<CandidatoDTO> candidatos = votacionService.listarCandidatos(idEleccion);

            req.getSession().setAttribute("votanteAutenticado", datosVotante);
            renderizar(resp, "", false, eleccion, datosVotante, candidatos, req);
        } catch (Exception e) {
            renderizar(resp, "Error al verificar credenciales", true, null, null, null, req);
        }
    }

    private void emitirVoto(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> votante = (session != null)
                ? (Map<String, Object>) session.getAttribute("votanteAutenticado") : null;
        if (votante == null) {
            renderizar(resp, "Debe autenticarse primero", true, null, null, null, req);
            return;
        }

        try {
            String tipoVoto = req.getParameter("tipoVoto");
            boolean esBlanco = "BLANCO".equalsIgnoreCase(tipoVoto);
            Number idComuneroNum = (Number) votante.get("idComunero");
            long idComunero = idComuneroNum.longValue();
            Long idCandidato = null;

            if (!esBlanco) {
                String idCandidatoStr = req.getParameter("idCandidato");
                if (idCandidatoStr == null || idCandidatoStr.isEmpty()) {
                    renderizar(resp, "Debe seleccionar un candidato o elegir voto en blanco", true, null, null, null, req);
                    return;
                }
                idCandidato = Long.parseLong(idCandidatoStr);
            }

            RespuestaApiDTO respEmitir = votacionService.emitirVoto(idComunero, idCandidato, esBlanco);
            if (respEmitir == null || !respEmitir.isExito()) {
                String msg = respEmitir != null ? respEmitir.getMensaje() : "Error al registrar el voto";
                renderizar(resp, msg, true, null, null, null, req);
                return;
            }

            session.removeAttribute("votanteAutenticado");
            renderizar(resp, "Voto registrado correctamente. Gracias por participar.", false, null, null, null, req);
        } catch (Exception e) {
            renderizar(resp, "Error al emitir el voto", true, null, null, null, req);
        }
    }

    private String imagenToBase64(String rawBase64) {
        if (rawBase64 == null || rawBase64.isEmpty()) return null;
        return "data:image/png;base64," + rawBase64;
    }

    private String formatearHora12(String hora24) {
        if (hora24 == null || hora24.length() < 5) return "";
        String[] partes = hora24.split(":");
        int h = Integer.parseInt(partes[0]);
        int m = Integer.parseInt(partes[1]);
        String ampm = h >= 12 ? "PM" : "AM";
        if (h == 0) h = 12;
        else if (h > 12) h -= 12;
        return h + ":" + String.format("%02d", m) + " " + ampm;
    }

    private String escapar(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private void renderizar(HttpServletResponse resp, String mensaje, boolean error,
            Map<String, Object> eleccion, Map<String, Object> votante,
            List<CandidatoDTO> candidatos, HttpServletRequest req) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.println("<!DOCTYPE html><html lang='es'>");
            out.println("<head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'>");
            out.println("<title>Votaci\u00f3n Digital - SVE CCSPM</title>");
            out.println("<link href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css' rel='stylesheet'>");
            out.println("<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css'>");
            out.println("<script src='https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js'></script>");
            out.println("<link rel='stylesheet' href='frontend/css/public.css'>");
            out.println("<link rel='preconnect' href='https://fonts.googleapis.com'>");
            out.println("<link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>");
            out.println("<link href='https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap' rel='stylesheet'>");
            out.println("<style>");
            out.println("*{font-family:'Inter','Segoe UI',system-ui,sans-serif}");
            out.println("body{background:linear-gradient(135deg,#0f0c29 0%,#1a1a4e 40%,#24243e 100%);min-height:100vh;padding:30px;display:flex;align-items:center}");
            out.println(".voto-card{max-width:900px;margin:0 auto;background:rgba(255,255,255,.98);border-radius:24px;box-shadow:0 30px 80px rgba(0,0,0,.4);overflow:hidden}");
            out.println(".voto-header{background:linear-gradient(135deg,#1a1a4e,#2d2d7f,#4a4ae0);color:#fff;padding:28px 24px;position:relative}");
            out.println(".voto-header::after{content:'';position:absolute;bottom:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#f59e0b,#ef4444,#8b5cf6,#3b82f6)}");
            out.println(".voto-body{padding:32px 28px}");
            out.println(".candidato-card{position:relative;border:2px solid #e8edf2;border-radius:18px;padding:20px 16px;cursor:pointer;transition:all .3s cubic-bezier(.4,0,.2,1);text-align:center;background:#fff}");
            out.println(".candidato-card:hover{border-color:#6366f1;box-shadow:0 12px 32px rgba(99,102,241,.15);transform:translateY(-4px)}");
            out.println(".candidato-card.selected{border-color:#4f46e5;background:linear-gradient(135deg,#eef2ff,#e0e7ff);box-shadow:0 12px 40px rgba(79,70,229,.25)}");
            out.println(".candidato-card.disabled{opacity:.35;pointer-events:none;transform:none}");
            // ═══════════════════════════════════════════════════════
            //  IMAGEN DEL CANDIDATO - AJUSTES PRINCIPALES
            // ═══════════════════════════════════════════════════════
            // width / height  = Tamaño del círculo (píxeles)
            // border-radius   = 50% lo hace circular
            // object-fit      = cover (rellena) / contain (completa visible)
            // border          = grosor, estilo y color del borde
            out.println(".candidato-foto{width:350px;height:350px;border-radius:50%;object-fit:contain;margin-bottom:14px;border:4px solid #e8edf2;transition:all .3s;box-shadow:0 4px 16px rgba(0,0,0,.08);background:#fff}");
            out.println(".candidato-card.selected .candidato-foto{border-color:#4f46e5;box-shadow:0 4px 20px rgba(79,70,229,.3)}");
            // ═══════════════════════════════════════════════════════
            //  PLACEHOLDER CUANDO NO HAY FOTO
            // ═══════════════════════════════════════════════════════
            out.println(".sin-foto{width:200px;height:200px;border-radius:50%;background:linear-gradient(135deg,#e8edf2,#d1d5db);display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:4rem;color:#9ca3af;border:4px solid #e8edf2}");
            out.println(".candidato-card.selected .sin-foto{border-color:#4f46e5}");
            out.println(".partido-badge{display:inline-block;padding:5px 16px;border-radius:20px;color:#fff;font-size:.72rem;font-weight:600;letter-spacing:.3px;margin-top:8px;text-transform:uppercase;box-shadow:0 2px 8px rgba(0,0,0,.1)}");
            out.println(".check-icon{position:absolute;top:12px;right:12px;width:30px;height:30px;border-radius:50%;background:#4f46e5;color:#fff;display:none;align-items:center;justify-content:center;font-size:1.1rem;box-shadow:0 2px 8px rgba(79,70,229,.4)}");
            out.println(".candidato-card.selected .check-icon{display:flex}");
            out.println(".candidato-nombre{font-size:1rem;font-weight:700;color:#1e293b;margin:6px 0 2px}");
            out.println(".candidato-cargo{font-size:.82rem;color:#64748b;font-weight:500}");
            out.println("</style></head><body>");

            out.println("<div class='voto-card'>");
            out.println("<div class='voto-header text-center'>");
            out.println("<h4><i class='bi bi-check2-square me-2'></i>Votaci\u00f3n Digital</h4>");
            out.println("<p class='mb-0' style='opacity:.9'>Comunidad Campesina San Pedro de M\u00f3rrope</p>");
            out.println("</div>");
            out.println("<div class='voto-body'>");

            if (mensaje != null && !mensaje.isEmpty()) {
                String tipo = error ? "danger" : "success";
                String icono = error ? "bi-exclamation-triangle" : "bi-check-circle";
                out.println("<div class='alert alert-" + tipo + " alert-dismissible fade show d-flex align-items-center py-2' role='alert'>");
                out.println("<i class='bi " + icono + " me-2'></i><span>" + escapar(mensaje) + "</span>");
                out.println("<button type='button' class='btn-close' data-bs-dismiss='alert'></button></div>");
            }

            if (votante == null || eleccion == null) {
                boolean finalizada = mensaje != null && mensaje.toLowerCase().contains("finaliz");
                if (!finalizada && (mensaje == null || !mensaje.toLowerCase().contains("no hay"))) {
                    out.println("<div class='alert alert-info'><i class='bi bi-info-circle me-2'></i>Ingrese sus credenciales para acceder a la votaci\u00f3n.</div>");
                }
                if (!finalizada && (mensaje == null || !mensaje.toLowerCase().contains("no hay"))) {
                    out.println("<form method='post' action='VotacionServlet' autocomplete='off'>");
                    out.println("<input type='hidden' name='paso' value='autenticar'>");
                    out.println("<div class='mb-3'><label class='form-label fw-semibold'>DNI</label>");
                    out.println("<div class='input-group'><span class='input-group-text bg-light'><i class='bi bi-person'></i></span>");
                    out.println("<input type='text' class='form-control' name='dni' maxlength='8' required placeholder='Ingrese su DNI'></div></div>");
                    out.println("<div class='mb-3'><label class='form-label fw-semibold'>C\u00f3digo personal</label>");
                    out.println("<div class='input-group'><span class='input-group-text bg-light'><i class='bi bi-key'></i></span>");
                    out.println("<input type='text' class='form-control' name='codigoPersonal' required placeholder='Ej: CC-12345678'></div></div>");
                    out.println("<div class='mb-3'><label class='form-label fw-semibold'>Clave personal (6 d\u00edgitos)</label>");
                    out.println("<div class='input-group'><span class='input-group-text bg-light'><i class='bi bi-lock'></i></span>");
                    out.println("<input type='password' class='form-control' name='clavePersonal' maxlength='6' required placeholder='Ingrese su clave de 6 d\u00edgitos'></div></div>");
                    out.println("<button type='submit' class='btn btn-primary w-100 mt-2'><i class='bi bi-shield-check me-2'></i>Validar identidad</button>");
                    out.println("</form>");
                }
                out.println("<div class='text-center mt-3'><a class='btn btn-outline-secondary btn-sm' href='index.html'><i class='bi bi-arrow-left me-1'></i>Volver al inicio</a></div>");
                out.println("</div></div></body></html>");
                return;
            }

            String nomEleccion = (String) eleccion.get("nombreEleccion");
            String estado = (String) eleccion.get("estado");
            out.println("<div class='text-center fw-bold fs-5 mb-3 py-2' style='color:#1e293b'>" + escapar(nomEleccion) + "</div>");
            String nomVotante = (String) votante.get("nombres") + " " + (String) votante.get("apellidos");
            String codMesa = (String) votante.getOrDefault("codigoMesa", "Sin asignar");
            out.println("<div class='text-center py-1'><strong>Bienvenido:</strong> " + escapar(nomVotante) + "</div>");
            out.println("<div class='text-center py-1'><strong>Mesa de Sufragio:</strong> " + escapar(codMesa) + "</div><br>");

            if (candidatos == null || candidatos.isEmpty()) {
                out.println("<div class='alert alert-warning'><i class='bi bi-exclamation-triangle me-2'></i>No hay candidatos registrados para esta elecci\u00f3n.</div>");
            } else {
                out.println("<form method='post' action='VotacionServlet' id='votoForm'>");
                out.println("<input type='hidden' name='paso' value='emitir'>");
                out.println("<input type='hidden' name='idEleccion' value='" + eleccion.get("idEleccion") + "'>");

                out.println("<h5 class='fw-bold mb-3' style='color:#1e293b'><i class='bi bi-person-badge me-2' style='color:#4f46e5'></i>Seleccione su candidato</h5>");
                out.println("<div class='row g-3 mb-3' id='candidatosContainer'>");
                for (CandidatoDTO c : candidatos) {
                    String color = c.getColorPartido() != null ? c.getColorPartido() : "#3949ab";
                    String imgSrc = c.getImagen() != null ? imagenToBase64(c.getImagen()) : null;
                    out.println("<div class='col-md-6'>");
                    out.println("<div class='candidato-card' onclick='seleccionarCandidato(this, " + c.getIdCandidato() + ")'>");
                    out.println("<input class='d-none' type='radio' name='idCandidato' value='" + c.getIdCandidato() + "'>");
                    if (imgSrc != null) {
                        out.println("<img class='candidato-foto' src='" + imgSrc + "' alt='Foto'>");
                    } else {
                        out.println("<div class='sin-foto'><i class='bi bi-person'></i></div>");
                    }
                    out.println("<div class='candidato-nombre'>" + escapar(c.getNombres() + " " + c.getApellidos()) + "</div>");
                    out.println("<div class='candidato-cargo'>" + escapar(c.getCargo()) + "</div>");
                    out.println("<span class='partido-badge' style='background:" + color + "'>" + escapar(c.getNombrePartido()) + "</span>");
                    out.println("<i class='bi bi-check-lg check-icon'></i>");
                    out.println("</div></div>");
                }
                out.println("</div>");

                out.println("<div class='d-flex gap-4 p-3 mb-4' style='background:#f1f5f9;border-radius:14px;border:1px solid #e2e8f0'>");
                out.println("<div class='form-check'><input class='form-check-input' type='radio' name='tipoVoto' value='NORMAL' id='votoNormal' checked onchange='toggleTipoVoto()' style='cursor:pointer;width:18px;height:18px'>");
                out.println("<label class='form-check-label fw-semibold' for='votoNormal' style='cursor:pointer;color:#1e293b;font-size:.9rem'>Voto a candidato</label></div>");
                out.println("<div class='form-check'><input class='form-check-input' type='radio' name='tipoVoto' value='BLANCO' id='votoBlanco' onchange='toggleTipoVoto()' style='cursor:pointer;width:18px;height:18px'>");
                out.println("<label class='form-check-label fw-semibold' for='votoBlanco' style='cursor:pointer;color:#1e293b;font-size:.9rem'>Voto en blanco</label></div>");
                out.println("</div>");

                out.println("<div class='d-flex gap-2'>");
                out.println("<button type='button' class='btn flex-grow-1' id='btnConfirmar' onclick='confirmarVoto()' style='background:linear-gradient(135deg,#4f46e5,#4338ca);color:#fff;border:none;padding:12px 0;font-weight:600;border-radius:12px;font-size:.95rem;box-shadow:0 4px 14px rgba(79,70,229,.35)'><i class='bi bi-check-lg me-2'></i>Confirmar voto</button>");
                out.println("<button type='button' class='btn btn-outline-secondary' onclick='mostrarConfirmacion(\"\\u00bfCancelar su votaci\\u00f3n?\",function(){window.location=\"VotacionServlet\"})' style='padding:12px 20px;border-radius:12px;font-weight:500'>Cancelar</button>");
                out.println("</div>");
                out.println("</form>");
            }

            out.println("<div class='modal fade' id='mensajeModal' tabindex='-1' data-bs-backdrop='static'>");
            out.println("<div class='modal-dialog modal-dialog-centered'><div class='modal-content' style='border:none;border-radius:18px;box-shadow:0 25px 80px rgba(0,0,0,.35)'>");
            out.println("<div class='modal-body text-center py-4 px-4'><i class='bi bi-exclamation-triangle' style='font-size:3rem;color:#f59e0b;display:block;margin-bottom:12px'></i>");
            out.println("<p class='mb-0 fs-5' id='mensajeModalTexto'></p></div>");
            out.println("<div class='modal-footer justify-content-center border-0 pt-0 pb-4'><button type='button' class='btn px-4' data-bs-dismiss='modal' style='background:linear-gradient(135deg,#4f46e5,#4338ca);color:#fff;border:none;border-radius:10px;font-weight:600'>Aceptar</button></div>");
            out.println("</div></div></div>");

            out.println("<div class='modal fade' id='confirmModal' tabindex='-1' data-bs-backdrop='static'>");
            out.println("<div class='modal-dialog modal-dialog-centered'><div class='modal-content' style='border:none;border-radius:18px;box-shadow:0 25px 80px rgba(0,0,0,.35)'>");
            out.println("<div class='modal-body text-center py-4 px-4'><i class='bi bi-question-circle' style='font-size:3rem;color:#4f46e5;display:block;margin-bottom:12px'></i>");
            out.println("<p class='mb-0 fs-5' id='confirmModalTexto'></p></div>");
            out.println("<div class='modal-footer justify-content-center border-0 pt-0 pb-4 gap-2'>");
            out.println("<button type='button' class='btn btn-outline-secondary px-4' data-bs-dismiss='modal' style='border-radius:10px;font-weight:500'>Cancelar</button>");
            out.println("<button type='button' class='btn px-4' id='confirmModalBtn' style='background:linear-gradient(135deg,#4f46e5,#4338ca);color:#fff;border:none;border-radius:10px;font-weight:600'>Aceptar</button>");
            out.println("</div></div></div>");

            out.println("<script>");
            out.println("var modalMensaje=null;var modalConfirm=null;");
            out.println("document.addEventListener('DOMContentLoaded',function(){");
            out.println("modalMensaje=new bootstrap.Modal(document.getElementById('mensajeModal'));");
            out.println("modalConfirm=new bootstrap.Modal(document.getElementById('confirmModal'));");
            out.println("});");
            out.println("var confirmCallback=null;");
            out.println("document.getElementById('confirmModalBtn').addEventListener('click',function(){if(confirmCallback){confirmCallback();confirmCallback=null;modalConfirm.hide();}});");
            out.println("function mostrarMensaje(t){document.getElementById('mensajeModalTexto').innerHTML=t;if(modalMensaje)modalMensaje.show();}");
            out.println("function mostrarConfirmacion(t,cb){document.getElementById('confirmModalTexto').innerHTML=t;confirmCallback=cb;if(modalConfirm)modalConfirm.show();}");
            out.println("function seleccionarCandidato(el,idCandidato){");
            out.println("document.querySelectorAll('.candidato-card').forEach(function(c){c.classList.remove('selected');});");
            out.println("el.classList.add('selected');");
            out.println("el.querySelector('input[type=radio]').checked=true;");
            out.println("document.getElementById('votoNormal').checked=true;");
            out.println("toggleTipoVoto();");
            out.println("}");
            out.println("function toggleTipoVoto(){");
            out.println("var blanco=document.getElementById('votoBlanco').checked;");
            out.println("document.querySelectorAll('.candidato-card').forEach(function(c){");
            out.println("if(blanco){c.classList.add('disabled');c.classList.remove('selected');c.querySelector('input[type=radio]').checked=false;}");
            out.println("else{c.classList.remove('disabled');}");
            out.println("});");
            out.println("}");
            out.println("function confirmarVoto(){");
            out.println("var blanco=document.getElementById('votoBlanco').checked;");
            out.println("if(!blanco && !document.querySelector('.candidato-card.selected')){");
            out.println("mostrarMensaje('Seleccione un candidato o elija voto en blanco.');return;}");
            out.println("mostrarConfirmacion('\\u00bfEst\\u00e1 seguro de confirmar su voto? Esta acci\\u00f3n no se puede deshacer.',function(){document.getElementById('votoForm').submit();});");
            out.println("}");
            out.println("</script>");

            out.println("</div></div></body></html>");
        }
    }
}

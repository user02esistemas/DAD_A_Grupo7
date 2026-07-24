package servicio;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import dto.RespuestaApiDTO;
import jakarta.servlet.http.HttpSession;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.util.*;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class ApiCliente {

    private static String API_BASE_URL = "https://inosies.pythonanywhere.com";
    private static final Gson gson = new Gson();

    private static SSLContext crearSslConfiable() {
        try {
            SSLContext sslContext = SSLContext.getInstance("TLS");
            TrustManager[] trustAll = new TrustManager[]{
                new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
                    public void checkClientTrusted(X509Certificate[] certs, String authType) {}
                    public void checkServerTrusted(X509Certificate[] certs, String authType) {}
                }
            };
            sslContext.init(null, trustAll, new SecureRandom());
            return sslContext;
        } catch (Exception e) {
            throw new RuntimeException("Error al inicializar SSL", e);
        }
    }

    private static final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .sslContext(crearSslConfiable())
            .build();

    public static void setApiBaseUrl(String url) {
        API_BASE_URL = url;
    }

    public static String getApiBaseUrl() {
        return API_BASE_URL;
    }

    public static String obtenerToken(HttpSession sesion) {
        if (sesion == null) return null;
        return (String) sesion.getAttribute("token");
    }

    public static void guardarToken(HttpSession sesion, String token) {
        if (sesion != null) sesion.setAttribute("token", token);
    }

    public static RespuestaApiDTO get(String endpoint, String token) throws IOException {
        return request("GET", endpoint, null, token);
    }

    public static RespuestaApiDTO post(String endpoint, Object body, String token) throws IOException {
        return request("POST", endpoint, body != null ? gson.toJson(body) : null, token);
    }

    public static RespuestaApiDTO put(String endpoint, Object body, String token) throws IOException {
        return request("PUT", endpoint, body != null ? gson.toJson(body) : null, token);
    }

    public static RespuestaApiDTO delete(String endpoint, String token) throws IOException {
        return request("DELETE", endpoint, null, token);
    }

    private static RespuestaApiDTO request(String method, String endpoint, String jsonBody, String token) throws IOException {
        String urlStr = API_BASE_URL + endpoint;
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(urlStr))
                    .timeout(Duration.ofSeconds(10))
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json");

            if (token != null && !token.isEmpty()) {
                builder.header("Authorization", "Bearer " + token);
            }

            if (jsonBody != null) {
                builder.method(method, HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8));
            } else {
                builder.method(method, HttpRequest.BodyPublishers.noBody());
            }

            HttpRequest request = builder.build();
            HttpResponse<InputStream> response = httpClient.send(request, HttpResponse.BodyHandlers.ofInputStream());

            int code = response.statusCode();
            InputStream body = response.body();
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] chunk = new byte[4096];
            int bytesRead;
            while ((bytesRead = body.read(chunk)) != -1) {
                buffer.write(chunk, 0, bytesRead);
            }
            String respBody = new String(buffer.toByteArray(), StandardCharsets.UTF_8);
            RespuestaApiDTO resp = gson.fromJson(respBody, RespuestaApiDTO.class);
            return resp;
        } catch (IOException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IOException("Request interrupted", e);
        } catch (Exception e) {
            throw new IOException("Error connecting to API: " + e.getClass().getName() + " - " + e.getMessage(), e);
        }
    }

    public static <T> List<T> parsearLista(RespuestaApiDTO respuesta, Class<T> clase) {
        if (respuesta == null || respuesta.getDatos() == null) {
            return new ArrayList<>();
        }
        Type listType = TypeToken.getParameterized(List.class, clase).getType();
        String json = gson.toJson(respuesta.getDatos());
        return gson.fromJson(json, listType);
    }

    public static <T> T parsearObjeto(RespuestaApiDTO respuesta, Class<T> clase) {
        if (respuesta == null || respuesta.getDatos() == null) {
            return null;
        }
        String json = gson.toJson(respuesta.getDatos());
        return gson.fromJson(json, clase);
    }
}

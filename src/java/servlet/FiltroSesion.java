package servlet;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class FiltroSesion implements Filter {

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String contextPath = req.getContextPath();
        String path = req.getRequestURI().substring(contextPath.length());

        String[] publicPaths = {
            "/css/", "/js/", "/images/", "/frontend/",
            "/index.html", "/",
            "/IniciarSesionServlet", "/CerrarSesionServlet",
            "/ResultadosPublicoServlet", "/VotacionServlet", "/EmitirVotoServlet",
            "/paginas/votacion.jsp", "/paginas/resultados_publico.jsp",
            "/paginas/login.jsp"
        };
        for (String p : publicPaths) {
            if (path.startsWith(p) || path.equals(p)) {
                chain.doFilter(request, response);
                return;
            }
        }

        if (path.startsWith("/paginas/")) {
            HttpSession session = req.getSession(false);
            String token = (session != null) ? (String) session.getAttribute("token") : null;
            if (token == null || token.isEmpty()) {
                res.sendRedirect(contextPath + "/IniciarSesionServlet");
                return;
            }
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}

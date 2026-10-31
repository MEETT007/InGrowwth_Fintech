package com.ingrowwth.homeloan;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Local request tracing. Deliberately excludes bodies, credentials and query values. */
@Component
@Profile("local")
class EmployeeRequestLogging extends OncePerRequestFilter {
  private static final Logger log = LoggerFactory.getLogger(EmployeeRequestLogging.class);

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    return !request.getRequestURI().startsWith("/api/employee/");
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String id = "REQ-" + UUID.randomUUID().toString();
    request.setAttribute("employeeRequestId", id);
    long start = System.nanoTime();
    response.setHeader("X-Request-ID", id);
    log.info("[Employee API] request={} {} {} received", id, request.getMethod(), request.getRequestURI());
    boolean completed = false;
    try {
      chain.doFilter(request, response);
      completed = true;
    } finally {
      log.info("[Employee API] request={} status={} durationMs={} source=local-SQLITE-demo",
          id, completed ? response.getStatus() : 500, (System.nanoTime() - start) / 1_000_000);
    }
  }
}

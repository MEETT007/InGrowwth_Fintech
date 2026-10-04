package com.ingrowwth.homeloan;

import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.csrf.*;

@Configuration
class Security {
  @Bean
  PasswordEncoder passwords() {
    return new BCryptPasswordEncoder(12);
  }

  @Bean
  UserDetailsService details(Users users) {
    return email -> {
      User u =
          users
              .findByEmail(email.toLowerCase())
              .orElseThrow(() -> new UsernameNotFoundException("Invalid credentials"));
      return org.springframework.security.core.userdetails.User.withUsername(u.email)
          .password(u.passwordHash)
          .roles(u.role)
          .build();
    };
  }

  @Bean
  SecurityFilterChain chain(HttpSecurity http) throws Exception {
    var tokenRepo = CookieCsrfTokenRepository.withHttpOnlyFalse();
    tokenRepo.setCookieCustomizer(c -> c.sameSite("Strict"));
    http.csrf(
            c ->
                c.csrfTokenRepository(tokenRepo)
                    .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler()))
        .authorizeHttpRequests(
            a ->
                a.dispatcherTypeMatchers(
                        jakarta.servlet.DispatcherType.ASYNC, jakarta.servlet.DispatcherType.ERROR)
                    .permitAll()
                    .requestMatchers(
                        "/api/auth/session",
                        "/api/auth/login",
                        "/api/auth/register",
                        "/api/planner",
                        "/api/refinance",
                        "/actuator/health")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .exceptionHandling(
            e ->
                e.authenticationEntryPoint(
                        (q, r, x) -> {
                          r.setStatus(401);
                          r.setContentType("application/json");
                          r.getWriter().write("{\"error\":\"Please sign in.\"}");
                        })
                    .accessDeniedHandler(
                        (q, r, x) -> {
                          r.setStatus(403);
                          r.setContentType("application/json");
                          r.getWriter()
                              .write(
                                  "{\"error\":\"Access denied or session expired. Reload and try"
                                      + " again.\"}");
                        }));
    return http.build();
  }
}

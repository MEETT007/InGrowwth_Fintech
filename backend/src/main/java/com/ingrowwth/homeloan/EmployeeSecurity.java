package com.ingrowwth.homeloan;
import org.springframework.context.annotation.*;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.*;
@Configuration @Profile("local")
class EmployeeSecurity {
 @Bean @Order(1) SecurityFilterChain employeeChain(HttpSecurity http) throws Exception {
  var cors=new CorsConfiguration();
  cors.setAllowedOriginPatterns(java.util.List.of("http://localhost:*","http://127.0.0.1:*"));
  cors.setExposedHeaders(java.util.List.of("X-Request-ID"));
  cors.setAllowedMethods(java.util.List.of("GET","POST","OPTIONS"));
  cors.setAllowedHeaders(java.util.List.of("Content-Type","Authorization"));
  var source=new UrlBasedCorsConfigurationSource(); source.registerCorsConfiguration("/**",cors);
  return http.securityMatcher("/api/employee/**").cors(c->c.configurationSource(source)).csrf(c->c.disable())
   .sessionManagement(c->c.sessionCreationPolicy(org.springframework.security.config.http.SessionCreationPolicy.STATELESS))
   .authorizeHttpRequests(a->a.anyRequest().permitAll()).build();
 }
}


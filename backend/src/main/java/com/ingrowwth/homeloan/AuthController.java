package com.ingrowwth.homeloan;

import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.*;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/auth")
class AuthController {
  final Users users;
  final PasswordEncoder encoder;
  final Map<String, Attempt> attempts = new ConcurrentHashMap<>();

  record Attempt(int count, long until) {}

  AuthController(Users u, PasswordEncoder p) {
    users = u;
    encoder = p;
  }

  record Login(@Email @NotBlank String email, @NotBlank @Size(max = 72) String password) {}

  record Register(
      @Email @NotBlank @Size(max = 254) String email,
      @NotBlank @Size(min = 2, max = 100) String name,
      @Size(min = 12, max = 72) String password) {}

  @GetMapping("/session")
  Map<String, Object> session(Authentication auth, CsrfToken csrf) {
    Map<String, Object> result = new HashMap<>();
    result.put("csrf", csrf.getToken());
    result.put(
        "user",
        auth == null
            ? null
            : users
                .findByEmail(auth.getName())
                .map(
                    u ->
                        Map.of("id", u.id, "name", u.displayName, "email", u.email, "role", u.role))
                .orElse(null));
    return result;
  }

  @PostMapping("/login")
  Map<String, Object> login(
      @Valid @RequestBody Login input, HttpServletRequest req, HttpServletResponse res) {
    if (input.password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72)
      throw new IllegalArgumentException("Password exceeds the supported length.");
    String key = req.getRemoteAddr() + ":" + input.email.toLowerCase();
    long now = System.currentTimeMillis();
    attempts.entrySet().removeIf(e -> e.getValue().until < now);
    Attempt a = attempts.get(key);
    if (a != null && a.count >= 5)
      throw new ResponseStatusException(
          HttpStatus.TOO_MANY_REQUESTS, "Too many sign-in attempts. Try again in 10 minutes.");
    User u = users.findByEmail(input.email.toLowerCase()).orElse(null);
    if (u == null || !encoder.matches(input.password, u.passwordHash)) {
      if (attempts.size() < 10000)
        attempts.put(key, new Attempt(a == null ? 1 : a.count + 1, now + 600000));
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect.");
    }
    attempts.remove(key);
    if (req.getSession(false) != null) req.changeSessionId();
    var auth =
        new UsernamePasswordAuthenticationToken(
            u.email, null, List.of(new SimpleGrantedAuthority("ROLE_" + u.role)));
    var context = SecurityContextHolder.createEmptyContext();
    context.setAuthentication(auth);
    SecurityContextHolder.setContext(context);
    new HttpSessionSecurityContextRepository().saveContext(context, req, res);
    return Map.of("id", u.id, "name", u.displayName, "email", u.email, "role", u.role);
  }

  @PostMapping("/register")
  Map<String, String> register(@Valid @RequestBody Register input) {
    if (input.password == null
        || input.password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72)
      throw new IllegalArgumentException("Password must contain 12–72 UTF-8 bytes.");
    if (users.findByEmail(input.email.toLowerCase()).isPresent())
      throw new IllegalArgumentException("An account already exists for this email.");
    User u = new User();
    u.email = input.email.toLowerCase();
    u.displayName = input.name;
    u.role = "BORROWER";
    u.passwordHash = encoder.encode(input.password);
    users.save(u);
    return Map.of("message", "Account created. You can sign in now.");
  }

  @PostMapping("/logout")
  Map<String, String> logout(HttpServletRequest req) {
    if (req.getSession(false) != null) req.getSession().invalidate();
    SecurityContextHolder.clearContext();
    return Map.of("message", "Signed out");
  }
}

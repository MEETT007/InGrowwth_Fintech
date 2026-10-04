package com.ingrowwth.homeloan;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile("bootstrap")
class OfficerBootstrap implements CommandLineRunner {
  final Users users;
  final PasswordEncoder encoder;
  final String email, password;
  private final org.springframework.context.ConfigurableApplicationContext context;

  OfficerBootstrap(
      Users u,
      PasswordEncoder e,
      @Value("${OFFICER_EMAIL}") String mail,
      @Value("${OFFICER_PASSWORD}") String pass,
      org.springframework.context.ConfigurableApplicationContext context) {
    users = u;
    encoder = e;
    email = mail.toLowerCase();
    password = pass;
    this.context = context;
  }

  public void run(String... args) {
    if (!email.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+")
        || password.length() < 12
        || password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72)
      throw new IllegalArgumentException(
          "Provide a valid officer email and password of 12–72 UTF-8 bytes.");
    if (users.findByEmail(email).isPresent())
      throw new IllegalArgumentException(
          "Bootstrap never elevates an existing account; use a new officer email.");
    User u = new User();
    u.email = email;
    u.displayName = "Lending officer";
    u.passwordHash = encoder.encode(password);
    u.role = "OFFICER";
    users.save(u);
    org.springframework.boot.SpringApplication.exit(context, () -> 0);
  }
}

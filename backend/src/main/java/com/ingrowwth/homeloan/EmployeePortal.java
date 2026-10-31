package com.ingrowwth.homeloan;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration;
import org.springframework.context.annotation.Import;

/** Standalone SQLite employee demo; legacy borrower modules retain their own entry point. */
@EnableAutoConfiguration(exclude = {DataSourceAutoConfiguration.class, HibernateJpaAutoConfiguration.class,
    FlywayAutoConfiguration.class, JpaRepositoriesAutoConfiguration.class})
@Import({EmployeeController.class, EmployeeCustomerRepository.class, EmployeeCustomerService.class,
    EmployeeSecurity.class, EmployeeRequestLogging.class, EmployeeHealthController.class, EmployeeErrors.class})
public class EmployeePortal {
  @org.springframework.context.annotation.Bean
  org.springframework.security.core.userdetails.UserDetailsService employeeUsers() {
    return new org.springframework.security.provisioning.InMemoryUserDetailsManager();
  }
  public static void main(String[] args) { SpringApplication.run(EmployeePortal.class, args); }
}


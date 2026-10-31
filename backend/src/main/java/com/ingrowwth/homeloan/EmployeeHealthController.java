package com.ingrowwth.homeloan;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
@RestController @Profile("local")
class EmployeeHealthController {
 private final EmployeeCustomerRepository repository;
 EmployeeHealthController(EmployeeCustomerRepository repository){this.repository=repository;}
 @GetMapping("/api/health") ResponseEntity<?> health(){boolean ok=repository.healthy();return ResponseEntity.status(ok?200:503).body(Map.of("success",ok,"message",ok?"Backend and employee database available":"Employee database unavailable","data",Map.of("backend","UP","database",ok?"UP":"DOWN")));}
}

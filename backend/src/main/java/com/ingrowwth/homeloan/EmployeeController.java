package com.ingrowwth.homeloan;
import java.util.*;
import org.springframework.context.annotation.Profile;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController @Profile("local") @RequestMapping("/api/employee")
class EmployeeController {
 private final EmployeeCustomerService service;
 EmployeeController(EmployeeCustomerService service){this.service=service;}
 record Credentials(String mobile,String otp) {}
 record Lookup(String panNumber) {}
 private final Map<String,Long> tokens=new java.util.concurrent.ConcurrentHashMap<>();
 static ResponseEntity<?> error(int status,String message) {return ResponseEntity.status(status).body(Map.of("success",false,"message",message));}
 @PostMapping("/demo-session") ResponseEntity<?> login(@RequestBody Credentials c) {
  if(!"8200229099".equals(c.mobile()) || !"123456".equals(c.otp())) return error(401,"Invalid demo employee credentials.");
  tokens.entrySet().removeIf(e->e.getValue()<System.currentTimeMillis());
  if(tokens.size()>1000) return error(429,"Too many demo sessions.");
  String token=UUID.randomUUID().toString(); tokens.put(token,System.currentTimeMillis()+1800000);
  return ResponseEntity.ok(Map.of("success",true,"token",token));
 }

 private boolean authorized(String auth){return auth.startsWith("Bearer ")&&tokens.getOrDefault(auth.substring(7),0L)>=System.currentTimeMillis();}
 private String requestId(jakarta.servlet.http.HttpServletRequest r){var id=r.getAttribute("employeeRequestId");return id==null?UUID.randomUUID().toString():id.toString();}
 private ResponseEntity<?> result(Object data,String id){return ResponseEntity.ok(Map.of("success",true,"message","Customer details fetched successfully","requestId",id,"data",data));}
 private ResponseEntity<?> failure(int status,String message,String id){return ResponseEntity.status(status).body(Map.of("success",false,"message",message,"requestId",id));}
 @PostMapping("/customers/pan-lookup") ResponseEntity<?> lookup(@RequestHeader(value="Authorization",defaultValue="")String auth,@RequestBody Lookup input,jakarta.servlet.http.HttpServletRequest r){
  String id=requestId(r);if(!authorized(auth))return failure(401,"Employee session expired. Sign in again.",id);
  String pan=input.panNumber()==null?"":input.panNumber().trim().toUpperCase(Locale.ROOT);
  if(!pan.matches("[A-Z]{5}[0-9]{4}[A-Z]")){org.slf4j.LoggerFactory.getLogger(getClass()).info("request={} validation=FAILED",id);return failure(400,"Enter a valid PAN, for example QWERT1234L.",id);}
  try{var found=service.lookup(pan,id);return found.isPresent()?result(found.get(),id):failure(404,"No customer record found.",id);}catch(Exception ex){org.slf4j.LoggerFactory.getLogger(getClass()).error("request={} database=SQLITE lookup=FAILED errorType={}",id,ex.getClass().getSimpleName());return failure(500,"Customer database unavailable. Please try again.",id);}
 }
 @GetMapping("/customers") ResponseEntity<?> list(@RequestHeader(value="Authorization",defaultValue="")String auth,jakarta.servlet.http.HttpServletRequest r){String id=requestId(r);if(!authorized(auth))return failure(401,"Employee sign-in required.",id);try{return result(service.repository.list(),id);}catch(Exception ex){return failure(500,"Customer database unavailable.",id);}}
 @GetMapping("/customers/{customerId}") ResponseEntity<?> detail(@PathVariable String customerId,@RequestHeader(value="Authorization",defaultValue="")String auth,jakarta.servlet.http.HttpServletRequest r){String id=requestId(r);if(!authorized(auth))return failure(401,"Employee sign-in required.",id);try{var found=service.repository.find(customerId,false);return found.isPresent()?result(found.get(),id):failure(404,"No customer record found.",id);}catch(Exception ex){return failure(500,"Customer database unavailable.",id);}}
}

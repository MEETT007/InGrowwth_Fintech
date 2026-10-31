package com.ingrowwth.homeloan;
import java.util.Map;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.*;
@RestControllerAdvice(assignableTypes=EmployeeController.class) @Profile("local")
class EmployeeErrors {
 @ExceptionHandler(HttpMessageNotReadableException.class)
 ResponseEntity<?> malformed(jakarta.servlet.http.HttpServletRequest request){
  Object id=request.getAttribute("employeeRequestId");
  return ResponseEntity.badRequest().body(Map.of("success",false,"message","Send a valid JSON request.","requestId",id==null?"unavailable":id.toString()));
 }
}

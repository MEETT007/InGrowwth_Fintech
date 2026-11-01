package com.ingrowwth.homeloan;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import com.fasterxml.jackson.databind.ObjectMapper;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest(classes=EmployeePortal.class)
@AutoConfigureMockMvc @ActiveProfiles("local")
class EmployeeControllerTest {
 static final java.nio.file.Path sqlite;
 static {try{sqlite=java.nio.file.Files.createTempDirectory("employee-test-").resolve("demo.sqlite");}catch(Exception ex){throw new RuntimeException(ex);}}
 @DynamicPropertySource static void properties(DynamicPropertyRegistry r){r.add("app.employee-database",()->sqlite.toString());}
 @Autowired MockMvc mvc;
 @Autowired ObjectMapper json;
 @Autowired EmployeeCustomerRepository repository;
 String token()throws Exception{
  var result=mvc.perform(post("/api/employee/demo-session").contentType("application/json").content("{\"mobile\":\"8200229099\",\"otp\":\"123456\"}"))
  .andExpect(status().isOk()).andReturn();return json.readTree(result.getResponse().getContentAsString()).get("token").asText();
 }
 @Test void allProfilesAndValidation()throws Exception{
  String auth="Bearer "+token();String[] pans={" qwert1234l ","PLMNO5678K","ZXCVB9012M"};int[] scores={782,715,642};
  for(int i=0;i<3;i++)mvc.perform(post("/api/employee/customers/pan-lookup").header("Authorization",auth).contentType("application/json").content(json.writeValueAsString(java.util.Map.of("panNumber",pans[i]))))
  .andExpect(status().isOk()).andExpect(jsonPath("$.data.customerId").value("CUS-100"+(i+1)))
  .andExpect(jsonPath("$.data.creditProfile.simulatedCreditScore").value(scores[i]))
  .andExpect(jsonPath("$.requestId").isString()).andExpect(header().exists("X-Request-ID"));
  for(var example:new Object[][]{{"ZZZZZ9999Z",404},{"bad",400},{"",400}})
   mvc.perform(post("/api/employee/customers/pan-lookup").header("Authorization",auth).contentType("application/json").content(json.writeValueAsString(java.util.Map.of("panNumber",example[0])))).andExpect(status().is((Integer)example[1]));
 }
 @Test void unauthorized()throws Exception{
  mvc.perform(post("/api/employee/customers/pan-lookup").contentType("application/json").content("{\"panNumber\":\"QWERT1234L\"}")).andExpect(status().isUnauthorized());
  mvc.perform(get("/api/employee/customers")).andExpect(status().isUnauthorized());
  mvc.perform(get("/api/employee/customers/CUS-1001")).andExpect(status().isUnauthorized());
 }
 @Test void sqlitePersistenceRelationshipsAndConstraints()throws Exception{
  assertTrue(repository.healthy());assertTrue(java.nio.file.Files.size(sqlite)>0);
  var reopened=new EmployeeCustomerRepository(json,sqlite.toString());assertEquals(3,reopened.list().size());
  assertEquals("Saurav Kumar Patel",reopened.find("CUS-1001",false).orElseThrow().basicInformation().get("fullName"));
  assertEquals("Pune",reopened.find("PLMNO5678K",true).orElseThrow().addressInformation().get("city"));
  assertEquals(1,reopened.find("CUS-1001",false).orElseThrow().homeLoans().size());
  assertEquals(0,reopened.find("CUS-1003",false).orElseThrow().homeLoans().size());
  try(var c=repository.open();var s=c.createStatement()){
   s.executeUpdate("INSERT INTO customers VALUES ('OTHER','{}')");
   try{assertThrows(java.sql.SQLException.class,()->s.executeUpdate("INSERT INTO customer_pans VALUES ('OTHER','QWERT1234L','{}')"));
    assertThrows(java.sql.SQLException.class,()->s.executeUpdate("INSERT INTO customer_addresses VALUES ('MISSING','{}')"));
   }finally{s.executeUpdate("DELETE FROM customers WHERE customer_id='OTHER'");}
  }
 }
 @Test void listDetailsAndHealth()throws Exception{
  String auth="Bearer "+token();
  mvc.perform(get("/api/employee/customers").header("Authorization",auth)).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(3)).andExpect(jsonPath("$.data[0].panNumber").doesNotExist());
  mvc.perform(get("/api/employee/customers/CUS-1002").header("Authorization",auth)).andExpect(status().isOk()).andExpect(jsonPath("$.data.basicInformation.fullName").value("Priya Sharma"));
  mvc.perform(get("/api/employee/customers/absent").header("Authorization",auth)).andExpect(status().isNotFound());
  mvc.perform(get("/api/health")).andExpect(status().isOk()).andExpect(jsonPath("$.data.database").value("UP"));
 }
 @Test void lookupReadsPersistedDatabaseInsteadOfSeedFile()throws Exception{
  String auth="Bearer "+token();
  try(var c=repository.open();var read=c.prepareStatement("SELECT basic_json FROM customers WHERE customer_id=?")){
   read.setString(1,"CUS-1001");
   String original;
   try(var rs=read.executeQuery()){assertTrue(rs.next());original=rs.getString(1);}
   var changed=json.readTree(original);((com.fasterxml.jackson.databind.node.ObjectNode)changed).put("fullName","SQLite persistence proof");
   try(var update=c.prepareStatement("UPDATE customers SET basic_json=? WHERE customer_id=?")){
    update.setString(1,json.writeValueAsString(changed));update.setString(2,"CUS-1001");update.executeUpdate();
    try{
     var reopened=new EmployeeCustomerRepository(json,sqlite.toString());
     assertEquals("SQLite persistence proof",reopened.find("QWERT1234L",true).orElseThrow().basicInformation().get("fullName"));
     mvc.perform(post("/api/employee/customers/pan-lookup").header("Authorization",auth).contentType("application/json").content("{\"panNumber\":\"QWERT1234L\"}"))
      .andExpect(status().isOk()).andExpect(jsonPath("$.data.basicInformation.fullName").value("SQLite persistence proof"));
    }finally{update.setString(1,original);update.executeUpdate();}
   }
  }
 }
}


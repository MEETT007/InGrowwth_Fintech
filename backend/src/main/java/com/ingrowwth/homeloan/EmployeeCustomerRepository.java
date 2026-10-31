package com.ingrowwth.homeloan;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.file.*;
import java.sql.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;
import org.springframework.core.io.ClassPathResource;
@Repository @Profile("local")
class EmployeeCustomerRepository {
 private final String url;
 private final ObjectMapper json;
 EmployeeCustomerRepository(ObjectMapper json,@Value("${app.employee-database:./.data/employee-demo.sqlite}") String file) throws Exception {
  this.json=json;Path path=Path.of(file).toAbsolutePath();Files.createDirectories(path.getParent());url="jdbc:sqlite:"+path;
  try(Connection c=open()) {
   c.setAutoCommit(false);
   try {
    String schema=new ClassPathResource("employee/schema.sql").getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
    try(Statement s=c.createStatement()){for(String sql:schema.split(";"))if(!sql.isBlank())s.execute(sql);}
    var profiles=json.readValue(new ClassPathResource("employee/customers.json").getInputStream(),new TypeReference<List<Map<String,Object>>>(){});
    for(var p:profiles){
     String id=(String)p.get("customerId");
     try(PreparedStatement s=c.prepareStatement("SELECT 1 FROM customers WHERE customer_id=?")){s.setString(1,id);try(ResultSet rs=s.executeQuery()){if(rs.next())continue;}}
     insert(c,"INSERT INTO customers VALUES (?,?)",id,json.writeValueAsString(p.get("basicInformation")));
     var pan=(Map<?,?>)p.get("panInformation");insert(c,"INSERT INTO customer_pans VALUES (?,?,?)",id,(String)pan.get("panNumber"),json.writeValueAsString(pan));
     for(var pair:Map.of("customer_addresses","addressInformation","customer_employment","employmentInformation","customer_credit_profiles","creditProfile").entrySet())insert(c,"INSERT INTO "+pair.getKey()+" VALUES (?,?)",id,json.writeValueAsString(p.get(pair.getValue())));
     for(var loan:(List<?>)p.get("homeLoans"))insert(c,"INSERT INTO customer_loans(customer_id,details_json) VALUES (?,?)",id,json.writeValueAsString(loan));
    }c.commit();
   }catch(Exception ex){c.rollback();throw ex;}
  }
 }
 Connection open()throws SQLException{Connection c=DriverManager.getConnection(url);try(Statement s=c.createStatement()){s.execute("PRAGMA foreign_keys=ON");s.execute("PRAGMA busy_timeout=5000");}return c;}
 private void insert(Connection c,String sql,String...values)throws SQLException{try(PreparedStatement s=c.prepareStatement(sql)){for(int i=0;i<values.length;i++)s.setString(i+1,values[i]);s.executeUpdate();}}
 record ProfileDto(String customerId,Map<String,Object> basicInformation,Map<String,Object> panInformation,Map<String,Object> addressInformation,Map<String,Object> employmentInformation,Map<String,Object> creditProfile,List<Map<String,Object>> homeLoans){}
 private Map<String,Object> object(String text)throws Exception{return json.readValue(text,new TypeReference<Map<String,Object>>(){});}
 Optional<ProfileDto> find(String value,boolean byPan)throws Exception{
  try(Connection c=open()){
   c.setAutoCommit(false);
   String sql="SELECT c.customer_id,c.basic_json,p.details_json AS pan,a.details_json AS address,e.details_json AS employment,cr.details_json AS credit FROM customers c JOIN customer_pans p ON c.customer_id=p.customer_id JOIN customer_addresses a ON c.customer_id=a.customer_id JOIN customer_employment e ON c.customer_id=e.customer_id JOIN customer_credit_profiles cr ON c.customer_id=cr.customer_id WHERE "+(byPan?"p.pan_number":"c.customer_id")+"=?";
   try(PreparedStatement s=c.prepareStatement(sql)){s.setString(1,value);try(ResultSet rs=s.executeQuery()){
    if(!rs.next())return Optional.empty();String id=rs.getString("customer_id");List<Map<String,Object>> loans=new ArrayList<>();
    try(PreparedStatement ls=c.prepareStatement("SELECT details_json FROM customer_loans WHERE customer_id=? ORDER BY id")){ls.setString(1,id);try(ResultSet lr=ls.executeQuery()){while(lr.next())loans.add(object(lr.getString(1)));}}
    return Optional.of(new ProfileDto(id,object(rs.getString("basic_json")),object(rs.getString("pan")),object(rs.getString("address")),object(rs.getString("employment")),object(rs.getString("credit")),loans));
   }}
  }
 }
 record SummaryDto(String customerId,String fullName){}
 List<SummaryDto> list()throws Exception{try(Connection c=open();Statement s=c.createStatement();ResultSet rs=s.executeQuery("SELECT customer_id,basic_json FROM customers ORDER BY customer_id")){List<SummaryDto> result=new ArrayList<>();while(rs.next())result.add(new SummaryDto(rs.getString(1),(String)object(rs.getString(2)).get("fullName")));return result;}}
 boolean healthy(){try(Connection c=open();Statement s=c.createStatement();ResultSet rs=s.executeQuery("SELECT COUNT(*) FROM customers")){return rs.next();}catch(Exception ex){return false;}}
}

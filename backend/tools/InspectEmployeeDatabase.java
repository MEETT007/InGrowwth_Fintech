import java.sql.*;
import java.nio.file.*;
class InspectEmployeeDatabase {
 public static void main(String[] args)throws Exception{
  Path file=Path.of(args[0]).toAbsolutePath();if(!Files.exists(file))throw new IllegalStateException("Start backend once to initialize SQLite.");
  try(Connection c=DriverManager.getConnection("jdbc:sqlite:file:"+file.toUri().getRawPath()+"?mode=ro");Statement s=c.createStatement();ResultSet rs=s.executeQuery("SELECT c.customer_id, json_extract(c.basic_json,'$.fullName') AS name, json_extract(a.details_json,'$.city') AS city, json_extract(cr.details_json,'$.simulatedCreditScore') AS score FROM customers c JOIN customer_addresses a USING(customer_id) JOIN customer_credit_profiles cr USING(customer_id) ORDER BY c.customer_id")){
   System.out.printf("%-12s %-25s %-15s %s%n","Customer ID","Fictional customer","City","Simulated score");
   while(rs.next())System.out.printf("%-12s %-25s %-15s %s%n",rs.getString(1),rs.getString(2),rs.getString(3),rs.getString(4));
  }
 }
}

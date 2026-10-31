package com.ingrowwth.homeloan;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.context.annotation.Profile;
import org.slf4j.LoggerFactory;
@Service @Profile("local")
class EmployeeCustomerService {
 final EmployeeCustomerRepository repository;
 EmployeeCustomerService(EmployeeCustomerRepository repository){this.repository=repository;}
 Optional<EmployeeCustomerRepository.ProfileDto> lookup(String pan,String id)throws Exception{
  var log=LoggerFactory.getLogger(getClass());log.info("request={} validation=PASSED pan={} database=SQLITE operation=SELECT",id,pan.substring(0,2)+"*****"+pan.substring(7));
  var result=repository.find(pan,true);log.info("request={} lookup={} customerId={}",id,result.isPresent()?"FOUND":"NOT_FOUND",result.map(EmployeeCustomerRepository.ProfileDto::customerId).orElse("none"));return result;
 }
}

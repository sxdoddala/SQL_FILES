--******************************************************************************--
--*Program Name: ttec_deferral_comparison.sql                                 *--   
--*                                                                            *--
--*                                                                            *--
--*Desciption: This program will write a report that compares   :              *--
--*            the 401K enteries supplied by Wachoviawith with                 *--
--*            that in the Oracle application                                  *--
--*                                                                            *--

--*                                                                            *--
--*Input/Output Parameters                                                     *--
--*                                                                            *--
--*Tables Accessed: CUST.ttec_us_deferral_tbl def
--*                 hr.per_all_people_f emp                                    *--
--*                 per_all_assignments_f asg                                  *--
--*                 hr.hr_locations_all loc                                    *--
--*                 hr.per_person_types                                        *--
--*                 hr.pay_element_links_f                                     *--
--*                 hr.pay_element_types_f                                     *--
--*                 hr.pay_element_entry_values_f                              *--
--*                 hr.pay_input_values_f                                      *--
--*                 sys.v$database                                             *--
--*                                                                            *--
--*                                                                            *--
--*Tables Modified: PAY_ELEMENT_ENTRY_VALUES_F		                           *--
--*                                                                            *--
--*Procedures Called: 
--*                                                                            *--
--*Created By: Elizur Alfred-Ockiya                                            *--
--*Date: 13-APR-2005                                                          *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya	 13-APR-2005   File created					               *---
--* E.Alfred-Ockiya	 16-MAY-2005   Modified to remove US 401k and add          *--
--*                                Pre Tax 401k and Pre Tax 401k CatchUp   
--* C. Chan   v2.0   15-MAY-2011    Fixed element to check for active elements only    on pay_element_types_f  + ttec_lib
--  NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation       
--******************************************************************************--

SET timing ON;
SET serveroutput ON SIZE 1000000;

DECLARE
/***Variables used by Common Error Procedure***/
        
p_comparedeferral        VARCHAR2(50)        := 'CompareDeferral.txt';



v_comparedeferral_file       UTL_FILE.FILE_TYPE;


ERRBUF  VARCHAR2(50);
RETCODE  NUMBER;
P_OUTPUT_DIR   VARCHAR2(600);
/***Exceptions***/

SKIP_RECORD       EXCEPTION;


/***************************************** Cursor declaration ******************************************/

cursor csr_deferral_compare is 
select distinct emp.national_identifier 			SSN
,  emp.last_name                                    last_name
,  emp.first_name				                    first_name
,  loc.location_code                                location_code
,  SUM(decode (entval.input_value_id ,11819,entval.screen_entry_value))  pre_tax401k
,  SUM(decode (entval.input_value_id,11831,entval.screen_entry_value)) pre_tax_catchup
,  to_number(def.deferral_pct,99.99)                wachovia_401k 
,  entval.effective_start_date                      element_start_date
,  entval.effective_end_date				        element_end_date
,  st.user_status 					                emp_status
,  serv.date_start       			                emp_start_date
,  def.attribute1									emp_plan_type
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f emp
, cust.ttec_us_deferral_tbl def
, hr.per_all_assignments_f asg
, hr.hr_locations_all loc
, hr.per_periods_of_service serv
, hr.per_assignment_status_types st
, hr.pay_element_entries_f entries
, hr.pay_element_entry_values_f entval
, hr.pay_element_types_f etypes
, hr.pay_input_values_f input*/
from apps.per_all_people_f emp
, apps.ttec_us_deferral_tbl def
, apps.per_all_assignments_f asg
, apps.hr_locations_all loc
, apps.per_periods_of_service serv
, apps.per_assignment_status_types st
, apps.pay_element_entries_f entries
, apps.pay_element_entry_values_f entval
, apps.pay_element_types_f etypes
, apps.pay_input_values_f input
--End R12.2 Upgrade Remediation
where emp.national_identifier(+) = def.ss_number 
  and emp.business_group_id = 325
  and emp.person_id = asg.person_id
  and asg.location_id = loc.location_id
  and asg.period_of_service_id = serv.period_of_service_id
  and asg.assignment_status_type_id = st.assignment_status_type_id
  and asg.assignment_id = entries.assignment_id
  and entries.element_entry_id = entval.element_entry_id
  and entval.element_entry_id = entries.element_entry_id
  and etypes.element_type_id = input.element_type_id
  and input.input_value_id = entval.input_value_id  
--  and entval.input_value_id = 2089
  and asg.primary_flag = 'Y'
  and def.t_type = '2'
  and  etypes.element_name in ('Pre Tax 401K Catchup','Pre Tax 401K')
  and trunc (sysdate) between emp.effective_start_date (+)and emp.effective_end_date(+)
  and trunc (sysdate) between asg.effective_start_date and asg.effective_end_date
  and  trunc (sysdate) between entries.effective_start_date (+) and entries.effective_end_date (+)
  and  trunc (sysdate) between entval.effective_start_date (+) and entval.effective_end_date (+)--;
  and trunc (sysdate)  between etypes.effective_start_date (+) and etypes.effective_end_date (+)  /* v2.0 */
--  and to_date('26-MAY-2005') between emp.effective_start_date (+)and emp.effective_end_date(+)
--  and to_date('26-MAY-2005') between asg.effective_start_date and asg.effective_end_date
--  and to_date('26-MAY-2005') between entries.effective_start_date (+) and entries.effective_end_date (+)
--  and to_date('26-MAY-2005') between entval.effective_start_date (+) and entval.effective_end_date (+)--;  
-- and emp.national_identifier = '111-60-5626' 
  group by emp.national_identifier
,  emp.last_name                                   
,  emp.first_name	
,  emp.employee_number			                    
,  loc.location_code   
,  entval.effective_start_date    
,  entval.effective_end_date                              
,  to_number(def.deferral_pct,99.99) 		
,  entval.effective_start_date                      
,  entval.effective_end_date				        
,  st.user_status 					                
,  serv.date_start
,  def.attribute1   
order by def.attribute1 desc,emp.last_name, emp.first_name;


--***************************************************************
PROCEDURE main(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER, P_OUTPUT_DIR IN VARCHAR2 ) IS
  --  
 v_output_dir    VARCHAR2(600) := P_OUTPUT_DIR;

l_comparedeferral_output            CHAR(600);
l_compare_pretax varchar2(10) null;
l_compare_catchup varchar2(10) null;
  
BEGIN              ---Starting main 

--dbms_output.put_line('Starting Main ');  
 
    /* v2.0
    begin
	  select '/d01/ora'||DECODE(name,'PROD','cle',lower(name))
	  ||'/'||lower(name)
	  ||'appl/teletech/11.5.0/data/BenefitInterface'
	  into v_output_dir
	  from V$DATABASE;
    end;
   */

      v_output_dir := TTEC_LIBRARY.GET_DIRECTORY ('CUST_TOP');         -- v2.0
      v_output_dir := v_output_dir || '/data/BenefitInterface';        -- v2.0

--************************************ Business Unit ******************************************  
begin
  v_comparedeferral_file := UTL_FILE.FOPEN(v_output_dir, p_comparedeferral, 'w'); 

  
	       l_comparedeferral_output := ('SSN'   							      ||'|'||
	                              'Last Name'    		 					      ||'|'||
		                          'First Name'    		 					      ||'|'||
	                              'Location Code'  		 					      ||'|'||	
	                              'Pre Tax 401K %' 		 	 					  ||'|'||	
	                              'Pre Tax 401K CatchUp%'  	 					  ||'|'||									  
	                              'Wachovia %'    		 	 					  ||'|'||
								  'Comparison of PreTax to Wachovia%'    		  ||'|'||	
								  'Comparison of PreTax CatchUp to Wachovia%'     ||'|'||								  
	                              'Element Start Date'    		   				  ||'|'||	
	                              'Element End Date'    	 					  ||'|'||	
	                              'Employee Status'    		 					  ||'|'||	
	                              'Employee Start Date');
								  
       utl_file.put_line(v_comparedeferral_file, l_comparedeferral_output);
	
    for sel in csr_deferral_compare loop
	
		if (sel.pre_tax401k = sel.wachovia_401k) then
		    l_compare_pretax := 'TRUE';
		else
			l_compare_pretax := 'FALSE';
	    end if;

		if (sel.pre_tax_catchup = sel.wachovia_401k) then
		    l_compare_catchup := 'TRUE';
		else
			l_compare_catchup := 'FALSE';
	    end if;	
		

        l_comparedeferral_output := (sel.ssn   			     ||'|'||
	                              sel.last_name   		 	 ||'|'||
	                              sel.first_name   		 	 ||'|'||
	                              sel.location_code  		 ||'|'||	
	                              sel.pre_tax401k 		 	 ||'|'||	
	                              sel.pre_tax_catchup		 ||'|'||									  
	                              sel.wachovia_401k   		 ||'|'||
								  l_compare_pretax    		 ||'|'||	
								  l_compare_catchup    		 ||'|'||	
	                              sel.element_start_date   	 ||'|'||	
	                              sel.element_end_date    	 ||'|'||	
	                              sel.emp_status    		 ||'|'||	
	                              sel.emp_start_date);
								 
       utl_file.put_line(v_comparedeferral_file, l_comparedeferral_output);

    end loop;	

end;

----***********************************************************************************************
UTL_FILE.FCLOSE(v_comparedeferral_file);

-- ************************************* EMPLOYEES *************************************----------

END; --ending main procedure 
--***************************************************************
--*****                  Call Main procedure                *****
--***************************************************************

begin
     main(ERRBUF, RETCODE, P_OUTPUT_DIR);
	 EXCEPTION
	 WHEN SKIP_RECORD THEN
	 dbms_output.put_line('Starting Main '); 
	 null;
end;
/



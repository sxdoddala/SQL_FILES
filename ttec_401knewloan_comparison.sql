--******************************************************************************--
--*Program Name: ttec_newloan_comparison.sql                                 *--   
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
--*Date: 29-APR-2005                                                          *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya	 29-APR-2005   File created					               *---
--  NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation       
--******************************************************************************--

SET timing ON;
SET serveroutput ON SIZE 1000000;

DECLARE
/***Variables used by Common Error Procedure***/
        
p_compare_newloan        VARCHAR2(50)        := 'Compare_newloan.txt';



v_compare_newloan_file       UTL_FILE.FILE_TYPE;


ERRBUF  VARCHAR2(50);
RETCODE  NUMBER;
P_OUTPUT_DIR   VARCHAR2(600);
/***Exceptions***/

SKIP_RECORD       EXCEPTION;


/***************************************** Cursor declaration ******************************************/

cursor csr_newloan_compare is 
select emp.national_identifier 			     	  			  	       ssn
,  emp.employee_number					   							   oracle_id
,  emp.last_name                                   					   last_name
,  emp.first_name	    		                    				   first_name
,  loc.location_code                                				   location_code
,  entval.effective_start_date                     					   system_start_date
,  SUM(decode (entval.input_value_id,1849,entval.screen_entry_value))  sys_payment_amt
,  SUM(decode (entval.input_value_id,1850,entval.screen_entry_value))  sys_goal_amt
,  nloan.loan_effective_date										   wachovia_start_date	
,  nloan.payment_amount                              				   wachovia_payment_amt 
,  nloan.goal_amount												   wachovia_goal_amt			
,  entval.effective_end_date				        				   element_end_date
,  st.user_status 					                				   emp_status
,  serv.date_start       			                				   emp_start_date
,  serv.actual_termination_date                     				   emp_termed_date
,  nloan.attribute1													   plan_type_id
,  emp.current_employee_flag                        				   current_flag
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f emp
, CUST.ttec_tti_newloan_tbl nloan
, hr.per_all_assignments_f asg
, hr.hr_locations_all loc
, hr.per_periods_of_service serv
, hr.per_assignment_status_types st
, hr.pay_element_entries_f entries
, hr.pay_element_entry_values_f entval*/
from apps.per_all_people_f emp
, apps.ttec_tti_newloan_tbl nloan
, apps.per_all_assignments_f asg
, apps.hr_locations_all loc
, apps.per_periods_of_service serv
, apps.per_assignment_status_types st
, apps.pay_element_entries_f entries
, apps.pay_element_entry_values_f entval
--End R12.2 Upgrade Remediation
where emp.national_identifier(+) = nloan.ss_number 
  and emp.business_group_id = 325
  and emp.person_id = asg.person_id
  and asg.location_id = loc.location_id
  and asg.period_of_service_id = serv.period_of_service_id
  and asg.assignment_status_type_id = st.assignment_status_type_id
  and asg.assignment_id = entries.assignment_id
  and entries.element_entry_id = entval.element_entry_id
  and entval.input_value_id in (1849,1850)
  and asg.primary_flag = 'Y'
  and nloan.t_type = '2'
  and entries.element_type_id = 325
  and trunc (sysdate + 30) between emp.effective_start_date (+)and emp.effective_end_date(+)
  and trunc (sysdate + 30) between asg.effective_start_date and asg.effective_end_date
  and  trunc (sysdate + 30) between entries.effective_start_date (+) and entries.effective_end_date (+)
  and  trunc (sysdate + 30) between entval.effective_start_date (+) and entval.effective_end_date (+) 
group by emp.national_identifier
,  entries.element_type_id 
,  emp.last_name                                   
,  emp.first_name	
,  emp.employee_number			                    
,  loc.location_code   
,  nloan.attribute1     
,  nloan.payment_amount                                
,  nloan.goal_amount		
,  nloan.loan_effective_date							
,  entval.effective_start_date                      
,  entval.effective_end_date				        
,  st.user_status 					                
,  serv.date_start       			                
,  serv.actual_termination_date                     
,  emp.current_employee_flag   
order by nloan.attribute1 desc,emp.last_name, emp.first_name;	                
 -- and emp.national_identifier = '111-38-1312'

--***************************************************************
PROCEDURE main(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER, P_OUTPUT_DIR IN VARCHAR2 ) IS
  --  
 v_output_dir    VARCHAR2(600) := P_OUTPUT_DIR;

l_compare_newloan_output            CHAR(600);
l_compare_dates varchar2(10) null;
l_compare_payment_amt varchar2(10) null;
l_compare_goal_amt varchar2(10) null;



  
BEGIN              ---Starting main 

--dbms_output.put_line('Starting Main ');  
 
    begin
	  select '/d01/ora'||DECODE(name,'PROD','cle',lower(name))
	  ||'/'||lower(name)
	  ||'appl/teletech/11.5.0/data/BenefitInterface'
	  into v_output_dir
	  from V$DATABASE;
    end;

--************************************ Business Unit ******************************************  
begin
  v_compare_newloan_file := UTL_FILE.FOPEN(v_output_dir, p_compare_newloan, 'w'); 

  
	       l_compare_newloan_output := ('SSN'   			 				||'|'||
		                          'Oracle ID'								||'|'||
	                              'Last Name'    		 	 				||'|'||
	                              'First Name'    		 					||'|'||
	                              'Location Code'  		 					||'|'||
								  'Loan 1 Start Date'        				||'|'||	
	                              'New Loan 1 Payment Amount'  		 		||'|'||	
								  'New Loan 1 Goal Amount'  		 		||'|'||
								  'Wachovia Start Date'	 					||'|'||	
								  'Wachovia Payment Amount'					||'|'||
	                              'Wachovia Goal Amount'    				||'|'||
								  'Effective Dates Compare'					||'|'||
								  'Loan Payment Amount Compare'				||'|'||	
								  'Loan Goal Amount Compare'				||'|'||
	                              'Oracle Status'    		 				||'|'||	
	                              'Termination Date' 	 					||'|'||	
								  '401k Plan ID');
								  
       utl_file.put_line(v_compare_newloan_file, l_compare_newloan_output);
	
    for sel in csr_newloan_compare loop

	--Compare Wachovia and System Element start dates.
	
		if (sel.system_start_date = sel.wachovia_start_date) then
		    l_compare_dates := 'TRUE';
		else
			l_compare_dates := 'FALSE';
	    end if;
		
	--Compare Wachovia loan amount system loan amount
	
		if (sel.sys_payment_amt= sel.wachovia_payment_amt) then
		    l_compare_payment_amt := 'TRUE';
		else
			l_compare_payment_amt := 'FALSE';
	    end if;
		
	--  Compare Wachovia loan goal amount with system goal amount 	
		
		if (sel.sys_goal_amt = sel.wachovia_goal_amt) then
		    l_compare_goal_amt := 'TRUE';
		else
			l_compare_goal_amt := 'FALSE';
	    end if;	
		
		
        l_compare_newloan_output := (sel.ssn   			     ||'|'||
	                              sel.oracle_id   		 	 ||'|'||							 
	                              sel.last_name   		 	 ||'|'||
	                              sel.first_name   		 	 ||'|'||
	                              sel.location_code  		 ||'|'||	
	                              sel.system_start_date  	 ||'|'||	
								  sel.sys_payment_amt  	     ||'|'||	
								  sel.sys_goal_amt  	     ||'|'||	
	                              sel.wachovia_start_date	 ||'|'||
								  sel.wachovia_payment_amt	 ||'|'||
								  sel.wachovia_goal_amt	     ||'|'||
								  l_compare_dates    		 ||'|'||	
	                              l_compare_payment_amt   	 ||'|'||	
	                              l_compare_goal_amt    	 ||'|'||	
	                              sel.emp_status    		 ||'|'||	
	                              sel.emp_termed_date 	     ||'|'||	
								  sel.plan_type_id);
								 
       utl_file.put_line(v_compare_newloan_file, l_compare_newloan_output);

    end loop;	

end;

----***********************************************************************************************
UTL_FILE.FCLOSE(v_compare_newloan_file);

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



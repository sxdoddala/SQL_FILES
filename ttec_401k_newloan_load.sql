--******************************************************************************--
--*Program Name: ttec_401k_newloan_load.sql                                   *--   
--*                                                                            *--
--*                                                                            *--
--*Desciption: This program will accomplish the following:                     *--
--*            Read employee information which was supplied by Wachovia        *--
--*            from a temporary table                                          *--
--*	   The program checks if a new loan setup is sent by Wachovia
--*     for a former employee (terminated or deceased status) - then           *--
--*     an Oracle termination report is generated.                             *--
--*                                                                            *--
--*     If a new loan setup is sent by Wachovia with an invalid SSN or invalid *--
--*     location code or if there is already an active loan existing           *--
--*     an error log report is generated.
--*     Report is generated for all new valid loans                            *--

--*    For new 401K loan  call 
--*            PAY_ELEMENT_ENTRY_API.CREATE_ELEMENT_ENTRY   		           *--
--*                                                                            *--
--*Input/Output Parameters                                                     *--
--*                                                                            *--
--*Tables Accessed: CUST.ttec_us_401k_newloan_tbl def
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
--*Procedures Called: PY_ELEMENT_ENTRY.create_element_entry                    *--
--*                  PAY_ELEMENT_ENTRY_API.UPDATE_ELEMENT_ENTRY                *--
--*                                                                            *--
--*Created By: Elizur Alfred-Ockiya                                            *--
--*Date: 11-APR-2005                                                           *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya	 11-APR-2005    File created					           *---
--*                                                 			               *---
--  NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            
--******************************************************************************--

SET timing ON;
SET serveroutput ON SIZE 1000000;

declare

/***Variables used by Common Error Procedure***/
g_validate               boolean 		 := false;
g_entry_type			 varchar2(1)	 := 'E';
        
p_newloan_active        VARCHAR2(50)          := 'NewLoan_Wachovia_Active.txt';
--p_newloan_comparison    VARCHAR2(50)          := 'NewLoan_Comparison.txt';
p_newloan_errorlog      VARCHAR2(50)          := 'NewLoan_ErrorLog.txt'; 
p_newloan_oratermed     VARCHAR2(50)          := 'NewLoan_Oracle_Termed.txt'; 


l_errorlog_output  varchar2(400);         --CHAR(400);
l_updated_output    varchar2(400);       -- CHAR(400);
l_update_status     varchar2(25):= 'Did Not Update';
l_isthere_newloan    varchar2(25):= 'NO';

v_active_file         UTL_FILE.FILE_TYPE;
--v_comparison_file     UTL_FILE.FILE_TYPE;
v_errorlog_file       UTL_FILE.FILE_TYPE;  
v_oratermed_file      UTL_FILE.FILE_TYPE;
 

v_errorlog_count    number := 0; 
--v_updated_count    number := 0;
--*****************************************************************************************************

g_element_name VARCHAR2(50):= 'Loan 1_401k';
g_input_name VARCHAR2(50) := 'Amount';

ERRBUF  VARCHAR2(50);
RETCODE  NUMBER;
P_OUTPUT_DIR   VARCHAR2(400);
/***Exceptions***/

SKIP_RECORD       EXCEPTION;
SKIP_RECORD2       EXCEPTION;
SKIP_RECORD3       EXCEPTION;

/***Cursor declaration***/


cursor csr_newloan is 
select t_type
, ss_number	 	   	  	  social_number
, last_name				  last_name
, first_name			  first_name
, loan_effective_date	  newloan_date
, payment_amount		  payment_amt
, goal_amount			  goal_amt
, unit_division			  unit_division
, attribute1			  plan_type_id
, attribute2			  report_date
--from CUST.ttec_tti_newloan_tbl	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from APPS.ttec_tti_newloan_tbl	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where t_type = '2'
--and ss_number = '541-04-7692';
order by attribute1 desc,last_name,first_name asc; --desc;

 --************************************************************************************--
  --*                          GET ASSIGNMENT ID 									  *--			     
  --************************************************************************************--

    PROCEDURE get_assignment_id 
	                            (v_ssn  IN VARCHAR2 
								,v_employee_number OUT VARCHAR2
								,p_assignment_id       OUT NUMBER
								,p_business_group_id   OUT NUMBER
								,p_effective_start_date OUT DATE
								,p_effective_end_date   OUT DATE) IS

    BEGIN     
	  
	--             l_error_message    := NULL;

              SELECT distinct asg.assignment_id ,emp.employee_number, asg.business_group_id, asg.effective_start_date , asg.effective_end_date 
	          INTO   p_assignment_id,v_employee_number,p_business_group_id , p_effective_start_date, p_effective_end_date 
              --START R12.2 Upgrade Remediation
			  /*FROM   hr.per_all_assignments_f asg,
			         hr.per_all_people_f emp*/
			  FROM   apps.per_all_assignments_f asg,
			         apps.per_all_people_f emp	 
			  --End R12.2 Upgrade Remediation		 
              WHERE  emp.national_identifier = v_ssn
			  AND    emp.person_id = asg.person_id
			  AND    TRUNC(SYSDATE) BETWEEN emp.effective_start_date AND emp.effective_end_date				   
			  AND    asg.primary_flag = 'Y'
		      AND	 asg.assignment_type = 'E'
			  AND	 asg.effective_start_date = (SELECT MAX(asg1.effective_start_date) FROM per_all_assignments_f  asg1
									  WHERE  asg1.person_id = asg.person_id
									  AND  asg1.primary_flag = 'Y'
                    		    	  AND  asg1.assignment_type = 'E');

    EXCEPTION
	
	   WHEN NO_DATA_FOUND THEN
       l_errorlog_output := (rpad(v_ssn,29)
							 ||'No Assignment');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
	   RAISE SKIP_RECORD;
	
		WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Assignments');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD; 
		  	
        WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                         ||'Other Assignment Issue');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
      
	             RAISE SKIP_RECORD;
    END; --*** END GET ASSIGNMENT ID***--  
	
---***********************************  Get Location Code ********************************-----

PROCEDURE  get_location (v_ssn IN VARCHAR2
						,v_unit_division IN VARCHAR2
						,v_location_code OUT VARCHAR2) IS

  l_location_code			 varchar2(150):= null;
						
 begin
    select distinct loc.location_code
	into l_location_code	
	--START R12.2 Upgrade Remediation	
    /*from hr.per_all_people_f emp
       , hr.per_all_assignments_f asg
       , hr.hr_locations_all loc*/
	from apps.per_all_people_f emp
       , apps.per_all_assignments_f asg
       , apps.hr_locations_all loc   
	--End R12.2 Upgrade Remediation   
    where emp.person_id = asg.person_id
    and loc.location_id = asg.location_id
	and asg.primary_flag = 'Y'
	and asg.assignment_type = 'E'
 --   and loc.attribute2  = v_unit_division
    and  trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
	and trunc(sysdate) between asg.effective_start_date and asg.effective_end_date
	and emp.national_identifier = v_ssn;
	--and emp.national_identifier = '053-60-6407'--v_ssn
	
	v_location_code := l_location_code;	

exception
   WHEN NO_DATA_FOUND THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                        ||v_unit_division
							 ||'No Location');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
	  
	      RAISE SKIP_RECORD;
		  
	WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Locations');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD; 	  
         
     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                         ||v_unit_division
							 ||'No Other Location');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          
          RAISE SKIP_RECORD;
end;
--***************************************************************
--*****                  GET PERSON TYPE                *****
--***************************************************************
 --get_person_type(sel.employee_number, l_system_person_type);
PROCEDURE  get_person_type (v_ssn IN VARCHAR2
		   				   ,v_person_id OUT NUMBER
						   ,v_assignment_id IN NUMBER
						   ,v_pay_basis_id OUT NUMBER
						   ,v_employment_category OUT VARCHAR2
						   ,v_people_group_id OUT NUMBER
		  			       ,v_system_person_type OUT VARCHAR2) IS

 v_effective_end_date 	 date 	   := null;

						   
begin
	 select distinct asg.person_id, asg.effective_end_date
	 , asg.pay_basis_id, asg.employment_category
	 , asg.people_group_id,types.system_person_type
	 into v_person_id, v_effective_end_date
	 , v_pay_basis_id, v_employment_category
	 , v_people_group_id, v_system_person_type
	 from
 	 --START R12.2 Upgrade Remediation
	 /*hr.per_all_assignments_f asg,
	 hr.per_all_people_f emp,
	 hr.per_person_types types */
	 apps.per_all_assignments_f asg,
	 apps.per_all_people_f emp,
	 apps.per_person_types types 	
	--End R12.2 Upgrade Remediation	 
	 where  emp.person_id = asg.person_id
	 and types.person_type_id = emp.person_type_id 
	 and asg.primary_flag = 'Y'
	 and asg.assignment_type = 'E'
	 and  trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
	 and trunc(sysdate) between asg.effective_start_date and asg.effective_end_date
	 and  emp.national_identifier = v_ssn;
        
exception
     WHEN NO_DATA_FOUND THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                     ||rpad(v_person_id,20)
                         ||lpad(v_effective_end_date,12)
						 ||'No Person Type'
						 );
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
         RAISE SKIP_RECORD;
		 
	WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Person Types');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD; 		 

     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                     ||rpad(v_person_id,20)
                         ||lpad(v_effective_end_date,12)
						 ||'No Person Type');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          
        RAISE SKIP_RECORD;
end;
---**************************************************************************************

PROCEDURE  get_employee_status (v_ssn IN VARCHAR2
        						,v_system_person_status OUT VARCHAR2) IS

  l_system_person_status	varchar2(50):= null;

  
begin
  
select distinct nvl(amdtl.user_status, sttl.user_status) 
      into v_system_person_status
--START R12.2 Upgrade Remediation	  
/*from   hr.per_all_people_f emp
	,  hr.per_all_assignments_f asg
	,  hr.per_person_types types  
	,  hr.per_ass_status_type_amends_tl amdtl
    ,  hr.per_assignment_status_types_tl sttl  
    ,  hr.per_assignment_status_types st
    ,  hr.per_ass_status_type_amends amd*/ 
from   apps.per_all_people_f emp
	,  apps.per_all_assignments_f asg
	,  apps.per_person_types types  
	,  apps.per_ass_status_type_amends_tl amdtl
    ,  apps.per_assignment_status_types_tl sttl  
    ,  apps.per_assignment_status_types st
    ,  apps.per_ass_status_type_amends amd 	
--End R12.2 Upgrade Remediation	
where  emp.person_id = asg.person_id
and asg.assignment_status_type_id = st.assignment_status_type_id 
and asg.assignment_status_type_id = amd.assignment_status_type_id (+) 
and asg.business_group_id + 0 = amd.business_group_id (+) + 0 
and types.person_type_id = emp.person_type_id  
and asg.primary_flag = 'Y'
and asg.assignment_type = 'E'
and asg.business_group_id = 325
and st.assignment_status_type_id = sttl.assignment_status_type_id
and sttl.language = userenv('LANG') 
and amd.ass_status_type_amend_id = amdtl.ass_status_type_amend_id (+) 
and decode(amdtl.ass_status_type_amend_id,null,'1',
amdtl.language) = decode(amdtl.ass_status_type_amend_id,null,'1',userenv('LANG')) 
and    trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
and	   trunc(sysdate) between asg.effective_start_date and asg.effective_end_date
and emp.national_identifier = v_ssn;
--and rownum < 2;

--v_system_person_status := l_system_person_status;	

exception
   WHEN NO_DATA_FOUND THEN
       l_errorlog_output := (rpad(v_ssn,29)
							 ||'No Employee Status');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
	  
	    RAISE SKIP_RECORD;
		  
	WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Employees Status');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
       
	   RAISE SKIP_RECORD; 	  
         
     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
							 ||'Other Reason for Status');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          
          RAISE SKIP_RECORD;
end;
----************************************Find if employee has loan ****************************-------
PROCEDURE get_element_entry_id (v_ssn IN VARCHAR2
							   ,v_element_entry_id OUT NUMBER
							   ,p_isthere_newloan IN OUT VARCHAR2 ) IS
 						  
							  
begin

   SELECT distinct entry.element_entry_id --- element_entry_id
   INTO v_element_entry_id	
	 FROM
 	 --START R12.2 Upgrade Remediation
	 /*hr.pay_element_entries_f entry,
 	 hr.pay_element_links_f link,
 	 hr.per_all_assignments_f asg,
	 hr.per_all_people_f emp,
	 hr.pay_element_types_f etypes,
	 hr.pay_element_entry_values_f entval,
	 hr.pay_input_values_f input*/
	 apps.pay_element_entries_f entry,
 	 apps.pay_element_links_f link,
 	 apps.per_all_assignments_f asg,
	 apps.per_all_people_f emp,
	 apps.pay_element_types_f etypes,
	 apps.pay_element_entry_values_f entval,
	 apps.pay_input_values_f input
	 --End R12.2 Upgrade Remediation
	 where entry.assignment_id = asg.assignment_id
	 and  link.element_type_id = etypes.element_type_id
	 and entval.element_entry_id = entry.element_entry_id
	 and etypes.element_type_id = input.element_type_id
	 and input.input_value_id = entval.input_value_id
     and input.name = 'Amount'
  	 and  link.element_link_id = entry.element_link_id
	 and  entry.effective_start_date between asg.effective_start_date and asg.effective_end_date
	 and  trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
	 and  entry.effective_start_date between link.effective_start_date and link.effective_end_date  
	 and  emp.person_id = asg.person_id
	 and entry.effective_end_date = (select max(effective_end_date) from pay_element_entries_f entry2
	 where entry.assignment_id = entry2.assignment_id)
	 and entval.effective_start_date = (select max(effective_start_date) from  pay_element_entry_values_f entval2
	 where entval.element_entry_id = entval2.element_entry_id)
	 and  etypes.element_name in ('Loan 1_401k')
	 and  emp.national_identifier = v_ssn;	
	-- and  emp.national_identifier = '012-48-4640'--'373-80-6304';	 

              p_isthere_newloan := 'YES';

exception

     WHEN NO_DATA_FOUND THEN
             p_isthere_newloan := 'NO';
			-- RAISE SKIP_RECORD;

      WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Row in Element Entry');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD;  
		       
     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Other in Element Entry');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD;
end;


--***************************************************************
--*****                  GET Element Link ID                *****
--***************************************************************

PROCEDURE get_element_link_id (v_ssn IN VARCHAR2
		  					  ,v_element_name IN VARCHAR2
		  					  ,v_business_group_id IN NUMBER
							  ,v_pay_basis_id IN NUMBER
							  ,v_employment_category IN VARCHAR2
							  ,v_people_group_id IN NUMBER							   
                              ,v_element_link_id OUT NUMBER) IS

begin
     SELECT link.element_link_id
     INTO v_element_link_id
     --FROM hr.pay_element_links_f link, hr.pay_element_types_f types	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	 FROM apps.pay_element_links_f link, apps.pay_element_types_f types	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
     WHERE link.element_type_id = types.element_type_id
     AND link.business_group_id = v_business_group_id
     AND types.element_name = v_element_name
	 AND nvl(link.employment_category, v_employment_category) = v_employment_category
	 AND nvl(link.people_group_id, v_people_group_id) = v_people_group_id
	 AND nvl(link.pay_basis_id, v_pay_basis_id) = v_pay_basis_id;
        
exception
     WHEN NO_DATA_FOUND THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                     ||rpad(v_element_name,20)
                         ||lpad(v_business_group_id,3)
						 );
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	 
         RAISE SKIP_RECORD;
		 
 	WHEN TOO_MANY_ROWS THEN
       l_errorlog_output := (rpad(v_ssn,29)||'Too Many Link IDs');
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD; 
		
     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                     ||rpad(v_element_name,20)
                         ||lpad(v_business_group_id,3)
						 );
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD;
end;

--***************************************************************
--*****               Create Element Entry            *****
--***************************************************************

PROCEDURE do_create_element_entry (v_ssn IN VARCHAR2
                       ,l_validate IN boolean
		  			   ,l_loan_effective_date IN DATE
					   ,l_business_group_id IN NUMBER
					   ,l_assignment_id IN NUMBER
					   ,l_element_link_id IN NUMBER
                       ,l_input_value_id_amount IN NUMBER
        			   ,l_payment_amt IN NUMBER
                       ,l_input_value_id_owed IN NUMBER
        			   ,l_goal_amt IN NUMBER
					   ,l_update_status IN OUT VARCHAR2) IS
		   
					   
  l_effective_start_date       date;
  l_effective_end_date		   date;
  l_element_entry_id		   number;
  l_object_version_number	   number;
  l_create_warning			   boolean;
			   

begin

       -- create the entry in the HR Schema 
      pay_element_entry_api.create_element_entry
        (p_validate          		  => l_validate
        ,p_effective_date          	  => l_loan_effective_date
	    ,p_business_group_id       	  => l_business_group_id 
        ,p_assignment_id              => l_assignment_id
	    ,p_element_link_id  		  => l_element_link_id
	    ,p_entry_type				  => 'E'
	    ,p_input_value_id1            => l_input_value_id_amount
        ,p_entry_value1               => l_payment_amt
	    ,p_input_value_id2            => l_input_value_id_owed
        ,p_entry_value2               => l_goal_amt		
--Out Parameters
        ,p_effective_start_date       => l_effective_start_date                                        
        ,p_effective_end_date         => l_effective_end_date                                       
        ,p_element_entry_id           => l_element_entry_id
        ,p_object_version_number      => l_object_version_number
        ,p_create_warning             => l_create_warning
         );

		 
		 l_update_status := 'Element Entry Created';
 	 
    commit;     
  EXCEPTION
		       
     WHEN OTHERS THEN
       l_errorlog_output := (rpad(v_ssn,29)
	                         ||'Element Entry Fallout'
	                         ||SQLERRM);
        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
          RAISE SKIP_RECORD;
   --  dbms_output.put_line('After NEW ENTRY Start Date->'||l_effective_start_date ||' '||l_element_entry_id);

	 
	 
end; ----------------End Create Element Entry ********************************************

--***************************************************************
--*****                  MAIN Program                       *****
--***************************************************************
PROCEDURE main(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER, P_OUTPUT_DIR IN VARCHAR2 ) IS
  --  
  v_output_dir    VARCHAR2(400) := P_OUTPUT_DIR;    ---VARCHAR2(240)
  l_active_output 	varchar2(400);  ---CHAR(400);
  v_active_count    number := 0;
  l_oratermed_output 	varchar2(400); --CHAR(400);
  v_oratermed_count    number := 0;
 -- v_termed_count    number := 0;  
 -- l_errorlog_output 	CHAR(242);
 -- v_errorlog_count    number := 0;  
   --l_termed_output 	CHAR(242);
   
 total_payment_amt    number := 0;
 total_goal_amt       number := 0;   
lcalc_payment_amt    number := 0;
lcalc_goal_amt       number := 0;    
   
  l_rows_active_read                number := 0;  -- rows read by api 
  l_rows_active_processed           number := 0;  -- rows processed by api  
  l_rows_active_skipped             number := 0;  -- rows skipped   
  l_rows_read                       number := 0;  -- rows read by api   
  l_rows_skipped                    number := 0;  -- rows skipped  

  l_business_group_id		        number := null;
  
  l_location_code			        varchar2(150);
  l_employee_number                 varchar2(60);
  l_person_id				        number;
  l_assignment_id                   number;
  l_system_person_type		        varchar2(30):= null;
  l_system_person_status            varchar2(50):= null;
  l_element_link_id                 number;
  l_input_value_id1                 number    := null;
  l_input_value_id2                 number    := null;
  l_input_value_id_amount           number    := null;
  l_input_value_id_owed             number    := null;  
  
  v_effective_start_date 	        date 	   := null;
  l_effective_element_date	        date 	   := null;
  l_element_update_date		        date 	   := null;
  l_pay_basis_id			        number    := null;    
  l_employment_category 	        varchar2(10)  := null;
  l_people_group_id 		        number    := null;
  l_screen_entry_value              number;
 -- l_update_status                 varchar2(150):= 'Did Not Update';
  -- OUT parameters
  --  
  l_effective_start_date            date;
  l_effective_end_date		        date;
  l_element_entry_id		        number;
  l_object_version_number	        number;
  l_create_warning			        boolean;
  l_delete_warning			        boolean;
  l_update_warning			        boolean;
  v_todays_date                     date;--varchar2(11);
  l_deferral_date                   date := trunc(sysdate);
  
BEGIN              ---Starting main 

  
    begin
	  select '/d01/ora'||DECODE(name,'PROD','cle',lower(name))
	  ||'/'||lower(name)
	  ||'appl/teletech/11.5.0/data/BenefitInterface'
	  into v_output_dir
	  from V$DATABASE;
    end;
---------------------------------------------------------------------------------------------------------------	
	
	
-------------------------------------------------------------------------------------------------------------  
   begin
    select distinct attribute2  
   into v_todays_date
    --from CUST.ttec_tti_newloan_tbl 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	from apps.ttec_tti_newloan_tbl 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	where t_type = '1'
	and attribute1 = 'TTI';
   end;
-------------------------------------------------------------------------------------------------------------

--***************************************Termed Employees**************************************************  
begin  --writing title 
   v_errorlog_file := UTL_FILE.FOPEN(v_output_dir, p_newloan_errorlog, 'w'); 

----*************************** Writing Error Log Title *********************************
       l_errorlog_output  := rpad(' ',20)||('401(k)  ')||lpad(to_char(v_todays_date,'MM/DD/YYYY'),10);
       utl_file.put_line(v_errorlog_file, l_errorlog_output);
	   l_errorlog_output  := ('Error Log');
      utl_file.put_line(v_errorlog_file, l_errorlog_output);
	   l_errorlog_output  := (rpad(' ',88)||'Loan'||rpad(' ',13)
	                        ||'Error'||rpad(' ',13)||'401k');
         utl_file.put_line(v_errorlog_file, l_errorlog_output);
	   l_errorlog_output := (rpad(' ',24)||'SSN'||rpad(' ',6)
	                       ||'Oracle ID'||rpad(' ',2)
						   ||'Last Name'||rpad(' ',16)
						   ||rpad(' ',2)
	                       ||'First Name'||rpad(' ',7)
	                       ||'Eff-Date'||rpad(' ',8)||'Message'||rpad(' ',11)
						   ||'Plan ID');
        utl_file.put_line(v_errorlog_file, l_errorlog_output);
----***************************** End Writing Error Log Title ************************  

--****************************** Begin Loading data into Oracle *****************************************
-- begin ---begin loading into oracle 

 v_active_file := UTL_FILE.FOPEN(v_output_dir, p_newloan_active, 'w'); 
 v_oratermed_file:= UTL_FILE.FOPEN(v_output_dir, p_newloan_oratermed, 'w');

----*************************** Opening Active Report and Writing Report Title ************************** 
      l_active_output  := rpad(' ',20)||('401(k)  ')||lpad(to_char(v_todays_date,'MM/DD/YYYY'),10);
       utl_file.put_line(v_active_file, l_active_output);
	  l_active_output   := ('Oracle Actives');
      utl_file.put_line(v_active_file, l_active_output);
	  l_active_output   := (rpad(' ',88)
	                       ||'Loan' 
						   ||rpad(' ',11)
						   ||'Payment'
	                       ||rpad(' ',7)
						   ||'Goal'
						   ||rpad(' ',4)
						   ||'Oracle'
						   ||rpad(' ',35)
						   ||'401k');
          utl_file.put_line(v_active_file, l_active_output);
	  l_active_output  := (rpad(' ',24)||'SSN' 
	                       ||rpad(' ',6)
						   ||'Oracle ID'||rpad(' ',4)
	                       ||'Last Name'||rpad(' ',16)
	                       ||'First Name'||rpad(' ',5)
	                       ||'Eff-Date'||rpad(' ',9)
						   ||'Amount'||rpad(' ',7)
						   ||'Amount'||rpad(' ',3)						   
						   ||'Status'||rpad(' ',14)
						   ||'Location'||rpad(' ',12)
						   ||'Plan ID'
						   ||rpad(' ',6)
						   ||'Load Status');
        utl_file.put_line(v_active_file, l_active_output);
---***************************************** Oracle Termed Employees ***************************		
		
       l_oratermed_output  := rpad(' ',20)||('401(k)  ')||lpad(to_char(v_todays_date,'MM/DD/YYYY'),10);
       utl_file.put_line(v_oratermed_file, l_oratermed_output);
	  l_oratermed_output   := ('Oracle Termed');
     utl_file.put_line(v_oratermed_file, l_oratermed_output);
	  l_oratermed_output  := (rpad(' ',90)
	                        ||'Loan'||rpad(' ',10)
	                        ||'Oracle'||rpad(' ',40)||'401k');
         utl_file.put_line(v_oratermed_file, l_oratermed_output);
	  l_oratermed_output  := (rpad(' ',24)||'SSN'||rpad(' ',6)
	                       ||'Oracle ID'||rpad(' ',2)
						   ||'Last Name'||rpad(' ',18)
	                       ||'First Name'||rpad(' ',7)
	                       ||'Eff-Date'||rpad(' ',8)
						   ||'Status'||rpad(' ',12)
						   ||'Location'||rpad(' ',19)
						   ||'Plan ID');
        utl_file.put_line(v_oratermed_file, l_oratermed_output);
		
end; --writing title		
----********************************** Start Processing Active Employees ***************************************
Begin

for sel in csr_newloan loop 

l_rows_read := l_rows_read + 1;

 
 Begin
-- dbms_output.put_line('Rows Read '||l_rows_read); 
 get_assignment_id (sel.social_number,l_employee_number,l_assignment_id, l_business_group_id,l_effective_start_date, l_effective_end_date);
 --dbms_output.put_line('Employee Number '||l_employee_number);    
 
 get_location(sel.social_number,sel.unit_division,l_location_code); 

--dbms_output.put_line('Employee Unit '||sel.unit_division||'Location Code '||l_location_code);     

 get_person_type(sel.social_number,l_person_id,l_assignment_id,l_pay_basis_id,l_employment_category,l_people_group_id, l_system_person_type);

--dbms_output.put_line('Employee Assgn '||l_assignment_id||'Person Type'||l_system_person_type||'Pay Basis '||l_pay_basis_id||'P_Group_Id '||l_people_group_id); 
 
 get_employee_status(sel.social_number,l_system_person_status);	 

 -- dbms_output.put_line('Employee SSN '||sel.social_number||'EMP_NO: '||l_employee_number ||'Empl Category '||l_employment_category||'Employee Status'||l_system_person_status);     

	 if l_system_person_status = 'Terminate - Process' then
        l_oratermed_output := (rpad(' ',20)
	                     ||rpad(sel.social_number,11)
	                     ||rpad(' ',2)
	                     ||lpad(l_employee_number ,9)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.last_name,' '),1,25),25)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.first_name,' '),1,15),15)
						 ||rpad(' ',2)						 
						 ||lpad(to_char(sel.newloan_date ,'MM/DD/YYYY'),10) 
						 ||rpad(' ',2)
						 ||rpad(l_system_person_status,20)
						 ||rpad(' ',2)
						 ||rpad(l_location_code,25)
						 ||rpad(' ',4)	
						 ||rpad(sel.plan_type_id,4)
						 );
        v_oratermed_count := v_oratermed_count + 1; 
       utl_file.put_line(v_oratermed_file,l_oratermed_output); 
	  end if;  
  
IF l_system_person_status <> 'Terminate - Process' then      ---person_status

    l_isthere_newloan := 'NO';
	l_element_entry_id := null;
	--begin
	   get_element_entry_id(sel.social_number,l_element_entry_id,l_isthere_newloan);
	   
--dbms_output.put_line('Employee Number '||sel.social_number||'Element ID'||l_element_entry_id);
 	   
--dbms_output.put_line('Loan Status '||l_isthere_newloan);    

 
   if l_isthere_newloan = 'YES' then

       l_errorlog_output :=(rpad(' ',20)
	                     ||rpad(sel.social_number,11)
	                     ||rpad(' ',2)
	                     ||lpad(l_employee_number ,9)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.last_name,' '),1,25),25)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.first_name,' '),1,15),15)
						 ||rpad(' ',2)
						 ||lpad(to_char(sel.newloan_date ,'MM/DD/YYYY'),10) 
						 ||rpad(' ',2)
						 ||rpad('Has existing loan',20)
						 ||rpad(' ',4)
						 ||rpad(sel.plan_type_id,4)
						 ||rpad(' ',2)						 							 
						 );	  

        v_errorlog_count := v_errorlog_count + 1; 
       utl_file.put_line(v_errorlog_file,l_errorlog_output);	
    --  end if;
	   
    --   if l_isthere_newloan = 'NO' and l_element_entry_id = null then
	 else  
	   lcalc_payment_amt   := 0;
       lcalc_goal_amt      := 0;

     --    l_rows_read := l_rows_read + 1;
 
     begin 
 	  SELECT input.input_value_id
      INTO l_input_value_id_amount
      --FROM hr.pay_input_values_f input, hr.pay_element_types_f etypes	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	  FROM apps.pay_input_values_f input, apps.pay_element_types_f etypes	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
      WHERE etypes.element_type_id = input.element_type_id
      AND etypes.element_name = 'Loan 1_401k'
      AND input.name = 'Amount'---g_input_name
	  AND input.business_group_id = 325;
     end;  

	begin 
 	  SELECT input.input_value_id
      INTO l_input_value_id_owed 
      --FROM hr.pay_input_values_f input, hr.pay_element_types_f etypes	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	  FROM apps.pay_input_values_f input, apps.pay_element_types_f etypes	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
      WHERE etypes.element_type_id = input.element_type_id
      AND etypes.element_name = 'Loan 1_401k'
      AND input.name = 'Total Owed'---g_input_name
	  AND input.business_group_id = 325;
    end;  
	 
	 
	  get_element_link_id(sel.social_number, g_element_name, l_business_group_id, l_pay_basis_id
	  					,l_employment_category, l_people_group_id, l_element_link_id);
						
   --dbms_output.put_line('Employee Number	 ' ||l_employee_number ||'Element Name '||g_element_name||' Element Link '||l_element_link_id||' Input Value '||l_input_value_id1);  	      
	  
	  l_update_status := 'Did Not Update';
	  
	  do_create_element_entry(sel.social_number,g_validate,sel.newloan_date,l_business_group_id,l_assignment_id
	      ,l_element_link_id,l_input_value_id_amount,sel.payment_amt,l_input_value_id_owed,sel.goal_amt,l_update_status);

 --   end if;	
--	end;
  
  ----- Active enteries -----------
	  
 -----*********************************Print Active Files *****************************************--------

 ---*******************************************************************************************-------
 --  end if; --	keeping track of datetrack issues ---- 26-apr-2005
   
   	 --  lcalc_payment_amt   := nvl(sel.payment_amt,0),'09999.99');
      -- lcalc_goal_amt      := nvl(sel.goal_amt,0),'09999.99');
   
   
   
 	           l_active_output := (rpad(' ',20)
			             ||lpad(substr(nvl(sel.social_number,' '),1,11),11)
						 ||rpad(' ',2)
						 ||lpad(substr(nvl(l_employee_number, ' '),1,9),9)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.last_name,' '),1,25),25)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(sel.first_name,' '),1,15),15)
						 ||rpad(' ',2)						 
						 ||lpad(to_char(sel.newloan_date ,'MM/DD/YYYY'),10,' ') 
						 ||rpad(' ',2)
                         ||lpad(sel.payment_amt,7)
						 ||rpad(' ',5)
                         ||lpad(sel.goal_amt,7)
						 ||rpad(' ',5)
						 ||lpad(substr(nvl(l_system_person_status,' '),1,20),20)
						 ||rpad(' ',2)
						 ||rpad(substr(nvl(l_location_code,' '),1,25),25)
						 ||rpad(' ',2)					 
						 ||lpad(substr(nvl(sel.plan_type_id,' '),1,4),4)
						 ||rpad(' ',2)
						 ||lpad(substr(nvl(l_update_status,' '),1,25),25));
						 
						 
	      total_payment_amt := total_payment_amt + sel.payment_amt;
             total_goal_amt := total_goal_amt + sel.goal_amt;  				 
						 
						 
        v_active_count := v_active_count + 1; 
       utl_file.put_line(v_active_file,l_active_output); 
	end if;   
--end;	   
 ---**********************************************************************************************************
END IF; -- person_status
exception
  	 WHEN SKIP_RECORD THEN
	 null; 
end;    
end loop; 
 
  commit;  -- commit any final rows   
  
  ---************************************ Summary of Active Employees **************************--------	
l_active_output := rpad(' ',24);
        utl_file.put_line(v_active_file,l_active_output);	
l_active_output := rpad(' ',24);
        utl_file.put_line(v_active_file,l_active_output);			
    l_active_output := ('Total Summary'
	                   ||rpad(' ',12)
  				       ||rpad(v_active_count,4)
					   ||rpad(' ',71)
					   ||lpad(total_payment_amt,10)
					   ||rpad(' ',2)
					   ||lpad(total_goal_amt,10));
					   
        utl_file.put_line(v_active_file,l_active_output);	
		
	  
---***********************************End Summary of Active Employees ****************************--------

---************************************** Summary of Error Records ***************************---------
	
	l_errorlog_output := rpad(' ',24);
         utl_file.put_line(v_errorlog_file,l_errorlog_output);	
	l_oratermed_output := rpad(' ',24);
         utl_file.put_line(v_oratermed_file,l_oratermed_output);		 	
    l_errorlog_output := ('Records with Errors'
	                   ||rpad(' ',8)
  				       ||rpad(v_errorlog_count,4));
        utl_file.put_line(v_errorlog_file,l_errorlog_output);	
			 
		
-----*********************************** End Summary of Error Records ************************-----------	 
---**************************************** Summary of Oracle Termed ********************-- 
	
	l_oratermed_output := rpad(' ',24);
         utl_file.put_line(v_oratermed_file,l_oratermed_output);	
	l_oratermed_output := rpad(' ',24);
         utl_file.put_line(v_oratermed_file,l_oratermed_output);		 	
    l_oratermed_output := ('Oracle Termed'
	                   ||rpad(' ',12)
  				       ||rpad(v_oratermed_count,4));
        utl_file.put_line(v_oratermed_file,l_oratermed_output);	

--*******************************************************************************************--- 


-- ********************************************End Element Entries   ----------

end;  
	  		
  UTL_FILE.FCLOSE(v_active_file);

  UTL_FILE.FCLOSE(v_oratermed_file);	

  UTL_FILE.FCLOSE(v_errorlog_file);  
 
  
END; --ending main procedure 
--***************************************************************
--*****                  Call Main procedure                *****
--***************************************************************

begin
     main(ERRBUF, RETCODE, P_OUTPUT_DIR);
	 EXCEPTION
	 WHEN SKIP_RECORD2 THEN
	 null;
end;
/



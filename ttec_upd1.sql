--************************************************************************************--
--*                                                                                  *--
--*     Program Name: conv_us_hr_assignment_translate.sql                            *--
--*                                                                                  *--
--*     Description:  The Assignments information from TeleTech will be converted 	 *--
--*  		 		   into the Oracle HR application tables.  This will be 		 *--
--*				   accomplished using a series of Oracle HR APIs: 		 			 *--
--*				   HR_ASSIGNMENT_API.update_us_emp_asg AND 							 *--
--*				   HR_ASSIGNMENT_API.update_emp_asg_criteria.  						 *--
--*				   The Assignments data will be extracted from the 					 *--
--*				   TeleTech legacy systems into staging tables.  A PL/SQL 			 *--
--*				   program will be used to translate the data and call the API 		 *--
--*				   that will load the data into the application tables.  Only 		 *--
--*				   the assignments data for active employees will be converted. 	 *--
--*                                                                                  *--
--*     Input/Output Parameters:                                                     *--
--*                                                                                  *--
--*     Tables Accessed:   CONV_HR_ASSIGNMENT_STAGE                                  *--
--*                        FND_COMMON_LOOKUPS                                        *--
--*                        GL_CODE_COMBINATIONS                                      *--
--*                        GL_SETS_OF_BOOKS                                          *--
--*                        HR_ALL_ORGANIZATION_UNITS                                 *--
--*                        HR_LOOKUPS                                                *--
--*                        HR_TAX_UNITS_V                                            *--
--*                        TTEC_ERROR_HANDLING                                      *--
--*                        PAY_ALL_PAYROLLS_F                                        *--
--*                        PER_ALL_ASSIGNMENTS_F                                     *--
--*                        PER_ALL_PEOPLE_F                                          *--
--*                        PER_GRADES                                                *--
--*                        PER_JOB_DEFINITIONS                                       *--
--*                        PER_JOBS                                                  *--
--*                        PER_PAY_BASES                                             *--
--*                                                                                  *--
--*     Tables Modified:   CONV_US_HR_ASG_STAGE									  	 *--
--*                        TTEC_ERROR_HANDLING                                       *--
--*                        PER_ALL_ASSIGNMENTS_F                                     *--
--*                        PER_ALL_PEOPLE_F                                          *--
--*                                                                                  *--
--*     Procedures Called: HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA                 *--
--*                        HR_ASSIGNMENT_API.UPDATE_US_EMP_ASG                       *--
--*                        TTEC_PROCESS_ERROR                                        *--
--*                                                                                  *--
--*Created By: David Thakker                                                   		 *--
--*Date: 06/20/2001                                                            		 *--
--*                                                                            		 *--
--*Modification Log:                                                           		 *--
--*Developer    Date        Description                                        		 *--
--*---------    ----        -----------                                        		 *--
--*D.Thakker   06/20        File created                                       		 *--
--*D.Thakker   07/15		Added comments in Main procedure documenting the		 *--
--*			   				correction/update rules for this conversion	 			 *--
--*D.Thakker   07/17		Made program US specific		 						 *--	
--*D.Thakker   07/30		Sucessfully tested with 5 records in CRP1				 *--						
--*D.Thakker   08/14		Loaded 53 records into DEV		  	 					 *--
--*D.Thakker   09/18		Updated procs and Main 									 *--
--*D.Thakker   09/26		Updated effective dates									 *--
--*D.Thakker   09/27		Loaded 141 records into DEV		  	 					 *--
--*D.Thakker   10/02		Included People Group segments in update_emp_asg_criteria*--
--*D.Thakker   10/04		Fixed GET DEFAULT CODE COMBINATIONS ID					 *--
--*D.Thakker   10/07		Added UPDATE statement to insert 'CHANGE_REASON'		 *--
--*D.Thakker   10/08		Loaded 13410 / 14016 records into HRSYSINT				 *--
--*D.Thakker   10/15		Added Costing API and changed logic for North H.Wood	 *-- 
--*			   				Location mapping
--*D.Thakker   10/23		Added suspense code logic; Added more date logic in MAIN	  	  	  
--*D.Thakker   11/06	   Loaded 13647/13649 into GOLD		  			
--*D.Thakker   11/21	   Added in additional logic for client code of 9222
--*NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation
--************************************************************************************--
    
    
--    SET TIMING ON
    SET SERVEROUTPUT ON SIZE 1000000;
    
    DECLARE

    --*** VARIABLES USED BY COMMON ERROR HANDLING PROCEDURES ***--
	--START R12.2 Upgrade Remediation
    /*c_application_code            CUST.ttec_error_handling.application_code%TYPE  := 'HR';
    c_interface                   CUST.ttec_error_handling.interface%TYPE := 'CON-07';
    c_program_name                CUST.ttec_error_handling.program_name%TYPE  := 'ttec_pay_cost_upd030131';
    c_initial_status              CUST.ttec_error_handling.status%TYPE  := 'INITIAL';
    c_warning_status              CUST.ttec_error_handling.status%TYPE  := 'WARNING';
    c_failure_status              CUST.ttec_error_handling.status%TYPE  := 'FAILURE';*/
	c_application_code            apps.ttec_error_handling.application_code%TYPE  := 'HR';
    c_interface                   apps.ttec_error_handling.interface%TYPE := 'CON-07';
    c_program_name                apps.ttec_error_handling.program_name%TYPE  := 'ttec_pay_cost_upd030131';
    c_initial_status              apps.ttec_error_handling.status%TYPE  := 'INITIAL';
    c_warning_status              apps.ttec_error_handling.status%TYPE  := 'WARNING';
    c_failure_status              apps.ttec_error_handling.status%TYPE  := 'FAILURE';
	--End R12.2 Upgrade Remediation

    --User specified variables
    p_validate BOOLEAN 		  := false;--:= &validate;
	p_org_name VARCHAR2(40)	  := 'TeleTech Holdings - CAN';


    --*** Global Variable Declarations ***--
	g_default_code_comb_seg5	   VARCHAR2(4)	 := '0000';
	g_default_code_comb_seg6	   VARCHAR2(4)	 := '0000';
	g_proportion				   NUMBER		 := 1;
	
    g_total_employees_read       NUMBER := 0;
    g_total_employees_processed  NUMBER := 0;
    g_total_record_count           NUMBER := 0;
    g_primary_column               VARCHAR2(60):= NULL;
    l_commit_point                 NUMBER := 20; 
    l_rows_processed               NUMBER := 0; 

    --*** EXCEPTIONS ***-- 
    SKIP_RECORD                   EXCEPTION;


    --*** CURSOR DECLARATION TO SELECT ROWS FROM CONV_HR_ASSIGNMENT_STAGE STAGING TABLE ***--
    CURSOR csr_cuhas IS				
    SELECT employee_number, client,effective_date
    --FROM   CUST.TTEC_TEMP_US_CLIENT_UPDATE cuhas	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	FROM   apps.TTEC_TEMP_US_CLIENT_UPDATE cuhas	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
   	;

    

--***************************************************************
--*****                  GET Business Group ID              *****
--***************************************************************

PROCEDURE get_business_group_id (v_business_group_id OUT NUMBER, v_org_name IN VARCHAR2) IS
--START R12.2 Upgrade Remediation
/*l_module_name              CUST.ttec_error_handling.MODULE_NAME%TYPE := 'get_business_group_id';
l_label1                   CUST.ttec_error_handling.LABEL1%TYPE      := 'Org Name';
l_reference1               CUST.ttec_error_handling.REFERENCE1%TYPE;  */
l_module_name              apps.ttec_error_handling.MODULE_NAME%TYPE := 'get_business_group_id';
l_label1                   apps.ttec_error_handling.LABEL1%TYPE      := 'Org Name';
l_reference1               apps.ttec_error_handling.REFERENCE1%TYPE;  
--End R12.2 Upgrade Remediation

BEGIN

     SELECT org.business_group_id
     INTO v_business_group_id
     FROM hr_organization_units org
     WHERE org.name = v_org_name;

EXCEPTION
     WHEN NO_DATA_FOUND THEN
          l_reference1 := v_org_name;
          
          --CUST.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  apps.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
          c_warning_status, SQLCODE, 'No business group id for this org', l_label1, l_reference1);
          
          v_business_group_id := NULL;
          
          RAISE SKIP_RECORD;
          
     WHEN TOO_MANY_ROWS THEN
          l_reference1 := v_org_name;
          
          --CUST.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  apps.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
          c_warning_status, SQLCODE, 'More than one business group id for this org', l_label1, l_reference1);
          
          v_business_group_id := NULL;
          
          RAISE SKIP_RECORD;
          
     WHEN OTHERS THEN
          l_reference1 := v_org_name;
          
          --CUST.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  apps.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
          c_failure_status, SQLCODE, SQLERRM, l_label1, l_reference1);
          
          v_business_group_id := NULL;
          
          RAISE;
END;


--***************************************************************
--*****                  GET Suspense Acct ID               *****
--***************************************************************

PROCEDURE get_suspense_acct_id (v_suspense_acct_id OUT NUMBER) IS

--l_module_name              CUST.ttec_error_handling.MODULE_NAME%TYPE := 'get_suspense_acct_id'; -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name              apps.ttec_error_handling.MODULE_NAME%TYPE := 'get_suspense_acct_id';	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 


BEGIN

	 					SELECT glc.code_combination_id
						INTO   v_suspense_acct_id
						FROM   apps.gl_code_combinations glc
						WHERE  glc.segment1 = '01002'
						AND    glc.segment2 = '0000'
						AND    glc.segment3 = '000'
						AND    glc.segment4 = '1999'
						AND    glc.segment5 = '0000'
						AND    glc.segment6 = '0000'
						AND	   glc.enabled_flag = 'Y';
						
EXCEPTION
          
     WHEN OTHERS THEN
          
          --CUST.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  apps.ttec_process_error(c_application_code, c_interface, c_program_name, l_module_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
          c_failure_status, SQLCODE, SQLERRM);
          
          RAISE;
END;

  --************************************************************************************--
  --*                            GET PERSON ID 									       *--			     
  --************************************************************************************--

    PROCEDURE get_person_id (v_person_id OUT NUMBER, v_per_eff_start_date OUT DATE,
                             v_employee_number IN VARCHAR2, v_business_group_id IN NUMBER) IS
    
	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_person_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Employee SSN';
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;    */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_person_id';	
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Employee SSN';
    l_error_message    apps.ttec_error_handling.error_message%TYPE;    
	--End R12.2 Upgrade Remediation							

    BEGIN     

--dbms_output.put_line('     '||v_employee_number); 
              SELECT peep.person_id, peep.effective_start_date
              INTO   v_person_id, v_per_eff_start_date
              --FROM   hr.per_all_people_f peep, hr.per_person_types peeptype	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.per_all_people_f peep, apps.per_person_types peeptype	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
              WHERE peep.employee_number = v_employee_number
			  AND	peep.business_group_id = v_business_group_id
			  AND peep.person_type_id = peeptype.person_type_id
			  AND peeptype.system_person_type = 'EMP';
--dbms_output.put_line(v_person_id); 
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Person ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Person ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_employee_number);
             RAISE;
    END; --*** END GET PERSON ID ***--


  --************************************************************************************--
  --*                          GET ASSIGNMENT ID 									  *--			     
  --************************************************************************************--

    PROCEDURE get_assignment_id (v_assignment_id OUT NUMBER
			  					,v_asg_eff_date  OUT DATE			  									 
			  					,v_employee_number IN VARCHAR2 
                                ,v_person_id IN VARCHAR2
								,v_business_group_id IN NUMBER) IS

    --START R12.2 Upgrade Remediation
	/*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_assignment_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Employee SSN';
	l_label2           CUST.ttec_error_handling.label2%TYPE := 'Person ID';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_assignment_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Employee SSN';
	l_label2           apps.ttec_error_handling.label2%TYPE := 'Person ID';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--START R12.2 Upgrade Remediation

    BEGIN     

              SELECT asg.assignment_id, asg.effective_start_date
              INTO   v_assignment_id, v_asg_eff_date
              --FROM   hr.per_all_assignments_f asg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.per_all_assignments_f asg -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 		
              WHERE  asg.person_id = v_person_id
			  AND	 asg.primary_flag = 'Y'
			  AND	 asg.assignment_type = 'E'
			  AND	 asg.effective_start_date = (select max(asg2.effective_start_date) 
			  		 						  	 --from hr.per_all_assignments_f asg2 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
												 from apps.per_all_assignments_f asg2 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
												 where  asg2.person_id = v_person_id
			  									 and asg2.primary_flag = 'Y'
			  									 and asg2.assignment_type = 'E'
												 and asg2.business_group_id = v_business_group_id
												 )
			  AND asg.business_group_id = v_business_group_id  
			  ;

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Assignment ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number, l_label2, v_person_id);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Assignment ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number, l_label2, v_person_id);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_employee_number, l_label2, v_person_id);
             RAISE;
    END; --*** END GET ASSIGNMENT ID***--  
    
    
    
  --************************************************************************************--
  --*                               GET SUPERVISOR ID            	                   *--			     
  --************************************************************************************--

    PROCEDURE get_supervisor_id (v_supervisor_id OUT NUMBER
			  					,v_supervisor_eff_date OUT DATE
			  					,v_supervisor_ssn IN VARCHAR2
								,v_business_group_id IN NUMBER
								,v_emp_ssn IN VARCHAR2) IS
    
	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_supervisor_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Supervisor SSN';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_supervisor_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Supervisor SSN';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE;                                  									
	--End R12.2 Upgrade Remediation

    BEGIN     
              SELECT peep.person_id, peep.effective_start_date
              INTO   v_supervisor_id, v_supervisor_eff_date
              --FROM   hr.per_all_people_f peep, hr.per_person_types peeptype	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.per_all_people_f peep, apps.per_person_types peeptype	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
              WHERE  peep.national_identifier = v_supervisor_ssn
			  AND peep.business_group_id = v_business_group_id
  			  AND peep.person_type_id = peeptype.person_type_id
			  AND peeptype.system_person_type = 'EMP';


    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Supervisor ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_supervisor_ssn, l_label2, v_emp_ssn);


             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Supervisor ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_supervisor_ssn, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_supervisor_ssn, l_label2, v_emp_ssn);
             RAISE;
    END; --*** END GET SUPERVISOR ID ***--





  --************************************************************************************--
  --*                       GET OBJECT VERSION NUMBER (outer select)  	               *--			     
  --************************************************************************************--

    PROCEDURE get_pay_cost_alloc_info (v_cost_allocation_id OUT NUMBER 
                                         ,v_proportion OUT NUMBER
                                         ,v_object_version_number OUT NUMBER
                                         ,v_assignment_id IN NUMBER
										 ,v_employee_number IN VARCHAR2) IS


    l_person_id        number;
	l_per_date		   date;
    --START R12.2 Upgrade Remediation
	/*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_pay_cost_alloc_info';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Person ID';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_pay_cost_alloc_info';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Person ID';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--End R12.2 Upgrade Remediation

    BEGIN     

			  
              SELECT cost_allocation_id
                    ,proportion
                    ,object_version_number
              INTO   v_cost_allocation_id
                    ,v_proportion
                    ,v_object_version_number
              --FROM   hr.pay_cost_allocations_f	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.pay_cost_allocations_f	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
              WHERE  object_version_number = ( SELECT MAX(a.object_version_number)
                                               --FROM hr.pay_cost_allocations_f a	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
											   FROM apps.pay_cost_allocations_f a	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                               WHERE a.assignment_id = v_assignment_id )
              AND assignment_id = v_assignment_id;


    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Object Version Number returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_assignment_id, l_label2, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Object Version Number returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name, 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_assignment_id, l_label2, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_assignment_id, l_label2, v_employee_number);
             RAISE;
    END; --*** END GET OBJECT VERSION NUMBER (OUTER SELECT) ***--




  --************************************************************************************--
  --*                                    GET JOB ID        				               *--			     
  --************************************************************************************--

    PROCEDURE get_job_id (v_job_id OUT NUMBER 
                          ,v_job_code IN VARCHAR2
                          ,v_date IN DATE
                          ,v_business_group_id IN NUMBER
						  ,v_emp_ssn	 IN VARCHAR2) IS

    v_job_definition_id   NUMBER;
	--START R12.2 Upgrade Remediation
    /*l_module_name         CUST.ttec_error_handling.module_name%TYPE := 'get_job_id';
    l_label1              CUST.ttec_error_handling.label1%TYPE := 'Job Code';
    l_label2           	  CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message       CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name         apps.ttec_error_handling.module_name%TYPE := 'get_job_id';
    l_label1              apps.ttec_error_handling.label1%TYPE := 'Job Code';
    l_label2           	  apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message       apps.ttec_error_handling.error_message%TYPE; 
	--End R12.2 Upgrade Remediation
    BEGIN 
			  
              SELECT jobs.job_id
              INTO   v_job_id
              --FROM   hr.per_jobs jobs, hr.per_job_definitions jobdef	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.per_jobs jobs, apps.per_job_definitions jobdef	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              WHERE  jobs.job_definition_id = jobdef.job_definition_id
			  AND	 jobdef.segment1 = v_job_code
              AND trunc(v_date) between jobs.date_from and decode(jobs.date_to, NULL, to_date('31-DEC-4712'), jobs.date_to)
              AND jobs.business_group_id = v_business_group_id;

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Job ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_job_code, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Job ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,  	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_job_code, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name, -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_job_code, l_label2, v_emp_ssn);
             RAISE;
    END; --*** END GET JOB ID ***--

    

  --************************************************************************************--
  --*                                    GET PAYROLL ID       				          *--			     
  --************************************************************************************--

    PROCEDURE get_payroll_id (v_payroll_id OUT NUMBER 
                              ,v_payroll_name IN VARCHAR2
                              ,v_business_group_id IN NUMBER
							  ,v_emp_ssn	 IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_payroll_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Payroll Name';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_payroll_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Payroll Name';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--End R12.2 Upgrade Remediation

	l_payroll_name	   VARCHAR2(30); 

    BEGIN     


		IF v_payroll_name = 'U4T' THEN
		   l_payroll_name := 'Corporate (U4T)';
			  
		ELSIF v_payroll_name = 'V76' THEN
			  l_payroll_name := 'Percepta (V76)';
				 
		ELSIF v_payroll_name = 'U38' THEN
			  l_payroll_name := 'Holdings (U38)'; 
			  
		ELSIF v_payroll_name = 'T9D' THEN
			  l_payroll_name := 'TeleTech CCM - General (T9D)';
		
		ELSE 
			 l_payroll_name :='TeleTech';
			 
		END IF;
			  
		SELECT payroll_id
        INTO   v_payroll_id
        --START R12.2 Upgrade Remediation
		/*FROM   hr.pay_all_payrolls_f
        WHERE  hr.pay_all_payrolls_f.payroll_name  = l_payroll_name */
		FROM   apps.pay_all_payrolls_f
        WHERE  apps.pay_all_payrolls_f.payroll_name  = l_payroll_name 
		--End R12.2 Upgrade Remediation
        AND business_group_id = v_business_group_id;

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Payroll ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_payroll_name, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Payroll ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_payroll_name, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_payroll_name, l_label2, v_emp_ssn);
             RAISE;
    END; --*** END GET PAYROLL ID ***--


  
  --************************************************************************************--
  --*                                   GET LOCATION ID        				          *--			     
  --************************************************************************************--

    PROCEDURE get_location_id (v_location_id OUT NUMBER
			  				   ,v_segment1 OUT VARCHAR2
							   ,v_data_control IN VARCHAR2 
                               ,v_location_code IN VARCHAR2
							   ,v_company	 IN VARCHAR2
							   ,v_emp_ssn	 IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_location_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Location Code';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Company';
    l_label3           CUST.ttec_error_handling.label3%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_location_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Location Code';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Company';
    l_label3           apps.ttec_error_handling.label3%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--End R12.2 Upgrade Remediation
	l_location_name    VARCHAR2(40) := null; 


	BEGIN
	
	IF v_location_code = '100' THEN
	   IF v_company = 'U38' THEN
	   
	   	  l_location_name := 'USA-Englewood (TTEC)';
		  
	   ELSIF v_company = 'U3T' THEN   
	   
	      l_location_name := 'USA-Englewood (VER)';
		  
	   ELSIF v_company = 'UJ6' THEN   
	   
	      l_location_name := 'USA-Englewood (UPS)';
		  
	   ELSIF v_company = 'U3V' THEN   
	   
	      l_location_name := 'USA-Denver East';
		  
	   ELSIF v_company = '98Y' THEN   
	   
	      l_location_name := 'USA-Englewood (ENHV)';
		  
	   ELSIF v_company = 'V76' THEN   
	   
	      l_location_name := 'USA-Englewood (PCTA)';	  	  	  
		  
	   ELSIF v_company = 'U4T' THEN   
	   
	      l_location_name := 'USA-Englewood (TTEC)';
	
	   END IF;
	   
		SELECT location_id, attribute2
	    INTO   v_location_id, v_segment1
	    --FROM   hr.hr_locations_all	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM   apps.hr_locations_all	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	    WHERE  location_code = l_location_name;
	
	ELSIF v_location_code = '202' THEN  --<<<<<ADD in DATA CONTROL FROM NEW EXTRACT>>>>--
	   IF v_data_control = 'NX' THEN
	   
	   	  l_location_name := 'USA-N. Holywd (NXTL)';
		  
	   ELSIF v_data_control = 'NH' THEN   
	   
	      l_location_name := 'USA-N. Holywd (TTEC)';
		  
	   END IF;
	   
	   SELECT location_id, attribute2
	    INTO   v_location_id, v_segment1
	    --FROM   hr.hr_locations_all	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM   apps.hr_locations_all	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	    WHERE  location_code = l_location_name;
		
	ELSE	
	
	    SELECT location_id, location_costing
	    INTO   v_location_id, v_segment1
	    --FROM   cust.conv_us_hr_loc_map	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM   apps.conv_us_hr_loc_map		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	    WHERE  legacy_location_code = v_location_code;
		
	END IF;	

    
	EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Location ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_location_code, l_label2, v_company, 
									   l_label3, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Location ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_location_code, l_label2, v_company, 
									   l_label3, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_location_code, l_label2, v_company, 
									   l_label3, v_emp_ssn);
             RAISE;
    END; --*** END GET LOCATION ID ***--

--************************************************************************************--
--*                                GET ORGANIZATION ID     				          *--			     
--************************************************************************************--

    PROCEDURE get_organization_id (v_organization_id OUT NUMBER 
                                   ,v_org_code IN VARCHAR2
								   ,v_company  IN VARCHAR2
								   ,v_emp_ssn  IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_organization_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Organization Code';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Company';
    l_label3           CUST.ttec_error_handling.label3%TYPE := 'Employee SSN';
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_organization_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Organization Code';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Company';
    l_label3           apps.ttec_error_handling.label3%TYPE := 'Employee SSN';
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--End R12.2 Upgrade Remediation	
	l_company		   VARCHAR2(10); 

	
    BEGIN
	
		 IF v_company = 'V76' THEN
		 	l_company := 'PCTA';
			
		 ELSIF v_company = '98Y' THEN
		 	l_company := 'ENHV';
		 
		 ELSE
		    l_company := 'TTEC';
			
		 END IF;   	
	     
              SELECT organization_id
              INTO   v_organization_id
              --FROM   CUST.conv_us_hr_org_map	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.conv_us_hr_org_map	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              WHERE  legacy_dept_no = v_org_code
			  AND	 legacy_co = l_company;


    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Organization ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_org_code, l_label2, v_company, l_label3, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Organization ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_org_code, l_label2, v_company, l_label3, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_error_message, l_label1, v_org_code, l_label2, v_company, l_label3, v_emp_ssn);
             RAISE;
    END;


  --************************************************************************************--
  --*                                GET PAY BASIS ID        				          *--			     
  --************************************************************************************--

    PROCEDURE get_pay_basis_id (v_pay_basis_id OUT NUMBER 
                                ,v_pay_basis_name IN VARCHAR2
                                ,v_business_group_id IN NUMBER
								,v_emp_ssn  IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_pay_basis_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Pay Basis Name';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_pay_basis_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Pay Basis Name';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE; 
	--End R12.2 Upgrade Remediation

    BEGIN     
              SELECT pay_basis_id
              INTO   v_pay_basis_id
              FROM   per_pay_bases
              WHERE  upper(per_pay_bases.name) = upper(v_pay_basis_name)
              AND business_group_id = v_business_group_id;

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Pay Basis ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,  	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_pay_basis_name, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Pay Basis ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name, -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_pay_basis_name, l_label2, v_emp_ssn);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_pay_basis_name, l_label2, v_emp_ssn);
             RAISE;
    END; --*** END GET PAY BASIS ID ***--

 
  --************************************************************************************--
  --*                                UPDATE STAGING TABLE        	                  *--			     
  --************************************************************************************--

   PROCEDURE update_staging_table (v_record_processed IN VARCHAR2, 
                                   v_error_flag IN VARCHAR2,
                                   v_error_message IN VARCHAR2, 
                                   v_assignment_code IN VARCHAR2,
                                   v_rowid IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
   /*l_label1	       CUST.ttec_error_handling.LABEL1%TYPE := 'Assignment Conversion';
   l_module_name   CUST.ttec_error_handling.MODULE_NAME%TYPE := 'update_staging_table';*/
	l_label1	       apps.ttec_error_handling.LABEL1%TYPE := 'Assignment Conversion';
   l_module_name   apps.ttec_error_handling.MODULE_NAME%TYPE := 'update_staging_table';
   --End R12.2 Upgrade Remediation
	
   BEGIN
		
        --UPDATE CUST.conv_us_hr_asg_stage	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		UPDATE apps.conv_us_hr_asg_stage	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
        SET    record_processed = v_record_processed,
	           error_flag = v_error_flag,
	           error_message = v_error_message          
        WHERE rowid = v_rowid;


        EXCEPTION
 	       WHEN OTHERS THEN
               --CUST.ttec_process_error (c_application_code,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			   apps.ttec_process_error (c_application_code,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
				                    c_interface,
                                    c_program_name,
                                    l_module_name,
                                    'FAILURE',
                                    SQLCODE,
                                    SQLERRM,
                                    l_label1,
                                    v_assignment_code);
           RAISE;
   END;
   
   
    
  --************************************************************************************--
  --*                                GET SET OF BOOKS ID           				      *--			     
  --************************************************************************************--

    PROCEDURE get_set_of_books (v_set_of_books_id OUT NUMBER 
                                ,v_company IN VARCHAR2
								,v_emp_ssn  IN VARCHAR2) IS

	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_set_of_books';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Set of Books Name';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_set_of_books';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Set of Books Name';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE; 
	--End R12.2 Upgrade Remediation
	l_set_of_books	   apps.gl_sets_of_books.name%TYPE;

    BEGIN    

		IF v_company = 'V76' THEN
		   l_set_of_books := 'PERCEPTA SET OF BOOKS';
		
		ELSE
		   l_set_of_books := 'TELETECH SET OF BOOKS';
			
		END IF;
		
		SELECT set_of_books_id
		INTO  v_set_of_books_id  
		FROM  apps.gl_sets_of_books 
 		WHERE name = l_set_of_books;
              

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Set of Books ID returned no data found';
				  v_set_of_books_id := NULL;
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, l_set_of_books, l_label2, v_emp_ssn);

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Set of Books ID returned too many rows';
				  v_set_of_books_id := NULL;
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, l_set_of_books, l_label2, v_emp_ssn);


             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, l_set_of_books, l_label2, v_emp_ssn);
             RAISE;
    END; --*** END GET SET OF BOOKS ID ***--
       
    
    
  --************************************************************************************--
  --*                          GET DEFAULT CODE COMBINATIONS ID                         *--			     
  --************************************************************************************--

    PROCEDURE get_default_code_comb_id (v_default_code_comb_id OUT NUMBER, 
                                        v_segment1 IN VARCHAR2,
                                        v_segment2 IN VARCHAR2,
                                        v_segment3 IN VARCHAR2,
                                        v_segment4 IN VARCHAR2,
										v_segment5 IN VARCHAR2,
										v_segment6 IN VARCHAR2,
										v_ssn	   IN VARCHAR2,
										v_effective_date IN DATE) IS
    
	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_default_code_comb_id';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Default Code Comb';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE := NULL; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_default_code_comb_id';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Default Code Comb';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE := NULL; 
	--End R12.2 Upgrade Remediation
    l_concat_segments  VARCHAR2(50);
	l_segment3		   VARCHAR2(3);	
	l_segment4		   VARCHAR2(4);
	l_count			   NUMBER := 0;

    BEGIN
	
--	If the client code is 0000, use account code 7680.If the client code is different than 0000, use account code 5680.

 	   	  IF v_segment2 = '0000' THEN
		  	 l_segment4 := '7680';
		  ELSE
		  	 l_segment4 := '5680';
		  END IF;
		  
		  l_segment3 := '0' || v_segment3;		  	  
 
 
 		  l_concat_segments := v_segment1 ||'.'||v_segment2||'.'||l_segment3||'.'||
                         l_segment4 ||'.'||v_segment5||'.'||v_segment6;
 
			  
              SELECT glc.code_combination_id
              INTO   v_default_code_comb_id
              FROM   apps.gl_code_combinations glc
              WHERE  glc.segment1 = v_segment1
              AND    glc.segment2 = v_segment2
              AND    glc.segment3 = l_segment3
              AND    glc.segment4 = l_segment4
              AND    glc.segment5 = v_segment5
              AND    glc.segment6 = v_segment6
			  AND	 glc.enabled_flag = 'Y';

       

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
			 
--                   IF l_error_message is NULL THEN
-- 				  	 l_error_message := 'Query for Default Code Comb. ID returned no data found';
--                   END IF;
-- 				  
-- 				  CUST.ttec_process_error (c_application_code, c_interface, c_program_name,
--                                        l_module_name, c_warning_status, SQLCODE, 
--                                        l_error_message, l_label1, l_concat_segments, l_label2, v_ssn);
				  v_default_code_comb_id := NULL;									   

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Default Code Comb. ID returned too many rows';	  
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, l_concat_segments, l_label2, v_ssn);
				  v_default_code_comb_id := NULL;									   

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, l_concat_segments, l_label2, v_ssn);
             RAISE;
    END; --*** END GET DEFAULT CODE COMBINATIONS ID ***--  
       
 
    
  --************************************************************************************--
  --*                              GET TAX UNIT ID (GRE)                               *--			     
  --************************************************************************************--

    PROCEDURE get_tax_unit_id (v_tax_unit_id OUT NUMBER 
                               ,v_tax_unit_name IN VARCHAR2
							   ,v_emp_ssn  IN VARCHAR2) IS
	
	--START R12.2 Upgrade Remediation	
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_tax_unit_id (gre)';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Get Tax Unit ID';
    l_label2           CUST.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_tax_unit_id (gre)';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Get Tax Unit ID';
    l_label2           apps.ttec_error_handling.label2%TYPE := 'Employee SSN';	
    l_error_message    apps.ttec_error_handling.error_message%TYPE; 
	--End R12.2 Upgrade Remediation

    BEGIN     
			  SELECT tax_unit_id 
              INTO   v_tax_unit_id
              --FROM cust.conv_us_hr_gre_map	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM apps.conv_us_hr_gre_map		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              WHERE  legacy_gre_codes = v_tax_unit_name;

              
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Tax Unit ID (GRE) returned no data found';
				  
				  
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_tax_unit_name, l_label2, v_emp_ssn);
									   
				  RAISE SKIP_RECORD;
                  
             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Tax Unit ID (GRE) returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_tax_unit_name, l_label2, v_emp_ssn);
                  RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_tax_unit_name, l_label2, v_emp_ssn);
                  RAISE;
    END; --*** END GET TAX UNIT ID (GRE) ***--  

	
 --************************************************************************************--
  --*                                GET DEFAULT WORK SCHEDULE     				       *--			     
  --************************************************************************************--

    PROCEDURE get_default_work_schedule (v_organization_id  IN NUMBER, 
                                         v_work_schedule   OUT NUMBER ) IS

    --START R12.2 Upgrade Remediation
	/*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_default_work_schedule';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Org ID';
    l_error_message    CUST.ttec_error_handling.error_message%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_default_work_schedule';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Org ID';
    l_error_message    apps.ttec_error_handling.error_message%TYPE;
	--End R12.2 Upgrade Remediation

    BEGIN     

              SELECT payuser.user_column_id
			  INTO   v_work_schedule
              FROM   hr_organization_information orginfo, pay_user_columns payuser 
              WHERE  orginfo.organization_id = v_organization_id
              AND  orginfo.org_information_context = 'Work Schedule'
			  AND payuser.legislation_code = 'US'			  
			  AND ltrim(rtrim(orginfo.org_information2)) = ltrim(rtrim(user_column_name));			

			  
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Work Schedule returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_organization_id);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Work Schedule returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_organization_id);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_organization_id);
             RAISE;
    END;
    
    
  --************************************************************************************--
  --*                                GET TOTAL RECORD COUNT                            *--			     
  --************************************************************************************--

    PROCEDURE get_total_record_count IS
	
	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'get_total_record_count';
    l_label1           CUST.ttec_error_handling.label1%TYPE := 'Get Total Record Count';
    l_error_message    CUST.ttec_error_handling.error_message%TYPE; */
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'get_total_record_count';
    l_label1           apps.ttec_error_handling.label1%TYPE := 'Get Total Record Count';
    l_error_message    apps.ttec_error_handling.error_message%TYPE; 
	--End R12.2 Upgrade Remediation
	
    BEGIN     
              SELECT COUNT(*)
              INTO   g_total_record_count
              --FROM   CUST.conv_us_hr_asg_stage;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.conv_us_hr_asg_stage;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

              

    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Total Record Count returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, 'Total Record Count Error!');
                  RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Total Record Count returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, 'Total Record Count Error!');
                  RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, 'Total Record Count Error!');
                  RAISE;
    END; --*** END GET TOTAL RECORD COUNT ***--  

	


  --************************************************************************************--
  --*                               MAIN PROGRAM PROCEDURE                             *--			     
  --************************************************************************************--

    PROCEDURE main IS
	
	--START R12.2 Upgrade Remediation
    /*l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'Main Procedure';
    l_business_group_id NUMBER := NULL;

	
	--*** API VARIABLE DECLARATION ***--  
    l_object_version_number        hr.per_all_assignments_f.object_version_number%TYPE;
    l_assignment_id                hr.per_all_assignments_f.assignment_id%TYPE;
     l_employee_number             hr.per_all_people_f.employee_number%TYPE;   
     l_proportion                  hr.pay_cost_allocations_f.proportion%TYPE;
     l_cost_allocation_id          hr.pay_cost_allocations_f.cost_allocation_id%TYPE;*/
	l_module_name      apps.ttec_error_handling.module_name%TYPE := 'Main Procedure';
    l_business_group_id NUMBER := NULL;

	
	--*** API VARIABLE DECLARATION ***--  
    l_object_version_number        apps.per_all_assignments_f.object_version_number%TYPE;
    l_assignment_id                apps.per_all_assignments_f.assignment_id%TYPE;
     l_employee_number             apps.per_all_people_f.employee_number%TYPE;   
     l_proportion                  apps.pay_cost_allocations_f.proportion%TYPE;
     l_cost_allocation_id          apps.pay_cost_allocations_f.cost_allocation_id%TYPE;
	--End R12.2 Upgrade Remediation	
    l_person_id 			            	   NUMBER;
    l_cost_allocation_keyflex_id   NUMBER;
    l_effective_date 			           DATE;
    	l_per_eff_start_date		   DATE;
    v_datetrack_mode 			           VARCHAR(30);
	  	l_pc_segment2		           		   VARCHAR2(4);
 

	
    
    --*** API OUT PARAMETERS DELCARATIONS ***--

	l_pc_combination_name                varchar2(80);
	l_pc_effective_start_date            date;
	l_pc_effective_end_date              date;
 l_asg_eff_strt_dt                    date;
	l_pc_cost_alloc_keyflex_id         	 number;
	l_pc_object_version_number           number;
 l_pc_cost_allocation_id              number;
	
    
    BEGIN
   
--dbms_output.put_line('00');   
--*** GET TOTAL RECORD COUNT USED BY CONTROL TOTALS ***--
--        get_total_record_count;
--dbms_output.put_line('0');
--		get_suspense_acct_id (l_suspense_acct_id);
		
   get_business_group_id (l_business_group_id, p_org_name);
-- dbms_output.put_line('1');      
 		IF csr_cuhas%ISOPEN THEN
      	  CLOSE csr_cuhas;
  		END IF;
		
        --*** OPEN AND FETCH EACH TEMPORARY ASSIGNMENT ***--
        FOR sel IN csr_cuhas LOOP
-- dbms_output.put_line('1');       
            g_primary_column := sel.employee_number;
            
            --*** INITIALIZE VALUES  ***--
   
            l_object_version_number        := NULL;
            l_assignment_id                := NULL;
            l_employee_number             := NULL;   
            l_proportion                  := NULL;
            l_cost_allocation_id          := NULL;
            l_person_id 			            	:= NULL;
            l_cost_allocation_keyflex_id   := NULL;
            l_effective_date 			        := NULL;
            v_datetrack_mode 			        := NULL;
        	  	l_pc_segment2		           := NULL;
            	l_per_eff_start_date		   := NULL;
 

	
	
	          --*** INITIALIZE OUT PARAMETERS  ***--
	        	  l_pc_combination_name                  := NULL;
        	  	l_pc_effective_start_date              := NULL;
        	  	l_pc_effective_end_date                := NULL;
        	  	l_pc_cost_alloc_keyflex_id             := NULL;
        	  	l_pc_object_version_number             := NULL;
            l_pc_cost_allocation_id                := NULL;
            
            --*** INCREMENT TOTAL ASSIGNMENTS READ BY 1 ***--
            g_total_employees_read := g_total_employees_read + 1; 
            
             
            BEGIN
                  
			l_pc_segment2	:= sel.client;	 
				 l_effective_date := trunc(sel.effective_date);
--dbms_output.put_line(sel.employee_number);                 
				 get_person_id (l_person_id, l_per_eff_start_date, sel.employee_number, l_business_group_id);
--dbms_output.put_line('get_person_id ->'||l_person_id||' '|| l_per_eff_start_date||' '|| sel.employee_number||' '|| l_business_group_id);				 
    get_assignment_id (l_assignment_id, l_asg_eff_strt_dt, sel.employee_number, l_person_id, l_business_group_id);
--dbms_output.put_line('get_assignment_id ->'||l_assignment_id||' '|| l_asg_eff_strt_dt||' '|| sel.employee_number||' '|| l_person_id||' '|| l_business_group_id);	              
			 get_pay_cost_alloc_info (l_cost_allocation_id, l_proportion, l_object_version_number, l_assignment_id, sel.employee_number);
--dbms_output.put_line('get_pay_cost_alloc_info ->'||l_cost_allocation_id||' '|| l_proportion||' '|| l_object_version_number||' '|| l_assignment_id||' '|| sel.employee_number);                

--dbms_output.put_line('===============================================');

     v_datetrack_mode := 'UPDATE';

				APPS.pay_cost_allocation_api.update_cost_allocation
				  (p_validate                      => p_validate
				  ,p_effective_date                => l_effective_date
      ,p_datetrack_update_mode         => v_datetrack_mode
				  ,p_cost_allocation_id            => l_cost_allocation_id
      ,p_object_version_number         => l_object_version_number
				  ,p_proportion                    => l_proportion
				  ,p_segment2                      => l_pc_segment2

				  --*** API OUT PARAMETERS ***--
				  ,p_combination_name                 => l_pc_combination_name  
				  ,p_cost_allocation_keyflex_id       => l_pc_cost_alloc_keyflex_id
				  ,p_effective_start_date             => l_pc_effective_start_date
				  ,p_effective_end_date               => l_pc_effective_end_date
				  );	
				  
  				 commit;			 
/*

				APPS.pay_cost_allocation_api.create_cost_allocation
				  (p_validate                      => p_validate
				  ,p_effective_date                => l_effective_date
				  ,p_assignment_id                 => l_assignment_id
				  ,p_proportion                    => l_proportion
				  ,p_business_group_id             => l_business_group_id
				  ,p_segment2                      => l_pc_segment2

				  --*** API OUT PARAMETERS ***--
				  ,p_combination_name                 => l_pc_combination_name  
				  ,p_cost_allocation_id               => l_pc_cost_allocation_id 
				  ,p_effective_start_date             => l_pc_effective_start_date
				  ,p_effective_end_date               => l_pc_effective_end_date
				  ,p_cost_allocation_keyflex_id       => l_pc_cost_alloc_keyflex_id 
				  ,p_object_version_number            => l_pc_object_version_number 
				  );	
				  
  				 commit;			 	
 */                   
                 --*** INCREMENT THE NUMBER OF ROWS PROCESSED BY THE API ***--
                 l_rows_processed := l_rows_processed + 1;

                 --*** UPDATE STAGING TABLE ***--
--                 update_staging_table ('Y', 'N', NULL, to_char(l_assignment_id), v_rowid);

                 --*** DETERMINE IF THE COMMIT POINT HAS BEEN REACHED ***--
    /*             IF (MOD(l_rows_processed, l_commit_point) = 0) THEN
                     --*** THE COMMIT POINT HAS BEEN REACHED, THEREFORE COMMIT ***--
                     COMMIT;
                 END IF;
*/
            EXCEPTION

              --   WHEN SKIP_RECORD THEN
              --   	  update_staging_table ('N', 'Y', SQLERRM, to_char(l_assignment_id), v_rowid);

                 WHEN OTHERS THEN
              --   	  update_staging_table ('N', 'Y', SQLERRM, to_char(l_assignment_id), v_rowid);
              --   	  commit;   
                 	  l_module_name := 'Main inside of loop';
                 	  --CUST.ttec_process_error(c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
					  apps.ttec_process_error(c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                     l_module_name, c_failure_status, SQLCODE, SQLERRM, 'Emp No', g_primary_column);

            END;
        END LOOP; 
		
        --***COMMIT ANY FINAL ROWS ***--
        COMMIT; 
    

        --*** DISPLAY CONTROL TOTALS ***--
        dbms_output.put_line (' CONVERSION TIMESTAMP END = '  || to_char(SYSDATE, 'dd-mon-yy hh:mm:ss'));
        dbms_output.put_line ('-------------------------------------------');
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS COUNT         = '  || g_total_record_count);
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS READ          = '  || to_char(g_total_employees_read));
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS INSERTED      = '  || to_char(l_rows_processed));
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS REJECTED      = '  || to_char(g_total_employees_read - l_rows_processed));        
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS NOT PROCESSED = '  || to_char(g_total_record_count - g_total_employees_read));
        dbms_output.put_line ('-------------------------------------------');


    END; --*** END MAIN ***--



  --************************************************************************************--
  --*                                 CALL MAIN PROCEDURE                              *--
  --************************************************************************************--
    
    BEGIN
         --*** CALL MAIN PROCEDURE ***--
         main;
    
    EXCEPTION
        WHEN OTHERS THEN   
             --CUST.ttec_process_error(c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			 apps.ttec_process_error(c_application_code, c_interface, c_program_name, 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                'Calling Main Procedure', c_failure_status, SQLCODE, SQLERRM);
                              
        RAISE;
    END;
/

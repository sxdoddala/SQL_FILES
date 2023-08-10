--************************************************************************************--
--*                                                                                  *--
--*     Program Name: ttec_us_supervisor.sql                                         *--  
--*                                                                                  *--
--*     Description:  The supervisor script is to load changes to employees    	 *--
--*  		 		  organization in the Oracle HR application. This is       		 *--
--*				   accomplished using a series of Oracle HR APIs: 		 			 *--
--*				   HR_ASSIGNMENT_API.update_us_emp_asg AND 							 *--
--*                                                                              	 *--
--*                                                                                  *--
--*     Input/Output Parameters:                                                     *--
--*                                                                                  *--
--*     Tables Accessed:                                                             *--
--*                        HR_ALL_ORGANIZATION_UNITS                                 *--
--*                        TTEC_ERROR_HANDLING                                       *--
--*                       PER_ALL_ASSIGNMENTS_F                                      *--
--*                        PER_ALL_PEOPLE_F                                          *--
--*                                                                                  *--
--*     Tables Modified:  								                          	 *--
--*                        TTEC_ERROR_HANDLING                                       *--
--*                        PER_ALL_ASSIGNMENTS_F                                     *--

--*     Procedures Called:                                                           *--
--*                        HR_ASSIGNMENT_API.UPDATE_US_EMP_ASG                       *--
--*                        TTEC_PROCESS_ERROR                                        *--
--*                                                                                  *--
--*Created By: Elizur Alfred-Ockiya                                                   		 *--
--*Date: 02/02/2004                                                            		 *--
--*                                                                            		 *--
--*Modification Log:                                                           		 *--
--*Developer    		 Date        Description                                     *--
--*---------    		 ----        -----------                                     *--
--* E Alfred-Ockiya		 02-02-04    Created
--* NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation
--************************************************************************************--
    
    
--    SET TIMING ON
  SET SERVEROUTPUT ON SIZE 1000000;
    
    DECLARE

	--START R12.2 Upgrade Remediation
    --*** VARIABLES USED BY COMMON ERROR HANDLING PROCEDURES ***--
    /*c_application_code            CUST.ttec_error_handling.application_code%TYPE  := 'HR';
    c_interface                   CUST.ttec_error_handling.interface%TYPE := 'US_SUP';
    c_program_name                CUST.ttec_error_handling.program_name%TYPE  := 'ttec_us_sup';
    c_initial_status              CUST.ttec_error_handling.status%TYPE  := 'INITIAL';
    c_warning_status              CUST.ttec_error_handling.status%TYPE  := 'WARNING';
    c_failure_status              CUST.ttec_error_handling.status%TYPE  := 'FAILURE';*/
	c_application_code            apps.ttec_error_handling.application_code%TYPE  := 'HR';
    c_interface                   apps.ttec_error_handling.interface%TYPE := 'US_SUP';
    c_program_name                apps.ttec_error_handling.program_name%TYPE  := 'ttec_us_sup';
    c_initial_status              apps.ttec_error_handling.status%TYPE  := 'INITIAL';
    c_warning_status              apps.ttec_error_handling.status%TYPE  := 'WARNING';
    c_failure_status              apps.ttec_error_handling.status%TYPE  := 'FAILURE';
	--End R12.2 Upgrade Remediation

    --User specified variables
 --   p_validate BOOLEAN 		  := false;--:= &validate;
	p_org_name VARCHAR2(40)	  := 'TeleTech Holdings - US';
	--p_org_name VARCHAR2(40)	  := 'TeleTech Holdings - CAN';


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
	SELECT  sup1.employee_number   employee_number
		   ,sup2.sup_number sup_number
		   ,sup1.effective_date effective_date
		   ,peep2.person_id supervisor_id
	--START R12.2 Upgrade Remediation
	/*FROM hr.per_all_people_f peep2
		,cust.ttec_temp_supload sup1 
	    ,cust.ttec_temp_supload sup2*/
	FROM apps.per_all_people_f peep2
		,apps.ttec_temp_supload sup1 
	    ,apps.ttec_temp_supload sup2
	--End R12.2 Upgrade Remediation
	WHERE sup1.employee_number = sup2.employee_number
	and sup2.sup_number = peep2.employee_number
	AND sysdate between peep2.effective_start_date and peep2.effective_end_date;
--	and sup1.employee_number = 1001557;
--	ORDER BY sup1.employee_number

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
			  AND	peep.business_group_id =  v_business_group_id
			  AND peep.person_type_id = peeptype.person_type_id
			  AND peeptype.system_person_type = 'EMP'
			  AND peep.effective_start_date = (Select max(effective_start_date)
       --from hr.per_all_people_f b	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   from apps.per_all_people_f b	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
       where peep.person_id = b.person_id);
--dbms_output.put_line(v_person_id); 
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Person ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Person ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number);
             RAISE SKIP_RECORD;

             WHEN OTHERS THEN
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_failure_status, SQLCODE, SQLERRM, 
                                       l_label1, v_employee_number);
             RAISE;
    END; --*** END GET PERSON ID ***--


  --************************************************************************************--
  --*                          GET ASSIGNMENT ID 									  *--			     
  --************************************************************************************--

    PROCEDURE get_assignment_id (v_employee_number IN VARCHAR2 
                                ,v_person_id IN VARCHAR2
								,v_business_group_id IN NUMBER
								,v_assignment_id OUT NUMBER
			  					,v_asg_eff_date  OUT DATE			  									 
			  					,v_object_version_number OUT NUMBER) IS
	
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
	
	
	--dbms_output.put_line(v_employee_number||' '||v_person_id||' '||v_business_group_id); 

              SELECT asg.assignment_id, asg.effective_start_date, asg.object_version_number
              INTO   v_assignment_id, v_asg_eff_date,v_object_version_number
              --FROM   hr.per_all_assignments_f asg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM   apps.per_all_assignments_f asg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
              WHERE  asg.person_id = v_person_id
			  AND	 asg.primary_flag = 'Y'
			  AND	 asg.assignment_type = 'E'
			  AND	 asg.effective_start_date = (select max(asg2.effective_start_date) 
			  		 						  	 --from hr.per_all_assignments_f asg2 -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
												 from apps.per_all_assignments_f asg2 -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
												 where  asg2.person_id = v_person_id
			  									 and asg2.primary_flag = 'Y'
			  									 and asg2.assignment_type = 'E'
												 and asg2.business_group_id = v_business_group_id
												 )
			  AND asg.business_group_id = v_business_group_id  
			  ;

	--dbms_output.put_line( v_assignment_id||' '||v_asg_eff_date||' '||v_object_version_number);			  
			  
    EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  l_error_message := 'Query for Assignment ID returned no data found';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       l_module_name, c_warning_status, SQLCODE, 
                                       l_error_message, l_label1, v_employee_number, l_label2, v_person_id);
             RAISE SKIP_RECORD;

             WHEN TOO_MANY_ROWS THEN
                  l_error_message := 'Query for Assignment ID returned too many rows';
                  --CUST.ttec_process_error (c_application_code, c_interface, c_program_name, -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  apps.ttec_process_error (c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
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
  --*                               MAIN PROGRAM PROCEDURE                             *--			     
  --************************************************************************************--

    PROCEDURE main IS
	/*--START R12.2 Upgrade Remediation
    l_module_name      CUST.ttec_error_handling.module_name%TYPE := 'Main Procedure';
    l_business_group_id NUMBER := NULL;

	
	--*** API VARIABLE DECLARATION ***--  
    l_object_version_number        hr.per_all_assignments_f.object_version_number%TYPE;
    l_assignment_id                hr.per_all_assignments_f.assignment_id%TYPE;
	l_organization_id			   hr.per_all_assignments_f.organization_id%TYPE;
	l_orgname					   hr.hr_all_organization_units.name%TYPE;
    l_employee_number             hr.per_all_people_f.employee_number%TYPE;   
    l_proportion                  hr.pay_cost_allocations_f.proportion%TYPE;
    l_cost_allocation_id          hr.pay_cost_allocations_f.cost_allocation_id%TYPE;
	l_supervisor_id                NUMBER; 
	*/
    l_module_name      apps.ttec_error_handling.module_name%TYPE := 'Main Procedure';
    l_business_group_id NUMBER := NULL;

	
	--*** API VARIABLE DECLARATION ***--  
    l_object_version_number        apps.per_all_assignments_f.object_version_number%TYPE;
    l_assignment_id                apps.per_all_assignments_f.assignment_id%TYPE;
	l_organization_id			   apps.per_all_assignments_f.organization_id%TYPE;
	l_orgname					   apps.hr_all_organization_units.name%TYPE;
    l_employee_number             apps.per_all_people_f.employee_number%TYPE;   
    l_proportion                  apps.pay_cost_allocations_f.proportion%TYPE;
    l_cost_allocation_id          apps.pay_cost_allocations_f.cost_allocation_id%TYPE;
	--End R12.2 Upgrade Remediation
    l_person_id 			       NUMBER;
    l_cost_allocation_keyflex_id   NUMBER;
    l_effective_date 			   DATE;
    l_per_eff_start_date	   DATE;
    v_datetrack_mode 			   VARCHAR2(30);
	l_pc_segment2		       VARCHAR2(4);
    l_validate 			        boolean;
    l_pc_segment1                VARCHAR2(5);
    l_pc_segment3               VARCHAR2(3);
    
    --*** API OUT PARAMETERS DELCARATIONS ***--

	l_pc_combination_name                varchar2(80);
	l_pc_effective_start_date            date;
	l_pc_effective_end_date              date;
    l_asg_eff_strt_dt                    date;
	l_pc_cost_alloc_keyflex_id         	 number;
	l_pc_object_version_number           number;
    l_pc_cost_allocation_id              number;
	
    l_concatenated_segments        VARCHAR2(240);                                                                                                   
    l_no_managers_warning          BOOLEAN;                                
    l_other_manager_warning        BOOLEAN;      
    l_soft_coding_keyflex_id       NUMBER;                                 
    l_comment_id                   NUMBER;         
    l_effective_start_date         DATE;
    l_effective_end_date           DATE;    
	
	
    BEGIN
   
		
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
			
			
			l_supervisor_id 			   := NULL;
            l_object_version_number        := NULL;
            l_assignment_id                := NULL;
            l_employee_number              := NULL;   
            l_proportion                   := NULL;
            l_cost_allocation_id           := NULL;
            l_person_id 			       := NULL;
            l_cost_allocation_keyflex_id   := NULL;
            l_effective_date 			   := NULL;
            v_datetrack_mode 			   := NULL;
        	l_pc_segment1		           := NULL;
			l_pc_segment2		           := NULL;
			l_pc_segment3		           := NULL;			
            l_per_eff_start_date		   := NULL;
 
 							l_validate   := NULL;
	
	
	          --*** INITIALIZE OUT PARAMETERS  ***--
	        	l_pc_combination_name                  := NULL;
        	  	l_pc_effective_start_date              := NULL;
        	  	l_pc_effective_end_date                := NULL;
				l_concatenated_segments  			   := NULL;                            
				l_soft_coding_keyflex_id 			   := NULL;                             
				l_comment_id           				   := NULL;                    
				l_pc_effective_start_date  			   := NULL;                           
				l_pc_effective_end_date   			   := NULL;                               
				l_no_managers_warning     			   := NULL;                           
				l_other_manager_warning    			   := NULL;                  

            
            --*** INCREMENT TOTAL ASSIGNMENTS READ BY 1 ***--
            g_total_employees_read := g_total_employees_read + 1; 
            
             
            BEGIN
                  l_validate    := false;     					  
				  l_effective_date := sel.effective_date;
				  l_supervisor_id  := sel.supervisor_id;
				  
--dbms_output.put_line(sel.employee_number);                 
				 get_person_id (l_person_id, l_per_eff_start_date, sel.employee_number, l_business_group_id);
--dbms_output.put_line('get_person_id ->'||l_person_id||' '|| l_per_eff_start_date||' '|| sel.employee_number||' '|| l_business_group_id);				 
    get_assignment_id (sel.employee_number,l_person_id,l_business_group_id,l_assignment_id, l_asg_eff_strt_dt,l_object_version_number);
--dbms_output.put_line('get_organization_id ->'||sel.orgname||' '|| l_person_id||' '|| l_organization_id);	     

--dbms_output.put_line('===============================================');

     v_datetrack_mode := 'UPDATE';

                  APPS.HR_ASSIGNMENT_API.update_us_emp_asg
                  (p_validate                     =>  l_validate
                  ,p_effective_date               =>  l_effective_date
                  ,p_datetrack_update_mode        =>  v_datetrack_mode
                  ,p_assignment_id                =>  l_assignment_id
                  ,p_object_version_number        =>  l_object_version_number
				  ,p_supervisor_id                =>  l_supervisor_id    
                 -- ,p_tax_unit                     =>  l_tax_unit_id
                 
                  --*** API OUT PARAMETERS ***--
             
                  ,p_concatenated_segments        =>  l_concatenated_segments                              
                  ,p_soft_coding_keyflex_id       =>  l_soft_coding_keyflex_id                              
                  ,p_comment_id                   =>  l_comment_id                               
                  ,p_effective_start_date         =>  l_pc_effective_start_date                             
                  ,p_effective_end_date           =>  l_pc_effective_end_date                                  
                  ,p_no_managers_warning          =>  l_no_managers_warning                                
                  ,p_other_manager_warning        =>  l_other_manager_warning                      
                  );
				  
				  
				  --update hr.per_all_assignments_f 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  update apps.per_all_assignments_f 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
				   set supervisor_id = sel.supervisor_id	
				  WHERE  person_id = l_person_id
				  and effective_start_date = l_pc_effective_start_date; 
				  --and effective_end_date = l_pc_effective_end_date;		  

  				 commit;			 
			 
            
                 --*** INCREMENT THE NUMBER OF ROWS PROCESSED BY THE API ***--
                 l_rows_processed := l_rows_processed + 1;

            EXCEPTION

                   WHEN OTHERS THEN
 
                 	  l_module_name := 'Main inside of loop';
                 	  --CUST.ttec_process_error(c_application_code, c_interface, c_program_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
					  apps.ttec_process_error(c_application_code, c_interface, c_program_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                     l_module_name, c_failure_status, SQLCODE, SQLERRM, 'Emp No', g_primary_column);

            END;
        END LOOP; 
		
        --***COMMIT ANY FINAL ROWS ***--
        COMMIT; 
    

        --*** DISPLAY CONTROL TOTALS ***--
        dbms_output.put_line (' CONVERSION TIMESTAMP END = '  || to_char(SYSDATE, 'dd-mon-yy hh:mm:ss'));
        dbms_output.put_line ('-------------------------------------------');
    --    dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS COUNT         = '  || g_total_record_count);
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS READ          = '  || to_char(g_total_employees_read));
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS INSERTED      = '  || to_char(l_rows_processed));
        dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS REJECTED      = '  || to_char(g_total_employees_read - l_rows_processed));        
    --    dbms_output.put_line (' TOTAL ASSIGNMENT RECORDS NOT PROCESSED = '  || to_char(g_total_record_count - g_total_employees_read));
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

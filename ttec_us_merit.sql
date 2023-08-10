-- Program Name:  	us_merit_increase.sql
--
-- Description:   This program will process each record in the
--		    	Salaries staging table before calling
--		    	the hr_upload_proposal_api.
--
-- Input/Output
-- Parameters:    	N/A
--
-- Tables Accessed:	ttec_us_merit_increase
--					PER_ALL_PEOPLE_F
-- 					PER_ALL_ASSIGNMENTS_F
--
-- Tables Modified: PER_PAY_PROPOSALS
--                  CUST.ttec_error_handling
--               --
-- Procedures Called: HR_MAINTAIN_PROPOSAL_API.insert_salary_proposal
--                    CUST.TTEC_PROCESS_ERROR
--
-- Created By:    	David Thakker
-- Date:	    	07/10/2002
--
-- Modification Log:
--
-- Developer		         Date	   Description
-- --------------------      ----      -----------------------
-- D.Thakker                 07/20     File created
-- D.Thakker	             07/17     Made program US specific
-- D.Thakker	             08/15     56 records loaded into DEV
-- D.Thakker		     09/27     Edited get assignment_id procedure
-- D.Thakker		     09/27     LOaded 140 records into DEV
-- D.Thakker		     10/09     Loaded 13388 / 14026 into HRSYSINT
-- D.Thakker		     11/06     Loaded 13647/13649 into GOLD
-- Elizur Alfred-Ockiya      02/06/03  Modified for merit increase
-- Elizur Alfred-Ockiya	     03/21/03  Modified for US merit load
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation    
SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

-- Declare variables
DECLARE

--Globals
g_validate BOOLEAN := false;
g_business_group_id NUMBER := 325;

--START R12.2 Upgrade Remediation
-- Variables used by Common Error Procedure
/*c_application_code            CUST.ttec_error_handling.application_code%TYPE := 'HR';
c_interface                   CUST.ttec_error_handling.interface%TYPE := 'Merit';
c_program_name                CUST.ttec_error_handling.program_name%TYPE := 'ttec_us_merit';
c_initial_status              CUST.ttec_error_handling.status%TYPE := 'INITIAL';
c_warning_status              CUST.ttec_error_handling.status%TYPE := 'WARNING';
c_failure_status              CUST.ttec_error_handling.status%TYPE := 'FAILURE';*/
c_application_code            apps.ttec_error_handling.application_code%TYPE := 'HR';
c_interface                   apps.ttec_error_handling.interface%TYPE := 'Merit';
c_program_name                apps.ttec_error_handling.program_name%TYPE := 'ttec_us_merit';
c_initial_status              apps.ttec_error_handling.status%TYPE := 'INITIAL';
c_warning_status              apps.ttec_error_handling.status%TYPE := 'WARNING';
c_failure_status              apps.ttec_error_handling.status%TYPE := 'FAILURE';
--End R12.2 Upgrade Remediation

-- Exceptions
SKIP_RECORD   EXCEPTION;
SKIP_RECORD2  EXCEPTION;
-- Cursor declarations

-- Pulls the Salaries Information
CURSOR 	c_get_salaries IS
SELECT	ss_number
        ,salary_amt
        ,salary_reason
        ,change_date
--FROM cust.ttec_us_merit_increase	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
FROM apps.ttec_us_merit_increase	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
WHERE record_processed = 'N'
AND error_flag = 'N';
--and ss_number = '077-60-4648';
--and ss_number = '001-70-5775';

--and ss_number IN ('251-94-9006','417-40-9620');


-- Control totals
g_total_records_read       NUMBER := 0;
g_total_records_processed  NUMBER := 0;
g_commit_point  		   NUMBER := 100; 
g_commit_pt_ctr  		   NUMBER := 0;
g_primary_column           VARCHAR2(60):= NULL;

-- Procedure declarations


/***********************************************************************/
PROCEDURE determine_person_id (v_ss_number IN VARCHAR2
		  	      ,v_business_group_id IN NUMBER
                              ,v_person_id OUT NUMBER) IS

--START R12.2 Upgrade Remediation
/*l_module_name 		CUST.ttec_error_handling.module_name %TYPE := 'determine_person_id';
l_label1 	        CUST.ttec_error_handling.label1%TYPE := 'ss_number';
l_error_message		CUST.ttec_error_handling.error_message%TYPE;*/
l_module_name 		apps.ttec_error_handling.module_name %TYPE := 'determine_person_id';
l_label1 	        apps.ttec_error_handling.label1%TYPE := 'ss_number';
l_error_message		apps.ttec_error_handling.error_message%TYPE;
--End R12.2 Upgrade Remediation

BEGIN

     SELECT DISTINCT pf.person_id
     INTO v_person_id
     --FROM hr.per_all_people_f pf, per_person_types pt	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	 FROM apps.per_all_people_f pf, per_person_types pt  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 		
     WHERE pf.national_identifier = v_ss_number
     AND pf.business_group_id = v_business_group_id
     and pf.person_type_id = pt.person_type_id
     and pf.business_group_id = pt.business_group_id
     and pt.user_person_type = 'Employee'
     and pt.system_person_type = 'EMP'
     AND trunc(SYSDATE) between effective_start_date and effective_end_date;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
         l_error_message := 'Query for Person Id returned no data found';
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_warning_status, SQLCODE, l_error_message,
               l_label1, v_ss_number);

    RAISE SKIP_RECORD2;

    WHEN TOO_MANY_ROWS THEN
         l_error_message := 'Query for Person Id returned too many rows';
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_warning_status, SQLCODE, l_error_message,
               l_label1, v_ss_number);

    RAISE SKIP_RECORD;

    WHEN OTHERS THEN
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_failure_status, SQLCODE, SQLERRM,
               l_label1, v_ss_number);

    RAISE;

END;

/***********************************************************************/
PROCEDURE determine_assignment_id (v_person_id IN NUMBER
                                    ,v_assignment_id OUT NUMBER) IS
 
--START R12.2 Upgrade Remediation
/*l_module_name 		CUST.ttec_error_handling.module_name %TYPE := 'determine_assignment_id';
l_label1 	        CUST.ttec_error_handling.label1%TYPE := 'Person Id';
l_error_message		CUST.ttec_error_handling.error_message%TYPE; */
l_module_name 		apps.ttec_error_handling.module_name %TYPE := 'determine_assignment_id';
l_label1 	        apps.ttec_error_handling.label1%TYPE := 'Person Id';
l_error_message		apps.ttec_error_handling.error_message%TYPE;
--End R12.2 Upgrade Remediation

BEGIN

/*
     SELECT assignment_id
     INTO v_assignment_id
     FROM hr.per_all_assignments_f
     WHERE person_id = v_person_id
     AND   assignment_type = 'E'  
     AND   effective_start_date = (select max(effective_start_date) 
	 	from hr.per_all_assignments_f
     	   	where person_id = v_person_id
     		and   assignment_type = 'E')
     AND trunc(SYSDATE) between effective_start_date and effective_end_date;
*/	 
	SELECT distinct ff.assignment_id
    INTO v_assignment_id
    --FROM hr.per_all_assignments_f ff	--  Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	FROM apps.per_all_assignments_f ff	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    WHERE ff.person_id = v_person_id
    AND   ff.assignment_type = 'E'  
    AND   ff.effective_start_date = (select max(effective_start_date) 
	 	  --from hr.per_all_assignments_f fff	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  from apps.per_all_assignments_f fff	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
     	  where ff.person_id = fff.person_id
     	  and   fff.assignment_type = 'E'); 

EXCEPTION
    WHEN NO_DATA_FOUND THEN
         l_error_message := 'Query for Assignment Id returned no data found';
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_warning_status, SQLCODE, l_error_message,
               l_label1, v_person_id);

    RAISE SKIP_RECORD2;

    WHEN TOO_MANY_ROWS THEN
         l_error_message := 'Query for Assignment Id returned too many rows';
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_warning_status, SQLCODE, l_error_message,
               l_label1, v_person_id);

    RAISE SKIP_RECORD;

    WHEN OTHERS THEN
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_failure_status, SQLCODE, SQLERRM,
               l_label1, v_person_id);

    RAISE;

END;
/********************************************************************************/
-- determine_element_entry_id (v_assignment_id, v_element_entry_id);
/***********************************************************************/
PROCEDURE determine_element_entry_id (v_assignment_id IN NUMBER
                                    ,v_element_entry_id OUT NUMBER,v_element_end_date OUT DATE) IS
 
--START R12.2 Upgrade Remediation
/*l_module_name 		CUST.ttec_error_handling.module_name %TYPE := 'determine_element_entry_id';
l_label1 	        CUST.ttec_error_handling.label1%TYPE := 'Assignment ID';
l_error_message		CUST.ttec_error_handling.error_message%TYPE;*/
l_module_name 		apps.ttec_error_handling.module_name %TYPE := 'determine_element_entry_id';
l_label1 	        apps.ttec_error_handling.label1%TYPE := 'Assignment ID';
l_error_message		apps.ttec_error_handling.error_message%TYPE;
--End R12.2 Upgrade Remediation

BEGIN
-- dbms_output.put_line('Assignment ID ' || v_assignment_id); 
 SELECT PEEF.ELEMENT_ENTRY_ID, PEEF.EFFECTIVE_END_DATE 
	 INTO
	 v_element_entry_id, v_element_end_date
	 FROM
 	 PAY_ELEMENT_ENTRIES_F PEEF,
 	 PAY_ELEMENT_LINKS_F PEL,
 	 PAY_INPUT_VALUES_F PIV,
 	 PER_PAY_BASES PPB,
	 --START R12.2 Upgrade Remediation
 	 /*HR.PER_ALL_ASSIGNMENTS_F PAF,
         HR.PER_PERIODS_OF_SERVICE PER*/
	 apps.PER_ALL_ASSIGNMENTS_F PAF,
         apps.PER_PERIODS_OF_SERVICE PER 
	 --End R12.2 Upgrade Remediation
	 WHERE   PEEF.ASSIGNMENT_ID = PAF.ASSIGNMENT_ID
  	 AND  PPB.PAY_BASIS_ID = PAF.PAY_BASIS_ID  
  	 AND  PPB.INPUT_VALUE_ID =  PIV.INPUT_VALUE_ID  
   	 AND  PIV.ELEMENT_TYPE_ID = PEL.ELEMENT_TYPE_ID  
  	 AND  PAF.EFFECTIVE_START_DATE BETWEEN PEL.EFFECTIVE_START_DATE AND PEL.EFFECTIVE_END_DATE 
         AND  PAF.PERSON_ID = PER.PERSON_ID
	 and  PER.ACTUAL_TERMINATION_DATE IS NULL
  	 AND  PEL.ELEMENT_LINK_ID = PEEF.ELEMENT_LINK_ID
	 AND  trunc(SYSDATE) BETWEEN PEEF.EFFECTIVE_START_DATE AND PEEF.EFFECTIVE_END_DATE
	 AND  trunc(SYSDATE) BETWEEN PAF.EFFECTIVE_START_DATE AND PAF.EFFECTIVE_END_DATE
	 AND  trunc(SYSDATE) BETWEEN PIV.EFFECTIVE_START_DATE AND  PIV.EFFECTIVE_END_DATE  
	 AND  trunc(SYSDATE) BETWEEN PEL.EFFECTIVE_START_DATE AND PEL.EFFECTIVE_END_DATE  
  	 AND  PAF.ASSIGNMENT_ID = v_assignment_id; --Ava Smith  3002012
 
	 

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RAISE SKIP_RECORD2;

    WHEN TOO_MANY_ROWS THEN
         l_error_message := 'Query for Element Entry Id returned too many rows';
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_warning_status, SQLCODE, l_error_message,
               l_label1, v_assignment_id);

    RAISE SKIP_RECORD;
    WHEN OTHERS THEN
         --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              (c_application_code, c_interface, c_program_name,
               l_module_name, c_failure_status, SQLCODE, SQLERRM,
               l_label1, v_assignment_id);

    RAISE;

END;
/********************************************************************************/
-- determine_element_entry_id (v_assignment_id, v_element_entry_id);
/***********************************************************************/
PROCEDURE determine_change_date (p_assignment_id IN NUMBER, p_change_date IN DATE) AS

/* --START R12.2 Upgrade Remediation
l_module_name 		CUST.ttec_error_handling.module_name %TYPE := 'determine_element_entry_id';
l_label1 	        CUST.ttec_error_handling.label1%TYPE := 'Assignment ID';
l_error_message		CUST.ttec_error_handling.error_message%TYPE;*/
l_module_name 		apps.ttec_error_handling.module_name %TYPE := 'determine_element_entry_id';
l_label1 	        apps.ttec_error_handling.label1%TYPE := 'Assignment ID';
l_error_message		apps.ttec_error_handling.error_message%TYPE;
--End R12.2 Upgrade Remediation
v_paychange_date        DATE := NULL;

BEGIN

   v_paychange_date := NULL;

   SELECT PAYP.change_date
	 INTO
	 v_paychange_date
	 FROM
	 --START R12.2 Upgrade Remediation
	 /*HR.PER_PAY_PROPOSALS PAYP,
 	 HR.PER_ALL_ASSIGNMENTS_F PAF*/
	 apps.PER_PAY_PROPOSALS PAYP,
 	 apps.PER_ALL_ASSIGNMENTS_F PAF
	 --End R12.2 Upgrade Remediation
	 WHERE PAF.ASSIGNMENT_ID = PAYP.ASSIGNMENT_ID
         and  PAF.BUSINESS_GROUP_ID = PAYP.BUSINESS_GROUP_ID
	 AND  trunc(SYSDATE) BETWEEN PAF.EFFECTIVE_START_DATE AND PAF.EFFECTIVE_END_DATE
         AND  PAYP.CHANGE_DATE = (select max(p.CHANGE_DATE) 
	 --from HR.PER_PAY_PROPOSALS p	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	 from apps.PER_PAY_PROPOSALS p	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	 WHERE p.ASSIGNMENT_ID = PAYP.ASSIGNMENT_ID
     	 and p.ASSIGNMENT_ID = p_assignment_id);
  	  --Ava Smith  3002012
        
     if trunc(v_paychange_date) >= trunc(p_change_date) THEN

         RAISE SKIP_RECORD2; 

     end if;    
END;  
/********************MAIN BODY***************************************************/
PROCEDURE main IS

v_person_id NUMBER := NULL;
v_assignment_id NUMBER := NULL;
v_change_date DATE := NULL;
v_pay_proposal_id NUMBER := NULL;
v_object_version_number NUMBER := NULL;
v_element_entry_id NUMBER := NULL;
v_inv_next_sal_date_warning BOOLEAN;
v_proposed_salary_warning BOOLEAN;
v_approved_warning BOOLEAN;
v_payroll_warning BOOLEAN;
v_rowid VARCHAR2(50) := NULL;
v_element_end_date DATE := NULL;
--v_paychange_date DATE := NULL;

--l_module_name CUST.ttec_error_handling.module_name%TYPE := 'Main';	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name apps.ttec_error_handling.module_name%TYPE := 'Main';	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

BEGIN

-- Open and fetch Salaries information from staging table
FOR sel IN c_get_salaries LOOP
    g_total_records_read := g_total_records_read + 1;
	g_primary_column := sel.ss_number;

    BEGIN
      
    -- Initialize values

        v_person_id := NULL;
        v_assignment_id := NULL;
	v_element_entry_id := NULL;
	
  --OUT Params
        v_pay_proposal_id := NULL;
        v_object_version_number := NULL;
        v_inv_next_sal_date_warning := NULL;
        v_proposed_salary_warning := NULL;
        v_approved_warning := NULL;
        v_payroll_warning := NULL;
   
    
--        v_rowid := sel.rowid;

       determine_person_id (sel.ss_number, g_business_group_id, v_person_id); 
--dbms_output.put_line('Person ID ' || v_person_id||' '||'SSN'||':'||sel.ss_number);      
       determine_assignment_id (v_person_id, v_assignment_id);
--dbms_output.put_line('Assignment ID ' || v_assignment_id); 
       determine_element_entry_id (v_assignment_id, v_element_entry_id,v_element_end_date);
--dbms_output.put_line('Element Entry ID ' || v_element_entry_id); 
       determine_change_date (v_assignment_id, sel.change_date);
--dbms_output.put_line('Element Entry ID ' || v_element_entry_id);  

      --Call Maintain Salary Proposal API
        hr_maintain_proposal_api.insert_salary_proposal
            (p_assignment_id                       => v_assignment_id
            ,p_business_group_id                   => g_business_group_id
            ,p_change_date                         => sel.change_date
            ,p_proposed_salary_n                   => sel.salary_amt
--	    ,p_proposal_reason                     => sel.salary_reason
	        ,p_multiple_components		           => 'N'
            ,p_approved                            => 'Y'
            ,p_validate                            => g_validate
--OUT Parameters
            ,p_element_entry_id                    => v_element_entry_id
            ,p_inv_next_sal_date_warning           => v_inv_next_sal_date_warning
            ,p_proposed_salary_warning             => v_proposed_salary_warning
            ,p_approved_warning                    => v_approved_warning
            ,p_payroll_warning                     => v_payroll_warning
            ,p_object_version_number               => v_object_version_number  
            ,p_pay_proposal_id                     => v_pay_proposal_id		
            ); 
			
--dbms_output.put_line('HR_API ' || v_pay_proposal_id); 
			
			--update hr.per_pay_proposals	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			 update apps.per_pay_proposals	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
   		        set proposal_reason = sel.salary_reason
     		        where pay_proposal_id = v_pay_proposal_id;     
              
            g_total_records_processed := g_total_records_processed + 1;
--           update_staging_table ('Y','N',NULL, v_rowid);
			
            g_commit_pt_ctr := g_commit_pt_ctr + 1;
            IF g_commit_pt_ctr = g_commit_point THEN
                 COMMIT;
	--     dbms_output.put_line('Committed '|| v_pay_proposal_id);
                g_commit_pt_ctr := 0;
            END IF;    
        
        EXCEPTION

        WHEN SKIP_RECORD2 THEN
            NULL;
		            
            --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                (c_application_code, c_interface, c_program_name,
                 l_module_name, c_failure_status, SQLCODE, SQLERRM,'Emp No', g_primary_column);
   
       WHEN OTHERS THEN
            
            --CUST.TTEC_PROCESS_ERROR	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			apps.TTEC_PROCESS_ERROR	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                (c_application_code, c_interface, c_program_name,
                 l_module_name, c_failure_status, SQLCODE, SQLERRM,'Emp No', g_primary_column);
				 
         raise;

    END;
                                        	
END LOOP;

COMMIT;    

-- Display control totals
dbms_output.put_line('Total Records Read ' || to_char(g_total_records_read));
dbms_output.put_line('Total Records Processed ' || to_char(g_total_records_processed));

END;     -- Main Body

/***********************************************************************/

BEGIN
     -- Call main procedure
     main;

EXCEPTION

    WHEN OTHERS THEN
         --CUST.TTEC_PROCESS_ERROR  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 apps.TTEC_PROCESS_ERROR  	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
             (c_application_code, c_interface, c_program_name,
              'Calling main procedure', c_failure_status, SQLCODE, SQLERRM);
    
    RAISE;
END;
/

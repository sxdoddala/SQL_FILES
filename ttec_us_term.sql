 /************************************************************************************
        Program Name: ttec_us_term.sql

        Description:   

        Developed by : 
        Date         :  

       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
    ****************************************************************************************/
SET timing ON;
SET serveroutput ON SIZE 1000000;

DECLARE

CURSOR csr_term_people IS
	SELECT  peep.full_name   full_name
	       ,peep.person_id person_id
		   ,peep.employee_number employee_number
		   ,types.user_person_type user_person_type 
		   ,asg.assignment_id assignment_id  
		   ,asg.assignment_status_type_id assignment_status_type_id
		   ,loc.location_code location_code 
		   ,serv.object_version_number object_version_number
		   ,serv.period_of_service_id period_of_service_id
		   ,term.term_date actual_term_date
		   ,term.finalprocess_date  final_process_date
	--START R12.2 Upgrade Remediation
	/*FROM hr.per_all_people_f peep
		,hr.per_all_assignments_f asg
		,hr.hr_locations_all loc
		,hr.per_person_types types
		,hr.per_periods_of_service serv
		,cust.ttec_us_term term*/
	FROM apps.per_all_people_f peep
		,apps.per_all_assignments_f asg
		,apps.hr_locations_all loc
		,apps.per_person_types types
		,apps.per_periods_of_service serv
		,apps.ttec_us_term term
	--End R12.2 Upgrade Remediation
	WHERE peep.person_id = asg.person_id
	AND asg.assignment_type = 'E'
	AND sysdate between asg.effective_start_date and asg.effective_end_date
	AND sysdate between peep.effective_start_date and peep.effective_end_date
	AND loc.location_id = asg.location_id
--	AND loc.location_code = term.location_code
--	AND peep.business_group_id = 325 
	AND types.person_type_id = peep.person_type_id
	AND serv.person_id = peep.person_id
	AND peep.employee_number = term.employee_number
	ORDER BY term.employee_number;

g_records_read  	NUMBER := 0;
g_records_processed NUMBER := 0;

--g_person_type_id		   	  NUMBER := 90;	   --EX_EMP
--g_assignment_status_type_id   NUMBER := 145;   --TERM_ASSIGN
--g_leaving_reason			  VARCHAR2(10) := '24011'; --(240 11) Employment Ended - Laid Off
--g_actual_termination_date 	  DATE	 := to_date('11-JUL-2003','DD-MON-RRRR');
	
--***************************************************************
--*****                  Main procedure                		*****
--***************************************************************	

PROCEDURE main IS

l_object_version_number 	 number    	  := null;
l_final_process_date         date 		  := null;

l_org_now_no_manager_warning boolean 	  := null;
l_asg_future_changes_warning boolean 	  := null;
l_entries_changed_warning 	 varchar2(20) := null;
--l_entries_changed_warning 	 varchar2(20) := null;

BEGIN

	FOR sel in csr_term_people LOOP
	
	g_records_read := g_records_read + 1; 
	
	BEGIN
			
			l_object_version_number 	 := null;
			l_final_process_date         := null;
			l_org_now_no_manager_warning := null;
			l_asg_future_changes_warning := null;
			l_entries_changed_warning 	 := null;
			
	
			l_object_version_number := sel.object_version_number;
			
			
			hr_ex_employee_api.final_process_emp
			  (p_validate                     => false
			  ,p_period_of_service_id         => sel.period_of_service_id
			  ,p_object_version_number        => l_object_version_number
			  ,p_final_process_date           => sel.final_process_date    

   			  --OUT Parameters
			  ,p_org_now_no_manager_warning   =>  l_org_now_no_manager_warning
			  ,p_asg_future_changes_warning   =>  l_asg_future_changes_warning
			  ,p_entries_changed_warning      =>  l_entries_changed_warning
			  );
			commit;
                     
--			  dbms_output.PUT_LINE('Processed: ' || sel.full_name || '   ' || sel.employee_number);
			  
		  	  g_records_processed := g_records_processed + 1;
			  
			EXCEPTION
				WHEN OTHERS THEN
                          --update hr.per_periods_of_service 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						  update apps.per_periods_of_service 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
						  set final_process_date =  sel.final_process_date
                          where period_of_service_id = sel.period_of_service_id
						  and actual_termination_date = sel.actual_term_date
						  and person_id = sel.person_id;

				  
				  commit;
				
	--			  dbms_output.PUT_LINE('Errored out: ' || sel.full_name || '   ' || sel.employee_number||SQLERRM);   
			
			END;  
	
	END LOOP;

	dbms_output.PUT_LINE('Total Read: ' || g_records_read ); 
	dbms_output.PUT_LINE('Total Processed: ' || g_records_processed); 
	
  
END;

--***************************************************************
--*****                  Call Main procedure                *****
--***************************************************************

begin
     main;

end;
/

commit;

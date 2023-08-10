 /************************************************************************************
        Program Name: termination.sql

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
	SELECT peep.full_name
		   ,peep.person_id
		   ,peep.employee_number
		   ,types.user_person_type
		   ,asg.assignment_status_type_id
		   ,loc.location_code
		   ,serv.object_version_number
		   ,serv.period_of_service_id
	--START R12.2 Upgrade Remediation		
	/*FROM hr.per_all_people_f peep
		,hr.per_all_assignments_f asg
		,hr.hr_locations_all loc
		,hr.per_person_types types
		,hr.per_periods_of_service serv*/
	FROM apps.per_all_people_f peep
		,apps.per_all_assignments_f asg
		,apps.hr_locations_all loc
		,apps.per_person_types types
		,apps.per_periods_of_service serv	
	--End R12.2 Upgrade Remediation	
	WHERE peep.person_id = asg.person_id
	AND asg.assignment_type = 'E'
	AND sysdate between asg.effective_start_date and asg.effective_end_date
	AND sysdate between peep.effective_start_date and peep.effective_end_date
	AND loc.location_id = asg.location_id
	AND location_code ='USA-Denver East'
	AND peep.business_group_id = 325 
	AND types.person_type_id = peep.person_type_id
	AND types.system_person_type = 'EMP'
	AND serv.person_id = peep.person_id
	ORDER BY peep.full_name;

g_records_read  	NUMBER := 0;
g_records_processed NUMBER := 0;

g_person_type_id		   	  NUMBER := 90;	   --EX_EMP
g_assignment_status_type_id   NUMBER := 145;   --TERM_ASSIGN
g_leaving_reason			  VARCHAR2(10) := '24011'; --(240 11) Employment Ended - Laid Off
g_actual_termination_date 	  DATE	 := to_date('16-MAR-2003','DD-MON-RRRR');
	
--***************************************************************
--*****                  Main procedure                		*****
--***************************************************************	

PROCEDURE main IS

l_object_version_number 	 number    	  := null;
l_last_standard_process_date date 		  := null;

l_supervisor_warning  		 boolean 	  := null;
l_event_warning 	  		 boolean 	  := null;
l_interview_warning   		 boolean 	  := null;
l_review_warning 	  		 boolean 	  := null;
l_recruiter_warning   		 boolean 	  := null;
l_asg_future_changes_warning boolean 	  := null;
l_entries_changed_warning 	 varchar2(20) := null;
l_pay_proposal_warning 		 boolean 	  := null;
l_dod_warning 				 boolean 	  := null;


BEGIN

	FOR sel in csr_term_people LOOP
	
	g_records_read := g_records_read + 1; 
	
			BEGIN
			
			l_object_version_number 	 := null;
			l_last_standard_process_date := null;
			l_supervisor_warning  		 := null;
			l_event_warning 	  		 := null;
			l_interview_warning   		 := null;
			l_review_warning 	  		 := null;
			l_recruiter_warning   		 := null;
			l_asg_future_changes_warning := null;
			l_entries_changed_warning 	 := null;
			l_pay_proposal_warning 		 := null;
			l_dod_warning 				 := null;
			
			
			--update hr.per_addresses	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			update apps.per_addresses		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
			set address_type = 'PHCA'	
			where person_id = sel.person_id
			and address_type = 'HOME';
			
			commit;
			
			
			l_object_version_number := sel.object_version_number;
			
			
			hr_ex_employee_api.actual_termination_emp
			  (p_validate                     => false
			  ,p_effective_date               => sysdate
			  ,p_period_of_service_id         => sel.period_of_service_id
			  ,p_object_version_number        => l_object_version_number
			  ,p_actual_termination_date      => g_actual_termination_date
			  ,p_last_standard_process_date   => l_last_standard_process_date 
			  ,p_person_type_id               => g_person_type_id 
			  ,p_assignment_status_type_id    => g_assignment_status_type_id 
  			  --,p_leaving_reason               => g_leaving_reason 
			--OUT Parameters
			  ,p_supervisor_warning           =>  l_supervisor_warning
			  ,p_event_warning                =>  l_event_warning
			  ,p_interview_warning            =>  l_interview_warning
			  ,p_review_warning               =>  l_review_warning
			  ,p_recruiter_warning            =>  l_recruiter_warning
			  ,p_asg_future_changes_warning   =>  l_asg_future_changes_warning
			  ,p_entries_changed_warning      =>  l_entries_changed_warning
			  ,p_pay_proposal_warning         =>  l_pay_proposal_warning
			  ,p_dod_warning                  =>  l_dod_warning  
			  );
			  
			  commit;
			  
			  --update hr.per_addresses	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  update apps.per_addresses	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  set address_type = 'HOME'
			  where person_id = sel.person_id
			  and address_type = 'PHCA';
			  
			  commit;
			  
                          update hr.per_periods_of_service	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						  update apps.per_periods_of_service	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                          set leaving_reason =  g_leaving_reason
                          where
                          period_of_service_id = sel.period_of_service_id;

                          commit;
                          
--			  dbms_output.PUT_LINE('Processed: ' || sel.full_name || '   ' || sel.employee_number);
			  
		  	  g_records_processed := g_records_processed + 1;
			  
			EXCEPTION
				WHEN OTHERS THEN
				
				  --update hr.per_addresses	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  update apps.per_addresses	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  set address_type = 'HOME'
				  where person_id = sel.person_id
				  and address_type = 'PHCA';
				  
				  commit;
				
				  dbms_output.PUT_LINE('Errored out: ' || sel.full_name || '   ' || sel.employee_number||SQLERRM);   
			
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

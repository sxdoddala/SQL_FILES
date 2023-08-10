/*
-------------------------------------------------------------

Program Name    : ttec_dac_hr_data_interface_intl.sql                                 

Desciption      : This program will get the files from /data/dac_data/data_in directory 
                        and validate and process HR Tables

Input/Output Parameters                                                     

Called From     :  Teletech DAC HR Interface

Created By      : Saket Raizada
Date            : 17-JAN-2023                                                         

Modification Log: 
-----------------                                                          
Developer             Date        Description   
NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation                            

SET SERVEROUTPUT ON SIZE 1000000;
---------------------------------------------------------------
*/

DECLARE
    --v_ssn cust.ttec_dac_ext_intl_data.ssn%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	v_ssn apps.ttec_dac_ext_intl_data.ssn%TYPE;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

    CURSOR c1 IS
    SELECT
        *
    FROM
        --cust.ttec_dac_ext_intl_data;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		apps.ttec_dac_ext_intl_data;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
-- WHERE UPPER(employee_status) IN ('ACTIVE','LOA');

BEGIN
    BEGIN
        SELECT ssn
        INTO v_ssn
        --FROM cust.ttec_dac_ext_intl_data	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM apps.ttec_dac_ext_intl_data	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
        --  WHERE UPPER(employee_status) IN ('ACTIVE','LOA')
        WHERE ROWNUM < 2;

    EXCEPTION
        WHEN no_data_found THEN
             fnd_file.put_line(fnd_file.output, 'No Records exists in Data File to Process');
    END;

    IF v_ssn IS NOT NULL THEN
        BEGIN
                -- Before copying new data to original table
                -- need to delete all the old data
            --DELETE FROM cust.ttec_dac_hr_intl_data;  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			DELETE FROM apps.ttec_dac_hr_intl_data;  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                 NULL;
        END;
 
       FOR v1 IN c1 LOOP
            BEGIN
                --INSERT INTO cust.ttec_dac_hr_intl_data (	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				INSERT INTO apps.ttec_dac_hr_intl_data (	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
                    original_hire_date,
                    adjusted_service_date,
                    date_first_hired,
                    last_name,
                    middle_name,
                    first_name,
                    gender,
                    ssn,
                    birth_date,
                    work_email_address,
                    personal_email_address,
                    legacy_employee_id,
                    address1,
                    address2,
                    address3,
                    city,
                    state,
                    postal_code,
                    county,
                    employmentcountry,
                    job_code,
                    grade_code,
                    assignment_category,
                    supervisor_id,
                    phone_number,
                    salary_basis,
                    salary,
                    candidate_id,
                    marital_status,
                    ethnic_origin,
                    location_code,
                    department_code,
                    account_code,
                    gl_client_code,
                    timecard_required,
                    psa_resource,
                    work_arrangement,
                    work_arrangement_reason,
                    work_hours,
                    frequency,
                    working_at_home,
                    client_code,
                    program_code,
                    project_code,
                    employment_status,
					working_days,
	                holiday_schedule
                ) VALUES (
                    TO_DATE(v1.original_hire_date, 'DD-MON-YYYY'),
                    TO_DATE(v1.adjusted_service_date, 'DD-MON-YYYY'),
                    TO_DATE(v1.date_first_hired, 'DD-MON-YYYY'),
                    v1.last_name,
                    v1.middle_name,
                    v1.first_name,
                    v1.gender,
                    v1.ssn,
                    v1.birth_date,
                    v1.work_email_address,
                    v1.personal_email_address,
                    v1.legacy_employee_id,
                    v1.address1,
                    v1.address2,
                    v1.address3,
                    v1.city,
                    v1.state,
                    v1.postal_code,
                    v1.county,
                    v1.employmentcountry,
                    v1.job_code,
                    v1.grade_code,
                    v1.assignment_category,
                    v1.supervisor_id,
                    v1.phone_number,
                    v1.salary_basis,
                    v1.salary,
                    v1.candidate_id,
                    v1.marital_status,
                    v1.ethnic_origin,
                    v1.location_code,
                    v1.department_code,
                    v1.account_code,
                    v1.gl_client_code,
                    v1.timecard_required,
                    v1.psa_resource,
                    v1.work_arrangement,
                    v1.work_arrangement_reason,                    
                    v1.work_hours,
                    v1.frequency,
                    v1.working_at_home,
                    v1.client_code,
                    v1.program_code,
                    v1.project_code,
                    v1.employment_status,
					v1.working_days,
	                v1.holiday_schedule
                );

            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output, 'Error during importing to ttec_dac_hr_data table. Error is '|| substr(sqlerrm, 1, 150));
            END;

        END LOOP;
        COMMIT;

        BEGIN
            ttec_dac_hr_interface_intl_pkg.process_data;
        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output, 'Error during processing data');
        END;
        COMMIT;

        BEGIN
            ttec_dac_hr_interface_intl_pkg.update_supervisor;
        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output, 'Error during Updating supervisor');
        END;
        COMMIT;

        BEGIN
            ttec_dac_hr_interface_intl_pkg.process_status_out;
        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output, 'Error during status report');
        END;

    END IF;  -- V_SSN END IF

EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.output, 'Error during importing to ttec_glb_hr_data table ');
END;
/
--! $CUST_TOP/bin/ttec_sgp_load.sh
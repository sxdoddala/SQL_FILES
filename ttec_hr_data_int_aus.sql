/*
-------------------------------------------------------------

Program Name    : ttec_dac_hr_data_interface_aus.sql                                 

Desciption      : This program will get the files from /data/dac_data/data_in directory 
                        and validate and process HR Tables

Input/Output Parameters                                                     



Created By      : Neelofar
Date            : 12OCT-2022                                                         

Modification Log: 
-----------------                                                          
Developer             Date        Description                               
NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation          

SET SERVEROUTPUT ON SIZE 1000000;
---------------------------------------------------------------
*/

DECLARE

--v_ssn  CUST.TTEC_EXT_AUS_DATA.ssn%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
v_ssn  apps.TTEC_EXT_AUS_DATA.ssn%TYPE;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

CURSOR c1 IS
 --SELECT * FROM  CUST.TTEC_EXT_AUS_DATA;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
 SELECT * FROM  apps.TTEC_EXT_AUS_DATA;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
-- WHERE UPPER(employee_status) IN ('ACTIVE','LOA');

BEGIN 
      BEGIN
           --SELECT ssn INTO v_ssn FROM  CUST.TTEC_EXT_AUS_DATA	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   SELECT ssn INTO v_ssn FROM  apps.TTEC_EXT_AUS_DATA	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
          --  WHERE UPPER(employee_status) IN ('ACTIVE','LOA')
           WHERE ROWNUM < 2;
         EXCEPTION 
	WHEN NO_DATA_FOUND THEN 
              fnd_file.put_line(fnd_file.output,'No Records exists in Data File to Process');
        END;
    IF v_ssn IS NOT NULL THEN

       BEGIN
                -- Before copying new data to original table
                -- need to delete all the old data
              --DELETE FROM CUST.TTEC_HR_AUS_DATA ;   -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  DELETE FROM apps.TTEC_HR_AUS_DATA ;   -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
         END;

             FOR v1 IN c1 LOOP
	     BEGIN 
		 --INSERT INTO CUST.TTEC_HR_AUS_DATA(   -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 INSERT INTO apps.TTEC_HR_AUS_DATA(   -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		           ORIGINAL_HIRE_DATE , 
    ADJUSTED_SERVICE_DATE , 
	DATE_FIRST_HIRED,
    LAST_NAME , 
	MIDDLE_NAME , 
	FIRST_NAME , 
	ADDRESS1 , 
    ADDRESS2 , 
	CITY , 
    STATE , 
	POSTAL_CODE , 
	COUNTY , 
	PERSONAL_EMAIL_ADDRESS , 
	JOB_CODE , 
	GRADE_CODE ,
	EMPLOYMENT_STATUS , 
	SSN , 
	SUPERVISOR_ID , 
	PHONE_NUMBER , 
	GENDER , 
	BIRTH_DATE ,
	SALARY_BASIS , 
    SALARY , 
	LEGACY_EMPLOYEE_ID , 
	CANDIDATE_ID , 
	WORK_EMAIL_ADDRESS ,
	MARITAL_STATUS , 
	LOCATION_CODE , 
	DEPARTMENT_CODE , 
	ACCOUNT_CODE , 
	GL_CLIENT_CODE , 
	PSA_RESOURCE,
	WORK_ARRANGEMENT , 
	WORK_ARRANGEMENT_REASON , 
	WORK_HOURS , 
	FREQUENCY , 
	WORKING_AT_HOME,
	CLIENT_CODE , 
    	PROGRAM_CODE , 
    	PROJECT_CODE ,
    	OFFERING,
	VACCINE_MANDATE,
	LEGAL_ENTITY,
	PAYROLL_NAME,
	LEDGER,
	GRADE,
	JOB_TITLE,
	FIELD_LEAVLING_LOADING,
	WORKING_DAYS,
	HOLIDAY_SCHEDULE

				)      
	         VALUES	
				    (TO_DATE(v1.ORIGINAL_HIRE_DATE,'DD-MON-YYYY') ,
					TO_DATE(v1.ADJUSTED_SERVICE_DATE,'DD-MON-YYYY') ,
					  TO_DATE(v1.DATE_FIRST_HIRED,'DD-MON-YYYY') ,
v1.LAST_NAME,
v1.MIDDLE_NAME,
v1.FIRST_NAME,
v1.ADDRESS1,
v1.ADDRESS2,
v1.CITY,
v1.STATE,
v1.POSTAL_CODE,
v1.COUNTY,
v1.PERSONAL_EMAIL_ADDRESS,
v1.JOB_CODE,
v1.GRADE_CODE,
v1.EMPLOYMENT_STATUS,
v1.SSN,
v1.SUPERVISOR_ID,
v1.PHONE_NUMBER,
v1.GENDER,
v1.BIRTH_DATE,
v1.SALARY_BASIS,
v1.SALARY,
v1.LEGACY_EMPLOYEE_ID,
v1.CANDIDATE_ID,
v1.WORK_EMAIL_ADDRESS,
v1.MARITAL_STATUS,
v1.LOCATION_CODE,
v1.DEPARTMENT_CODE,
v1.ACCOUNT_CODE,
v1.GL_CLIENT_CODE , 
v1.PSA_RESOURCE,
v1.WORK_ARRANGEMENT,
v1.WORK_ARRANGEMENT_REASON,
v1.WORK_HOURS,
v1.FREQUENCY,
v1.WORKING_AT_HOME,
v1.CLIENT_CODE,
v1.PROGRAM_CODE,
v1.PROJECT_CODE,
v1.OFFERING,
v1.VACCINE_MANDATE,
v1.LEGAL_ENTITY,
v1.PAYROLL_NAME,
v1.LEDGER,
v1.GRADE,
v1.JOB_TITLE,
v1.FIELD_LEAVLING_LOADING,
v1.WORKING_DAYS,
v1.HOLIDAY_SCHEDULE				);
        	EXCEPTION 
		WHEN OTHERS THEN
                 	fnd_file.put_line(fnd_file.output,'Error during importing to ttec_dac_hr_data table. Error is '||SUBSTR(SQLERRM,1,150));
   	 END;
         END LOOP;
        COMMIT;

            BEGIN
	         ttec_hr_interface_aus_pkg.process_data;
            EXCEPTION
	WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output,'Error during processing data');
            END;
            COMMIT;

            BEGIN
	         ttec_hr_interface_aus_pkg.update_supervisor;
            EXCEPTION
	WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output,'Error during Updating supervisor');
            END;
         COMMIT;

         BEGIN
		ttec_hr_interface_aus_pkg.process_status_out;
         EXCEPTION
	WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output,'Error during status report');
         END;
    END IF;  -- V_SSN END IF

EXCEPTION 
   WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.output,'Error during importing to ttec_glb_hr_data table ');
END;
/
--! $CUST_TOP/bin/ttec_sgp_load.sh

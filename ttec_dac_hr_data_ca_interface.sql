/*
-------------------------------------------------------------

Program Name    : ttec_dac_hr_data_interface_ca.sql                                 

Desciption      : This program will get the files from /data/dac_data/data_in directory 
                        and validate and process HR Tables

Input/Output Parameters                                                     

Called From     :  Teletech DAC HR Interface


Created By      : Amir Aslam
Date            : 1-JAN-2016                                                         

Modification Log: 
-----------------                                                          
Developer             Date        Description                               
NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation 

SET SERVEROUTPUT ON SIZE 1000000;
---------------------------------------------------------------
*/

DECLARE

--v_ssn  CUST.TTEC_DAC_EXT_CA_DATA.ssn%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
v_ssn  apps.TTEC_DAC_EXT_CA_DATA.ssn%TYPE;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

CURSOR c1 IS
 --SELECT * FROM  CUST.TTEC_DAC_EXT_CA_DATA;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
 SELECT * FROM  apps.TTEC_DAC_EXT_CA_DATA;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
-- WHERE UPPER(employee_status) IN ('ACTIVE','LOA');

BEGIN 
      BEGIN
           --SELECT ssn INTO v_ssn FROM  CUST.TTEC_DAC_EXT_CA_DATA	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   SELECT ssn INTO v_ssn FROM  apps.TTEC_DAC_EXT_CA_DATA	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
            WHERE UPPER(employee_status) IN ('ACTIVE','LOA')
           AND ROWNUM < 2;
         EXCEPTION 
	WHEN NO_DATA_FOUND THEN 
              fnd_file.put_line(fnd_file.output,'No Records exists in Data File to Process');
        END;
    IF v_ssn IS NOT NULL THEN

       BEGIN
                -- Before copying new data to original table
                -- need to delete all the old data
              --DELETE FROM CUST.ttec_dac_hr_ca_data ;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  DELETE FROM apps.ttec_dac_hr_ca_data ;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
              COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
         END;

             FOR v1 IN c1 LOOP
	     BEGIN 
		 --INSERT INTO CUST.ttec_dac_hr_ca_data(  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		 INSERT INTO apps.ttec_dac_hr_ca_data(  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
				  last_name      ,
				  middle_name    ,
				  first_name     ,
				  pay_group_code ,
				  salary_basis   ,
				  address1       ,
				  city           ,
				  address2       ,
				  state          ,
				  postal_code    ,
				  position_code  ,
				  position_code_user_defined  ,
				 cost_code                   ,
				 employee_status             ,
			  	 original_hire_date          ,
				  email_address               ,
				  payroll_status              ,
				  seniority_date              ,
				  job_code                    ,
				  employment_status           ,
				  ssn                         ,
				  location                    ,
				  supervisor                  ,
				  phone_number                ,
				  gender                      ,
				  birth_date                  ,
				  annual_salary               ,
				  last_hire_date,
				 legacy_id,
				marital_status,
				ethnic_origin,
				veteran_status,
				i9,
				organization			  ,
				payroll                   ,
			  LEDGER                      ,
			  LOCATION_CODE               ,
			  CLIENT                      ,
			  DEPARTMENT                  ,
			  ACCOUNT                     ,
			  GL_LOCATION_CODE            ,
			  GL_CLIENT_CODE              ,
			  GL_DEPARTMENT_CODE          ,
			  CLIENT_CODE                 ,
			  ATELKA_ID       			,
			  US_MGR		
				)      
	         VALUES	
				(v1.last_name,                  
				v1.middle_name,
				v1.first_name,
				v1.pay_group_code,
				v1.salary_basis,
				v1.address1,
				v1.city,
				v1.address2,
				v1.state,
				v1.postal_code,
				v1.position_code,
	  			v1.position_code_user_defined,
			              v1.cost_code,
				v1.employee_status,
	  			TO_DATE(v1.original_hire_date,'MM-DD-YYYY') ,
	  			v1.email_address,               
	  			v1.payroll_status,      
	  			TO_DATE(v1.seniority_date,'MM-DD-YYYY') ,        
	  			v1.job_code,                    
	  			v1.employment_status,           
	  			v1.ssn,                        
	  			v1.location,                    
	  			v1.supervisor,                 
	  			v1.phone_number,                
	  			v1.gender,                     
	  			TO_DATE(v1.birth_date,'MM-DD-YYYY'),                 
	  			v1.annual_salary,               
	  			TO_DATE( v1.last_hire_date,'MM-DD-YYYY') ,
				 v1.legacy_id,
				v1.marital_status,
				v1.ethnic_origin,
				v1.veteran_status,
				v1.i9,
				v1.organization,
				v1.payroll						,
				v1.LEDGER                      ,
				v1.LOCATION_CODE               ,
				v1.CLIENT                      ,
				v1.DEPARTMENT                  ,
				v1.ACCOUNT                     ,
				v1.GL_LOCATION_CODE            ,
				v1.GL_CLIENT_CODE              ,
				v1.GL_DEPARTMENT_CODE          ,
				v1.CLIENT_CODE                 ,
				v1.ATELKA_ID                   ,
				v1.US_MGR
				);
        	EXCEPTION 
		WHEN OTHERS THEN
                 	fnd_file.put_line(fnd_file.output,'Error during importing to ttec_dac_hr_data table. Error is '||SUBSTR(SQLERRM,1,150));
   	 END;
         END LOOP;
        COMMIT;

            BEGIN
	         ttec_dac_hr_interface_ca_pkg.process_data;
            EXCEPTION
	WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output,'Error during processing data');
            END;
            COMMIT;

            BEGIN
	         ttec_dac_hr_interface_ca_pkg.update_supervisor;
            EXCEPTION
	WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.output,'Error during Updating supervisor');
            END;
         COMMIT;

         BEGIN
		ttec_dac_hr_interface_ca_pkg.process_status_out;
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

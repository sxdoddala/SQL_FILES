-- Program Name:  TTEC_VSP
--
-- Description:  This program will provide an extract of the Oracle Advanced Benefit system 
-- to be provided to VSP (Vision Service Plan). The extracted data will contain employee and dependent
-- information for participants in the VSP plan.
--
-- NOTE:  Per 10/1 discussion with Cathy Rien and Becca Smith, any employee terminations with future
--        cancellation of coverage will be handled by processing the life-event DateTracked to the future --        date.
--        So we should NOT need to do any special code logic for those situations.  If this logic does not --        hold to be true, this code will need to be modified to reflect a different OAB approach. 
--
-- Input/Output Parameters: 
--
-- Oracle Tables Accessed:  ttec_emptmp_vsp_tbl
--                          ttec_depntmp_vsp_tbl
--  
--
-- Tables Modified:  N/A
--
-- Procedures Called:  TTEC_PROCESS_ERROR
--
-- Created By:  Elizur Alfred-Ockiya
-- Date: November 26, 2002
--
-- Modification Log:
-- Developer   		Date        Description
-- ----------   	--------    --------------------
-- EAlfred-Ockiya  	11/26/02    Converted all output text to UPPER
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation 

--SET TIMING ON
--SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
-- Global Variables ---------------------------------------------------------------------------------
g_plan_1 VARCHAR2(50):= 'VSP';
g_date DATE := SYSDATE;
g_section_id VARCHAR2(3) := 'GEN';
g_transaction_code VARCHAR2(1) := 'R';
g_control_number VARCHAR2(5) := '99686';
g_adr_id VARCHAR2(3) := 'ADR';

--START R12.2 Upgrade Remediation
-- Variables used by Common Error Procedure
/*g_application_code               CUST.TTEC_error_handling.application_code%TYPE := 'OAB';
g_interface                      CUST.TTEC_error_handling.interface%TYPE := 'BEN_INT-10';
g_program_name                   CUST.TTEC_error_handling.program_name%TYPE := 'TTEC_VSP';
g_initial_status                 CUST.TTEC_error_handling.status%TYPE := 'INITIAL';
g_warning_status                 CUST.TTEC_error_handling.status%TYPE := 'WARNING';
g_failure_status                 CUST.TTEC_error_handling.status%TYPE := 'FAILURE';*/
g_application_code               apps.TTEC_error_handling.application_code%TYPE := 'OAB';
g_interface                      apps.TTEC_error_handling.interface%TYPE := 'BEN_INT-10';
g_program_name                   apps.TTEC_error_handling.program_name%TYPE := 'TTEC_VSP';
g_initial_status                 apps.TTEC_error_handling.status%TYPE := 'INITIAL';
g_warning_status                 apps.TTEC_error_handling.status%TYPE := 'WARNING';
g_failure_status                 apps.TTEC_error_handling.status%TYPE := 'FAILURE';
--End R12.2 Upgrade Remediation

-- Filehandle Variables
p_FileDir VARCHAR2(60)           :=  '/usr/tmp';
p_FileName VARCHAR2(50)          := 'VSP_REPORT';
v_daily_file UTL_FILE.FILE_TYPE;

-----------------------------------------------------------------------------------------------------
-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
CURSOR c_emp_data IS
SELECT national_identifier emp_ssn
       ,last_name emp_last_name
       ,first_name emp_first_name
       ,middle_names emp_middle_name
       ,sex emp_sex
       ,to_char(date_of_birth, 'YYYYMMDD') emp_dob
       ,to_char(orgnl_enrt_dt,'YYYYMMDD') emp_cvg_start_date
       ,decode(to_char(enrt_cvg_thru_dt,'YYYYMMDD'), '47121231', '        ',         to_char(enrt_cvg_thru_dt, 'YYYYMMDD')) emp_cvg_end_date
       ,address_line1 emp_addr_line1
       ,address_line2 emp_addr_line2
       ,town_or_city emp_city
       ,state emp_state
       ,zipcode emp_zip_code
       ,telephone_number_1 emp_home_phone
       ,country emp_country
       ,location_id emp_location_id
       ,opt_name emp_opt_name
    
--FROM   cust.ttec_emptmp_vsp_tbl 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
FROM   apps.ttec_emptmp_vsp_tbl 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
--DT 12/10/2001
;





------------------------------
-- Begin format_lastname ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_lastname (v_last_name IN OUT VARCHAR2) IS

--l_temp_name hr.per_all_people_f.last_name%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_temp_name apps.per_all_people_f.last_name%TYPE;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
i NUMBER := 0;
n NUMBER := 1;

BEGIN
  SELECT length(v_last_name)
  INTO   i
  FROM   DUAL;
  
  IF (i > 0) THEN  
    FOR c IN 1..i LOOP
      IF (upper(substr(v_last_name, n, 1)) between 'A' and 'Z') THEN
        l_temp_name := (l_temp_name||substr(v_last_name, n, 1));
        n := n + 1;
      ELSE
        n := n + 1;
      END IF; 
    END LOOP;
    v_last_name := l_temp_name;
  END IF;
END;
-----------------------------------------------------------------------------------------------------
-- Begin format_ssn ---------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_ssn (v_ssn IN OUT VARCHAR2) IS

--l_temp_ssn hr.per_all_people_f.national_identifier%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_temp_ssn apps.per_all_people_f.national_identifier%TYPE;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
i NUMBER := 0;
n NUMBER := 1;

BEGIN
  SELECT length(v_ssn)
  INTO   i
  FROM   dual;
  
  IF (i > 0) THEN  
    FOR c IN 1..i LOOP
      IF (upper(substr(v_ssn, n, 1)) between '0' and '9') THEN
        l_temp_ssn := (l_temp_ssn||substr(v_ssn, n, 1));
        n := n + 1;
      ELSE
        n := n + 1;
      END IF; 
    END LOOP;
    v_ssn := l_temp_ssn;
  END IF;
END;
-----------------------------------------------------------------------------------------------------
-- Begin format_address -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_address (v_address IN OUT VARCHAR2) IS

--l_temp_address hr.per_addresses.address_line1%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_temp_address apps.per_addresses.address_line1%TYPE;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
i NUMBER := 0;
n NUMBER := 1;

BEGIN
  SELECT length(v_address)
  INTO   i
  FROM   dual;
  
  IF (i > 0) THEN
    FOR c IN 1..i LOOP
      IF (upper(substr(v_address, n, 1)) = '/') OR
         (upper(substr(v_address, n, 1)) = '#')THEN
        n := n + 1;
      ELSE
        l_temp_address := (l_temp_address||substr(v_address, n, 1));
        n := n + 1;
      END IF; 
    END LOOP;
  END IF;
  v_address := l_temp_address;
END;

-----------------------------------------------------------------------------------------------------
-- Begin format_phone--------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_phone (v_phone IN OUT VARCHAR2) IS

i NUMBER := 0;
n NUMBER := 1;
--l_temp_phone hr.per_addresses.telephone_number_1%TYPE;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_temp_phone apps.per_addresses.telephone_number_1%TYPE;	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

BEGIN
  i := length(v_phone);
  
  IF (i > 0) THEN  
    FOR c IN 1..i LOOP
      IF substr(v_phone, n, 1) NOT IN (' ','(',')','-') THEN      -- Keep character if not a format character
        l_temp_phone := (l_temp_phone||substr(v_phone, n, 1));
        n := n + 1;
      ELSE
        n := n + 1;
      END IF; 
    END LOOP;
    v_phone := l_temp_phone;
  END IF;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_family_cvg  ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_family_cvg (v_plan IN VARCHAR2, v_relation OUT VARCHAR2) AS

v_cnct_rel VARCHAR2(5);

BEGIN
  
      if v_plan = 'Employee' or v_plan = 'Exec Employee' then     			  -- Employee Only
	  	 v_relation := 'C';
	  elsif instr(v_plan,'+1') > 0 or                                         -- Employee + 1
	        (instr(v_plan,'+Dom') > 0 and instr(v_plan,'+Fam') = 0) then        -- Domestic Partner, but not Family
	  		   v_relation := 'B';  	   						  
	  else 
	  		v_relation := 'A';                    -- Employee + All Dependents
      end if;
	  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_relation := null;
  WHEN TOO_MANY_ROWS THEN
    v_relation := null;
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_gender -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_gender (v_gender IN VARCHAR2, v_new_gender OUT VARCHAR2) IS

BEGIN

IF v_gender not in ('M','F') THEN             -- If field is blank, VSP defaults to Female anyway      
   v_new_gender := 'F';    
ELSE
   v_new_gender := v_gender;         
END IF;  

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_new_gender := null;
  WHEN TOO_MANY_ROWS THEN
    v_new_gender := null;
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_relation -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_relation (p_depn_person_type IN VARCHAR2,  p_disabled IN VARCHAR2, 
                            p_student IN VARCHAR2, p_relation OUT VARCHAR2) IS
BEGIN
    IF p_depn_person_type in ('S','CLS') THEN
       p_relation := 'S';
    ELSIF p_depn_person_type in ('C', 'A', 'O', 'T') THEN     -- Child, Adopted Child, Foster Child, Step Child
       IF p_disabled in ('F', 'P', 'Y') THEN
          p_relation := 'H';                      -- Disabled Dependent
       ELSIF p_student = 'FULL-TIME' then
	  p_relation := 'T ';                      -- Student
       ELSE 
	  p_relation := 'C';                       -- Child
       END IF;
     ELSIF p_depn_person_type = 'D' THEN							  -- Same Sex Domestic Partner
	   p_relation := 'P';
     ELSE
	   p_relation := 'O';                            -- Need to determine "others"
     END IF;

END;

---------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------
-- Begin get_family_cvg  ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_vsp_div (v_location IN VARCHAR2, v_vsp_div OUT VARCHAR2) AS

v_cnct_rel VARCHAR2(5);

BEGIN
  
      if v_location in ('11012','01002','01350','01400') then         -- Corporate
	     v_vsp_div := '0001';
	  elsif v_location = '01118' then			      -- Atlanta, GA
	     v_vsp_div := '0002';
	  elsif v_location = '01254' then     			      -- Birmingham, AL
	     v_vsp_div := '0003';
          elsif v_location = '01115' then			      -- Bremerton, WA
	     v_vsp_div := '0004';
          elsif v_location = '01650' then		              -- DeLand, FL
	     v_vsp_div := '0005';
          elsif v_location = '01551' then			      -- Enfield, CT
	     v_vsp_div := '0006';
	  elsif v_location = '01119' then 		              -- Englewood, CO
	     v_vsp_div := '0007';
	  elsif v_location = '01352' then	 	  	      -- Greenville, SC
	     v_vsp_div := '0008';
	  elsif v_location = '01117' then		              -- Hampton, VA
	     v_vsp_div := '0009';
	  elsif v_location in ('99905','99900') then		      -- Irvine, CA
	     v_vsp_div := '0010';
	  elsif v_location = '01402' then			      -- Kansas City, KS
	     v_vsp_div := '0011';
	  elsif v_location = '11100' then			      -- Melbourne
	     v_vsp_div := '0012';
	  elsif v_location IN ('11014','11050','11055') then				-- Percepta, MI
	     v_vsp_div := '0013';
	  elsif v_location = '01401' then			-- Montbello, CO
	     v_vsp_div := '0014';
	  elsif v_location = '01310' then			-- Morgantown, WV
	     v_vsp_div := '0015';
	  elsif v_location = '01300' then			-- Moundsville, WV
	     v_vsp_div := '0016';
	  elsif v_location in ('01121','01202') then           -- N. Hollywood, CA
	     v_vsp_div := '0017';
	  elsif v_location = '01251' then	  				    -- Niagara Falls, NY
	     v_vsp_div := '0018';
	  elsif v_location = '92121' then			-- San Diego, CA
             v_vsp_div := '0019';
	  elsif v_location = '01271' then			-- Stockton, CA
	     v_vsp_div := '0020';
	  elsif v_location = '01351' then			-- Tampa, FL
	     v_vsp_div := '0021';
	  elsif v_location = '01253' then	  				  	-- Topeka, KS
	     v_vsp_div := '0022';
	  elsif v_location = '01353' then			-- Tucson, AZ
	     v_vsp_div := '0023';
	  elsif v_location = '01600' then			-- Uniontown, PA  
	     v_vsp_div := '0024';
	  elsif v_location = '11200' then			-- San Diego - Percepta 
	     v_vsp_div := '0025';
	  else
	     v_vsp_div := NULL;
	  end if;
	  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_vsp_div := null;
  WHEN TOO_MANY_ROWS THEN
    v_vsp_div := null;
  WHEN OTHERS THEN
    RAISE;
END;


------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
PROCEDURE dependent_info(p_emp_ssn IN VARCHAR2,p_vsp_div IN VARCHAR2) IS

l_depn_output	CHAR(242);
l_relation		VARCHAR2(10);
l_depn_ssn		VARCHAR2(11);
l_record_code   VARCHAR2(1);

--l_module_name CUST.TTEC_error_handling.module_name%type := 'OAB';	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name apps.TTEC_error_handling.module_name%type := 'OAB';	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

l_emp_status    VARCHAR2(2);
l_emp_gender    VARCHAR2(2);
l_family_cvg    VARCHAR2(1);
l_vsp_div       VARCHAR2(30) := p_vsp_div ;

v_emp_ssn   VARCHAR2(30) := p_emp_ssn;
	
CURSOR c_depn_data  IS					
	SELECT national_identifier emp_ssn
    , last_name depn_last_name
    , first_name depn_first_name
    , sex depn_sex 
    , relationship depn_person_type
    , to_char(date_of_birth, 'YYYYMMDD') depn_dob
    , to_char(orgnl_enrt_dt,'YYYYMMDD') depn_cvg_start_date
    , decode(to_char(enrt_cvg_thru_dt,'YYYYMMDD'), '47121231', '        ', 
      to_char(enrt_cvg_thru_dt, 'YYYYMMDD')) depn_cvg_end_date
    , depn_ssn depn_ssn
    , disabled depn_disabled
    , student depn_student
--FROM   cust.ttec_depntmp_vsp_tbl depn	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
FROM   apps.ttec_depntmp_vsp_tbl depn	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
WHERE  national_identifier = v_emp_ssn;
		
BEGIN
     FOR depn IN c_depn_data LOOP
			 	       
--       format_lastname(depn.depn_last_name); -- Changes O'Brien to OBrien
       format_ssn(depn.emp_ssn); -- Changes 999-99-9999 to 999999999
       l_depn_ssn := depn.depn_ssn;
	   format_ssn(depn.depn_ssn); -- Changes 999-99-9999 to 999999999
						     
	   l_record_code := 'D';	    -- Subscriber		
	
          get_relation (depn.depn_person_type, depn.depn_disabled, depn.depn_student, l_relation);
  
	  get_gender(depn.depn_sex, l_emp_gender);
			
--		        v_rows := depn.depn_ssn;     
		      
--		        IF(v_rows is not null) THEN
		        l_depn_output := (NVL(UPPER(g_section_id),'GEN')
		                         || nvl(UPPER(l_record_code),'D')
						         || nvl(UPPER(g_transaction_code),'R')
					 	         || rpad(UPPER(g_control_number),5,' ')
						         || nvl(substr(rpad(depn.emp_ssn,9,'0'),1,9), rpad('0',9,'0'))
                                 || nvl(substr(rpad(UPPER(depn.depn_last_name),18,' '),1,18), rpad(' ',18,' '))
                                 || nvl(substr(rpad(UPPER(RTRIM(depn.depn_first_name)),12,' '),1,12),rpad(' ',12,' '))
						         || nvl(substr(rpad(UPPER(l_emp_gender),1,' '),1,1), rpad(' ',1,' '))
						         || rpad(' ',1,' ')  -- 1 space
						         || nvl(rpad(UPPER(l_relation),1,' '),' ')
						         || nvl(substr(rpad(depn.depn_dob,8,' '),1,8), rpad(' ',8,' '))
						         || nvl(substr(rpad(depn.depn_cvg_start_date,8,' '),1,8), rpad(' ',8,' '))
						         || nvl(substr(rpad(depn.depn_cvg_end_date,8,' '),1,8), rpad(' ',8,' '))
						         || nvl(substr(rpad(l_vsp_div,30,' '),1,30), rpad(' ',30,' ')) -- Div based on Employee's assignment location code
						         || rpad(' ',8,' ')   -- 8 blank spaces
						         || rpad(' ',8,' ')   -- 8 blank spaces
						         || rpad(' ',4,' ')   -- 4 blank spaces
						         || nvl(substr(rpad(depn.depn_ssn,9,'0'),1,18), rpad('0',9,'0'))			 
                                 || rpad(' ',107,' ') -- 107 blank spaces
		                         );
		        utl_file.put_line(v_daily_file, l_depn_output);			      

		
--		        END IF; --l_depn_output IF
				
--				l_relation := NULL;
		    END LOOP;  --Dependent Loop

END;
			

-----------------------------------------------------------------------------------------------------
-- Begin main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE main IS

-- Declare variables
--emp 	   	 	T_EMPLOYEE_INFO;
--depn 	   	 	T_DEPENDENT_INFO;
l_emp_output 	CHAR(242);
l_depn_output	CHAR(242);
v_rows 			VARCHAR2(20);
l_relation		VARCHAR2(10);
l_emp_ssn		VARCHAR2(11);
l_depn_ssn		VARCHAR2(11);
l_record_code   VARCHAR2(1);

--l_module_name CUST.TTEC_error_handling.module_name%type := 'OAB';	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name apps.TTEC_error_handling.module_name%type := 'OAB';	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

l_emp_status    VARCHAR2(2);
l_emp_gender    VARCHAR2(2);
l_family_cvg    VARCHAR2(1);
l_vsp_div       VARCHAR2(30);

-- Extract the invoice information from Oracle
BEGIN  
  v_daily_file := UTL_FILE.FOPEN(p_FileDir, p_FileName, 'w');
 
  
  -- Employee Data Extract --
  BEGIN

    FOR emp IN c_emp_data LOOP
    
--        EXIT  WHEN c_emp_data%NOTFOUND;
		
		l_emp_ssn := emp.emp_ssn;  
	
		DBMS_OUTPUT.PUT_LINE(emp.emp_ssn);

--        format_lastname(emp.emp_last_name); 
        format_ssn(emp.emp_ssn);
        format_address(emp.emp_addr_line1);
        format_address(emp.emp_addr_line2);
		format_phone(emp.emp_home_phone);
		
		l_record_code := 'E';	    -- Subscriber
		l_relation := '01';    -- Subscriber   
		get_family_cvg(emp.emp_opt_name, l_family_cvg);

		get_gender(emp.emp_sex, l_emp_gender);	
		
		get_vsp_div(emp.emp_location_id, l_vsp_div);

        dependent_info(l_emp_ssn,l_vsp_div);
      
--        v_rows := emp.emp_ssn;
		       
--        IF (v_rows is not null) THEN
        l_emp_output := (   NVL(UPPER(g_section_id),'GEN')
		                 || nvl(UPPER(l_record_code),'E')
						 || nvl(UPPER(g_transaction_code),'R')
					 	 || rpad(UPPER(g_control_number),5,' ')
						 || nvl(substr(rpad(emp.emp_ssn,9,'0'),1,9), rpad('0',9,'0'))
                         || nvl(substr(rpad(UPPER(emp.emp_last_name),18,' '),1,18), rpad(' ',18,' '))
                         || nvl(substr(rpad(UPPER(RTRIM(emp.emp_first_name))||' '||UPPER(RTRIM(emp.emp_middle_name)),12,' '),1,12),rpad(' ',12,' '))
						 || nvl(substr(rpad(UPPER(l_emp_gender),1,' '),1,1), rpad(' ',1,' '))
						 || nvl(rpad(UPPER(l_family_cvg),1,' '),'C')
						 || rpad(' ',1,' ')  -- 1 space
						 || nvl(substr(rpad(emp.emp_dob,8,' '),1,8), rpad(' ',8,' '))
						 || nvl(substr(rpad(emp.emp_cvg_start_date,8,' '),1,8), rpad(' ',8,' '))
						 || nvl(substr(rpad(emp.emp_cvg_end_date,8,' '),1,8), rpad(' ',8,' '))
						 || nvl(substr(rpad(l_vsp_div,30,' '),1,30), rpad(' ',30,' ')) -- Div based on assignment location code
						 || rpad(' ',8,' ')   -- Cross-Reference Code 1
						 || rpad(' ',8,' ')   -- Cross-Reference Code 2
						 || rpad(' ',4,' ')   -- 4 blank spaces
						 || rpad(' ',9,' ')   -- 9 blank spaces
						 || nvl(substr(rpad(UPPER(g_adr_id),3,' '),1,3), 'ADR')			 
                         || nvl(substr(rpad(UPPER(emp.emp_addr_line1),30,' '),1,30), rpad(' ',30,' '))
						 || nvl(substr(rpad(UPPER(emp.emp_addr_line2),30,' '),1,30), rpad(' ',30,' '))
                         || nvl(substr(rpad(UPPER(emp.emp_city),19,' '),1,19),rpad(' ',19,' '))
                         || nvl(substr(rpad(UPPER(emp.emp_state),2,' '),1,2),rpad(' ',2,' '))
                         || nvl(substr(rpad(emp.emp_zip_code,10,' '),1,10),rpad(' ',10,' '))
						 || nvl(substr(rpad(emp.emp_home_phone,10,' '),1,10), rpad(' ',10,' '))
--						 || nvl(substr(rpad(UPPER(emp.emp_country),3,' '),1,3), rpad(' ',3,' '))
                        );
      
        utl_file.put_line(v_daily_file, l_emp_output);
		

    END LOOP;	 --Employee Loop
END;	  		 --Outer Dependent BEGIN
  
  UTL_FILE.FCLOSE(v_daily_file);
  
EXCEPTION
  WHEN UTL_FILE.INVALID_OPERATION THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20051, p_FileName ||':  Invalid Operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20052, p_FileName ||':  Invalid File Handle');
  WHEN UTL_FILE.READ_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20053, p_FileName ||':  Read Error');
  WHEN UTL_FILE.INVALID_PATH THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20054, p_FileName ||':  Invalid Path');
  WHEN UTL_FILE.INVALID_MODE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20055, p_FileName ||':  Invalid Mode');
  WHEN UTL_FILE.WRITE_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20056, p_FileName ||':  Write Error');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20057, p_FileName ||':  Internal Error');
  WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20058, p_FileName ||':  Maxlinesize Error');
  WHEN OTHERS THEN
		UTL_FILE.FCLOSE(v_daily_file);
    --CUST.TTEC_PROCESS_ERROR (g_application_code, g_interface, g_program_name, l_module_name,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	apps.TTEC_PROCESS_ERROR (g_application_code, g_interface, g_program_name, l_module_name,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                         'FAILURE', SQLCODE, SQLERRM);
		RAISE;

END; 
-----------------------------------------------------------------------------------------------------
-- Calls main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
BEGIN
   main;
END;


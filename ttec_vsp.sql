-- Program Name:  TTEC_VSP
--
-- Description:  This program will provide an extract of the Oracle Advanced Benefit system 
-- to be provided to VSP (Vision Service Plan). The extracted data will contain employee and dependent
-- information for participants in the VSP plan.
--
-- NOTE:  Per 10/1 discussion with Cathy Rien and Becca Smith, any employee terminations with future
--        cancellation of coverage will be handled by processing the life-event DateTracked to the future date.
--        So we should NOT need to do any special code logic for those situations.  If this logic does not hold
--        to be true, this code will need to be modified to reflect a different OAB approach. 
--
-- Input/Output Parameters: 
--
-- Oracle Tables Accessed:  PER_ALL_PEOPLE_F
--                          PER_ADDRESSES
--                          BEN_PRTT_ENRT_RSLT_F
--                          BEN_DPNT_CVG_ELIGY_PRFL_F
--                          BEN.BEN_PER_IN_LER
--                          BEN.BEN_PL_F PL
--
-- Tables Modified:  N/A
--
-- Procedures Called:  TTEC_PROCESS_ERROR
--
-- Created By:  C.Boehmer
-- Date: September 19, 2002
--
-- Modification Log:
-- Developer    Date        Description
-- ----------   --------    --------------------
-- CBoehmer     09/27/02    Converted all output text to UPPER
-- CBoehmer     10/01/02    Added get_vsp_div to lookup Division code from Employee's assignment location
--                          This will eventually be replaced with an OAB lookup table
-- CBoehmer     10/09/02    Remove unused global variable settings
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation 
SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

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
p_FileName VARCHAR2(50)          := 't4399686';
v_daily_file UTL_FILE.FILE_TYPE;

-----------------------------------------------------------------------------------------------------
-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
CURSOR c_emp_data IS
SELECT emp.national_identifier
       , emp.last_name
       , emp.first_name
	   , emp.middle_names
       , emp.sex
       , to_char(emp.date_of_birth, 'YYYYMMDD')
	   , to_char(rslt.enrt_cvg_strt_dt,'YYYYMMDD')
       , decode(to_char(rslt.enrt_cvg_thru_dt,'YYYYMMDD'), '47121231', '        ', to_char(rslt.enrt_cvg_thru_dt, 'YYYYMMDD'))
       , adr.address_line1
       , adr.address_line2
       , adr.town_or_city
       , adr.region_2
       , adr.postal_code
	   , adr.telephone_number_1
	   , adr.country
	   , asg.location_id
	   , opt.name
--START R12.2 Upgrade Remediation    
/*FROM   hr.per_all_people_f emp
    ,  hr.per_addresses adr
	,  hr.per_person_types pt
	,  hr.per_periods_of_service pos
	,  hr.per_all_assignments_f asg
    ,  ben.ben_prtt_enrt_rslt_f rslt
    ,  ben.ben_pl_f pl
	,  ben.ben_opt_f opt
	,  ben.ben_oipl_f oipl
    ,  ben.ben_per_in_ler ler
    ,  ben.ben_pgm_f pgm --DT 12/10/2001*/
FROM   apps.per_all_people_f emp
    ,  apps.per_addresses adr
	,  apps.per_person_types pt
	,  apps.per_periods_of_service pos
	,  apps.per_all_assignments_f asg
    ,  apps.ben_prtt_enrt_rslt_f rslt
    ,  apps.ben_pl_f pl
	,  apps.ben_opt_f opt
	,  apps.ben_oipl_f oipl
    ,  apps.ben_per_in_ler ler
    ,  apps.ben_pgm_f pgm --DT 12/10/2001
--End R12.2 Upgrade Remediation
WHERE  emp.person_id = adr.person_id
AND    rslt.person_id = emp.person_id
AND    emp.person_type_id = pt.person_type_id
AND    emp.person_id = pos.person_id (+)
AND    emp.person_id = asg.person_id
AND    pgm.pgm_id = rslt.pgm_id --DT 12/10/2001
AND    UPPER(pgm.name) != 'COBRA' --DT 12/10/2001
AND    adr.primary_flag = 'Y'
AND    pl.pl_id = rslt.pl_id
AND    (pl.name = g_plan_1)
AND	   oipl.opt_id = opt.opt_id
AND    rslt.oipl_id = oipl.oipl_id
AND    rslt.per_in_ler_id = ler.per_in_ler_id
AND    ler.bckt_dt is null
-- Restricts to most current record
AND    trunc(sysdate) between pl.effective_start_date and pl.effective_end_date
AND    trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
AND    trunc(sysdate) between adr.date_from and nvl(adr.date_to, trunc(sysdate))
AND    trunc(sysdate) between asg.effective_start_date AND asg.effective_end_date
AND    trunc(sysdate) between rslt.effective_start_date and rslt.effective_end_date
AND    rslt.enrt_cvg_thru_dt > rslt.enrt_cvg_strt_dt
AND    trunc(sysdate) between rslt.enrt_cvg_strt_dt and rslt.enrt_cvg_thru_dt --DT 11/20/2001
AND    trunc(sysdate) between pos.date_start and nvl(pos.actual_termination_date, trunc(sysdate))
;


CURSOR c_depn_data (v_emp_ssn IN VARCHAR2) IS					
SELECT emp.national_identifier
       , depn.last_name
       , depn.first_name
       , depn.sex
	   , pt.user_person_type
	   , to_char(depn.date_of_birth, 'YYYYMMDD')
       , to_char(eldp.cvg_strt_dt,'YYYYMMDD')
       , decode(to_char(eldp.cvg_thru_dt,'YYYYMMDD'), '47121231', '        ', to_char(eldp.cvg_thru_dt, 'YYYYMMDD'))
       , depn.national_identifier
	   , depn.registered_disabled_flag
	   , depn.student_status
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
     , hr.per_all_people_f depn
	 , hr.per_person_types pt
     , ben.ben_pl_f pl
     , ben.ben_elig_cvrd_dpnt_f eldp
     , ben.ben_prtt_enrt_rslt_f rslt
     , ben.ben_per_in_ler ler
     , ben.ben_pgm_f pgm --DT 12/10/2001    */
FROM   apps.per_all_people_f emp
     , apps.per_all_people_f depn
	 , apps.per_person_types pt
     , apps.ben_pl_f pl
     , apps.ben_elig_cvrd_dpnt_f eldp
     , apps.ben_prtt_enrt_rslt_f rslt
     , apps.ben_per_in_ler ler
     , apps.ben_pgm_f pgm --DT 12/10/2001      
--End R12.2 Upgrade Remediation
WHERE  eldp.dpnt_person_id = depn.person_id
AND    pgm.pgm_id = rslt.pgm_id --DT 12/10/2001
AND    depn.person_type_id = pt.person_type_id
AND    UPPER(pgm.name) != 'COBRA' --DT 12/10/2001
AND    eldp.prtt_enrt_rslt_id = rslt.prtt_enrt_rslt_id
AND    rslt.person_id = emp.person_id
AND    pl.pl_id = rslt.pl_id
AND    eldp.cvg_strt_dt < eldp.cvg_thru_dt
AND    eldp.per_in_ler_id = ler.per_in_ler_id
AND    (pl.name = g_plan_1)
AND    ler.bckt_dt is null --DT 11/20/2001
-- Restricts to most recent record
AND    trunc(sysdate)between emp.effective_start_date and emp.effective_end_date
AND    trunc(sysdate)between depn.effective_start_date and depn.effective_end_date
AND    trunc(sysdate) between rslt.effective_start_date and rslt.effective_end_date
AND    trunc(sysdate) between eldp.effective_start_date and eldp.effective_end_date
-- AND    trunc(sysdate) between eldp.cvg_strt_dt and eldp.cvg_thru_dt --DT 11/20/2001
AND	   emp.NATIONAL_IDENTIFIER = v_emp_ssn 
;


-----------------------------------------------------------------------------------------------------
-- Record declaration -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--START R12.2 Upgrade Remediation
/*TYPE T_EMPLOYEE_INFO IS RECORD
(
  emp_ssn            hr.per_all_people_f.national_identifier%TYPE
, emp_last_name      hr.per_all_people_f.last_name%TYPE
, emp_first_name     hr.per_all_people_f.first_name%TYPE
, emp_middle_name    hr.per_all_people_f.middle_names%TYPE
, emp_sex            hr.per_all_people_f.sex%TYPE
, emp_dob            VARCHAR2(8)
, emp_cvg_start_date VARCHAR2(8)
, emp_cvg_end_date   VARCHAR2(8)
, emp_addr_line1     hr.per_addresses.address_line1%TYPE
, emp_addr_line2     hr.per_addresses.address_line2%TYPE
, emp_city           hr.per_addresses.town_or_city%TYPE
, emp_state          hr.per_addresses.region_2%TYPE
, emp_zip_code       hr.per_addresses.postal_code%TYPE
, emp_home_phone     hr.per_addresses.telephone_number_1%TYPE
, emp_country        hr.per_addresses.country%TYPE
, emp_location_id    hr.per_all_assignments_f.location_id%TYPE
, emp_opt_name       ben.ben_opt_f.NAME%TYPE

);

TYPE T_DEPENDENT_INFO IS RECORD
( emp_ssn                   hr.per_all_people_f.national_identifier%TYPE
, depn_last_name            hr.per_all_people_f.last_name%TYPE
, depn_first_name           hr.per_all_people_f.first_name%TYPE
, depn_sex                  hr.per_all_people_f.sex%TYPE
, depn_person_type          hr.per_person_types.USER_PERSON_TYPE%TYPE
, depn_dob                  VARCHAR2(8)
, depn_cvg_start_date       VARCHAR2(8)
, depn_cvg_end_date         VARCHAR2(8)
, depn_ssn                  hr.per_all_people_f.national_identifier%TYPE
, depn_disabled             hr.per_all_people_f.REGISTERED_DISABLED_FLAG%TYPE
, depn_student              hr.per_all_people_f.STUDENT_STATUS%TYPE
);
*/
TYPE T_EMPLOYEE_INFO IS RECORD
(
  emp_ssn            apps.per_all_people_f.national_identifier%TYPE
, emp_last_name      apps.per_all_people_f.last_name%TYPE
, emp_first_name     apps.per_all_people_f.first_name%TYPE
, emp_middle_name    apps.per_all_people_f.middle_names%TYPE
, emp_sex            apps.per_all_people_f.sex%TYPE
, emp_dob            VARCHAR2(8)
, emp_cvg_start_date VARCHAR2(8)
, emp_cvg_end_date   VARCHAR2(8)
, emp_addr_line1     apps.per_addresses.address_line1%TYPE
, emp_addr_line2     apps.per_addresses.address_line2%TYPE
, emp_city           apps.per_addresses.town_or_city%TYPE
, emp_state          apps.per_addresses.region_2%TYPE
, emp_zip_code       apps.per_addresses.postal_code%TYPE
, emp_home_phone     apps.per_addresses.telephone_number_1%TYPE
, emp_country        apps.per_addresses.country%TYPE
, emp_location_id    apps.per_all_assignments_f.location_id%TYPE
, emp_opt_name       apps.ben_opt_f.NAME%TYPE

);

TYPE T_DEPENDENT_INFO IS RECORD
( emp_ssn                   apps.per_all_people_f.national_identifier%TYPE
, depn_last_name            apps.per_all_people_f.last_name%TYPE
, depn_first_name           apps.per_all_people_f.first_name%TYPE
, depn_sex                  apps.per_all_people_f.sex%TYPE
, depn_person_type          apps.per_person_types.USER_PERSON_TYPE%TYPE
, depn_dob                  VARCHAR2(8)
, depn_cvg_start_date       VARCHAR2(8)
, depn_cvg_end_date         VARCHAR2(8)
, depn_ssn                  apps.per_all_people_f.national_identifier%TYPE
, depn_disabled             apps.per_all_people_f.REGISTERED_DISABLED_FLAG%TYPE
, depn_student              apps.per_all_people_f.STUDENT_STATUS%TYPE
);
--End R12.2 Upgrade Remediation
-----------------------------------------------------------------------------------------------------
-- Begin format_lastname ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_lastname (v_last_name IN OUT VARCHAR2) IS

l_temp_name hr.per_all_people_f.last_name%TYPE;
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

l_temp_ssn hr.per_all_people_f.national_identifier%TYPE;
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

l_temp_address hr.per_addresses.address_line1%TYPE;
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
l_temp_phone hr.per_addresses.telephone_number_1%TYPE;

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
PROCEDURE get_relation (v_depn_id IN VARCHAR2, v_disabled IN VARCHAR2, v_student IN VARCHAR2, v_relation OUT VARCHAR2) AS

v_type hr.per_contact_relationships.contact_type%TYPE;

BEGIN
  SELECT rel.contact_type
  INTO v_type
--START R12.2 Upgrade Remediation
/*  FROM hr.per_all_people_f depn,
       hr.per_contact_relationships rel,
       ben.ben_prtt_enrt_rslt_f rslt,
       ben.ben_per_in_ler ler,
       ben.ben_pl_f pl*/
  FROM apps.per_all_people_f depn,
       apps.per_contact_relationships rel,
       apps.ben_prtt_enrt_rslt_f rslt,
       apps.ben_per_in_ler ler,
       apps.ben_pl_f pl
--START R12.2 Upgrade Remediation
  where rel.person_id = rel.person_id
  AND   rel.contact_person_id = depn.person_id
  AND   depn.national_identifier = v_depn_id
  AND   rslt.person_id = rel.person_id
  AND   rslt.per_in_ler_id = ler.per_in_ler_id
  AND   ler.bckt_dt is null
  AND   rslt.enrt_cvg_thru_dt > rslt.enrt_cvg_strt_dt
  AND   pl.pl_id = rslt.pl_id
  AND   pl.name = g_plan_1
  AND   trunc(sysdate) between rel.date_start and nvl(rel.date_end, trunc(sysdate))
  AND   trunc(sysdate) between depn.effective_start_date and depn.effective_end_date
  AND   trunc(sysdate) between rslt.effective_start_date and rslt.effective_end_date;
  
  		IF v_type in ('S','CLS') THEN
		   v_relation := 'S';
		ELSIF v_type in ('C', 'A', 'O', 'T') THEN     -- Child, Adopted Child, Foster Child, Step Child
  	  		  IF v_disabled in ('F', 'P', 'Y') THEN
                 v_relation := 'H';                      -- Disabled Dependent
              ELSIF v_student = 'FULL-TIME' then
			     v_relation := 'T ';                      -- Student
			  ELSE 
			     v_relation := 'C';                       -- Child
			  END IF;
	    ELSIF v_type = 'D' THEN							  -- Same Sex Domestic Partner
		  	  v_relation := 'P';
		ELSE
			v_relation := 'O';                            -- Need to determine "others"
	    END IF;
			  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_relation := null;
  WHEN TOO_MANY_ROWS THEN
    v_relation := null;
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_family_cvg  ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_vsp_div (v_location IN VARCHAR2, v_vsp_div OUT VARCHAR2) AS

v_cnct_rel VARCHAR2(5);

BEGIN
  
      if v_location in ('101', '117') then              -- Corporate
	  	 v_vsp_div := '0001';
	  elsif v_location = '1648' then					-- Atlanta, GA
	     v_vsp_div := '0002';
	  elsif v_location = '282' then					    -- Birmingham, AL
	     v_vsp_div := '0003';
      elsif v_location = '1649' then					-- Bremerton, WA
	     v_vsp_div := '0004';
      elsif v_location = '562' then					    -- DeLand, FL
	     v_vsp_div := '0005';
      elsif v_location in ('182', '9118') then			-- Enfield, CT
	     v_vsp_div := '0006';
	  elsif v_location in ('113', '442', '622', '1650', '9111', '9113', '9114') then 	 -- Englewood, CO
	     v_vsp_div := '0007';
	  elsif v_location = '114' then	 	  			    -- Greenville, SC
	     v_vsp_div := '0008';
	  elsif v_location = '1652' then					-- Hampton, VA
	     v_vsp_div := '0009';
	  elsif v_location = '422' then					    -- Irvine, CA
	     v_vsp_div := '0010';
	  elsif v_location = '226' then					    -- Kansas City, KS
	     v_vsp_div := '0011';
	  elsif v_location = '1424' then					-- Percepta, MI
	     v_vsp_div := '0013';
	  elsif v_location in ('122', '9119') then			-- Montbello, CO
	     v_vsp_div := '0014';
	  elsif v_location in ('322', '9117') then			-- Morgantown, WV
	     v_vsp_div := '0015';
	  elsif v_location in ('112', '9116') then			-- Moundsville, WV
	     v_vsp_div := '0016';
	  elsif v_location in ('462', '1653', '9122') then	-- N. Hollywood, CA
	     v_vsp_div := '0017';
	  elsif v_location = '108' then	  				    -- Niagara Falls, NY
	     v_vsp_div := '0018';
	  elsif v_location in ('642', '1264') then			-- San Diego, CA
	     v_vsp_div := '0019';
	  elsif v_location in ('9115', '342') then			-- Stockton, CA
	     v_vsp_div := '0020';
	  elsif v_location in ('115', '9120') then			-- Tampa, FL
	     v_vsp_div := '0021';
	  elsif v_location = '262' then	  				  	-- Topeka, KS
	     v_vsp_div := '0022';
	  elsif v_location in ('116', '9121') then			-- Tucson, AZ
	     v_vsp_div := '0023';
	  elsif v_location in ('162', '9167') then			-- Uniontown, PA  
	     v_vsp_div := '0024';
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


-----------------------------------------------------------------------------------------------------
-- Begin main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE main IS

-- Declare variables
emp 	   	 	T_EMPLOYEE_INFO;
depn 	   	 	T_DEPENDENT_INFO;
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
    OPEN c_emp_data;
    LOOP
      BEGIN
        FETCH c_emp_data 
        INTO  emp.emp_ssn
            , emp.emp_last_name
            , emp.emp_first_name
			, emp.emp_middle_name
            , emp.emp_sex
            , emp.emp_dob
			, emp.emp_cvg_start_date
			, emp.emp_cvg_end_date
            , emp.emp_addr_line1
            , emp.emp_addr_line2
            , emp.emp_city
            , emp.emp_state
            , emp.emp_zip_code
			, emp.emp_home_phone
			, emp.emp_country
			, emp.emp_location_id
			, emp.emp_opt_name;
        EXIT  WHEN c_emp_data%NOTFOUND;
		
		l_emp_ssn := emp.emp_ssn;      

        format_lastname(emp.emp_last_name); 
        format_ssn(emp.emp_ssn);
        format_address(emp.emp_addr_line1);
        format_address(emp.emp_addr_line2);
		format_phone(emp.emp_home_phone);
		
		l_record_code := 'E';	    -- Subscriber
		l_relation := '01';    -- Subscriber   
		get_family_cvg(emp.emp_opt_name, l_family_cvg);

		get_gender(emp.emp_sex, l_emp_gender);	
		
		get_vsp_div(emp.emp_location_id, l_vsp_div);
      
        v_rows := emp.emp_ssn;
		       
        IF (v_rows is not null) THEN
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
						 || nvl(substr(rpad(UPPER(emp.emp_country),3,' '),1,3), rpad(' ',3,' '))
                        );
      
        utl_file.put_line(v_daily_file, l_emp_output);
		
	
		  -- Dependent Data Extract --
		  BEGIN 
		    OPEN c_depn_data (l_emp_ssn);
		    LOOP
		      BEGIN
		
		        FETCH c_depn_data
		        INTO  depn.emp_ssn 		   
					, depn.depn_last_name 			
					, depn.depn_first_name 			 		
					, depn.depn_sex 	
					, depn.depn_person_type	  					  			 	
					, depn.depn_dob 		 		  			
					, depn.depn_cvg_start_date			
					, depn.depn_cvg_end_date
					, depn.depn_ssn 
					, depn.depn_disabled
					, depn.depn_student	;		
		        EXIT  WHEN c_depn_data%NOTFOUND;     
			        
		        format_lastname(depn.depn_last_name); -- Changes O'Brien to OBrien
		        format_ssn(depn.emp_ssn); -- Changes 999-99-9999 to 999999999
				l_depn_ssn := depn.depn_ssn;
		        format_ssn(depn.depn_ssn); -- Changes 999-99-9999 to 999999999
						     
				l_record_code := 'D';	    -- Subscriber
				get_relation(l_depn_ssn, depn.depn_disabled, depn.depn_student, l_relation);
				get_gender(depn.depn_sex, l_emp_gender);
			
		        v_rows := depn.depn_ssn;     
		      
		        IF(v_rows is not null) THEN
		        l_depn_output := (	NVL(UPPER(g_section_id),'GEN')
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
		
		        END IF; --l_depn_output IF
				
				l_relation := NULL;
				
		      END;	   --Inner Dependent BEGIN   
		    END LOOP;  --Dependent Loop
		    CLOSE c_depn_data;
		  END;	  	   --Outer Dependent BEGIN
 
        END IF;  --l_emp_output IF
      	
		l_emp_ssn := NULL;
	  
	  END;		 --Inner Employee BEGIN
    END LOOP;	 --Employee Loop
    CLOSE c_emp_data;
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
    CUST.TTEC_PROCESS_ERROR (g_application_code, g_interface, g_program_name, l_module_name,
                         'FAILURE', SQLCODE, SQLERRM);
		RAISE;

END; 
-----------------------------------------------------------------------------------------------------
-- Calls main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
BEGIN
   main;
END;
/

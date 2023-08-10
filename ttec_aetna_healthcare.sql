-- Program Name:  TTEC_AETNA_US_HEALTHCARE
--
-- Description:  This program will provide an extract of the Oracle Advanced Benefit system 
-- to be provided to Aetna US Healthcare. The extracted data will contain employee and dependent
-- information for participants in the Aetna U.S. Healthcare Eligibility.
--
-- Input/Output Parameters: 
--
-- Oracle Tables Accessed:  PER_ALL_PEOPLE_F
--                          PER_ALL_ASSIGNMENTS_F
--                          PER_ADDRESSES
--                          PER_CONTACT_RELATIONSHIPS
--                          BEN_PRTT_ENRT_RSLT_F
--                          BEN_DPNT_CVG_ELIGY_PRFL_F
--                          BEN_ELIG_CVRD_DPNT_F
--                          BEN_PER_IN_LER
--                          BEN_PL_F PL
--                          BEN_PGM_F
--                          BEN_OPT_F
--                          BEN_OIPL_F
--                          HR_LOCATIONS_ALL
--
-- Tables Modified:  N/A
--
-- Procedures Called:  TTEC_PROCESS_ERROR
--
-- Created By:  Christiane Chan
-- Date: October 8, 2002
--
-- Modification Log:
-- Developer    Date        Description
-- ----------  ----------   --------------------
-- C. Chan     10/08/2002   File created
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation     


SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
-- Global Variables ---------------------------------------------------------------------------------
g_plan_1  			VARCHAR2(50) := 'Aetna%';
g_record_type	VARCHAR2(3)  := '010';
g_sys_date VARCHAR2(8) := to_char(sysdate,'YYYYMMDD');
g_end_of_month_date VARCHAR2(8) := to_char(last_day(sysdate),'YYYYMMDD');

-- Variables used by Common Error Procedure
g_application_code               CUST.TTEC_error_handling.application_code%TYPE := 'OAB';
g_interface                      CUST.TTEC_error_handling.interface%TYPE 		:= 'BEN_INT-02';
g_program_name                   CUST.TTEC_error_handling.program_name%TYPE 	:= 'TTEC_AETNA_HEALTHCARE';
g_initial_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'INITIAL';
g_warning_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'WARNING';
g_failure_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'FAILURE';

-- Filehandle Variables
p_FileDir VARCHAR2(60)          :=  '/usr/tmp';
p_FileName VARCHAR2(50)         := 'aetna_healthcare_'||to_char(sysdate, 'YYYYMMDD_HH24MISS')||'.txt';
v_daily_file UTL_FILE.FILE_TYPE;

-----------------------------------------------------------------------------------------------------
-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
CURSOR c_emp_data IS
SELECT emp.national_identifier						             emp_ssn												 		
       , emp.first_name						     		             emp_first_name
       , emp.middle_names							                 emp_middle_name
       , emp.last_name								                   emp_last_name       
       , emp.sex									                        emp_sex									
       , emp.suffix									                     emp_suffix	
       , to_char(emp.date_of_birth, 'YYYYMMDD')		emp_dob
       , adr.address_line1							                emp_addr_line1							
       , adr.address_line2							                emp_addr_line2
       , adr.town_or_city							                 emp_city							
       , decode(nvl(adr.country,'99')
                ,'US',adr.region_2
                ,'CA',adr.region_2
                ,'99',adr.region_2
                     ,'ZZ')                      emp_state
       , adr.postal_code							                  emp_zip_code
	      , grp.name      					                     emp_ben_grp
	      , loc.attribute3					                     emp_subgroup							
   	   , pl.name								                        	emp_pl_name
	      , opt.name									                       emp_opt_name
       , to_char(rslt.enrt_cvg_strt_dt,'YYYYMMDD')		emp_cvg_start_date		
       , decode(to_char(rslt.enrt_cvg_thru_dt,'YYYYMMDD'), 
         '47121231', '00000000', 
         to_char(rslt.enrt_cvg_thru_dt, 'YYYYMMDD'))	emp_cvg_end_date
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
   	,  hr.per_all_assignments_f asg
	   ,  hr.hr_locations_all loc
    ,  hr.per_addresses adr
    ,  ben.ben_prtt_enrt_rslt_f rslt
    ,  ben.ben_pl_f pl
   	,  ben.ben_opt_f opt
   	,  ben.ben_oipl_f oipl
    ,  ben.ben_per_in_ler ler
    ,  ben.ben_pgm_f pgm
    ,  ben.ben_benfts_grp grp*/
FROM   apps.per_all_people_f emp
   	,  apps.per_all_assignments_f asg
	   ,  apps.hr_locations_all loc
    ,  apps.per_addresses adr
    ,  apps.ben_prtt_enrt_rslt_f rslt
    ,  apps.ben_pl_f pl
   	,  apps.ben_opt_f opt
   	,  apps.ben_oipl_f oipl
    ,  apps.ben_per_in_ler ler
    ,  apps.ben_pgm_f pgm
    ,  apps.ben_benfts_grp grp	
--End R12.2 Upgrade Remediation	
WHERE  emp.person_id = adr.person_id
AND    rslt.person_id = emp.person_id
AND	   emp.person_id = asg.person_id
AND    grp.benfts_grp_id = emp.benefit_group_id (+)
AND    pgm.pgm_id = rslt.pgm_id
AND	   loc.location_id = asg.location_id
AND    upper(pgm.name) != 'COBRA'
AND    adr.primary_flag = 'Y'
AND	   asg.assignment_type = 'E'
AND	   asg.primary_flag = 'Y'
AND    pl.pl_id = rslt.pl_id
AND    (pl.name like g_plan_1)
AND	   oipl.opt_id = opt.opt_id
AND    rslt.oipl_id = oipl.oipl_id
AND    rslt.per_in_ler_id = ler.per_in_ler_id
AND    ler.bckt_dt is null
-- Restricts to most current record
AND    trunc(sysdate) between pl.effective_start_date and pl.effective_end_date
AND    trunc(sysdate) between emp.effective_start_date and emp.effective_end_date
AND	   trunc(sysdate) between asg.effective_start_date and asg.effective_end_date
AND    trunc(sysdate) between adr.date_from and nvl(adr.date_to, trunc(sysdate))
AND    trunc(sysdate) between rslt.effective_start_date and rslt.effective_end_date
AND    rslt.enrt_cvg_thru_dt > rslt.enrt_cvg_strt_dt
AND    trunc(sysdate) between rslt.enrt_cvg_strt_dt and rslt.enrt_cvg_thru_dt
;


CURSOR c_depn_data (v_emp_ssn IN VARCHAR2) IS
SELECT DISTINCT emp.national_identifier	 		   	 	emp_ssn
       , depn.first_name			                  				depn_first_name
       , depn.middle_names							                depn_middle_name
       , depn.last_name								                  depn_last_name       
       , depn.sex									                       depn_sex									
       , rel.contact_type                        depn_relationship
       , depn.suffix									                    depn_suffix       
       , to_char(depn.date_of_birth, 'YYYYMMDD')	depn_dob
	      , depn.registered_disabled_flag				       depn_disabled				
	      , depn.student_status						               depn_student
       , depn.national_identifier					           depn_ssn
       , to_char(eldp.cvg_strt_dt,'YYYYMMDD')		  depn_cvg_strt_dt		
       , decode(to_char(eldp.cvg_thru_dt,'YYYYMMDD'), 
         '47121231', '00000000', 
         to_char(eldp.cvg_thru_dt, 'YYYYMMDD'))  depn_cvg_end_dt
       , depn.rowid									                     depn_row_id  
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
     , hr.per_all_people_f depn
     , hr.per_contact_relationships rel
     , ben.ben_pl_f pl
     , ben.ben_elig_cvrd_dpnt_f eldp
     , ben.ben_prtt_enrt_rslt_f rslt
     , ben.ben_per_in_ler ler
     , ben.ben_pgm_f pgm     */
FROM   apps.per_all_people_f emp
     , apps.per_all_people_f depn
     , apps.per_contact_relationships rel
     , apps.ben_pl_f pl
     , apps.ben_elig_cvrd_dpnt_f eldp
     , apps.ben_prtt_enrt_rslt_f rslt
     , apps.ben_per_in_ler ler
     , apps.ben_pgm_f pgm     	 
--End R12.2 Upgrade Remediation	 
WHERE  eldp.dpnt_person_id = depn.person_id
AND    pgm.pgm_id = rslt.pgm_id
AND    upper(pgm.name) != 'COBRA'
AND    eldp.prtt_enrt_rslt_id = rslt.prtt_enrt_rslt_id
AND    rslt.person_id = emp.person_id
AND    rel.person_id = emp.person_id
AND    rel.contact_person_id = depn.person_id -- Add this line
AND    pl.pl_id = rslt.pl_id
AND    eldp.cvg_strt_dt < eldp.cvg_thru_dt
AND    eldp.per_in_ler_id = ler.per_in_ler_id
AND    (pl.name like g_plan_1)
AND    ler.bckt_dt is null
-- Restricts to most recent record
AND    trunc(sysdate)between emp.effective_start_date and emp.effective_end_date
AND    trunc(sysdate)between depn.effective_start_date and depn.effective_end_date
AND    trunc(sysdate) between rslt.effective_start_date and rslt.effective_end_date
AND    trunc(sysdate) between eldp.effective_start_date and eldp.effective_end_date
AND    trunc(sysdate) between eldp.cvg_strt_dt and eldp.cvg_thru_dt
AND	   emp.national_identifier = v_emp_ssn 
;


-----------------------------------------------------------------------------------------------------
-- Begin format_name ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_name (v_name IN OUT VARCHAR2) IS

l_temp_name hr.per_all_people_f.last_name%TYPE;
i NUMBER := 0;
n NUMBER := 1;

BEGIN
  SELECT length(v_name)
  INTO   i
  FROM   DUAL;
  
  IF (i > 0) THEN  
    FOR c IN 1..i LOOP
    
      IF (substr(v_name, n, 1)) in ('.',',') THEN
        n := n + 1;
      ELSE
        l_temp_name := (l_temp_name||substr(v_name, n, 1));      
        n := n + 1;
      END IF;
       
    END LOOP;
    v_name := l_temp_name;
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
      IF (upper(substr(v_address, n, 1)) = '.') OR
         (upper(substr(v_address, n, 1)) = ',') OR
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
-- Begin format_zip ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE format_zip (v_zip IN OUT VARCHAR2) IS

l_temp_zip hr.per_addresses.postal_code%TYPE;
i NUMBER := 0;
n NUMBER := 1;

BEGIN
  SELECT length(v_zip)
  INTO   i
  FROM   DUAL;
  
  IF (i > 0) THEN  
    FOR c IN 1..i LOOP
      IF substr(v_zip, n, 1) = '-' THEN
        n := n + 1;
      ELSE
        l_temp_zip := (l_temp_zip||substr(v_zip, n, 1));
        n := n + 1;
      END IF; 
    END LOOP;
    v_zip := l_temp_zip;
  END IF;
END;
-----------------------------------------------------------------------------------------------------
-- Begin get_disabled -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_disabled (v_disabled IN OUT VARCHAR2) IS

BEGIN

IF v_disabled in ('F', 'P', 'Y') THEN
   
   v_disabled := 'Y';
   
ELSE

   v_disabled := 'N';
   
END IF;   

--F	Yes - Fully Disabled
--N	No
--P	Yes - Partially Disabled
--Y	Yes

  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_disabled := null;
  WHEN TOO_MANY_ROWS THEN
    v_disabled := null;
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_student -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_student (v_student IN OUT VARCHAR2) IS

BEGIN

IF v_student in ( 'FULL_TIME') THEN

   v_student := 'Y';
  
ELSE

   v_student := 'N';
   
END IF;   
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_student := null;
  WHEN TOO_MANY_ROWS THEN
    v_student := null;
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_relation -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_relation (v_depn_relationship IN VARCHAR2, 
                        v_depn_sex IN VARCHAR2,
                        v_relation OUT VARCHAR2) IS

BEGIN
IF v_depn_relationship ='S' THEN
   
   IF v_depn_sex = 'F' Then
      v_relation := '02';
   ELSE
      v_relation := '03';
   END IF;

ELSIF v_depn_relationship ='LW' THEN
   
   IF v_depn_sex = 'F' Then
      v_relation := '11';
   ELSE
      v_relation := '10';
   END IF;

ELSIF v_depn_relationship ='CLS' THEN
   
    v_relation := '12';

ELSIF v_depn_relationship ='D' THEN
   
    v_relation := '14';
  
ELSIF v_depn_relationship in ('A','C','T','O','R','OC') THEN
   
   IF v_depn_sex = 'F' Then
      v_relation := '05';
   ELSE
      v_relation := '04';
   END IF;
       
ELSE
    
    V_relation := '  ';  
   
END IF;   

END;

-----------------------------------------------------------------------------------------------------
-- Begin get_ben_grp  -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_ben_grp (v_ben_grp IN OUT VARCHAR2) IS

BEGIN

IF v_ben_grp in ('FT Corporate Benefits', 'FT GA Benefits', 'Operating Committee','Ex-Patriots') THEN
   
   v_ben_grp := '020';
   
ELSIF v_ben_grp = 'FT Agent Benefits' THEN

   v_ben_grp := '030';
   
ELSE
    
   v_ben_grp := '   ';   
   
END IF;   

  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_ben_grp := '   '; 
  WHEN TOO_MANY_ROWS THEN
    v_ben_grp := '   '; 
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin get_plan_id -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_plan_id (v_plan_name IN VARCHAR2,
                       v_plan_id OUT VARCHAR2) IS

BEGIN

IF substr(v_plan_name,1,14)= 'Aetna PPO Plus' THEN

   v_plan_id := '017'; --??? Validate plan name once it is defined in the system
   
ELSIF substr(v_plan_name,1,9)= 'Aetna OOA' THEN

   v_plan_id := '018'; --??? Validate plan name once it is defined in the system
     
ELSIF substr(v_plan_name,1,9)= 'Aetna PPO' THEN

   v_plan_id := '016'; --??? Validate plan name once it is defined in the system
            
ELSE
    
   v_plan_id := '   ';   
   
END IF;   

  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_plan_id := '   '; 
  WHEN TOO_MANY_ROWS THEN
    v_plan_id := '   '; 
  WHEN OTHERS THEN
    RAISE;
END;

-----------------------------------------------------------------------------------------------------
-- Begin main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE main IS

-- Declare variables
l_header_output 	CHAR(1000);
l_emp_output 	CHAR(1000);
l_depn_output	CHAR(1000);
l_trailer_output 	CHAR(1000);
v_rows 			VARCHAR2(500);
l_relation		VARCHAR2(2);
l_character		VARCHAR(1);
l_emp_ssn		VARCHAR2(11);
l_plan_id  VARCHAR2(3);


l_module_name CUST.TTEC_error_handling.module_name%type := 'OAB';

-- Extract the invoice information from Oracle
BEGIN  
  v_rows := 0;
  v_daily_file := UTL_FILE.FOPEN(p_FileDir, p_FileName, 'w');

  BEGIN
  
  -- Build Header Record --
  
  l_header_output := (
     '001'                        -- Field #1
  || '0701170'                    -- Field #2
  || rpad(' ',2,' ')	             -- Field #3	Space fill    
	 || rpad(' ',7,' ')	             -- Field #4	Space fill
  || rpad('TELETECH HOLD',15,' ') -- Field #5
  || g_sys_date                   -- Field #6  
  || g_sys_date                   -- Field #7
  || g_end_of_month_date          -- Field #8
  || rpad(' ',2,' ')	             -- Field #9	Space fill           
  || ' '	                         -- Field #10	Space fill
  || rpad('0',6,'0')              -- Field #11 Zero fill   
  || rpad(' ',432,' ')	           -- Field #12	Space fill      
  || rpad(' ',24,' ')	            -- Field #13 Space fill               
  || rpad(' ',376,' ')	           -- Field #14	Space fill      
  || rpad(' ',15,' ')	            -- Field #15	Space fill
  || rpad(' ',9,' ')	             -- Field #16 Space fill               
  || rpad(' ',1,' ')	             -- Field #17	Space fill      
  || rpad(' ',76,' ')	            -- Field #18	Space fill            
  );
  
  utl_file.put_line(v_daily_file, l_header_output);
  
  -- Employee Data Extract --
    FOR emp IN c_emp_data LOOP
		
	    	l_emp_ssn := emp.emp_ssn;      

        format_name(emp.emp_first_name); 
        format_name(emp.emp_last_name); 
        format_name(emp.emp_suffix); 
        format_ssn(emp.emp_ssn);
        format_address(emp.emp_addr_line1);
        format_address(emp.emp_addr_line2);
        IF emp.emp_state = 'ZZ'  THEN
           emp.emp_zip_code := '000000000';
        ELSE   
             format_zip(emp.emp_zip_code);
        END IF;
        
        get_ben_grp(emp.emp_ben_grp);
        l_plan_id := '   ';
        get_plan_id(emp.emp_pl_name,l_plan_id);		 

        l_emp_output := ( 	
          g_record_type    -- Field #1
       || nvl(substr(lpad(emp.emp_ssn,9,'0'),1,9),lpad('0',9,'0')) -- Field #2
						 || rpad(' ',3,' ')	 -- Field #3	Space fill 
					  || rpad('0',9,'0')  -- Field #4 Zero fill for SSN on Dependent, since this is empl record
						 || rpad(' ',5,' ')  -- Field #5 Space fill
					  || rpad('0',10,'0') -- Field #6 Zero fill
						 || rpad(' ',12,' ') -- Field #7 Space fill           
       || nvl(substr(rpad(emp.emp_last_name,20,' '),1,20), rpad(' ',20,' ')) -- Field #8 
       || nvl(substr(rpad(emp.emp_first_name,15,' '),1,15),rpad(' ',15,' ')) -- Field #9
       || nvl(substr(emp.emp_middle_name,1,1),' ')                           -- Field #10 
						 || rpad(' ',2,' ')	 -- Field # 11 Space fill              
       || nvl(substr(rpad(emp.emp_suffix,15,' '),1,3),rpad(' ',3,' ')) -- Field #12
       || '01' -- Field # 13 Hardcoded to '01' for Self, since this is the employee record
						 || nvl(substr(rpad(UPPER(emp.emp_sex),1,' '),1,1),'M') -- Field # 14 Default to male if null
						 || nvl(substr(rpad(emp.emp_dob,8,' '),1,8), rpad(' ',8,' '))  -- Field # 15
       || ' ' -- Field #16 Special Characteristics TBD with Cathy
       || '0' -- Field #17 Harcoded to 0   
       || nvl(substr(rpad(emp.emp_addr_line1,30,' '),1,30),rpad(' ',30,' '))  -- Field #18
       || nvl(substr(rpad(emp.emp_addr_line2,30,' '),1,30),rpad(' ',30,' '))  -- Field #19       
       || nvl(substr(rpad(UPPER(emp.emp_city),20,' '),1,20),rpad(' ',20,' ')) -- Field #20
       || nvl(substr(rpad(UPPER(emp.emp_state),2,' '),1,2),rpad(' ',2,' '))   -- Field #21         
       || nvl(substr(rpad(emp.emp_zip_code,9,' '),1,9),rpad(' ',9,' '))  -- Field #22
						 || rpad(' ',5,' ')	 -- Field # 23 Space fill 
						 || rpad(' ',10,' ')	-- Field # 24 Space fill
						 || rpad(' ',10,' ')	-- Field # 25 Space fill                       
					  || rpad('0',8,'0')  -- Field # 26 Zero fill   
						 || rpad(' ',10,' ')	-- Field # 27 Space fill
						 || rpad(' ',15,' ')	-- Field # 28 Space fill
						 || rpad(' ',9,' ')	-- Field # 29 Space fill   
						 || rpad(' ',2,' ')	-- Field # 30 Space fill                                     
						 || rpad(' ',2,' ')	-- Field # 31 Space fill         
						 || rpad(' ',50,' ')	-- Field # 32 Space fill         
						 || rpad(' ',11,' ')	-- Field # 33 Space fill         
						 || rpad(' ',161,' ')	-- Field # 34 thru 66 Space fill
						 || 'AAS' 	-- Field # 67 Harcoded to AAS                 
						 || '001' 	-- Field # 68 Harcoded to 001 
						 || rpad(' ',2,' ')	-- Field # 69 Space fill
						 || '0701170' 	-- Field # 70 Harcoded to 0701170                                       
       || nvl(substr(lpad(emp.emp_ben_grp,3,' '),1,3),lpad(' ',3,' '))  -- Field #71 
       || nvl(substr(lpad(emp.emp_subgroup,5,' '),1,5),rpad(' ',5,' '))  -- Field #72                
       || nvl(substr(lpad(l_plan_id,5,' '),1,5),rpad(' ',5,' '))  -- Field #73 ???? TBD waiting on Becca to define values in the system ????
						 || nvl(substr(rpad(emp.emp_cvg_start_date,8,' '),1,8), rpad(' ',8,' ')) -- Field #74
						 || nvl(substr(rpad(emp.emp_cvg_end_date,8,' '),1,8), rpad(' ',8,' ')) -- Field #75
 				  || rpad('0',8,'0')  -- Field # 76 Zero fill
       || ' ' -- Field # 77 Space fill
       || ' ' -- Field # 78 Space fill   
       || '132' -- Field # 79 Hardcoded to 132    
				   || rpad('0',5,'0')  -- Field # 80 Zero fill 
				   || rpad('0',11,'0') -- Field # 81 Zero fill 
				   || rpad('0',1,'0')  -- Field # 82 Zero fill               
				   || rpad('0',11,'0') -- Field # 83 Zero fill       
				   || rpad('0',1,'0')  -- Field # 84 Zero fill 
				   || rpad('0',7,'0')  -- Field # 85 Zero fill 
				   || rpad('0',1,'0')  -- Field # 86 Zero fill 
				   || rpad('0',7,'0')  -- Field # 87 Zero fill 
				   || rpad('0',2,'0')  -- Field # 88 Zero fill                                                                 
				   || rpad('0',7,'0')  -- Field # 89 Zero fill 
				   || rpad('0',7,'0')  -- Field # 90 Zero fill        
				   || rpad('0',7,'0')  -- Field # 91 Zero fill               
				   || rpad('0',7,'0')  -- Field # 92 Zero fill        
				   || rpad('0',7,'0')  -- Field # 93 Zero fill
       || ' '              -- Field # 94 Space fill    
				   || rpad('0',7,'0')  -- Field # 95 Zero fill
       || ' '              -- Field # 96 Space fill
       || ' '              -- Field # 97 Space fill
       || ' '              -- Field # 98 Space fill              
						 || '0'              -- Field # 99 Harcoded to 0                             
				   || rpad('0',7,'0')  -- Field # 100 Zero fill       
						 || rpad(' ',4,' ')	 -- Field # 101 Space fill                
						 || rpad(' ',350,' ')	 -- Field # 102 Space fill        
       );
      
        utl_file.put_line(v_daily_file, l_emp_output);
        v_rows := v_rows + 1;
		
		  -- Dependent Data Extract --
		 FOR depn IN c_depn_data (l_emp_ssn) LOOP
		      
          l_relation := '  ';
          
		        get_relation(depn.depn_relationship, depn.depn_sex, l_relation);
          -- Note that get_disable must go after get_student, since disabled takes precedence over the student status
				      get_student(depn.depn_student);
		      		get_disabled(depn.depn_disabled);          
           
          l_character := '0' ;
          
          IF depn.depn_student = 'Y' THEN
              l_character := '1' ;
          END IF;
          
          IF depn.depn_disabled = 'Y' THEN
              l_character := '2' ;
          END IF;
                    
				        
		        format_name(depn.depn_last_name);
 	        format_name(depn.depn_first_name);          
		        format_ssn(depn.emp_ssn); -- Changes 999-99-9999 to 999999999
		        format_ssn(depn.depn_ssn); -- Changes 999-99-9999 to 999999999
		      

		        l_depn_output := (
          g_record_type    -- Field #1
       || nvl(substr(lpad(depn.emp_ssn,9,'0'),1,9),lpad('0',9,'0')) -- Field #2
						 || rpad(' ',3,' ')	 -- Field #3	Space fill 
       || nvl(substr(lpad(depn.depn_ssn,9,'0'),1,9),lpad('0',9,'0')) -- Field #4
						 || rpad(' ',5,' ')  -- Field #5 Space fill
					  || rpad('0',10,'0') -- Field #6 Zero fill
						 || rpad(' ',12,' ') -- Field #7 Space fill           
       || nvl(substr(rpad(depn.depn_last_name,20,' '),1,20), rpad(' ',20,' ')) -- Field #8 
       || nvl(substr(rpad(depn.depn_first_name,15,' '),1,15),rpad(' ',15,' ')) -- Field #9
       || nvl(substr(depn.depn_middle_name,1,1),' ')                           -- Field #10 
						 || rpad(' ',2,' ')	 -- Field # 11 Space fill              
       || nvl(substr(rpad(depn.depn_suffix,15,' '),1,3),rpad(' ',3,' ')) -- Field #12
       || l_relation -- Field # 13 
						 || nvl(substr(rpad(UPPER(depn.depn_sex),'1',' '),1,1),'M') -- Field # 14 Default to male if null
						 || nvl(substr(rpad(depn.depn_dob,8,' '),1,8), rpad(' ',8,' '))  -- Field # 15
       || l_character -- Field #16 Special Characteristics To be validated with Cathy
       || '0' -- Field #17 Harcoded to 0   
       || rpad(' ',30,' ')  -- Field #18 Space fill for dependent
       || rpad(' ',30,' ')  -- Field #19 Space fill for dependent 
       || rpad(' ',20,' ')  -- Field #20 Space fill for dependent 
       || rpad(' ',2,' ')  -- Field #21 Space fill for dependent                        
       || rpad(' ',9,' ')  -- Field #22 Space fill for dependent 
						 || rpad(' ',5,' ')	 -- Field # 23 Space fill 
						 || rpad(' ',10,' ')	-- Field # 24 Space fill
						 || rpad(' ',10,' ')	-- Field # 25 Space fill                       
					  || rpad('0',8,'0')  -- Field # 26 Zero fill   
						 || rpad(' ',10,' ')	-- Field # 27 Space fill
						 || rpad(' ',15,' ')	-- Field # 28 Space fill
						 || rpad(' ',9,' ')	-- Field # 29 Space fill   
						 || rpad(' ',2,' ')	-- Field # 30 Space fill                                     
						 || rpad(' ',2,' ')	-- Field # 31 Space fill         
						 || rpad(' ',50,' ')	-- Field # 32 Space fill         
						 || rpad(' ',11,' ')	-- Field # 33 Space fill         
						 || rpad(' ',161,' ')	-- Field # 34 thru 66 Space fill
						 || 'AAS' 	-- Field # 67 Harcoded to AAS                 
						 || '001' 	-- Field # 68 Harcoded to 001 
						 || rpad(' ',2,' ')	-- Field # 69 Space fill
						 || '0701170' 	-- Field # 70 Harcoded to 0701170                                       
       || nvl(substr(lpad(emp.emp_ben_grp,3,' '),1,3),lpad(' ',3,' '))  -- Field #71 
       || nvl(substr(lpad(emp.emp_subgroup,5,' '),1,5),rpad(' ',5,' '))  -- Field #72                
       || nvl(substr(lpad(l_plan_id,5,' '),1,5),rpad(' ',5,' '))  -- Field #73 ???? TBD waiting on Becca to define values in the system ????
						 || nvl(substr(rpad(depn.depn_cvg_strt_dt,8,' '),1,8), rpad(' ',8,' ')) -- Field #74
						 || nvl(substr(rpad(depn.depn_cvg_end_dt,8,' '),1,8), rpad(' ',8,' ')) -- Field #75
 				  || rpad('0',8,'0')  -- Field # 76 Zero fill
       || ' ' -- Field # 77 Space fill
       || ' ' -- Field # 78 Space fill   
       || '132' -- Field # 79 Hardcoded to 132    
				   || rpad('0',5,'0')  -- Field # 80 Zero fill 
				   || rpad('0',11,'0') -- Field # 81 Zero fill 
				   || rpad('0',1,'0')  -- Field # 82 Zero fill               
				   || rpad('0',11,'0') -- Field # 83 Zero fill       
				   || rpad('0',1,'0')  -- Field # 84 Zero fill 
				   || rpad('0',7,'0')  -- Field # 85 Zero fill 
				   || rpad('0',1,'0')  -- Field # 86 Zero fill 
				   || rpad('0',7,'0')  -- Field # 87 Zero fill 
				   || rpad('0',2,'0')  -- Field # 88 Zero fill                                                                 
				   || rpad('0',7,'0')  -- Field # 89 Zero fill 
				   || rpad('0',7,'0')  -- Field # 90 Zero fill        
				   || rpad('0',7,'0')  -- Field # 91 Zero fill               
				   || rpad('0',7,'0')  -- Field # 92 Zero fill        
				   || rpad('0',7,'0')  -- Field # 93 Zero fill
       || ' '              -- Field # 94 Space fill    
				   || rpad('0',7,'0')  -- Field # 95 Zero fill
       || ' '              -- Field # 96 Space fill
       || ' '              -- Field # 97 Space fill
       || ' '              -- Field # 98 Space fill              
						 || '0'              -- Field # 99 Harcoded to 0                               
				   || rpad('0',7,'0')  -- Field # 100 Zero fill       
						 || rpad(' ',4,' ')	 -- Field # 101 Space fill                
						 || rpad(' ',350,' ')	 -- Field # 102 Space fill             
       );
		      
		        utl_file.put_line(v_daily_file, l_depn_output);
          v_rows := v_rows + 1;		

				l_relation := NULL;
  
		 END LOOP;  --Dependent Loop
      	
		l_emp_ssn := NULL;
	  
    END LOOP;	 --Employee Loop

  END;	  		 --Outer Dependent BEGIN

  -- Build Trailer Record --
  
  l_trailer_output := (
     '099'                        -- Field #1
  || '0011002'                    -- Field #2
  || lpad(v_rows + 2,7,0)         -- Field #3 
  || lpad(v_rows,7,0)             -- Field #4   
  || rpad('0',7,'0')              -- Field #5 Zero fill   
  || rpad('0',7,'0')              -- Field #6 Zero fill    
  || rpad(' ',962,' ')	           -- Field #7	Space fill             
  );
  
  utl_file.put_line(v_daily_file, l_trailer_output);

  COMMIT;
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

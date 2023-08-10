-- Program Name:  TTEC_DELTA_DENTAL
--
-- Description:  This program will provide an extract of the Oracle Advanced Benefit system 
-- to be provided to Delta Dental. The extracted data will contain employee and dependent
-- information for participants in the Delta Dental plan.
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
-- Created By:  D.Thakker
-- Date: July 24, 2002
--
-- Modification Log:
-- Developer   		 Date       		 Description
-- ----------  		 --------   		 --------------------
-- D. Thakker  		 07/24/2002   		 File created
-- D. Thakker  		 08/16/2002		 Added dependent piece
-- D. Thakker  		 09/13/2002		 Changed cursors from FETCH to FOR LOOP   
-- D. Thakker  		 09/13/2002		 Added Subgroup information
-- D. Thakker  		 11/25/2002		 Updated code to meet PROD config.
-- D.Thakker   		 12/16/2002		 Testing in UAT
-- D.Thakker   		 12/20/2002		 Made program parameter driven
-- D.Thakker   		 12/30/2002		 Made updates to the contact code mapping
-- D.Thakker   		 01/06/2003		 Updated contact code mapping to include Domestic Partner
-- E.Alfred-Ockiya	 07/30/2003		 Modified to report information based on date employee 
--  	  					 termination was updated.
-- E.Alfred-Ockiya	 09/18/2003		 Modified to include member code
-- E.Alfred-Ockiya       11/05/2000 		 Eliminate EMRG contact type
-- I KONAK               06/01/2004              Eliminate duplicates in employee and dependent records
-- C. Chan               04/06/2005              Eliminate Employee who terminated more than 30 days
--                                               Also eliminated harcoded path + added delimited
-- Elango                11/11/2005              Added forms logic enrt_result table where condition for EE selection
--Hema Puvvada         . 04/20/2006     Modified the emp & depn cursors to pull the future dated coverages.
--NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation

SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
-- Global Variables ---------------------------------------------------------------------------------


 g_rundate 			DATE		 :=   '&1';
--g_rundate 			DATE		 := sysdate;

g_plan_1  			VARCHAR2(50) := 'Delta Dental';
g_emp_record_type	VARCHAR2(2)  := '01';
g_emp_revision_num 	VARCHAR2(2)  := '01';
g_emp_record 		VARCHAR2(1)  := 'E';
g_group_number 		VARCHAR2(6)  := '000109';
g_cobra_flag 		VARCHAR2(1)  := 'N';

g_depn_record_type 	VARCHAR2(2)  := '02';


-- Variables used by Common Error Procedure
--START R12.2 Upgrade Remediation
/*g_application_code               CUST.TTEC_error_handling.application_code%TYPE := 'OAB';
g_interface                      CUST.TTEC_error_handling.interface%TYPE 		:= 'BEN_INT-01';
g_program_name                   CUST.TTEC_error_handling.program_name%TYPE 	:= 'TTEC_DELTA_DENTAL';
g_initial_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'INITIAL';
g_warning_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'WARNING';
g_failure_status                 CUST.TTEC_error_handling.status%TYPE 			:= 'FAILURE';*/
g_application_code               apps.TTEC_error_handling.application_code%TYPE := 'OAB';
g_interface                      apps.TTEC_error_handling.interface%TYPE 		:= 'BEN_INT-01';
g_program_name                   apps.TTEC_error_handling.program_name%TYPE 	:= 'TTEC_DELTA_DENTAL';
g_initial_status                 apps.TTEC_error_handling.status%TYPE 			:= 'INITIAL';
g_warning_status                 apps.TTEC_error_handling.status%TYPE 			:= 'WARNING';
g_failure_status                 apps.TTEC_error_handling.status%TYPE 			:= 'FAILURE';
--End R12.2 Upgrade Remediation

-- Filehandle Variables
p_FileDir VARCHAR2(80)            :=  '&2'; -- C.Chan 04/06/05
--p_FileDir VARCHAR2(80)          :=  '/d01/oracle/prodappl/teletech/11.5.0/data/BenefitInterface';--'$CUST_TOP/data/BenefitInterface' PROD ;
--p_FileDir VARCHAR2(80)          :=  '/d01/oravis/visappl/teletech/11.5.0/data/BenefitInterface';--'$CUST_TOP/data/BenefitInterface' HRDEV ;
--p_FileDir VARCHAR2(80)          :=  '/usr/tmp';--hrdev ';
p_FileName VARCHAR2(50)         := 'delta_dental_'||to_char(sysdate, 'YYYYMMDD_HH24MISS')||'.txt';
v_daily_file UTL_FILE.FILE_TYPE;

-----------------------------------------------------------------------------------------------------
-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
CURSOR c_emp_data IS
SELECT distinct emp.national_identifier				emp_ssn	,emp.person_id											 		
       , emp.first_name								emp_first_name
       , emp.last_name								emp_last_name
       , emp.sex								    emp_sex									
       , to_char(emp.date_of_birth, 'YYYYMMDD')		emp_dob
       , adr.address_line1							emp_addr_line1							
       , adr.address_line2							emp_addr_line2
       , adr.town_or_city							emp_city							
       , adr.region_2								emp_state
       , adr.postal_code							emp_zip_code
       , loc.attribute4							    emp_subgroup							
       , opt.name								    emp_opt_name
       , to_char(rslt.ORGNL_ENRT_DT,'YYYYMMDD')		emp_cvg_start_date		
       , decode(to_char(rslt.enrt_cvg_thru_dt,'YYYYMMDD'),
                '47121231',to_char(LAST_DAY(pos.actual_termination_date),'YYYYMMDD')
                          ,to_char(LAST_DAY(rslt.enrt_cvg_thru_dt),'YYYYMMDD')) emp_cvg_end_date
      , pos.actual_termination_date                                             emp_actual_term_date
      , pos.last_update_date			                                        emp_term_update_dt	
--START R12.2 Upgrade Remediation	  
/*FROM   hr.per_all_people_f emp
    ,  hr.per_all_assignments_f asg
    ,  hr.per_periods_of_service pos
    ,  hr.per_addresses adr
    ,  hr.hr_locations_all loc
    ,  ben.ben_prtt_enrt_rslt_f rslt
    ,  ben.ben_pl_f pl
    ,  ben.ben_opt_f opt
    ,  ben.ben_oipl_f oipl
    ,  ben.ben_per_in_ler ler
    ,  ben.ben_pgm_f pgm    */
FROM   apps.per_all_people_f emp
    ,  apps.per_all_assignments_f asg
    ,  apps.per_periods_of_service pos
    ,  apps.per_addresses adr
    ,  apps.hr_locations_all loc
    ,  apps.ben_prtt_enrt_rslt_f rslt
    ,  apps.ben_pl_f pl
    ,  apps.ben_opt_f opt
    ,  apps.ben_oipl_f oipl
    ,  apps.ben_per_in_ler ler
    ,  apps.ben_pgm_f pgm    	
--End R12.2 Upgrade Remediation	
WHERE  emp.person_id = adr.person_id
AND    adr.primary_flag = 'Y'
AND    emp.person_id = pos.person_id
AND    emp.person_id = asg.person_id
AND    asg.period_of_service_id  = pos.period_of_Service_id
AND    asg.location_id = loc.location_id
AND    asg.assignment_type = 'E'
AND    asg.primary_flag = 'Y'
AND    emp.person_id = rslt.person_id
AND    rslt.pgm_id = pgm.pgm_id
AND    upper(pgm.name) != 'COBRA'
AND    rslt.pl_id = pl.pl_id
AND    pl.name like g_plan_1 || '%'
AND    rslt.oipl_id = oipl.oipl_id
AND    oipl.opt_id = opt.opt_id
AND    rslt.per_in_ler_id = ler.per_in_ler_id
AND    ler.bckt_dt is null
AND    trunc(g_rundate) between   pgm.effective_start_date and   pgm.effective_end_date
AND    trunc(g_rundate) between   pl.effective_start_date and   pl.effective_end_date
AND    trunc(g_rundate) between  emp.effective_start_date and  emp.effective_end_date
AND    trunc(g_rundate) between  asg.effective_start_date and  asg.effective_end_date
--hpuvvadaAND    trunc(g_rundate) between rslt.effective_start_date and rslt.effective_end_date
--hpvuvadaand    trunc(g_rundate)  between rslt.enrt_cvg_strt_dt and rslt.enrt_cvg_thru_dt 
--added hpuvvada
AND    trunc(g_rundate) between  adr.date_from and nvl(adr.date_to, trunc(g_rundate))
and ((sysdate < pos.actual_termination_date)or pos.actual_termination_date is null)
--added hpuvvada
and (rslt.enrt_cvg_thru_dt is null or  rslt.enrt_cvg_thru_dt= '31-DEC-4712')
--and (rslt.effective_end_date is null or  rslt.effective_end_date= '31-DEC-4712')
and   (rslt.enrt_cvg_thru_dt <= rslt.effective_end_date 
       OR ( rslt.sspndd_flag = 'Y' AND rslt.enrt_cvg_thru_dt >= rslt.effective_end_date 
	    AND trunc(g_rundate) between rslt.effective_start_date and rslt.effective_end_date ) );

/*
--Added the above code and removed the following code as per stephen clark request

AND  ( ( rslt.ENRT_CVG_THRU_DT = '31-DEC-4712' and trunc(g_rundate) between rslt.ENRT_CVG_STRT_DT     and rslt.ENRT_CVG_THRU_DT)
       or 
	   (  rslt.ENRT_CVG_THRU_DT <> '31-DEC-4712' and  rslt.ENRT_CVG_THRU_DT >= trunc(g_rundate - 30)
	  and rslt.effective_start_date  = (Select max(effective_start_date)                                                             
                                        from ben.ben_prtt_enrt_rslt_f c                                                                                  
                                        where rslt.person_id = c.person_id and rslt.prtt_enrt_rslt_id = c.prtt_enrt_rslt_id)
	      )
	 )  
;
*/



-----------------------------------------------------------------------------------------------------
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

--l_temp_ssn hr.per_all_people_f.national_identifier%TYPE; -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_temp_ssn apps.per_all_people_f.national_identifier%TYPE; -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
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

IF v_student = 'FULL_TIME' THEN

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
-- Begin get_coverage code -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE get_coverage_code (v_opt_name IN VARCHAR2, v_coverage_code OUT VARCHAR2) IS

BEGIN
  
  IF v_opt_name IN ('Employee','Exec Employee','Post Tax Employee') THEN
  
  	 v_coverage_code := '01';
	 
  ELSIF v_opt_name IN ('Employee+1','Exec Employee+1','Employee+Dom Partner', 'Exec Employee+Dom Partner'
  				   	  ,'Post Tax Employee+1','Post Tax Employee+Dom Partner') THEN
					  
	 v_coverage_code := '05';
	 
  ELSIF v_opt_name IN ('Employee+Family','Employee+Fam','Employee+Dom Part+Family','Exec Employee+Fam'
  				   	  ,'Exec Employee+Dom Part+Family','Post Tax Employee+Family','Post Tax Employee+Dom Part+Family') THEN

  	 v_coverage_code := '06';
	 
  ELSE
  
	 v_coverage_code := NULL;
	 
  END IF;  	  
  
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_coverage_code := null;
  WHEN TOO_MANY_ROWS THEN
    v_coverage_code := null;
  WHEN OTHERS THEN
    RAISE;
END;

----------------------------------------------------------------------------------------------------

-- Procedure getDependent--------------------------------------------------------------------------
Procedure getDependent(p_emp_ssn IN VARCHAR2) IS

--DECLARE VARIABLES
v_emp_ssn  VARCHAR2(50) := p_emp_ssn;
l_emp_output 	VARCHAR2(300);
l_depn_output	VARCHAR2(300);
v_rows 			VARCHAR2(500);
l_relation		VARCHAR2(10);
l_emp_ssn		VARCHAR2(30);
l_coverage_code VARCHAR2(2);


CURSOR c_depn_data IS
SELECT distinct emp.national_identifier	 		   	 		emp_ssn
       , depn.first_name							depn_first_name
       , depn.last_name								depn_last_name
       , depn.sex									depn_sex
       , to_char(depn.date_of_birth, 'YYYYMMDD')	depn_dob
	   , depn.registered_disabled_flag				depn_disabled				
	   , depn.student_status						depn_student
       , rel.contact_type							depn_contact	   
       , depn.national_identifier					depn_ssn
       , to_char(eldp.cvg_strt_dt,'YYYYMMDD')		depn_cvg_strt_dt		
       , decode(to_char(eldp.cvg_thru_dt,'YYYYMMDD'),
                '47121231',to_char(LAST_DAY(pos.actual_termination_date),'YYYYMMDD')
                             ,to_char(LAST_DAY(eldp.cvg_thru_dt),'YYYYMMDD'))         depn_cvg_end_dt
      , pos.actual_termination_date    emp_actual_term_date
      , pos.last_update_date			emp_term_update_dt				
      , depn.rowid									depn_row_id  
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
    ,  hr.per_all_assignments_f asg
     , hr.per_periods_of_service pos
     , hr.per_all_people_f depn
	 , hr.per_contact_relationships rel	 
     , ben.ben_elig_cvrd_dpnt_f eldp
     , ben.ben_prtt_enrt_rslt_f rslt
     , ben.ben_pl_f pl
     , ben.ben_per_in_ler ler
     , ben.ben_pgm_f pgm  	   */
FROM   apps.per_all_people_f emp
    ,  apps.per_all_assignments_f asg
     , apps.per_periods_of_service pos
     , apps.per_all_people_f depn
	 , apps.per_contact_relationships rel	 
     , apps.ben_elig_cvrd_dpnt_f eldp
     , apps.ben_prtt_enrt_rslt_f rslt
     , apps.ben_pl_f pl
     , apps.ben_per_in_ler ler
     , apps.ben_pgm_f pgm  	   	 
--End R12.2 Upgrade Remediation	 
WHERE  eldp.dpnt_person_id = depn.person_id
AND    pgm.pgm_id = rslt.pgm_id
AND    upper(pgm.name) != 'COBRA'
AND    eldp.prtt_enrt_rslt_id = rslt.prtt_enrt_rslt_id
AND    rslt.person_id = emp.person_id
AND    pos.person_id = emp.person_id
AND    rel.person_id = emp.person_id
AND    asg.period_of_service_id  = pos.period_of_Service_id
AND    asg.assignment_type = 'E'
AND    asg.primary_flag = 'Y'
AND    rel.contact_person_id = depn.person_id
AND    pl.pl_id = rslt.pl_id
AND    eldp.per_in_ler_id = ler.per_in_ler_id
AND    pl.name like g_plan_1 || '%'
and    rel.contact_type in ('A','C','D','LW','O','R','S','T')
AND    ler.bckt_dt is null
AND    trunc(g_rundate)between emp.effective_start_date and emp.effective_end_date
AND    trunc(g_rundate) between  asg.effective_start_date and  asg.effective_end_date
AND    trunc(g_rundate)between depn.effective_start_date and depn.effective_end_date
--AND    trunc(g_rundate) between rslt.effective_start_date and rslt.effective_end_date
AND (  trunc(g_rundate) <rslt.enrt_cvg_thru_dt 
and  trunc(g_rundate) < rslt.effective_end_date
	 and trunc(g_rundate) <eldp.effective_end_date
--AND  (  trunc(g_rundate) between rslt.ENRT_CVG_STRT_DT     and rslt.ENRT_CVG_THRU_DT
       or ( rslt.ENRT_CVG_THRU_DT <> '31-DEC-4712' and  rslt.ENRT_CVG_THRU_DT > trunc(g_rundate - 30)
	  and rslt.effective_start_date  = (Select max(effective_start_date)                                                             
                                        --from ben.ben_prtt_enrt_rslt_f c  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023                                                                                 
										from apps.ben_prtt_enrt_rslt_f c    -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023                                                                               
                                        where rslt.person_id = c.person_id)
	      )
	 )  
--AND    trunc(g_rundate) between eldp.effective_start_date and eldp.effective_end_date
AND (  trunc(g_rundate) < rslt.enrt_cvg_thru_dt  
--AND  (  trunc(g_rundate) between eldp.cvg_strt_dt     and eldp.cvg_thru_dt
      or ( eldp.cvg_thru_dt <> '31-DEC-4712' and  eldp.cvg_thru_dt > trunc(g_rundate - 30)
	      ) 
	 ) 
AND	   emp.national_identifier = v_emp_ssn;

Begin

	FOR depn IN c_depn_data LOOP

            if  to_date(to_char(to_date(nvl(depn.depn_cvg_end_dt,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))) >= (g_rundate - 30) then
		 
			  
	      	--get_relation(depn.depn_row_id, l_relation);   -- EAO 09-18-2003 

		get_disabled(depn.depn_disabled);
		get_student(depn.depn_student);
				        
	        format_lastname(depn.depn_last_name); -- Changes O'Brien to OBrien
	        format_ssn(depn.emp_ssn); -- Changes 999-99-9999 to 999999999
	        format_ssn(depn.depn_ssn); -- Changes 999-99-9999 to 999999999		 

		IF depn.depn_contact in ('A','C','O','R','T', 'LW') THEN     -- EAO 09-18-2003 

		   l_relation := 'C';
				 
		ELSIF depn.depn_contact in ('S', 'D') THEN
			  
		   l_relation := 'S';
				 
		ELSE
		  
		   l_relation := 'Z';  --'Z' for errors 
				 
		END IF;
			      
                --  IF (depn.depn_cvg_end_dt is null) THEN  --EAO  07-31-2003 
                --    depn.depn_cvg_end_dt := '00000000';	 
                --  END IF;	
				
                -- DBMS_OUTPUT.PUT_LINE('depn Processed ->'||depn.depn_cvg_strt_dt||'-'||to_date(to_char(to_date(nvl(depn.depn_cvg_end_dt,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))));	

	        l_depn_output := (      g_depn_record_type
				 ||'|'|| nvl(substr(l_relation,1,1),rpad(' ',1,' '))	
				 ||'|'|| rpad(' ',2,' ') -- 2 spaces	
				 ||'|'|| g_group_number
                                 ||'|'|| rpad(' ',2,' ') -- 2 spaces
				 ||'|'|| rpad(' ',4,' ') -- 4 spaces
				 ||'|'|| to_char(g_rundate, 'YYYYMM')						 						 
	                         ||'|'|| nvl(substr(rpad(depn.emp_ssn,9,' '),1,9),rpad(' ',9,' '))
	                         ||'|'|| nvl(substr(rpad(depn.depn_ssn,9,' '),1,9),rpad(' ',9,' '))
	                         ||'|'|| nvl(substr(rpad(UPPER(depn.depn_last_name),18,' '),1,18),rpad(' ',18,' '))
	                         ||'|'|| nvl(substr(rpad(UPPER(depn.depn_first_name),15,' '),1,15),rpad(' ',15,' '))  -- extended to 15 characters
				 ||'|'|| nvl(substr(rpad(depn.depn_dob,8,' '),1,8), rpad(' ',8,' '))
				 ||'|'|| nvl(substr(rpad(depn.depn_cvg_strt_dt,8,' '),1,8), rpad(' ',8,' '))
				 ||'|'|| nvl(substr(rpad(depn.depn_cvg_end_dt,8,' '),1,8), rpad(' ',8,' '))						 						 						 
				 ||'|'|| rpad(' ',2,' ') -- 2 spaces
	                         ||'|'|| nvl(substr(rpad(depn.depn_sex,1,' '),1,1),rpad(' ',1,' '))
				 ||'|'|| nvl(substr(rpad(depn.depn_disabled,1,' '),1,1),rpad(' ',1,' '))
				 ||'|'|| nvl(substr(rpad(depn.depn_student,1,' '),1,1),rpad(' ',1,' '))					 	
	                         ||'|'|| 'N' --COBRA
	                         ||'|'|| rpad(' ',15,' ') -- 15 spaces; Provider dental location
	                         ||'|'|| rpad(' ',30,' ') -- 30 spaces
	                         ||'|'|| rpad(' ',16,' ') -- 16 spaces
	                         ||'|'|| rpad(' ', 2,' ') --  2 spaces
	                         ||'|'|| rpad(' ', 5,' ') --  5 spaces
	                         ||'|'|| rpad(' ', 4,' ') --  4 spaces
	                         ||'|'|| rpad(' ',25,' ') -- 25 spaces; Future use
				 ||'|'|| g_emp_revision_num
	                         );

	         if l_depn_output is not null then 
 
 	           utl_file.put_line(v_daily_file, l_depn_output);		

                 end if;

	         l_relation := NULL;

                 --else
                      --DBMS_OUTPUT.PUT_LINE('depn Skipped ->'||depn.depn_ssn||depn.depn_cvg_strt_dt||'-'||to_date(to_char(to_date(nvl(depn.depn_cvg_end_dt,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))));	
                 end if;

	END LOOP;  --Dependent Loop
END;

-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- Begin main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE main IS

-- Declare variables
l_emp_output 	CHAR(300);
l_depn_output	CHAR(300);
v_rows 			VARCHAR2(500);
l_relation		VARCHAR2(10);
l_emp_ssn		VARCHAR2(30);
l_coverage_code VARCHAR2(2);

--l_module_name CUST.TTEC_error_handling.module_name%type := 'OAB';	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name apps.TTEC_error_handling.module_name%type := 'OAB';	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

-- Extract the invoice information from Oracle 
BEGIN  
  v_daily_file := UTL_FILE.FOPEN(p_FileDir, p_FileName, 'w');

  
  BEGIN

    -- Employee Data Extract --

    DBMS_OUTPUT.PUT_LINE('g_run_date      ->'||g_rundate);
    DBMS_OUTPUT.PUT_LINE('g_run_date - 30 ->'||(g_rundate - 30));

    FOR emp IN c_emp_data LOOP
 

      if  to_date(to_char(to_date(nvl(emp.emp_cvg_end_date,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))) >= (g_rundate - 30) then

        l_emp_output := null;
	l_emp_ssn := emp.emp_ssn;
	
        --DBMS_OUTPUT.PUT_LINE(emp.emp_name);	

        --DBMS_OUTPUT.PUT_LINE('Emp Processed ->'||emp.emp_cvg_start_date||'-'||to_date(to_char(to_date(nvl(emp.emp_cvg_end_date,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))));
  	
  
        format_lastname(emp.emp_last_name); 
        format_ssn(emp.emp_ssn);
        format_address(emp.emp_addr_line1);
        format_address(emp.emp_addr_line2);
		
	get_coverage_code(emp.emp_opt_name, l_coverage_code); 

             l_emp_output := (   g_emp_record_type
			 ||'|'|| g_emp_record
			 ||'|'|| rpad(' ',2,' ')	 --Two spaces	
			 ||'|'|| g_group_number
			 ||'|'|| rpad(' ',2,' ')  --Two spaces
			 ||'|'|| nvl(substr(lpad(emp.emp_subgroup,4,'0'),1,4), rpad(' ',4,' '))
			 ||'|'|| to_char(g_rundate, 'YYYYMM')
                         ||'|'|| nvl(substr(rpad(emp.emp_ssn,9,' '),1,9),rpad(' ',9,' '))
			 ||'|'|| rpad(' ',9,' ')  --Nine spaces
                         ||'|'|| nvl(substr(rpad(UPPER(emp.emp_last_name),18,' '),1,18), rpad(' ',18,' '))
                         ||'|'|| nvl(substr(rpad(UPPER(emp.emp_first_name),15,' '),1,15),rpad(' ',15,' '))   -- extended to 15 characters
			 ||'|'|| nvl(substr(rpad(emp.emp_dob,8,' '),1,8), rpad(' ',8,' '))
			 ||'|'|| nvl(substr(rpad(emp.emp_cvg_start_date,8,' '),1,8), rpad(' ',8,' '))
			 ||'|'|| nvl(substr(rpad(emp.emp_cvg_end_date,8,' '),1,8), rpad(' ',8,' '))
			 ||'|'|| nvl(substr(rpad(l_coverage_code,2,' '),1,2), rpad(' ',2,' '))-- Coverage code
			 ||'|'|| nvl(substr(rpad(UPPER(emp.emp_sex),1,' '),1,1),rpad(' ',1,' '))
			 ||'|'|| ' '  --one spaces
                         ||'|'|| ' '  --one spaces
                         ||'|'|| nvl(substr(rpad(UPPER(g_cobra_flag),1,' '),1,1),rpad(' ',1,' '))
			 ||'|'|| rpad(' ',15,' ')  --15 spaces in place of provider location						 
                         ||'|'|| nvl(substr(rpad(emp.emp_addr_line1 || emp.emp_addr_line2,30,' '),1,30),rpad(' ',30,' '))
                         ||'|'|| nvl(substr(rpad(UPPER(emp.emp_city),16,' '),1,16),rpad(' ',16,' '))
                         ||'|'|| nvl(substr(rpad(UPPER(emp.emp_state),2,' '),1,2),rpad(' ',2,' '))
                         ||'|'|| nvl(substr(emp.emp_zip_code,1,5),'00000')
			 ||'|'|| nvl(substr(emp.emp_zip_code,7,10),'0000')
                         ||'|'|| rpad(' ',25,' ') -- Twenty-five spaces
			 ||'|'|| g_emp_revision_num
                        );

	    utl_file.put_line(v_daily_file, l_emp_output);
     --else

      --DBMS_OUTPUT.PUT_LINE('Emp Skipped ->'||emp.emp_ssn||emp.emp_cvg_start_date||'-'||to_date(to_char(to_date(nvl(emp.emp_cvg_end_date,to_char(sysdate,'YYYYMMDD')),'YYYYMMDD'))));
    end if;

    if emp.emp_opt_name not IN ('Employee','Exec Employee','Post Tax Employee') then
			
       -- Get Dependent information----------------------------------

	l_coverage_code := NULL;
	 
        getDependent(l_emp_ssn);  

	l_emp_ssn := NULL;

    end if;
	  

    END LOOP; --Employee Loop
	
  END;
  
  
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

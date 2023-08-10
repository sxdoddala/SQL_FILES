-- Program Name:  TTEC_ORACLE_VSP_INSERT
--
--
-- Description:  This program will provide an extract of the Oracle Advanced Benefit system 
-- to be provided to VSP (Vision Service Plan) into temporary tables, where it would be used 
-- to generate the VSP report. The extracted data will contain employee and dependent 
-- information for participants in the VSP plan of oracle.
--
-- NOTE: 
--
--
--- Input/Output Parameters: 
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
-- Created By:  Elizur Alfred-Ockiya
-- Date: November 26, 2002
--
-- Modification Log:
-- Developer   			 Date        Description
-- ----------   		--------    --------------------
-- Elizur Alfred-Ockiya    	11/26/2002    Converted all output text to UPPER
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation

--SET TIMING ON
--SET SERVEROUTPUT ON SIZE 1000000;

-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
DECLARE
-- Global Variables ---------------------------------------------------------------------------------
g_plan_1 VARCHAR2(50):= 'VSP';
g_date DATE := SYSDATE;
--g_section_id VARCHAR2(3) := 'GEN';
--g_transaction_code VARCHAR2(1) := 'R';
--g_control_number VARCHAR2(5) := '99686';
--g_adr_id VARCHAR2(3) := 'ADR';

CURSOR c_emp_data IS
SELECT 'Ora8i' type_system
       ,  emp.national_identifier          emp_ssn												 		
       , emp.first_name	                   emp_first_name
       , emp.middle_names                  emp_middle_name
       , emp.last_name		           emp_last_name       
       , emp.sex		           emp_sex									
       , emp.suffix		           emp_suffix	
       , emp.date_of_birth      	   emp_dob
       , adr.address_line1	           emp_addr_line1							
       , adr.address_line2	           emp_addr_line2
       , adr.town_or_city	           emp_city							
       , adr.region_2                      emp_state
       , adr.postal_code	           emp_zip_code
       , adr.telephone_number_1            emp_home_phone
       , adr.country                       emp_country
       , loc.attribute2                    emp_location					
       , pl.name	                   emp_pl_name
       , opt.name                          emp_opt_name
       , rslt.enrt_cvg_strt_dt             emp_cvg_start_date		
       , rslt.enrt_cvg_thru_dt             emp_cvg_end_date
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
   	,  hr.per_all_assignments_f asg
	,  hr.hr_locations_all loc
        ,  hr.per_addresses adr
        ,  hr.hr_all_organization_units o
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
        ,  apps.hr_all_organization_units o
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
AND    emp.person_id = asg.person_id
AND    grp.benfts_grp_id = emp.benefit_group_id (+)
AND    pgm.pgm_id = rslt.pgm_id
AND    asg.location_id = loc.location_id
AND    asg.organization_id = o.organization_id
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
AND    trunc(SYSDATE) between pl.effective_start_date and pl.effective_end_date
AND    trunc(SYSDATE) between emp.effective_start_date and emp.effective_end_date
AND    trunc(SYSDATE) between asg.effective_start_date and asg.effective_end_date
AND    trunc(SYSDATE) between adr.date_from and nvl(adr.date_to, trunc(SYSDATE))
AND    trunc(SYSDATE) between rslt.effective_start_date and rslt.effective_end_date
AND    rslt.enrt_cvg_thru_dt > rslt.enrt_cvg_strt_dt
AND    trunc(SYSDATE) between rslt.enrt_cvg_strt_dt and rslt.enrt_cvg_thru_dt
;




-- Begin populate_depntmp_tbl Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE populate_depntmp_tbl(p_emp_ssn IN VARCHAR2) IS

--DECLARE VARIABLES
v_emp_ssn  VARCHAR2(30) := p_emp_ssn;


CURSOR c_depn_data IS					
SELECT DISTINCT 'Ora8i' type2_system
       ,emp.national_identifier	    	 	emp_ssn
       , depn.first_name 				depn_first_name
       , depn.middle_names		                depn_middle_name
       , depn.last_name		                       depn_last_name       
       , depn.sex		                       depn_sex									
       , rel.contact_type                              depn_relationship
       , depn.suffix				       depn_suffix       
       , depn.date_of_birth                            depn_dob
       , depn.registered_disabled_flag		depn_disabled				
       , depn.student_status		        depn_student
       , depn.national_identifier		        depn_ssn
       , eldp.cvg_strt_dt		depn_cvg_strt_dt		
       , eldp.cvg_thru_dt             depn_cvg_end_dt 
       , depn.rowid	                depn_row_id  
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f emp
     , hr.per_all_people_f depn
     , hr.per_contact_relationships rel
     , ben.ben_pl_f pl
     , ben.ben_elig_cvrd_dpnt_f eldp
     , ben.ben_prtt_enrt_rslt_f rslt
     , ben.ben_per_in_ler ler
     , ben.ben_pgm_f pgm   */
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
AND    trunc(SYSDATE)between emp.effective_start_date and emp.effective_end_date
AND    trunc(SYSDATE)between depn.effective_start_date and depn.effective_end_date
AND    trunc(SYSDATE) between rslt.effective_start_date and rslt.effective_end_date
AND    trunc(SYSDATE) between eldp.effective_start_date and eldp.effective_end_date
AND    trunc(SYSDATE) between eldp.cvg_strt_dt and eldp.cvg_thru_dt
AND	   emp.national_identifier = v_emp_ssn 
;



BEGIN

FOR depn IN c_depn_data LOOP


--INSERT INTO cust.ttec_depntmp_vsp_tbl ( -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
INSERT INTO apps.ttec_depntmp_vsp_tbl ( 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
TYPE_SYSTEM,					 
NATIONAL_IDENTIFIER,			
LAST_NAME,					
FIRST_NAME,					
SEX,
RELATIONSHIP,
DATE_OF_BIRTH,
ORGNL_ENRT_DT,	
ENRT_CVG_THRU_DT,
DEPN_SSN,
DISABLED,
STUDENT)
VALUES(depn.type2_system
	,depn.emp_ssn
        ,depn.depn_last_name
        ,depn.depn_first_name
        ,depn.depn_sex
        ,depn.depn_relationship
        ,depn.depn_dob
        ,depn.depn_cvg_strt_dt
        ,depn.depn_cvg_end_dt
        ,depn.depn_ssn
        ,depn.depn_disabled
        ,depn.depn_student);
END LOOP;
--Commit

COMMIT;
END;
 
 
------------
-- Calls main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

-- Begin populate_emptmp_tbl Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE populate_emptmp_tbl IS


--DECLARE VARIABLES
l_emp_ssn 		   			VARCHAR2(30);

BEGIN


FOR emp IN c_emp_data LOOP
       
	    l_emp_ssn := emp.emp_ssn;
	
		populate_depntmp_tbl(l_emp_ssn);
			
	    DBMS_OUTPUT.PUT_LINE(emp.emp_last_name);
	
--INSERT INTO cust.ttec_emptmp_vsp_tbl(	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
INSERT INTO apps.ttec_emptmp_vsp_tbl(	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
TYPE_SYSTEM,					 
NATIONAL_IDENTIFIER,			
LAST_NAME,					
FIRST_NAME,					
MIDDLE_NAMES,
SEX,
DATE_OF_BIRTH,					
ORGNL_ENRT_DT,		
ENRT_CVG_THRU_DT,	
ADDRESS_LINE1,
ADDRESS_LINE2,
TOWN_OR_CITY,
STATE,
ZIPCODE,
TELEPHONE_NUMBER_1,
COUNTRY,
LOCATION_ID,	
OPT_NAME)
VALUES(	emp.type_system
     	,emp.emp_ssn
        ,emp.emp_last_name
        ,emp.emp_first_name
        ,emp.emp_middle_name
        ,emp.emp_sex
        ,emp.emp_dob
        ,emp.emp_cvg_start_date
        ,emp.emp_cvg_end_date
        ,emp.emp_addr_line1
        ,emp.emp_addr_line2
        ,emp.emp_city
        ,emp.emp_state
        ,emp.emp_zip_code
        ,emp.emp_home_phone
        ,emp.emp_country
        ,emp.emp_location
        ,emp.emp_opt_name);
END LOOP;

DBMS_OUTPUT.PUT_LINE('Finishing inserting into employee temp table');
--Commit

COMMIT;
END;
------------
BEGIN
  execute immediate 'TRUNCATE TABLE cust.ttec_emptmp_vsp_tbl';
  execute immediate 'TRUNCATE TABLE cust.ttec_depntmp_vsp_tbl';
   populate_emptmp_tbl;
END;


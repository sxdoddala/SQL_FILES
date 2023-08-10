--******************************************************************************--
--*Program Name: ttec_recruitmax_interface.sql                                 *--   
--*                                                                            *--
--*                                                                            *--
--*Desciption: This program will write several interface reports:              *--
--*            Job Family Interface                                            *--
--*            Business Unit Interface                                         *--
--*            Department Interface                                            *--
--*            Employee/Hiring Manager Interface                               *--
--*	           Locations Interface                                             *--
--*            Job Templates Interface                                         *--
--*                                                                            *--
--*                                                                            *--

--*                                                                            *--
--*Input/Output Parameters                                                     *--
--*                                                                            *--
--*Tables Accessed: CUST.ttec_us_deferral_tbl def
--*                 hr.per_all_people_f emp                                    *--
--*                 per_all_assignments_f asg                                  *--
--*                 hr.hr_locations_all loc                                    *--
--*                 hr.per_person_types                                        *--
--*                 hr.pay_element_links_f                                     *--
--*                 hr.pay_element_types_f                                     *--
--*                 hr.pay_element_entry_values_f                              *--
--*                 hr.pay_input_values_f                                      *--
--*                 sys.v$database                                             *--
--*                                                                            *--
--*                                                                            *--
--*Tables Modified: PAY_ELEMENT_ENTRY_VALUES_F		                           *--
--*                                                                            *--
--*Procedures Called: 
--*                                                                            *--
--*Created By: Elizur Alfred-Ockiya                                            *--
--*Date: 02-MAR-2005                                                           *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya	 02-MAR-2005   File created					               *--
--* E.Alfred-Ockiya  13-JUL-2005   Modified 								   *-- 
--* Andy Becker      11-NOV-2005   Updated for Philippines data				   *--
--* Andy Becker      14-NOV-2005   Updated so file size <> 600 chars/line	   *--
--* 				 			   											   *-- 
--* Elango Pandu	08-mar-2006 Added Australia Business Group 	
--* Elango Pandu        05-apr-2006 Added Australia Location			
--* NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation														   *-- 
--******************************************************************************--

SET timing ON;
SET serveroutput ON SIZE 1000000;

DECLARE
/***Variables used by Common Error Procedure***/
        
p_businessunit         VARCHAR2(50)        := 'BusinessUnit.dat';
p_departments          VARCHAR2(50)        := 'Departments.dat';
p_employees            VARCHAR2(50)        := 'HiringManagers.dat'; 
p_jobfamily            VARCHAR2(50)        := 'JobFamily.dat'; 
p_jobgrades            VARCHAR2(50)        := 'JobGrades.dat'; 
p_jobcode_table        VARCHAR2(50)        := 'JobCode.dat'; 
p_location_table       VARCHAR2(50)        := 'Location.dat'; 


v_businessunit_file       UTL_FILE.FILE_TYPE;
v_departments_file        UTL_FILE.FILE_TYPE;
v_employees_file          UTL_FILE.FILE_TYPE;
v_jobfamily_file          UTL_FILE.FILE_TYPE;
v_jobgrades_file          UTL_FILE.FILE_TYPE;
v_jobcode_table_file      UTL_FILE.FILE_TYPE;
v_location_table_file     UTL_FILE.FILE_TYPE;



ERRBUF  VARCHAR2(50);
RETCODE  NUMBER;
P_OUTPUT_DIR   VARCHAR2(600);
/***Exceptions***/

SKIP_RECORD       EXCEPTION;


/***************************************** Cursor declaration ******************************************/

cursor csr_business_unit is 
select distinct
  d.segment3 business_unit_id,
  substr (c.name,6) business_unit,
  '1' active
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f a,
	 hr.per_all_assignments_f b,
	 hr.hr_all_organization_units c,
	 hr.pay_cost_allocation_keyflex d*/
from apps.per_all_people_f a,
	 apps.per_all_assignments_f b,
	 apps.hr_all_organization_units c,
	 apps.pay_cost_allocation_keyflex d
--End R12.2 Upgrade Remediation
where a.business_group_id in (325,326,1517,1839)
  and a.person_id = b.person_id
  and b.organization_id = c.organization_id
  and a.current_employee_flag = 'Y'
  and c.cost_allocation_keyflex_id = d.cost_allocation_keyflex_id
  and c.organization_id not in (1615,1616,1617)
  and to_date(sysdate) between a.effective_start_date and a.effective_end_date
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
order by 1;

cursor csr_departments is
select distinct
  d.segment3||f.segment2 department_id,
  f.segment2 department_code,
  substr (g.description||' ('||f.segment2||')'||' - '||upper(c.attribute3),1,100) department_name,
  d.segment3 business_unit_id,
  '1' Active
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f a,
	 hr.per_all_assignments_f b,
	 hr.hr_all_organization_units c,
	 hr.pay_cost_allocation_keyflex d,
	 hr.pay_cost_allocations_f e,
	 hr.pay_cost_allocation_keyflex f,*/
from apps.per_all_people_f a,
	 apps.per_all_assignments_f b,
	 apps.hr_all_organization_units c,
	 apps.pay_cost_allocation_keyflex d,
	 apps.pay_cost_allocations_f e,
	 apps.pay_cost_allocation_keyflex f,
--End R12.2 Upgrade Remediation
	 apps.fnd_flex_values_vl g
where a.business_group_id in (325,326,1517,1839)
  and a.person_id = b.person_id
  and b.organization_id = c.organization_id
  and c.cost_allocation_keyflex_id = d.cost_allocation_keyflex_id
  and b.assignment_id = e.assignment_id
  and e.cost_allocation_keyflex_id = f.cost_allocation_keyflex_id
  and f.segment2 = g.flex_value
  and g.flex_value_set_id = '1002611'
  and a.current_employee_flag = 'Y'
  and to_date(sysdate) between a.effective_start_date and a.effective_end_date
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
  and to_date(sysdate) between e.effective_start_date and e.effective_end_date
order by 1;

cursor csr_employees is 
select distinct
  a.employee_number employee_number,
  d.segment3||f.segment2 department_id,
  a.first_name firstname,
  a.last_name lastname,
  substr (h.name,instr(h.name,'.')+1) title,
  a.email_address email,
  i.country country,
  h.attribute6 org_area_id,
  j.employee_number supevisor_number,
  i.attribute2 OfficeID,
  k.phone_number phone,
  '1' active,
  a.attribute30 candidate_id
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f a,
	 hr.per_all_assignments_f b,
	 hr.hr_all_organization_units c,
	 hr.pay_cost_allocation_keyflex d,
	 hr.pay_cost_allocations_f e,
	 hr.pay_cost_allocation_keyflex f,
	 apps.fnd_flex_values_vl g,
	 hr.per_jobs h,
	 hr.hr_locations_all i,
	 hr.per_all_people_f j,
	 hr.per_phones k*/
from apps.per_all_people_f a,
	 apps.per_all_assignments_f b,
	 apps.hr_all_organization_units c,
	 apps.pay_cost_allocation_keyflex d,
	 apps.pay_cost_allocations_f e,
	 apps.pay_cost_allocation_keyflex f,
	 apps.fnd_flex_values_vl g,
	 apps.per_jobs h,
	 apps.hr_locations_all i,
	 apps.per_all_people_f j,
	 apps.per_phones k
--End R12.2 Upgrade Remediation
where a.business_group_id in (325,326,1517,1839)
  and a.person_id = b.person_id
  and b.organization_id = c.organization_id
  and c.cost_allocation_keyflex_id = d.cost_allocation_keyflex_id
  and b.assignment_id = e.assignment_id
  and e.cost_allocation_keyflex_id = f.cost_allocation_keyflex_id
  --and e.cost_allocation_keyflex_id = (select max (cost_allocation_keyflex_id) from hr.pay_cost_allocations_f x where x.assignment_id = b.assignment_id and to_date(sysdate) between x.effective_start_date and x.effective_end_date) -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  and e.cost_allocation_keyflex_id = (select max (cost_allocation_keyflex_id) from apps.pay_cost_allocations_f x where x.assignment_id = b.assignment_id and to_date(sysdate) between x.effective_start_date and x.effective_end_date)	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  and f.segment2 = g.flex_value
  and g.flex_value_set_id = '1002611'
  and b.job_id = h.job_id
  and b.location_id = i.location_id
  and h.attribute5 <> 'Agent'
  and a.current_employee_flag = 'Y'
  and b.primary_flag = 'Y'
  and b.supervisor_id = j.person_id(+)
  and j.effective_end_date(+) = '31-DEC-4712'
  and a.person_id = k.parent_id(+)
  and k.phone_type(+) = 'W1'
  and k.date_to(+) is null
  and to_date(sysdate) between a.effective_start_date and a.effective_end_date
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
  and to_date(sysdate) between e.effective_start_date and e.effective_end_date
order by 4,3;

cursor csr_jobfamily is
select distinct
  a.attribute5 jobfamily_id,
  a.attribute5 hriscode,
  a.attribute5 description,
  '1' active
--from hr.per_jobs a -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from apps.per_jobs a -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where a.business_group_id in (325,326,1517,1839)
  and a.date_to is null;

cursor csr_jobcode is
select distinct
	substr(a.name,1,instr(a.name,'.')-1)||replace(b.name,'TeleTech Holdings - ') job_id,
	substr(a.name,instr(a.name,'.')+1)||' ('||replace(b.name,'TeleTech Holdings - ')||')' jobtitle,
	substr(a.name,1,instr(a.name,'.')-1) jobcode,
	'1' active,
	a.attribute5 jobfamily_id,
	nvl (a.attribute9,a.job_information3) flsaexempt,
	decode(a.business_group_id,325,a.job_information1) eeocode_id,
	a.attribute1 bonus_eligible,
	a.attribute2 incentive_plan,
	a.attribute3 target_bonus
--START R12.2 Upgrade Remediation
/*from hr.per_jobs a,
	 hr.hr_all_organization_units b*/
from apps.per_jobs a,
	 apps.hr_all_organization_units b
--End R12.2 Upgrade Remediation
where a.business_group_id in (325, 326, 1517,1839)
  and a.date_to is null
  and a.business_group_id = b.organization_id
order by 2;

cursor csr_locations is
select distinct
  a.attribute2 offices_id,
  substr (a.location_code,5) offices_description,
  substr(a.address_line_1,1,50) offices_address1,
  a.address_line_2 offices_address2,
  a.town_or_city offices_city,
  decode (a.country,'US',a.region_2,'CA',a.region_1) offices_state,
  a.country offices_country,
  a.postal_code offices_zip,
  '' offices_phone,
  '' offices_fax,
  '1' active
--from hr.hr_locations_all a	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from apps.hr_locations_all a	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where a.country in ('US','CA','PH','AU')
  and a.location_code not like 'HW%'
  and a.location_code not like 'FORD%'
  and a.location_id not in (442,522,15338,1424)
  and a.inactive_date is null
  and a.attribute2 is not null
order by offices_country,offices_description;

cursor csr_jobgrades is
select distinct
  substr(a.name,1,instr(a.name,'.')-1) jobgradeid,
  a.name jobgrade,
  b.minimum wagemin,
  b.mid_value wagemid,
  b.maximum wagemax,
  'Hourly/Non-Exempt' wagefrequencyid,
  b.currency_code wagecurrencyid
--START R12.2 Upgrade Remediation
/*from hr.per_grades a,
	 hr.pay_grade_rules_f b*/
from apps.per_grades a,
	 apps.pay_grade_rules_f b
--End R12.2 Upgrade Remediation
where a.date_to is null
  and a.grade_id = b.grade_or_spinal_point_id
  and a.business_group_id = 325
  and b.minimum < 100
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
UNION  
select distinct
  substr(a.name,1,instr(a.name,'.')-1) jobgradeid,
  a.name jobgrade,
  b.minimum wagemin,
  b.mid_value wagemid,
  b.maximum wagemax,
  'Hourly' wagefrequencyid,
  b.currency_code wagecurrencyid
--START R12.2 Upgrade Remediation
/*from hr.per_grades a,
	 hr.pay_grade_rules_f b*/
from apps.per_grades a,
	 apps.pay_grade_rules_f b
--End R12.2 Upgrade Remediation
where a.date_to is null
  and a.grade_id = b.grade_or_spinal_point_id
  and a.business_group_id = 326
  and b.minimum < 100
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
UNION  
select distinct
  substr(a.name,1,instr(a.name,'.')-1) jobgradeid,
  a.name jobgrade,
  b.minimum wagemin,
  b.mid_value wagemid,
  b.maximum wagemax,
  'Salary/Exempt' wagefrequencyid,
  b.currency_code wagecurrencyid
--START R12.2 Upgrade Remediation
/*from hr.per_grades a,
	 hr.pay_grade_rules_f b*/
from apps.per_grades a,
	 apps.pay_grade_rules_f b
--End R12.2 Upgrade Remediation
where a.date_to is null
  and a.grade_id = b.grade_or_spinal_point_id
  and a.business_group_id = 325
  and b.minimum >= 100
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
UNION  
select distinct
  substr(a.name,1,instr(a.name,'.')-1) jobgradeid,
  a.name jobgrade,
  b.minimum wagemin,
  b.mid_value wagemid,
  b.maximum wagemax,
  'Salary' wagefrequencyid,
  b.currency_code wagecurrencyid
--START R12.2 Upgrade Remediation
/*from hr.per_grades a,
	 hr.pay_grade_rules_f b*/
from apps.per_grades a,
	 apps.pay_grade_rules_f b
--End R12.2 Upgrade Remediation
where a.date_to is null
  and a.grade_id = b.grade_or_spinal_point_id
  and a.business_group_id = 326
  and b.minimum >= 100
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date
UNION
select distinct
  substr(a.name,1,instr(a.name,'.')-1) jobgradeid,
  a.name jobgrade,
  b.minimum wagemin,
  b.mid_value wagemid,
  b.maximum wagemax,
  'Monthly Salary Non Exempt' wagefrequencyid,
  b.currency_code wagecurrencyid
--START R12.2 Upgrade Remediation
/*from hr.per_grades a,
	 hr.pay_grade_rules_f b*/
from apps.per_grades a,
	 apps.pay_grade_rules_f b
--End R12.2 Upgrade Remediation
where a.date_to is null
  and a.grade_id = b.grade_or_spinal_point_id
  and a.business_group_id = 1517
  --and b.minimum >= 100
  and to_date(sysdate) between b.effective_start_date and b.effective_end_date;


--***************************************************************
PROCEDURE main(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER, P_OUTPUT_DIR IN VARCHAR2 ) IS
  --  
 v_output_dir    VARCHAR2(600) := P_OUTPUT_DIR;

l_businessunit_output            CHAR(600);
l_departments_output             CHAR(600);
l_employees_output               CHAR(600);
l_jobfamily_output               CHAR(600);
l_jobgrade_output                CHAR(600);
l_jobcode_table_output           CHAR(600);
l_location_table_output          CHAR(600);
  
BEGIN              ---Starting main 

 --dbms_output.put_line('Starting Main ');  
 
    begin
	  select '/d01/ora'||DECODE(name,'PROD','cle',lower(name))
	  ||'/'||lower(name)
	  ||'appl/teletech/11.5.0/data/BenefitInterface'
	  into v_output_dir
	  from V$DATABASE;
    end;

--************************************ Business Unit ******************************************  
begin
  v_businessunit_file := UTL_FILE.FOPEN(v_output_dir, p_businessunit, 'w'); 
  v_departments_file := UTL_FILE.FOPEN(v_output_dir, p_departments, 'w'); 
  v_employees_file := UTL_FILE.FOPEN(v_output_dir, p_employees, 'w'); 
  v_jobfamily_file := UTL_FILE.FOPEN(v_output_dir, p_jobfamily, 'w');  
  v_jobcode_table_file := UTL_FILE.FOPEN(v_output_dir, p_jobcode_table, 'w');
  v_location_table_file := UTL_FILE.FOPEN(v_output_dir, p_location_table, 'w');  
  v_jobgrades_file   := UTL_FILE.FOPEN(v_output_dir, p_jobgrades, 'w');  
  
       l_businessunit_output := ('BusinessUnitID'   ||'|'||
	                              'BusinessUnit'    ||'|'||
								  'Active');
								  
       utl_file.put_line(v_businessunit_file, rtrim(l_businessunit_output));
	
    for unit in csr_business_unit loop
		
        l_businessunit_output :=(unit.business_unit_id          ||'|'||
		                         unit.business_unit             ||'|'||
						         unit.active );
								 
       utl_file.put_line(v_businessunit_file, rtrim(l_businessunit_output));

    end loop;	

end;

-- ************************************* Department ********************************  ----------

begin

      l_departments_output := ('DepartmentID'        ||'|'||
	                              'DepartmentCode'   ||'|'||
								  'DepartmentName'   ||'|'||
								  'BusinessUnitID'   ||'|'||
								  'Active');
								  
       utl_file.put_line(v_departments_file, rtrim(l_departments_output));
	
    for dept in csr_departments loop
		
        l_departments_output := (dept.department_id        ||'|'||
		                         dept.department_code      ||'|'||
								 dept.department_name      ||'|'||
								 dept.business_unit_id     ||'|'||
						         dept.Active);
								 
       utl_file.put_line(v_departments_file, rtrim(l_departments_output));

    end loop;	

end;


-- ************************************* EMPLOYEES *************************************----------
begin
  
           l_employees_output := ('EmployeeID'     ||'|'||
		                          'DepartmentID'   ||'|'||
	                              'FirstName'      ||'|'||
								  'LastName'       ||'|'||
								  'Title'          ||'|'||
								  'Email'          ||'|'||
								  'Country'        ||'|'||
								  'OrgAreaID'      ||'|'||
								  'ReportsToID'    ||'|'||
								  'OfficeID'       ||'|'||
								  'Phone'          ||'|'||
								  'Active'         ||'|'||
								  'CandidateID');
								  
       utl_file.put_line(v_employees_file, rtrim(l_employees_output));
	
    for emp in csr_employees loop
		
        l_employees_output :=(emp.employee_number         ||'|'||
		                      emp.department_id           ||'|'||
							  emp.firstname               ||'|'||         
							  emp.lastname                ||'|'||
							  emp.title                   ||'|'||
							  emp.email                   ||'|'||
							  emp.country                 ||'|'||
							  emp.org_area_id             ||'|'||
							  emp.supevisor_number        ||'|'||
							  emp.OfficeID                ||'|'||
							  emp.phone                   ||'|'||
						      emp.active                  ||'|'||      
							  emp.candidate_id);
							  
        utl_file.put_line(v_employees_file, rtrim(l_employees_output));
      end loop;	

end;
-----**************************************** Job Family ********************************--------
begin
  
       l_jobfamily_output := ('JobFamilyID'                      ||'|'||
	                           'HRISCode'                        ||'|'||
							   'Description'           ||'|'||
							   'Active');
								  
       utl_file.put_line(v_jobfamily_file, rtrim(l_jobfamily_output));
	
    for jobfamily in csr_jobfamily loop
		
        l_jobfamily_output :=(jobfamily.jobfamily_id        ||'|'||
		                      jobfamily.hriscode            ||'|'||
							  jobfamily.description         ||'|'||
						      jobfamily.active);
								 
       utl_file.put_line(v_jobfamily_file, rtrim(l_jobfamily_output));

    end loop;	

end;
-----**************************************** Job Template - Job Code ********************************--------
begin
  
       l_jobcode_table_output := ('ID'                            ||'|'||
	                              'JobTitle'                      ||'|'||
							      'JobCode'                       ||'|'||
								  'Active'                        ||'|'||
								  'JobFamilyID'                   ||'|'||
								  'FLSAExempt'                    ||'|'||
								  'EEOCodeID'                     ||'|'||
								  'Bonus Eligible?'               ||'|'||
								  'Incentive Plan'				  ||'|'||
								  'Target Bonus %');  
								  
       utl_file.put_line(v_jobcode_table_file, rtrim(l_jobcode_table_output));
	
    for jobcode in csr_jobcode loop
		
        l_jobcode_table_output :=(jobcode.job_id                ||'|'||
		                      jobcode.jobtitle                  ||'|'||
							  jobcode.jobcode                   ||'|'||
							  jobcode.active                    ||'|'||
							  jobcode.jobfamily_id              ||'|'||
							  jobcode.flsaexempt                ||'|'||
							  jobcode.eeocode_id                ||'|'||
							  jobcode.bonus_eligible                ||'|'||
							  jobcode.incentive_plan                ||'|'||
						      rpad(substr(nvl(jobcode.target_bonus,' '),1,20),20));
							  
							  
		--				 ||rpad(substr(nvl(sel.last_name,' '),1,25),25)							  
							  
								 
      utl_file.put_line(v_jobcode_table_file, rtrim(l_jobcode_table_output));

    end loop;	

end;
-----**************************************** Locations ********************************--------
begin
  
       l_location_table_output := ('ID'                 ||'|'||
	                              'Description'         ||'|'||
							      'Address1'            ||'|'||
							      'Address2'            ||'|'||								  
								  'City'                ||'|'||
							      'State'               ||'|'||								  
								  'Country'             ||'|'||
								  'Zip'                 ||'|'||
								  'Phone'               ||'|'||
								  'Fax'                 ||'|'||								  
								  'Active');  
								  
    utl_file.put_line(v_location_table_file, rtrim(l_location_table_output));
	
    for loc in csr_locations loop
		
        l_location_table_output :=(loc.offices_id               ||'|'||
		                          loc.offices_description       ||'|'||
							      loc.offices_address1          ||'|'||
							      loc.offices_address2          ||'|'||
							      loc.offices_city              ||'|'||
							      loc.offices_state             ||'|'||
							      loc.offices_country           ||'|'||
							      loc.offices_zip               ||'|'||
							      loc.offices_phone             ||'|'||
							      loc.offices_fax               ||'|'||								  
						          loc.active);
								 
    utl_file.put_line(v_location_table_file, rtrim(l_location_table_output));

    end loop;	

end;
-----**************************************** Job Grades ********************************--------
---*********************************************************************************************
begin
  
      l_jobgrade_output  := ('JobGradeID'                ||'|'||
	                         'JobGrade'                  ||'|'||
							 'WageMin'                   ||'|'||
							 'WageMid'                   ||'|'||
							 'WageMax'                   ||'|'||
							 'WageFrequencyID'           ||'|'||
							 'WageCurrencyID');  
								  
       utl_file.put_line(v_jobgrades_file , rtrim(l_jobgrade_output));
	
    for jobgrade in csr_jobgrades loop
		
        l_jobgrade_output :=(jobgrade.jobgradeid                 ||'|'||
		                      jobgrade.jobgrade                  ||'|'||
							  jobgrade.wagemin                   ||'|'||
							  jobgrade.wagemid                   ||'|'||
							  jobgrade.wagemax                   ||'|'||
							  jobgrade.wagefrequencyid           ||'|'||
							  jobgrade.wagecurrencyid);
								 
      utl_file.put_line(v_jobgrades_file, rtrim(l_jobgrade_output));

    end loop;	

end;

----***********************************************************************************************
UTL_FILE.FCLOSE(v_businessunit_file);
UTL_FILE.FCLOSE(v_departments_file);		
UTL_FILE.FCLOSE(v_employees_file);
UTL_FILE.FCLOSE(v_jobfamily_file);
UTL_FILE.FCLOSE(v_jobcode_table_file);		
UTL_FILE.FCLOSE(v_location_table_file);
-- ************************************* EMPLOYEES *************************************----------

END; --ending main procedure 
--***************************************************************
--*****                  Call Main procedure                *****
--***************************************************************

begin
     main(ERRBUF, RETCODE, P_OUTPUT_DIR);
	 EXCEPTION
	 WHEN SKIP_RECORD THEN
--	 dbms_output.put_line('Starting Main '); 
	 null;
end;
/



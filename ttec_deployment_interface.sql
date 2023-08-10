--******************************************************************************--
--*Program Name: ttec_deployment_interface.sql                                 *--   
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
--*Date: 02-MAR-2005                                                            *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya	 02-MAR-2005   File created					               *---
--* NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation
--******************************************************************************--

SET timing ON;
SET serveroutput ON SIZE 1000000;

DECLARE
/***Variables used by Common Error Procedure***/
        
p_businessunit         VARCHAR2(50)        := 'BusinessUnit.dat';
p_departments          VARCHAR2(50)        := 'Departments.dat';
p_employees            VARCHAR2(50)        := 'Employees.dat'; 
p_jobfamily            VARCHAR2(50)        := 'JobFamily.dat'; 
p_jobgrades            VARCHAR2(50)        := 'JobGrades.dat'; 
p_jobcode_table        VARCHAR2(50)        := 'Jobcode_Table.dat'; 
p_location_table       VARCHAR2(50)        := 'Location_Table.dat'; 


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
select distinct paycost.segment3 business_unit_id
  ,substr (org.name,6)  business_unit
  ,'1' active
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f emp,
	 hr.per_all_assignments_f asg,
	 hr.hr_all_organization_units org,
	 hr.pay_cost_allocation_keyflex paycost*/
from apps.per_all_people_f emp,
	 apps.per_all_assignments_f asg,
	 apps.hr_all_organization_units org,
	 apps.pay_cost_allocation_keyflex paycost	 
--End R12.2 Upgrade Remediation	 
where emp.business_group_id in (325,326)
  and emp.person_id = asg.person_id
  and asg.organization_id = org.organization_id
  and emp.current_employee_flag = 'Y'
  and org.cost_allocation_keyflex_id = paycost.cost_allocation_keyflex_id
  and org.organization_id not in (1615,1616,1617)
  and to_date(sysdate) between emp.effective_start_date and emp.effective_end_date
  and to_date(sysdate) between asg.effective_start_date and asg.effective_end_date
order by 1;


cursor csr_departments is
select distinct paycost.segment3||paycost2.segment2 department_id
  ,paycost2.segment2 department_code
  ,fndval.description||' ('||upper(org.attribute3)||')' department_name
  ,paycost.segment3 business_unit_id
  ,'1' Active
--START R12.2 Upgrade Remediation
/*from hr.per_all_people_f emp,
	 hr.per_all_assignments_f asg,
	 hr.hr_all_organization_units org,
	 hr.pay_cost_allocation_keyflex paycost,
	 hr.pay_cost_allocations_f pcost,
	 hr.pay_cost_allocation_keyflex paycost2,*/
from apps.per_all_people_f emp,
	 apps.per_all_assignments_f asg,
	 apps.hr_all_organization_units org,
	 apps.pay_cost_allocation_keyflex paycost,
	 apps.pay_cost_allocations_f pcost,
	 apps.pay_cost_allocation_keyflex paycost2,
--End R12.2 Upgrade Remediation	 
	 apps.fnd_flex_values_vl fndval
where emp.business_group_id in (325,326)
  and emp.person_id = asg.person_id
  and asg.organization_id = org.organization_id
  and org.cost_allocation_keyflex_id = paycost.cost_allocation_keyflex_id
  and asg.assignment_id = pcost.assignment_id
  and pcost.cost_allocation_keyflex_id = paycost2.cost_allocation_keyflex_id
  and paycost2.segment2 = fndval.flex_value
  and fndval.flex_value_set_id = '1002611'
  and emp.current_employee_flag = 'Y'
  and to_date(sysdate) between emp.effective_start_date and emp.effective_end_date
  and to_date(sysdate) between asg.effective_start_date and asg.effective_end_date
  and to_date(sysdate) between pcost.effective_start_date and pcost.effective_end_date
order by 1;

cursor csr_employees is 
select distinct a.employee_number employee_number,
  d.segment3||f.segment2 department_id,
  a.first_name firstname,
  a.last_name lastname,
  substr (h.name,instr(h.name,'.')+1) title,
  a.email_address email,
  decode (a.business_group_id,325,'US',326,'CAN') country,
  d.segment3 org_area_id,
  j.employee_number supevisor_number,
  i.attribute2 OfficeID,
  k.phone_number phone,
  '1' active
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
where a.business_group_id in (325,326)
  and a.person_id = b.person_id
  and b.organization_id = c.organization_id
  and c.cost_allocation_keyflex_id = d.cost_allocation_keyflex_id
  and b.assignment_id = e.assignment_id
  and e.cost_allocation_keyflex_id = f.cost_allocation_keyflex_id
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

--and emp.employee_number = 3000053
-- rownum < 10

cursor csr_jobfamily is
select distinct job.attribute5  jobfamily_id
, job.attribute5  hriscode
, job.attribute5  description
, '1'             active
--from hr.per_jobs job	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from apps.per_jobs job	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where job.business_group_id in (325,326)
  and job.date_to is null;
--where rownum < 5

---/***** JOB TEMPLATE *****/

cursor csr_jobcode is
select distinct	substr(job.name,1,instr(job.name,'.')-1) jobcapsules_id,
	substr(job.name,instr(job.name,'.')+1) jobtitle,
	substr(job.name,1,instr(job.name,'.')-1) jobcode,
	'1' active,
	job.attribute5 jobfamily_id,
	job.job_information3 flsaexempt,
	nvl (job.job_information1,job2.job_information1) eeocode_id,
	job.attribute1 attribute1,
	job.attribute2 attribute2,
	job.attribute3 attribute3
--START R12.2 Upgrade Remediation
/*from hr.per_jobs job,
	 hr.per_jobs job2*/
from apps.per_jobs job,
	 apps.per_jobs job2	 
--End R12.2 Upgrade Remediation	 
where job.business_group_id in (325, 326)
  and job.date_to is null
  and job.name = job2.name(+)
  and job2.business_group_id(+) = 325
  and job2.date_to(+) is null
order by 2;
--and rownum < 5 

cursor csr_locations is
select loc.attribute2     offices_id
, substr(loc.location_code,5)       offices_description
, loc.address_line_1                offices_address1
, loc.address_line_2                offices_address2
, loc.town_or_city                  offices_city
, decode (loc.country,'US',loc.region_2,'CA',loc.region_1) offices_state
, loc.country                       offices_county
, loc.postal_code                   offices_zip
, loc.telephone_number_1            offices_phone
, loc.telephone_number_2            offices_fax
, '1'                               active
--from hr.hr_locations_all loc	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from apps.hr_locations_all loc	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where loc.country in ('US','CA')
  and loc.location_code not like 'HW%'
  and loc.location_code not like 'FORD%'
  and loc.location_id not in (442,522,15338,1424)
  and loc.inactive_date is null
  and loc.attribute2 is not null
order by 2;
--where rownum < 5



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

 dbms_output.put_line('Starting Main ');  
 
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
  
  
       l_businessunit_output := ('BusinessUnits.BusinessUnitID'   ||'|'||
	                              'BusinessUnits.BusinessUnit'    ||'|'||
								  'BusinessUnits.Active');
								  
       utl_file.put_line(v_businessunit_file, l_businessunit_output);
	
    for unit in csr_business_unit loop
		
        l_businessunit_output :=(unit.business_unit_id          ||'|'||
		                         unit.business_unit             ||'|'||
						         unit.active );
								 
       utl_file.put_line(v_businessunit_file, l_businessunit_output);

    end loop;	

end;

-- ************************************* Department ********************************  ----------

begin

      l_departments_output := ('Departments.DepartmentID'        ||'|'||
	                              'Departments.DepartmentCode'   ||'|'||
								  'Departments.DepartmentName'   ||'|'||
								  'Departments.BusinessUnitID'   ||'|'||
								  'Departments.Active');
								  
       utl_file.put_line(v_departments_file, l_departments_output);
	
    for dept in csr_departments loop
		
        l_departments_output := (dept.department_id        ||'|'||
		                         dept.department_code      ||'|'||
								 dept.department_name      ||'|'||
								 dept.business_unit_id     ||'|'||
						         dept.Active);
       utl_file.put_line(v_departments_file, l_departments_output);

    end loop;	

end;


-- ************************************* EMPLOYEES *************************************----------
begin
  
           l_employees_output := ('DepartmentsHiringManagers.EmployeeID'     ||'|'||
		                          'DepartmentsHiringManagers.DepartmentID'   ||'|'||
	                              'DepartmentsHiringManagers.FirstName'      ||'|'||
								  'DepartmentsHiringManagers.LastName'       ||'|'||
								  'DepartmentsHiringManagers.Title'          ||'|'||
								  'DepartmentsHiringManagers.Email'          ||'|'||
								  'DepartmentsHiringManagers.Country'        ||'|'||
								  'DepartmentsHiringManagers.OrgAreaID'      ||'|'||
								  'DepartmentsHiringManagers.ReportsToID'    ||'|'||
								  'DepartmentsHiringManagers.OfficeID'       ||'|'||
								  'DepartmentsHiringManagers.Phone'          ||'|'||
								  'Departments.Active');
								  
       utl_file.put_line(v_employees_file, l_employees_output);
	
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
						      emp.active);
        utl_file.put_line(v_employees_file, l_employees_output);
      end loop;	

end;
-----**************************************** Job Family ********************************--------
begin
  
       l_jobfamily_output := ('JobFamily.JobFamilyID'   ||'|'||
	                           'JobFamily.HRISCode'     ||'|'||
							   'JobFamily.Description'   ||'|'||
							   'JobFamily.Active');
								  
       utl_file.put_line(v_jobfamily_file, l_jobfamily_output);
	
    for jobfamily in csr_jobfamily loop
		
        l_jobfamily_output :=(jobfamily.jobfamily_id        ||'|'||
		                      jobfamily.hriscode       ||'|'||
							  jobfamily.description       ||'|'||
						      jobfamily.active);
								 
       utl_file.put_line(v_jobfamily_file, l_jobfamily_output);

    end loop;	

end;
-----**************************************** Job Template - Job Code ********************************--------
begin
  
       l_jobcode_table_output := ('JobCapsules.ID'                ||'|'||
	                              'JobCapsules.JobTitle'          ||'|'||
							      'JobCapsules.JobCode'           ||'|'||
								  'JobCapsules.Active'            ||'|'||
								  'JobCapsules.JobFamilyID'       ||'|'||
								  'JobCapsules.FLSAExempt'        ||'|'||
								  'JobCapsules.EEOCodeID'         ||'|'||
								  'Bonus Eligible?'               ||'|'||
								  'Incentive Plan'				  ||'|'||
								  'Target Bonus %');  
								  
       utl_file.put_line(v_jobcode_table_file, l_jobcode_table_output);
	
    for jobcode in csr_jobcode loop
		
        l_jobcode_table_output :=(jobcode.jobcapsules_id        ||'|'||
		                      jobcode.jobtitle                  ||'|'||
							  jobcode.jobcode                   ||'|'||
							  jobcode.active                    ||'|'||
							  jobcode.jobfamily_id              ||'|'||
							  jobcode.flsaexempt                ||'|'||
							  jobcode.eeocode_id                ||'|'||
							  jobcode.attribute1                ||'|'||
							  jobcode.attribute2                ||'|'||
						      jobcode.attribute3);
								 
      utl_file.put_line(v_jobcode_table_file, l_jobcode_table_output);

    end loop;	

end;
-----**************************************** Locations ********************************--------
begin
  
       l_location_table_output := ('Offices.ID'                 ||'|'||
	                              'Offices.Description'         ||'|'||
							      'Offices.Address1'            ||'|'||
							      'Offices.Address2'            ||'|'||								  
								  'Offices.City'                ||'|'||
							      'Offices.State'               ||'|'||								  
								  'Offices.Country'             ||'|'||
								  'Offices.Zip'                 ||'|'||
								  'Offices.Phone'               ||'|'||
								  'Offices.Fax'                 ||'|'||								  
								  'Offices.Active');  
								  
    utl_file.put_line(v_location_table_file, l_location_table_output);
	
    for loc in csr_locations loop
		
        l_location_table_output :=(loc.offices_id                ||'|'||
		                          loc.offices_description       ||'|'||
							      loc.offices_address1          ||'|'||
							      loc.offices_address2          ||'|'||
							      loc.offices_city              ||'|'||
							      loc.offices_state             ||'|'||
							      loc.offices_county            ||'|'||
							      loc.offices_zip               ||'|'||
							      loc.offices_phone             ||'|'||
							      loc.offices_fax               ||'|'||								  
						          loc.active);
								 
    utl_file.put_line(v_location_table_file, l_location_table_output);

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
	 dbms_output.put_line('Starting Main '); 
	 null;
end;
/



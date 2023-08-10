 /************************************************************************************
        Program Name: tt_costing_override.sql

        Description:   

        Developed by : 
        Date         :  

       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    NXGARIKAPATI(ARGANO)            1.0      21-JULY-2023      R12.2 Upgrade Remediation
    ****************************************************************************************/

-- Displays default costing sources, including;
-- 			Location Code from Assigned Location
--			Department from Assigned Organization
--			Location, Client, and Department Override from the Costing Override zone
set linesize  300
set pagesize 0
select 'PAYROLL'||'|'||'LAST NAME'||'|'||'FIRST NAME'||'|'||'MIDDLE NAME'||'|'||
       'EMPLOYEE NUMBER'||'|'||'SSN'||'|'||'LOCATION CODE'||'|'||'ORG'||'|'||'LOCATION'||'|'||
       'ORG ACCOUNT'||'|'||'COST LOCATION'||'|'||'COST CLIENT'||'|'||
       'COST DEPARTMENT' from dual
/
select papf.payroll_name||'|'|| 
       aa.last_name||'|'||aa.first_name||'|'||aa.middle_names||'|'||
       aa.EMPLOYEE_NUMBER||'|'|| aa.NATIONAL_IDENTIFIER||'|'||
       hl.location_code||'|'|| haou.name||'|'||
       hl.attribute2||'|'||
       pcak.concatenated_segments||'|'||
       c.segment1||'|'||
       c.segment2||'|'||
       c.segment3
from   apps.per_all_assignments_f a,
           --hr.per_periods_of_service ppos,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.per_periods_of_service ppos,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   apps.pay_cost_allocations_f b,
	   apps.pay_cost_allocation_keyflex c,
	   apps.per_all_people_f aa,
	   apps.hr_locations hl,
	   apps.pay_cost_allocation_keyflex pcak,
	   apps.hr_all_organization_units haou,
	   apps.pay_all_payrolls_f papf
where  a.assignment_id = b.assignment_id
  and  a.business_group_id in (325,326)
  and  a.primary_flag || '' = 'Y'
  and  aa.person_id = ppos.person_id 
  and  sysdate BETWEEN ppos.date_start AND NVL(ppos.final_process_date, sysdate)
  and  sysdate - NVL(ppos.actual_termination_date,sysdate ) < 30 
  and  b.cost_allocation_keyflex_id = c.cost_allocation_keyflex_id
  and  sysdate between a.effective_start_date and a.effective_end_date
  and  aa.person_id = a.person_id
  and  sysdate between aa.effective_start_date and aa.effective_end_date
  and  sysdate between b.effective_start_date and b.effective_end_date
  and  a.location_id = hl.location_id
  and  a.ORGANIZATION_ID 			   = haou.ORGANIZATION_ID
  and  haou.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id (+)
  and  a.payroll_id = papf.payroll_id
UNION
select papf.payroll_name||'|'|| 
       aa.last_name||'|'||aa.first_name||'|'||aa.middle_names||'|'||
       aa.EMPLOYEE_NUMBER||'|'|| aa.NATIONAL_IDENTIFIER||'|'||
       hl.location_code||'|'|| haou.name||'|'||
       hl.attribute2||'|'||
       pcak.concatenated_segments||'|'||
       ''||'|'||
       ''||'|'||
       ''
from   apps.per_all_assignments_f a,
           --hr.per_periods_of_service ppos, -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.per_periods_of_service ppos, -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   apps.per_all_people_f aa,
	   apps.hr_locations hl,
	   apps.pay_cost_allocation_keyflex pcak,
	   apps.hr_all_organization_units haou,
	   apps.pay_all_payrolls_f papf
where  a.assignment_id NOT IN (select bb.assignment_id from apps.pay_cost_allocations_f bb)
  and   a.business_group_id in (325,326)
  and  a.primary_flag || '' = 'Y'
  and  aa.person_id = ppos.person_id 
  and  sysdate BETWEEN ppos.date_start AND NVL(ppos.final_process_date, sysdate)
  and  sysdate - NVL(ppos.actual_termination_date,sysdate ) < 30 
  and  sysdate between a.effective_start_date and a.effective_end_date
  and  aa.person_id = a.person_id
  and  sysdate between aa.effective_start_date and aa.effective_end_date
  and  a.location_id = hl.location_id
  and  a.ORGANIZATION_ID 			   = haou.ORGANIZATION_ID
  and  haou.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id (+)
  and  a.payroll_id = papf.payroll_id
order by 1
/

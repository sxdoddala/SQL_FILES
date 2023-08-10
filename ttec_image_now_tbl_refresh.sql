--
-- Program Name:  ttec_image_now_tbl_refresh.sql
-- /* $Header: ttec_image_now_tbl_refresh.sql 1.0 2015/04/09  chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 09-APR-2015
--
-- Call From: Concurrent Program -> TTEC IMAGE_NOW Table nightly refresh
--      Desc: Script to create table cust.imagenow_hc, it will be used by IMAGE_NOW application to manage employee  
--            document upload to HRMS in Oracle PRODUCTION. The table needs to be refreshed on a nightly basis.
--            The Concurrent Program will be scheduled from HRMS_UPDATE 
--
--     Parameter Description:
--
--       Oracle Standard Parameters:
--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      1.0  04/09/15   CChan     Initial Version
--   1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)     R12.2 Upgrade Remediation
--

truncate table cust.imagenow_hc;

--insert into cust.imagenow_hc	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
insert into apps.imagenow_hc	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
(
  EMP_ORACLE_ID ,
  EMP_FIRST_NAME,
  EMP_MIDDLE_NAME,
  EMP_LAST_NAME,
  REHIRE_DATE,
  COUNTRY,
  EMP_LOC_NO,
  EMP_LOC_NAME,
  EMP_CLIENT_NO,
  EMP_CLIENT_NAME,
  ACTUAL_TERMINATION_DATE,
  REHIRE_FLAG
)
   SELECT NVL (papf.employee_number, papf.npw_number) emp_oracle_id,
          papf.first_name emp_first_name, papf.middle_names emp_middle_name,
          papf.last_name emp_last_name, emps.rehire_date,
         --ftv.TERRITORY_SHORT_NAME  country,
          hla.country country,
          NVL (org_alloc.segment1, gcc.segment1) emp_loc_no,
          (SELECT t.description
             --START R12.2 Upgrade Remediation
			 /*FROM applsys.fnd_flex_values v,
                  applsys.fnd_flex_value_sets s,
                  applsys.fnd_flex_values_tl t*/
			 FROM apps.fnd_flex_values v,
                  apps.fnd_flex_value_sets s,
                  apps.fnd_flex_values_tl t	  
			--End R12.2 Upgrade Remediation	  
            WHERE flex_value_set_name = 'TELETECH_LOCATION'
              AND s.flex_value_set_id = v.flex_value_set_id
              AND t.flex_value_id = v.flex_value_id
              AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                               TRUNC (SYSDATE)
                                              )
                                      AND NVL (end_date_active, '31-DEC-4712')
              AND t.LANGUAGE = 'US'
              AND v.flex_value = NVL (org_alloc.segment1, gcc.segment1))
                                                                 emp_loc_name,
          NVL (org_alloc.segment2, gcc.segment2) emp_client_no,
          (SELECT SUBSTR (b.description, 1, 26)
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values_vl b
            WHERE a.flex_value_set_id = b.flex_value_set_id
              AND a.flex_value_set_name = 'TELETECH_CLIENT'
              AND b.flex_value = NVL (org_alloc.segment2, gcc.segment2))
                                                              emp_client_name,
          emps.actual_termination_date,
          DECODE
             (emps.rehire_date,
              (CASE
                  WHEN paaf.assignment_type = 'E'
                     THEN (SELECT NVL (ppos.adjusted_svc_date,
                                       ppos.date_start)
                             FROM per_periods_of_service ppos
                            WHERE person_id = papf.person_id
                              AND ppos.date_start =
                                           (SELECT MIN (date_start)
                                              FROM per_periods_of_service ppos
                                             WHERE person_id = papf.person_id))
                  ELSE (SELECT ppos.date_start
                          FROM per_periods_of_placement ppos
                         WHERE person_id = papf.person_id
                           AND ppos.date_start =
                                         (SELECT MIN (date_start)
                                            FROM per_periods_of_placement ppos
                                           WHERE person_id = papf.person_id))
               END
              ), 'N',
              'Y'
             ) rehire_flag
     --START R12.2 Upgrade Remediation
	 /*FROM hr.per_all_people_f papf,
          hr.per_all_assignments_f paaf,
          hr_locations_all hla,
          --apps.fnd_territories_vl ftv,
          hr.hr_all_organization_units haou,
          apps.pay_cost_allocation_keyflex org_alloc,
          gl.gl_code_combinations gcc,*/
	FROM apps.per_all_people_f papf,
          apps.per_all_assignments_f paaf,
          hr_locations_all hla,
          --apps.fnd_territories_vl ftv,
          apps.hr_all_organization_units haou,
          apps.pay_cost_allocation_keyflex org_alloc,
          apps.gl_code_combinations gcc,	  
	 --End R12.2 Upgrade Remediation	  
          (SELECT ppos.person_id, actual_termination_date,
                  CASE SIGN (date_start - TRUNC (SYSDATE))
                     WHEN -1
                        THEN                      -- Past Start Date
                            CASE SIGN (  TRUNC (SYSDATE)
                                       - NVL (actual_termination_date,
                                              TRUNC (SYSDATE) + 1
                                             )
                                      )
                               WHEN 1
                                  THEN actual_termination_date
                                                      -- Past Termination Date
                               ELSE TRUNC
                                      (SYSDATE)
                                           -- Current / Future or No Term Date
                            END
                     ELSE date_start           -- Future or Current Start Date
                  END asg_date,
                  NVL (ppos.adjusted_svc_date, ppos.date_start) rehire_date
             --FROM hr.per_periods_of_service ppos	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			 FROM apps.per_periods_of_service ppos	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
            WHERE ppos.date_start =
                     (SELECT MAX (ppos2.date_start)
                        --FROM hr.per_periods_of_service ppos2	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						FROM apps.per_periods_of_service ppos2	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                       WHERE ppos2.date_start <= SYSDATE
                         AND ppos.person_id = ppos2.person_id)
             and nvl(ppos.actual_termination_date,trunc(sysdate))  >= trunc(sysdate) - 365             
                         ) emps
    WHERE papf.business_group_id = NVL ('', papf.business_group_id)
      AND papf.person_id = paaf.person_id
      AND hla.location_id = paaf.location_id
      --AND ftv.territory_code = hla.country
      AND paaf.business_group_id != 0
      AND emps.asg_date BETWEEN paaf.effective_start_date
                            AND paaf.effective_end_date
      AND papf.person_id = paaf.person_id
      AND paaf.person_id = emps.person_id
      AND emps.asg_date BETWEEN papf.effective_start_date
                            AND papf.effective_end_date
      AND paaf.organization_id = haou.organization_id
      AND haou.cost_allocation_keyflex_id = org_alloc.cost_allocation_keyflex_id(+)
      AND gcc.code_combination_id(+) = paaf.default_code_comb_id;

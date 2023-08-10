/* Formatted on 2014/01/22 15:31 (Formatter Plus v4.8.8) */
/** Author : Kaushik Babu G - October 16 2008  Version 1.0**/
/** Desc: This particular report prints costing information for all businessgroups for finanance department
    Parameter Information 
    Business Group , Employee Number, Payroll Date (Effective_Date Range), Cost Loction (Range)
    Cost Department, Element Name , Debit amount and Credit amount 
    The Header should retrieve only one row..
    
    Fixing code for WO 542152 - Added a new parameter p_balance_cost to provide user to query for both cost & balance lines
    Fixing Code for WO 563653 - Adding new parameter for user to query by range on cost client field parameters
    Fixing Code for WO 598909 - Query by employee number and also providing user to query by departement range (adding 2 new parameters from dept and to dept)
    Fixing Code for WO 1179843 - Added logic to extract missing lines if segment2, segment3 & segment4 is null
    Fixing Code for R 547142 - Changed the whole selecting query to fix the issue when the user run with department and client parameters.
    Fixing code for I#1462592 - Removed 2 columns and rearranged certain columns as per user requirement.
	Fixing code for INC0090942 - Fixed code to get the debit summary value.
    
	NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
**/

/*** Format for Header Record **/
SET pagesize 0;
SET linesize 400;
SET wrap off;
SET feedback off;
SET verify off;
SET echo off;
SET heading off
SET termout off
SET serveroutput on

SELECT    'PAYROLL_NAME'
       || '|'
       || 'GRE'
       || '|'
       || 'LOCATION'
       || '|'
       || 'LOCAL_CURR_CODE'
       || '|'
       || 'COST_LOCATION'
       || '|'
       || 'COST_CLIENT'
       || '|'
       || 'COST_DEPARTMENT'
       || '|'
       || 'COST_ACCOUNT'
       || '|'
       || 'PAYROLL_END_DATE'
       || '|'
       || 'DEBIT_AMOUNT'
       || '|'
       || 'CREDIT_AMOUNT'
  FROM DUAL
UNION ALL
/**** Format for Detail Record ***/
SELECT    cst.payroll_name
       || '|'
       || cst.gre_name
       || '|'
       || cst.location_code
       || '|'
       || cst.input_currency_code
       || '|'
       || cst.segment1
       || '|'
       || cst.segment2
       || '|'
       || cst.segment3
       || '|'
       || cst.segment4
       || '|'
       || cst.pay_end_dt
       || '|'
       || cst.db_costed_value
       || '|'
       || cst.cr_costed_value
  FROM (SELECT   pcak.segment4, pcak.segment2, pcak.segment3, pcak.segment1,
                 SUM (DECODE (pc.debit_or_credit,
                              'C', NVL (pc.costed_value, 0),
                              0
                             )
                     ) cr_costed_value,
                 pay.payroll_name, grel.NAME gre_name, hlat.location_code,
                 petf.input_currency_code,
                 TO_CHAR (ptp.end_date, 'DD-MON-YYYY') pay_end_dt,
                 SUM (DECODE (pc.debit_or_credit,
                              'D', NVL (pc.costed_value, 0),
                              0
                             )
                     ) db_costed_value	
            --START R12.2 Upgrade Remediation
			/*FROM hr.pay_cost_allocation_keyflex pcak,
                 hr.pay_costs pc,
                 hr.pay_assignment_actions paa,
                 hr.pay_payroll_actions ppa,
                 hr.per_all_assignments_f paaf,
                 hr.per_all_people_f papf,
                 hr.per_jobs_tl pjt,
                 hr.hr_locations_all_tl hlat,
                 hr.hr_all_organization_units_tl orgl,
                 hr.pay_all_payrolls_f pay,
                 hr.pay_consolidation_sets pcs,
                 hr.per_time_periods ptp,
                 hr.hr_all_organization_units_tl grel,
                 hr.hr_all_organization_units bgr,
                 hr.hr_all_organization_units_tl bgrl,
                 hr.pay_element_types_f_tl pettl,
                 hr.pay_element_classifications_tl pectl,
                 hr.pay_element_types_f petf,
                 hr.pay_input_values_f pivf*/
			FROM apps.pay_cost_allocation_keyflex pcak,
                 apps.pay_costs pc,
                 apps.pay_assignment_actions paa,
                 apps.pay_payroll_actions ppa,
                 apps.per_all_assignments_f paaf,
                 apps.per_all_people_f papf,
                 apps.per_jobs_tl pjt,
                 apps.hr_locations_all_tl hlat,
                 apps.hr_all_organization_units_tl orgl,
                 apps.pay_all_payrolls_f pay,
                 apps.pay_consolidation_sets pcs,
                 apps.per_time_periods ptp,
                 apps.hr_all_organization_units_tl grel,
                 apps.hr_all_organization_units bgr,
                 apps.hr_all_organization_units_tl bgrl,
                 apps.pay_element_types_f_tl pettl,
                 apps.pay_element_classifications_tl pectl,
                 apps.pay_element_types_f petf,
                 apps.pay_input_values_f pivf	
			--End R12.2 Upgrade Remediation
           WHERE pc.assignment_action_id = paa.assignment_action_id
             AND hlat.location_id = NVL ('&&1', hlat.location_id)
             AND pcak.cost_allocation_keyflex_id =
                                                 pc.cost_allocation_keyflex_id
             AND ppa.payroll_action_id = paa.payroll_action_id
             AND pay.payroll_id = ppa.payroll_id
             AND pjt.job_id(+) = paaf.job_id
             AND pjt.LANGUAGE(+) LIKE 'US'
             AND hlat.location_id(+) = paaf.location_id
             AND hlat.LANGUAGE(+) LIKE 'US'
             AND orgl.organization_id(+) = paaf.organization_id
             AND orgl.LANGUAGE(+) LIKE 'US'
             AND ppa.business_group_id = bgr.organization_id
             AND bgr.organization_id = bgr.business_group_id
             AND bgrl.organization_id(+) = bgr.organization_id
             AND bgrl.LANGUAGE(+) LIKE 'US'
             AND grel.organization_id(+) = paa.tax_unit_id
             AND grel.LANGUAGE(+) LIKE 'US'
             AND paa.assignment_id = paaf.assignment_id
             AND paaf.person_id = papf.person_id
             AND (   pcak.segment1 BETWEEN NVL ('&&8', pcak.segment1)
                                       AND NVL ('&&9', pcak.segment1)
                  OR pcak.segment1 = NVL ('&&8', pcak.segment1)
                  OR pcak.segment1 = NVL ('&&9', pcak.segment1)
                 )
             AND (   pcak.segment2 BETWEEN NVL ('&&15', pcak.segment2)
                                       AND NVL ('&&16', pcak.segment2)
                  OR pcak.segment2 = NVL ('&&15', pcak.segment2)
                  OR pcak.segment2 = NVL ('&&16', pcak.segment2)
                 )
             AND (   pcak.segment3 BETWEEN NVL ('&&10', pcak.segment3)
                                       AND NVL ('&&11', pcak.segment3)
                  OR pcak.segment3 = NVL ('&&10', pcak.segment3)
                  OR pcak.segment3 = NVL ('&&11', pcak.segment3)
                 )
             AND (   pcak.segment4 BETWEEN NVL ('&&5', pcak.segment4)
                                       AND NVL ('&&6', pcak.segment4)
                  OR pcak.segment4 = NVL ('&&5', pcak.segment4)
                  OR pcak.segment4 = NVL ('&&6', pcak.segment4)
                 )
             AND ptp.payroll_id = ppa.payroll_id
             AND ppa.consolidation_set_id = pcs.consolidation_set_id
             AND ppa.date_earned BETWEEN ptp.start_date AND ptp.end_date
             AND pivf.element_type_id = petf.element_type_id
             AND pivf.input_value_id = pc.input_value_id
             AND pettl.element_type_id(+) = petf.element_type_id
             AND pettl.LANGUAGE(+) LIKE 'US'
             AND pectl.classification_id(+) = petf.classification_id
             AND pectl.LANGUAGE(+) LIKE 'US'
             AND ppa.effective_date BETWEEN pivf.effective_start_date
                                        AND pivf.effective_end_date
             AND ppa.effective_date BETWEEN petf.effective_start_date
                                        AND petf.effective_end_date
             AND ppa.effective_date BETWEEN pay.effective_start_date
                                        AND pay.effective_end_date
             AND ppa.effective_date BETWEEN paaf.effective_start_date
                                        AND paaf.effective_end_date
             AND ppa.effective_date BETWEEN papf.effective_start_date
                                        AND papf.effective_end_date
             AND petf.element_name LIKE NVL ('&&7', petf.element_name)
             AND papf.employee_number LIKE NVL ('&&17', papf.employee_number)
             AND papf.business_group_id = NVL ('&&2', papf.business_group_id)
             AND pc.balance_or_cost LIKE NVL ('&&14', '%')
             AND ppa.effective_date
                    BETWEEN TO_CHAR (TO_DATE ('&&3', 'YYYY/MM/DD HH24:MI:SS'),
                                     'DD-MON-YYYY'
                                    )
                        AND TO_CHAR (TO_DATE ('&&4', 'YYYY/MM/DD HH24:MI:SS'),
                                     'DD-MON-YYYY'
                                    )
        GROUP BY pcak.segment4,
                 pcak.segment2,
                 pcak.segment3,
                 pcak.segment1,
                 pay.payroll_name,
                 grel.NAME,
                 hlat.location_code,
                 petf.input_currency_code,
                 TO_CHAR (ptp.end_date, 'DD-MON-YYYY')
        ORDER BY pay.payroll_name,
                 grel.NAME,
                 hlat.location_code,
                 TO_CHAR (ptp.end_date, 'DD-MON-YYYY')) cst
 WHERE (   TRIM (cr_costed_value) = NVL ('&&12', TRIM (cr_costed_value))
        OR 1 = NVL ('&&12', 1)
       )
   AND (   TRIM (db_costed_value) = NVL ('&&13', TRIM (db_costed_value))
        OR 1 = NVL ('&&13', 1)
       );
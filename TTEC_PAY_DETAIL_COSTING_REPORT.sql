/* Formatted on 2011/02/09 16:04 (Formatter Plus v4.8.8) */
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
	Fixing code for TASK1651700 - Modified code to get the proper the pay period start_date and end_date
	Fixing code for TASK3030083 - Modified code to increase LINESIZE 400 to 2000
    NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
**/

/*** Format for Header Record **/
SET PAGESIZE 0;

SET LINESIZE 500;

SET WRAP OFF;

SET FEEDBACK OFF;

SET VERIFY OFF;

SET ECHO OFF;

SET HEADING OFF

SET TERMOUT OFF

SET SERVEROUTPUT ON

/* Formatted on 2011/02/09 16:05 (Formatter Plus v4.8.8) */

SELECT
    'EMPLOYEE_NAME'
    || '|'
    || 'EMPLOYEE_NUMBER'
    || '|'
    || 'BALANCE_OR_COST'
    || '|'
    || 'PAYROLL_NAME'
    || '|'
    || 'DATE_EFFECTIVE'
    || '|'
    || 'GRE'
    || '|'
    || 'JOB_NAME'
    || '|'
    || 'LOCATION'
    || '|'
    || 'EMP_ORG_NAME'
    || '|'
    || 'PAYROLL_CONSOLIDATION_SET'
    || '|'
    || 'COST_LOCATION'
    || '|'
    || 'COST_CLIENT'
    || '|'
    || 'COST_DEPARTMENT'
    || '|'
    || 'COST_ACCOUNT'
    || '|'
    || 'ELEMENT_CLASSIFICATION'
    || '|'
    || 'ELEMENT_NAME'
    || '|'
    || 'DEBIT_AMOUNT'
    || '|'
    || 'CREDIT_AMOUNT'
    || '|'
    || 'LOCAL_CURR_CODE'
    || '|'
    || 'DATE_EARNED'
    || '|'
    || 'PAYROLL_START_DATE'
    || '|'
    || 'PAYROLL_END_DATE'
FROM
    dual
UNION ALL
/**** Format for Detail Record ***/
SELECT
    cst.full_name
    || '|'
    || cst.employee_number
    || '|'
    || cst.balance_or_cost
    || '|'
    || cst.payroll_name
    || '|'
    || cst.effective_date
    || '|'
    || cst.gre_name
    || '|'
    || cst.job_name
    || '|'
    || cst.location_code
    || '|'
    || cst.emp_org_name
    || '|'
    || cst.consolidation_set_name
    || '|'
    || cst.segment1
    || '|'
    || cst.segment2
    || '|'
    || cst.segment3
    || '|'
    || cst.segment4
    || '|'
    || cst.classification_name
    || '|'
    || cst.element_name
    || '|'
    || cst.db_costed_value
    || '|'
    || cst.cr_costed_value
    || '|'
    || cst.input_currency_code
    || '|'
    || cst.date_earned
    || '|'
    || cst.start_date
    || '|'
    || cst.end_date
FROM
    (   /* Start changes as part of TASK1651700 */
        SELECT
            a.*,
            ppa1.date_earned,
            ptp.start_date,
            ptp.end_date,
            ptp.period_name
        FROM
            (   /* End changes as part of TASK1651700 */
                SELECT
                    papf.full_name,
                    papf.employee_number,
                    papf.national_identifier,
                    pc.balance_or_cost,
                    bgrl.name   business_group_name,
                    ppa.effective_date,
                    grel.name   gre_name,
                    pjt.name    job_name,
                    hlat.location_code,
                    orgl.name   emp_org_name,
                    pcs.consolidation_set_name,
                    pcak.segment4,
                    pcak.segment2,
                    pcak.segment3,
                    pcak.segment1,
                    pectl.classification_name,
                    petf.element_name,
                    DECODE(pc.debit_or_credit, 'C', nvl(pc.costed_value, 0), 0) cr_costed_value,
                    DECODE(pc.debit_or_credit, 'D', nvl(pc.costed_value, 0), 0) db_costed_value,
                    petf.input_currency_code,
                    pay.payroll_name,
                    /* Start changes as part of TASK1651700 */
                    paa.assignment_action_id,
                    (
                        SELECT
                            MAX(locked_action_id)
                        FROM
                            pay_action_interlocks
                        WHERE
                            locking_action_id = paa.assignment_action_id
                    ) locked_action_id
                    --ptp.start_date,
                    --ptp.end_date,
                    /* End changes as part of TASK1651700 */
                --START R12.2 Upgrade Remediation
				/*FROM
                    hr.pay_cost_allocation_keyflex      pcak,
                    hr.pay_costs                        pc,
                    hr.pay_assignment_actions           paa,
                    hr.pay_payroll_actions              ppa,
                    hr.per_all_assignments_f            paaf,
                    hr.per_all_people_f                 papf,
                    hr.per_jobs_tl                      pjt,
                    hr.hr_locations_all_tl              hlat,
                    hr.hr_all_organization_units_tl     orgl,
                    hr.pay_all_payrolls_f               pay,
                    hr.pay_consolidation_sets           pcs,
                    --hr.per_time_periods ptp, Commented as part of TASK1651700
                    hr.hr_all_organization_units_tl     grel,
                    hr.hr_all_organization_units        bgr,
                    hr.hr_all_organization_units_tl     bgrl,
                    hr.pay_element_types_f_tl           pettl,
                    hr.pay_element_classifications_tl   pectl,
                    hr.pay_element_types_f              petf,
                    hr.pay_input_values_f               pivf*/
				FROM
                    apps.pay_cost_allocation_keyflex      pcak,
                    apps.pay_costs                        pc,
                    apps.pay_assignment_actions           paa,
                    apps.pay_payroll_actions              ppa,
                    apps.per_all_assignments_f            paaf,
                    apps.per_all_people_f                 papf,
                    apps.per_jobs_tl                      pjt,
                    apps.hr_locations_all_tl              hlat,
                    apps.hr_all_organization_units_tl     orgl,
                    apps.pay_all_payrolls_f               pay,
                    apps.pay_consolidation_sets           pcs,
                    --hr.per_time_periods ptp, Commented as part of TASK1651700
                    apps.hr_all_organization_units_tl     grel,
                    apps.hr_all_organization_units        bgr,
                    apps.hr_all_organization_units_tl     bgrl,
                    apps.pay_element_types_f_tl           pettl,
                    apps.pay_element_classifications_tl   pectl,
                    apps.pay_element_types_f              petf,
                    apps.pay_input_values_f               pivf
				--End R12.2 Upgrade Remediation
                WHERE
                    pc.assignment_action_id = paa.assignment_action_id
                    AND hlat.location_id = nvl('&&1', hlat.location_id)
                    AND pcak.cost_allocation_keyflex_id = pc.cost_allocation_keyflex_id
                    AND ppa.payroll_action_id = paa.payroll_action_id
                    AND pay.payroll_id = ppa.payroll_id
                    AND pjt.job_id (+) = paaf.job_id
                    AND pjt.language (+) LIKE 'US'
                    AND hlat.location_id (+) = paaf.location_id
                    AND hlat.language (+) LIKE 'US'
                    AND orgl.organization_id (+) = paaf.organization_id
                    AND orgl.language (+) LIKE 'US'
                    AND ppa.business_group_id = bgr.organization_id
                    AND bgr.organization_id = bgr.business_group_id
                    AND bgrl.organization_id (+) = bgr.organization_id
                    AND bgrl.language (+) LIKE 'US'
                    AND grel.organization_id (+) = paa.tax_unit_id
                    AND grel.language (+) LIKE 'US'
                    AND paa.assignment_id = paaf.assignment_id
                    AND paaf.person_id = papf.person_id
                    AND ( pcak.segment1 BETWEEN nvl('&&8', pcak.segment1) AND nvl('&&9', pcak.segment1)
                          OR pcak.segment1 = nvl('&&8', pcak.segment1)
                          OR pcak.segment1 = nvl('&&9', pcak.segment1) )
                    AND ( pcak.segment2 BETWEEN nvl('&&15', pcak.segment2) AND nvl('&&16', pcak.segment2)
                          OR pcak.segment2 = nvl('&&15', pcak.segment2)
                          OR pcak.segment2 = nvl('&&16', pcak.segment2) )
                    AND ( pcak.segment3 BETWEEN nvl('&&10', pcak.segment3) AND nvl('&&11', pcak.segment3)
                          OR pcak.segment3 = nvl('&&10', pcak.segment3)
                          OR pcak.segment3 = nvl('&&11', pcak.segment3) )
                    AND ( pcak.segment4 BETWEEN nvl('&&5', pcak.segment4) AND nvl('&&6', pcak.segment4)
                          OR pcak.segment4 = nvl('&&5', pcak.segment4)
                          OR pcak.segment4 = nvl('&&6', pcak.segment4) ) 
                    --AND ptp.payroll_id = ppa.payroll_id --Commented as part of TASK1651700
                    AND ppa.consolidation_set_id = pcs.consolidation_set_id
                    --AND ppa.date_earned BETWEEN ptp.start_date AND ptp.end_date --Commented as part of TASK1651700
                    AND pivf.element_type_id = petf.element_type_id
                    AND pivf.input_value_id = pc.input_value_id
                    AND pettl.element_type_id (+) = petf.element_type_id
                    AND pettl.language (+) LIKE 'US'
                    AND pectl.classification_id (+) = petf.classification_id
                    AND pectl.language (+) LIKE 'US'
                    AND ppa.effective_date BETWEEN pivf.effective_start_date AND pivf.effective_end_date
                    AND ppa.effective_date BETWEEN petf.effective_start_date AND petf.effective_end_date
                    AND ppa.effective_date BETWEEN pay.effective_start_date AND pay.effective_end_date
                    AND ppa.effective_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
                    AND ppa.effective_date BETWEEN papf.effective_start_date AND papf.effective_end_date
                    AND petf.element_name LIKE nvl('&&7', petf.element_name)
                    AND papf.employee_number LIKE nvl('&&17', papf.employee_number)
                    AND papf.business_group_id = nvl('&&2', papf.business_group_id)
                    AND pc.balance_or_cost LIKE nvl('&&14', '%')
                    AND ppa.effective_date BETWEEN TO_CHAR(TO_DATE('&&3', 'YYYY/MM/DD HH24:MI:SS'), 'DD-MON-YYYY') AND TO_CHAR(TO_DATE
                    ('&&4', 'YYYY/MM/DD HH24:MI:SS'), 'DD-MON-YYYY')
            /* Start changes as part of TASK1651700 */
            ) a,
            hr.pay_assignment_actions   paa1,
            hr.pay_payroll_actions      ppa1,
            hr.per_time_periods         ptp
        WHERE
            a.locked_action_id = paa1.assignment_action_id
            AND ppa1.payroll_action_id = paa1.payroll_action_id
            AND ptp.payroll_id = ppa1.payroll_id
            AND nvl(ppa1.date_earned, ppa1.effective_date) BETWEEN ptp.start_date AND ptp.end_date
            /* End changes as part of TASK1651700 */
    ) cst
WHERE
    ( TRIM(cr_costed_value) = nvl('&&12', TRIM(cr_costed_value))
      OR 1 = nvl('&&12', 1) )
    AND ( TRIM(db_costed_value) = nvl('&&13', TRIM(db_costed_value))
          OR 1 = nvl('&&13', 1) );
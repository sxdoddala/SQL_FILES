/* Formatted on 2011/04/11 11:04 (Formatter Plus v4.8.8) */
/** Author : Kaushik Babu G - March 08 2011  Version 1.0**/
/** Desc: This particular report prints costing errors for all business groups, Useful for finanance department
    Parameter Information 
    Business Group , Employee Number, execution start date, execution end date, business_group_name, request id.  

	Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |  
**/

/*** Format for Header Record **/
SET pagesize 0
SET linesize 400
SET wrap off
SET feedback off
SET verify off
SET echo off
SET heading off
SET termout off
SET serveroutput on

SELECT    'APPLICATION_CODE'
       || '|'
       || 'INTERFACE'
       || '|'
       || 'PROGRAM_NAME'
       || '|'
       || 'MODULE_NAME'
       || '|'
       || 'CONCURRENT_REQUEST_ID'
       || '|'
       || 'EXECUTION_DATE'
       || '|'
       || 'STATUS'
       || '|'
       || 'ERROR_MESSAGE'
       || '|'
       || 'LABEL1'
       || '|'
       || 'REFERENCE1'
       || '|'
       || 'LABEL2'
       || '|'
       || 'REFERENCE2'
       || '|'
       || 'USER_CONCURRENT_PROGRAM_NAME'
       || '|'
       || 'EMPLOYEE_NUMBER'
       || '|'
       || 'BUSINESS_GROUP_NAME'
       || '|'
       || 'PAYROLL_NAME'
  FROM DUAL
UNION
SELECT    cst.application_code
       || '|'
       || cst.INTERFACE
       || '|'
       || cst.program_name
       || '|'
       || cst.module_name
       || '|'
       || cst.concurrent_request_id
       || '|'
       || cst.execution_date
       || '|'
       || cst.status
       || '|'
       || cst.error_message
       || '|'
       || cst.label1
       || '|'
       || cst.reference1
       || '|'
       || cst.label2
       || '|'
       || cst.reference2
       || '|'
       || cst.user_concurrent_program_name
       || '|'
       || cst.employee_number
       || '|'
       || cst.business_group_name
       || '|'
       || cst.payroll_name
  FROM (SELECT   teh.application_code, teh.INTERFACE, teh.program_name, teh.module_name,
                 teh.concurrent_request_id, teh.execution_date, teh.status, teh.error_message,
                 teh.label1, teh.reference1, teh.label2, teh.reference2,
                 fcpt.user_concurrent_program_name, SUBSTR (paaf.assignment_number, 1,
                                                            7) employee_number,
                 pbg.NAME business_group_name, ppf.payroll_name
            --FROM cust.ttec_error_handling teh,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  FROM apps.ttec_error_handling teh,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
                 apps.fnd_concurrent_requests fcr,
                 apps.fnd_concurrent_programs_tl fcpt,
                 apps.per_all_assignments_f paaf,
                 apps.per_business_groups pbg,
                 apps.pay_payrolls_f ppf
           WHERE teh.program_name IN ('TTEC_ASSIGN_COSTING_RULES', 'TTEC_PAY_FIN_CUST_COSTING')
             AND TRUNC (execution_date) BETWEEN fnd_date.canonical_to_date ('&&1')
                                            AND fnd_date.canonical_to_date ('&&2')
             AND teh.concurrent_request_id = NVL ('&&3', teh.concurrent_request_id)
             AND paaf.business_group_id = NVL ('&&4', paaf.business_group_id)
             AND SUBSTR (paaf.assignment_number, 1, 7) =
                                                       NVL ('&&5', SUBSTR (paaf.assignment_number, 1, 7))
             AND teh.concurrent_request_id = fcr.request_id
             AND fcr.concurrent_program_id = fcpt.concurrent_program_id
             AND fcpt.LANGUAGE = 'US'
             AND paaf.primary_flag = 'Y'
             AND fcpt.user_concurrent_program_name LIKE
                                                 'TeleTech Custom Costing%Offset Balance Program - 2010%'
             AND TO_NUMBER (teh.reference1) = paaf.assignment_id
             AND paaf.payroll_id = ppf.payroll_id
             AND TRUNC (execution_date) BETWEEN ppf.effective_start_date AND ppf.effective_end_date
             AND TRUNC (execution_date) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
             AND paaf.business_group_id = pbg.business_group_id
             AND TRUNC (execution_date) BETWEEN pbg.date_from AND NVL (pbg.date_to, TRUNC (SYSDATE))
        UNION ALL
        SELECT   teh.application_code, teh.INTERFACE, teh.program_name, teh.module_name,
                 teh.concurrent_request_id, teh.execution_date, teh.status, teh.error_message,
                 teh.label1, teh.reference1, teh.label2, teh.reference2, '' user_concurrent_program_name,
                 '' employee_number, '' business_group_name, '' payroll_name
            --FROM cust.ttec_error_handling teh,  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			 FROM apps.ttec_error_handling teh,  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                 apps.fnd_concurrent_requests fcr,
                 apps.fnd_concurrent_programs_tl fcpt
           WHERE teh.program_name IN ('TTEC_ASSIGN_COSTING_RULES', 'TTEC_PAY_FIN_CUST_COSTING')
             AND TRUNC (execution_date) BETWEEN fnd_date.canonical_to_date ('&&1')
                                            AND fnd_date.canonical_to_date ('&&2')
             AND teh.concurrent_request_id = NVL ('&&3', teh.concurrent_request_id)
             AND teh.concurrent_request_id = fcr.request_id
             AND fcr.concurrent_program_id = fcpt.concurrent_program_id
             AND fcpt.LANGUAGE = 'US'
             AND teh.reference1 IS NULL
             AND fcpt.user_concurrent_program_name LIKE
                                                  'TeleTech Custom Costing%Offset Balance Program - 2010'
        ORDER BY 5) cst
/

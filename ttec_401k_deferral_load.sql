/* Formatted on 5/17/2011 6:16:34 PM (QP5 v5.163.1008.3004) */
--******************************************************************************--
--*Program Name: ttec_401k_deferral_load.sql                                   *--
--*                                                                            *--
--*                                                                            *--
--*Desciption: This program will accomplish the following:                     *--
--*            Read employee information which was supplied by Wachovia        *--
--*            from a temporary table                                          *--
--*            A report is generated for all termed employees received         *--
--*            from Wachovia.                                                  *--
--*        Then the program checks if active employee as supplied by           *--
--*     Wachovia is active in the system, If not,the information on this       *--
--*     employee is written in an error file.                                  *--
--*     If employee is active, the employee's information is process           *--
--*     as follows:                                                            *--
--*    If dropping 401K, call PAY_ELEMENT_ENTRY_API.DELETE_ELEMENT_ENTRY       *--
--*    If changing 401K percentages call                                       *--
--*                PAY_ELEMENT_ENTRY_API.UPDATE_ELEMENT_ENTRY                  *--
--*    IF new 401K entry call
--*            PAY_ELEMENT_ENTRY_API.CREATE_ELEMENT_ENTRY                      *--
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
--*Tables Modified: PAY_ELEMENT_ENTRY_VALUES_F                                   *--
--*                                                                            *--
--*Procedures Called: PY_ELEMENT_ENTRY.create_element_entry                    *--
--*                  PAY_ELEMENT_ENTRY_API.DELETE_ELEMENT_ENTRY                *--
--*                  PAY_ELEMENT_ENTRY_API.UPDATE_ELEMENT_ENTRY                *--
--*
--*                                                                            *--
--*Created By: Elizur Alfred-Ockiya                                            *--
--*Date: 19-AUG-04                                                             *--
--*                                                                            *--
--*Modification Log:                                                           *--
--*Developer             Date        Description                               *--
--*---------            ----        -----------                                *--
--* E.Alfred-Ockiya     15-FEB-2005   File created                                   *---
--* E.Alfred-Ockiya     08-MAR-2005   Modified                                      *---
--* E.Alfred-Ockiya     10-MAY-2005   Modified to include new elements            *--
--*                                'Pre Tax 401K';
--*                                'Pre Tax 401K Catchup';
--* W Manasfi    v2.0   15-MAY-2011    Fixed element to check for active elements only    on pay_element_types_f  + ttec_lib
--* W Manasfi    v2.1   07-JUN-2011    Do not delete elements just update them.  643323 
--  NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation  
--******************************************************************************--

SET TIMING ON;
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
   /***Variables used by Common Error Procedure***/
   g_validate              BOOLEAN := FALSE;
   g_entry_type            VARCHAR2 (1) := 'E';

   p_deferral_active       VARCHAR2 (50) := 'Deferral_Active.txt';
   p_deferral_termed       VARCHAR2 (50) := 'Deferral_Wachovia_Termed.txt';
   p_deferral_errorlog     VARCHAR2 (50) := 'Deferral_ErrorLog.txt';
   p_deferral_oratermed    VARCHAR2 (50) := 'Deferral_Oracle_Termed.txt';


   l_errorlog_output       CHAR (242);
   l_updated_output        CHAR (242);
   l_update_status         VARCHAR2 (150) := 'Did Not Update';

   v_oratermed_file        UTL_FILE.FILE_TYPE;
   v_active_file           UTL_FILE.FILE_TYPE;
   v_termed_file           UTL_FILE.FILE_TYPE;
   v_errorlog_file         UTL_FILE.FILE_TYPE;


   v_errorlog_count        NUMBER := 0;
   v_updated_count         NUMBER := 0;
   --*****************************************************************************************************

   --g_element_name VARCHAR2(50):= 'US 401K';
   g_input_name            VARCHAR2 (50) := 'Percentage';

   g_elementnew_name       VARCHAR2 (50) := 'Pre Tax 401K';
   g_elementcatchup_name   VARCHAR2 (50) := 'Pre Tax 401K Catchup';


   ERRBUF                  VARCHAR2 (50);
   RETCODE                 NUMBER;
   P_OUTPUT_DIR            VARCHAR2 (240);
   /***Exceptions***/

   SKIP_RECORD             EXCEPTION;
   SKIP_RECORD2            EXCEPTION;
   SKIP_RECORD3            EXCEPTION;

   /***Cursor declaration***/


   CURSOR csr_deferral
   IS
        SELECT DISTINCT def.T_TYPE trans_type,
                        def.SS_NUMBER social_number,
                        TRUNC (SYSDATE) deferral_date--, to_date('26-MAY-2005')                   deferral_date
                        ,
                        def.MONEY_TYPE money_type,
                        def.DEFERRAL_PCT deferral_pct,
                        def.STATUS_CODE status_code,
                        def.EMPLOYEE_INDICATOR employee_indicator,
                        def.PLAN_ENTRY_DATE plan_entry_date,
                        def.UNIT_DIVISION unit_division,
                        def.EXTRA_UNIT_CODE extra_unit_code,
                        def.DOLLAR_AMOUNT_REQUESTED dollar_amount_requested,
                        def.ATTRIBUTE1 plan_type_id,
                        def.ATTRIBUTE2 plan_type,
                        def.ATTRIBUTE3 attribute3
          --FROM CUST.ttec_us_deferral_tbl def	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  FROM APPS.ttec_us_deferral_tbl def	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
         WHERE def.t_type = '2'
               AND def.status_code IN
                      ('ACTV',
                       'AUTO',
                       'INEL',
                       'DISB',
                       'INAC',
                       'INEL',
                       'LEAV',
                       'RETD',
                       'SUSC',
                       'ELND',
                       'TRES')
      --and rownum < 3
    --   and def.ss_number = '600-42-2880' 
      ORDER BY def.attribute1 DESC;

   --order by def.ss_number;
   -- and emp.employee_number = 3115964 ;
   --and emp.national_identifier = '600-14-5499';

   CURSOR csr_termed_def
   IS
        SELECT DISTINCT def.T_TYPE trans_type,
                        def.SS_NUMBER social_number,
                        TRUNC (SYSDATE) deferral_date--, to_date('26-MAY-2005')                   deferral_date
                        ,
                        def.MONEY_TYPE money_type,
                        def.DEFERRAL_PCT deferral_pct,
                        def.STATUS_CODE status_code,
                        def.EMPLOYEE_INDICATOR employee_indicator,
                        def.PLAN_ENTRY_DATE plan_entry_date,
                        def.UNIT_DIVISION unit_division,
                        def.EXTRA_UNIT_CODE extra_unit_code,
                        def.DOLLAR_AMOUNT_REQUESTED dollar_amount_requested,
                        def.ATTRIBUTE1 plan_type_id,
                        def.ATTRIBUTE2 plan_type,
                        def.ATTRIBUTE3 attribute3
          --FROM cust.ttec_us_deferral_tbl def	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  FROM apps.ttec_us_deferral_tbl def	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
         WHERE def.t_type = '2' AND def.status_code IN ('DTH', 'TERM', 'LAYO')
      --   and def.ss_number = '600-42-2880' 
      --and rownum < 3
      ORDER BY def.attribute1 DESC;

   --************************************************************************************--
   --*                          GET ASSIGNMENT ID                                       *--
   --************************************************************************************--

   PROCEDURE get_termed_assignment_id (v_ssn                    IN     VARCHAR2,
                                       v_employee_number           OUT VARCHAR2,
                                       p_assignment_id             OUT NUMBER,
                                       p_business_group_id         OUT NUMBER,
                                       p_effective_start_date      OUT DATE,
                                       p_effective_end_date        OUT DATE)
   IS
   BEGIN
      --             l_error_message    := NULL;

      SELECT DISTINCT asg.assignment_id,
                      emp.employee_number,
                      asg.business_group_id,
                      asg.effective_start_date,
                      asg.effective_end_date
        INTO p_assignment_id,
             v_employee_number,
             p_business_group_id,
             p_effective_start_date,
             p_effective_end_date
        --FROM hr.per_all_assignments_f asg, hr.per_all_people_f emp -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM apps.per_all_assignments_f asg, apps.per_all_people_f emp -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
       WHERE emp.national_identifier = v_ssn
             AND emp.person_id = asg.person_id
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             AND asg.effective_start_date =
                    (SELECT MAX (asg1.effective_start_date)
                       FROM per_all_assignments_f asg1
                      WHERE     asg1.person_id = asg.person_id
                            AND asg1.primary_flag = 'Y'
                            AND asg1.assignment_type = 'E');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'No Assignment');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD3;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Assignments');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD3;
      WHEN OTHERS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Other Assignment Issue');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD3;
   END;                                       --*** END GET ASSIGNMENT ID***--

   ---***********************************  Get Location Code ********************************-----

   PROCEDURE get_termed_location (v_ssn             IN     VARCHAR2,
                                  v_unit_division   IN     VARCHAR2,
                                  v_location_code      OUT VARCHAR2)
   IS
      l_location_code   VARCHAR2 (150) := NULL;
   BEGIN
      SELECT DISTINCT loc.location_code
        INTO l_location_code
		--START R12.2 Upgrade Remediation
        /*FROM hr.per_all_people_f emp,
             hr.per_all_assignments_f asg,
             hr.hr_locations_all loc*/
		FROM apps.per_all_people_f emp,
             apps.per_all_assignments_f asg,
             apps.hr_locations_all loc	 
		--End R12.2 Upgrade Remediation	 
       WHERE     emp.person_id = asg.person_id
             AND loc.location_id = asg.location_id
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             --   and loc.attribute2  = v_unit_division
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                     AND asg.effective_end_date
             AND emp.national_identifier = v_ssn;

      --and emp.national_identifier = '053-60-6407'--v_ssn

      v_location_code := l_location_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || v_unit_division || 'No Location');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD3;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Locations');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD3;
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || v_unit_division || 'No Other Location');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD3;
   END;

   --***************************************************************
   --************************************************************************************--
   --*                          GET ASSIGNMENT ID                                       *--
   --************************************************************************************--

   PROCEDURE get_assignment_id (v_ssn                    IN     VARCHAR2,
                                v_employee_number           OUT VARCHAR2,
                                p_assignment_id             OUT NUMBER,
                                p_business_group_id         OUT NUMBER,
                                p_effective_start_date      OUT DATE,
                                p_effective_end_date        OUT DATE)
   IS
   BEGIN
      --             l_error_message    := NULL;

      SELECT DISTINCT asg.assignment_id,
                      emp.employee_number,
                      asg.business_group_id,
                      asg.effective_start_date,
                      asg.effective_end_date
        INTO p_assignment_id,
             v_employee_number,
             p_business_group_id,
             p_effective_start_date,
             p_effective_end_date
        --FROM hr.per_all_assignments_f asg, hr.per_all_people_f emp	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM apps.per_all_assignments_f asg, apps.per_all_people_f emp	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
       WHERE emp.national_identifier = v_ssn
             AND emp.person_id = asg.person_id
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             AND asg.effective_start_date =
                    (SELECT MAX (asg1.effective_start_date)
                       FROM per_all_assignments_f asg1
                      WHERE     asg1.person_id = asg.person_id
                            AND asg1.primary_flag = 'Y'
                            AND asg1.assignment_type = 'E');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'No Assignment');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Assignments');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Other Assignment Issue');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
   END;                                       --*** END GET ASSIGNMENT ID***--

   ---***********************************  Get Location Code ********************************-----

   PROCEDURE get_location (v_ssn             IN     VARCHAR2,
                           v_unit_division   IN     VARCHAR2,
                           v_location_code      OUT VARCHAR2)
   IS
      l_location_code   VARCHAR2 (150) := NULL;
   BEGIN
      SELECT DISTINCT loc.location_code
        INTO l_location_code
		--START R12.2 Upgrade Remediation
        /*FROM hr.per_all_people_f emp,
             hr.per_all_assignments_f asg,
             hr.hr_locations_all loc*/
		FROM apps.per_all_people_f emp,
             apps.per_all_assignments_f asg,
             apps.hr_locations_all loc	 
		--End R12.2 Upgrade Remediation	 
       WHERE     emp.person_id = asg.person_id
             AND loc.location_id = asg.location_id
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             --   and loc.attribute2  = v_unit_division
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                     AND asg.effective_end_date
             AND emp.national_identifier = v_ssn;

      --and emp.national_identifier = '053-60-6407'--v_ssn

      v_location_code := l_location_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || v_unit_division || 'No Location');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Locations');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || v_unit_division || 'No Other Location');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
   END;

   --***************************************************************
   --*****                  GET PERSON TYPE                *****
   --***************************************************************
   --get_person_type(sel.employee_number, l_system_person_type);
   PROCEDURE get_person_type (v_ssn                   IN     VARCHAR2,
                              v_person_id                OUT NUMBER,
                              v_assignment_id         IN     NUMBER,
                              v_pay_basis_id             OUT NUMBER,
                              v_employment_category      OUT VARCHAR2,
                              v_people_group_id          OUT NUMBER,
                              v_system_person_type       OUT VARCHAR2)
   IS
      v_effective_end_date   DATE := NULL;
   BEGIN
      SELECT DISTINCT asg.person_id,
                      asg.effective_end_date,
                      asg.pay_basis_id,
                      asg.employment_category,
                      asg.people_group_id,
                      types.system_person_type
        INTO v_person_id,
             v_effective_end_date,
             v_pay_basis_id,
             v_employment_category,
             v_people_group_id,
             v_system_person_type
		--START R12.2 Upgrade Remediation	 
        /*FROM hr.per_all_assignments_f asg,
             hr.per_all_people_f emp,
             hr.per_person_types types*/
		FROM apps.per_all_assignments_f asg,
             apps.per_all_people_f emp,
             apps.per_person_types types	 
		--End R12.2 Upgrade Remediation	 
       WHERE     emp.person_id = asg.person_id
             AND types.person_type_id = emp.person_type_id
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                     AND asg.effective_end_date
             AND emp.national_identifier = v_ssn;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output :=
            (   RPAD (v_ssn, 29)
             || RPAD (v_person_id, 20)
             || LPAD (v_effective_end_date, 12)
             || 'No Person Type');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Person Types');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (   RPAD (v_ssn, 29)
             || RPAD (v_person_id, 20)
             || LPAD (v_effective_end_date, 12)
             || 'No Person Type');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
   END;

   ----*******************************************************************---------------------
   --get_employee_status(sel.social_number,l_system_person_status);
   PROCEDURE get_termed_status (v_ssn                    IN     VARCHAR2,
                                v_system_person_status      OUT VARCHAR2)
   IS
      l_system_person_status   VARCHAR2 (50) := NULL;
   BEGIN
      SELECT DISTINCT NVL (amdtl.user_status, sttl.user_status)
        INTO l_system_person_status
		--START R12.2 Upgrade Remediation
        /*FROM hr.per_all_people_f emp,
             hr.per_all_assignments_f asg,
             hr.per_person_types types,
             hr.per_ass_status_type_amends_tl amdtl,
             hr.per_assignment_status_types_tl sttl,
             hr.per_assignment_status_types st,
             hr.per_ass_status_type_amends amd*/
		FROM apps.per_all_people_f emp,
             apps.per_all_assignments_f asg,
             apps.per_person_types types,
             apps.per_ass_status_type_amends_tl amdtl,
             apps.per_assignment_status_types_tl sttl,
             apps.per_assignment_status_types st,
             apps.per_ass_status_type_amends amd	 
		--End R12.2 Upgrade Remediation	 
       WHERE emp.person_id = asg.person_id
             AND asg.assignment_status_type_id = st.assignment_status_type_id
             AND asg.assignment_status_type_id =
                    amd.assignment_status_type_id(+)
             AND asg.business_group_id + 0 = amd.business_group_id(+) + 0
             AND types.person_type_id = emp.person_type_id
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             AND asg.business_group_id = 325
             AND st.assignment_status_type_id =
                    sttl.assignment_status_type_id
             AND sttl.LANGUAGE = USERENV ('LANG')
             AND amd.ass_status_type_amend_id =
                    amdtl.ass_status_type_amend_id(+)
             AND DECODE (amdtl.ass_status_type_amend_id,
                         NULL, '1',
                         amdtl.LANGUAGE) =
                    DECODE (amdtl.ass_status_type_amend_id,
                            NULL, '1',
                            USERENV ('LANG'))
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                     AND asg.effective_end_date
             AND emp.national_identifier = v_ssn;

      --and rownum < 2;

      v_system_person_status := l_system_person_status;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'No Employee Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD3;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Too Many Employees Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD3;
      WHEN OTHERS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Other Reason for Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD3;
   END;

   ----***************************************************************************-------------


   ---**************************************************************************************
   --get_employee_status(sel.social_number,l_system_person_status);
   PROCEDURE get_employee_status (v_ssn                    IN     VARCHAR2,
                                  v_system_person_status      OUT VARCHAR2)
   IS
      l_system_person_status   VARCHAR2 (50) := NULL;
   BEGIN
      SELECT DISTINCT NVL (amdtl.user_status, sttl.user_status)
        INTO l_system_person_status
		--START R12.2 Upgrade Remediation
        /*FROM hr.per_all_people_f emp,
             hr.per_all_assignments_f asg,
             hr.per_person_types types,
             hr.per_ass_status_type_amends_tl amdtl,
             hr.per_assignment_status_types_tl sttl,
             hr.per_assignment_status_types st,
             hr.per_ass_status_type_amends amd*/
		FROM apps.per_all_people_f emp,
             apps.per_all_assignments_f asg,
             apps.per_person_types types,
             apps.per_ass_status_type_amends_tl amdtl,
             apps.per_assignment_status_types_tl sttl,
             apps.per_assignment_status_types st,
             apps.per_ass_status_type_amends amd	 
		--End R12.2 Upgrade Remediation	 
       WHERE emp.person_id = asg.person_id
             AND asg.assignment_status_type_id = st.assignment_status_type_id
             AND asg.assignment_status_type_id =
                    amd.assignment_status_type_id(+)
             AND asg.business_group_id + 0 = amd.business_group_id(+) + 0
             AND types.person_type_id = emp.person_type_id
             AND asg.primary_flag = 'Y'
             AND asg.assignment_type = 'E'
             AND asg.business_group_id = 325
             AND st.assignment_status_type_id =
                    sttl.assignment_status_type_id
             AND sttl.LANGUAGE = USERENV ('LANG')
             AND amd.ass_status_type_amend_id =
                    amdtl.ass_status_type_amend_id(+)
             AND DECODE (amdtl.ass_status_type_amend_id,
                         NULL, '1',
                         amdtl.LANGUAGE) =
                    DECODE (amdtl.ass_status_type_amend_id,
                            NULL, '1',
                            USERENV ('LANG'))
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                     AND asg.effective_end_date
             AND emp.national_identifier = v_ssn;

      --and rownum < 2;

      v_system_person_status := l_system_person_status;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'No Employee Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Too Many Employees Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Other Reason for Status');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
   END;

   ----***************************************************************************-------------


   --***************************************************************
   --*****                  GET Element Link ID                *****
   --***************************************************************

   PROCEDURE get_element_link_id (v_ssn                   IN     VARCHAR2,
                                  v_element_name          IN     VARCHAR2,
                                  v_business_group_id     IN     NUMBER,
                                  v_pay_basis_id          IN     NUMBER,
                                  v_employment_category   IN     VARCHAR2,
                                  v_people_group_id       IN     NUMBER,
                                  v_element_link_id          OUT NUMBER)
   IS
   BEGIN
      SELECT LINK.element_link_id
        INTO v_element_link_id
        --FROM hr.pay_element_links_f LINK, hr.pay_element_types_f types	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM apps.pay_element_links_f LINK, apps.pay_element_types_f types	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
       WHERE     LINK.element_type_id = types.element_type_id
             AND LINK.business_group_id = v_business_group_id
             AND types.element_name = v_element_name
             AND NVL (LINK.employment_category, v_employment_category) =
                    v_employment_category
             AND NVL (LINK.people_group_id, v_people_group_id) =
                    v_people_group_id
             AND ( (types.effective_end_date >= SYSDATE)
                  OR (types.effective_end_date IS NULL)) --  v2.0 Wasim added this
             AND NVL (LINK.pay_basis_id, v_pay_basis_id) = v_pay_basis_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errorlog_output :=
            (   RPAD (v_ssn, 29)
             || RPAD (v_element_name, 20)
             || LPAD (v_business_group_id, 3));
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Too Many Link IDs');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (   RPAD (v_ssn, 29)
             || RPAD (v_element_name, 20)
             || LPAD (v_business_group_id, 3));
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
   END;

   --***************************************************Create Element API********************************************

   --***************************************************************
   --*****               Create Element Entry            *****
   --***************************************************************

   PROCEDURE do_create_element_entry (v_ssn                 IN VARCHAR2,
                                      l_validate            IN BOOLEAN,
                                      l_deferral_date       IN DATE,
                                      l_business_group_id   IN NUMBER,
                                      l_assignment_id       IN NUMBER,
                                      l_element_link_id     IN NUMBER,
                                      l_input_value_id      IN NUMBER,
                                      l_deferral_pct        IN NUMBER)
   IS
      l_effective_start_date    DATE;
      l_effective_end_date      DATE;
      l_element_entry_id        NUMBER;
      l_object_version_number   NUMBER;
      l_create_warning          BOOLEAN;
   BEGIN
      -- create the entry in the HR Schema
      pay_element_entry_api.create_element_entry (
         p_validate                => l_validate,
         p_effective_date          => l_deferral_date,
         p_business_group_id       => l_business_group_id,
         p_assignment_id           => l_assignment_id,
         p_element_link_id         => l_element_link_id,
         p_entry_type              => 'E',
         p_input_value_id1         => l_input_value_id,
         p_entry_value1            => l_deferral_pct--Out Parameters
         ,
         p_effective_start_date    => l_effective_start_date,
         p_effective_end_date      => l_effective_end_date,
         p_element_entry_id        => l_element_entry_id,
         p_object_version_number   => l_object_version_number,
         p_create_warning          => l_create_warning);


      l_update_status := 'Element Entry Created';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Element Entry Fallout' || SQLERRM);
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
   --  dbms_output.put_line('After NEW ENTRY Start Date->'||l_effective_start_date ||' '||l_element_entry_id);



   END; ----------------End Create Element Entry ********************************************

   --***************************************************************
   --*****                  GET Element Entry ID                *****
   --***************************************************************

   PROCEDURE get_element_entry_id (v_ssn                      IN     VARCHAR2,
                                   v_element_name             IN     VARCHAR2,
                                   v_object_version_number       OUT NUMBER,
                                   v_element_update_date         OUT DATE,
                                   v_effective_element_date      OUT DATE,
                                   v_element_entry_id            OUT NUMBER,
                                   l_validate                 IN     BOOLEAN,
                                   l_deferral_date            IN     DATE,
                                   l_business_group_id        IN     NUMBER,
                                   l_assignment_id            IN     NUMBER,
                                   l_element_link_id          IN     NUMBER,
                                   l_input_value_id           IN     NUMBER,
                                   l_deferral_pct             IN     NUMBER)
   IS
      l_screen_entry_value   NUMBER;
   BEGIN
      SELECT ENTRY.object_version_number               --object_version_number
                                        ,
             ENTRY.last_update_date,
             entval.effective_start_date,
             ENTRY.element_entry_id                       --- element_entry_id
                                   ,
             entval.screen_entry_value                         --current_value
        INTO v_object_version_number,
             v_element_update_date,
             v_effective_element_date,
             v_element_entry_id,
             l_screen_entry_value
		--START R12.2 Upgrade Remediation	 
        /*FROM hr.pay_element_entries_f ENTRY,
             hr.pay_element_links_f LINK,
             hr.per_all_assignments_f asg,
             hr.per_all_people_f emp,
             hr.pay_element_types_f etypes,
             hr.pay_element_entry_values_f entval,
             hr.pay_input_values_f input*/
		FROM apps.pay_element_entries_f ENTRY,
             apps.pay_element_links_f LINK,
             apps.per_all_assignments_f asg,
             apps.per_all_people_f emp,
             apps.pay_element_types_f etypes,
             apps.pay_element_entry_values_f entval,
             apps.pay_input_values_f input	 
		--End R12.2 Upgrade Remediation	 
       WHERE     ENTRY.assignment_id = asg.assignment_id
             AND LINK.element_type_id = etypes.element_type_id
             AND entval.element_entry_id = ENTRY.element_entry_id
             AND etypes.element_type_id = input.element_type_id
             AND input.input_value_id = entval.input_value_id
             AND input.name = 'Percentage'
             AND LINK.element_link_id = ENTRY.element_link_id
             AND ENTRY.effective_start_date BETWEEN asg.effective_start_date
                                                AND asg.effective_end_date
             AND TRUNC (SYSDATE) BETWEEN emp.effective_start_date
                                     AND emp.effective_end_date
             AND ENTRY.effective_start_date BETWEEN LINK.effective_start_date
                                                AND LINK.effective_end_date
             AND emp.person_id = asg.person_id
             AND ENTRY.effective_end_date =
                    (SELECT MAX (effective_end_date)
                       FROM pay_element_entries_f entry2
                      WHERE ENTRY.assignment_id = entry2.assignment_id)
             AND entval.effective_start_date =
                    (SELECT MAX (effective_start_date)
                       FROM pay_element_entry_values_f entval2
                      WHERE entval.element_entry_id =
                               entval2.element_entry_id)
             AND etypes.element_name = v_element_name
             AND ( (etypes.effective_end_date >= SYSDATE)
                  OR (etypes.effective_end_date IS NULL)) --  v2.0 Wasim added this
             AND emp.national_identifier = v_ssn;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         -- dbms_output.put_line('Element entry id is null');
         do_create_element_entry (v_ssn,
                                  l_validate,
                                  l_deferral_date,
                                  l_business_group_id,
                                  l_assignment_id,
                                  l_element_link_id,
                                  l_input_value_id,
                                  l_deferral_pct);
      WHEN TOO_MANY_ROWS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Too Many Row in Element Entry');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
      WHEN OTHERS
      THEN
         l_errorlog_output := (RPAD (v_ssn, 29) || 'Other in Element Entry');
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
   END;

   ----****************************************************************************************************
   --*****               Delete Element Entry            *****
   --***************************************************************

   PROCEDURE do_delete_element_entry (
      v_ssn                     IN     VARCHAR2,
      l_deferral_date           IN     DATE,
      l_element_entry_id        IN     NUMBER,
      l_object_version_number   IN     NUMBER,
      l_update_status           IN OUT VARCHAR2)
   IS
      l_effective_start_date   DATE;
      l_effective_end_date     DATE;
      l_version_number         NUMBER := l_object_version_number;
      l_delete_warning         BOOLEAN;
   BEGIN
      pay_element_entry_api.delete_element_entry (
         p_validate                => FALSE --   in            boolean  default false
                                           ,
         p_datetrack_delete_mode   => 'DELETE'    -- '  in            varchar2
                                              ,
         p_effective_date          => l_deferral_date   --  in            date
                                                     ,
         p_element_entry_id        => l_element_entry_id --  in            number
                                                        ,
         p_object_version_number   => l_version_number --     in out nocopy number
                                                      ,
         p_effective_start_date    => l_effective_start_date --      out nocopy date
                                                            ,
         p_effective_end_date      => l_effective_end_date --           out nocopy date
                                                          ,
         p_delete_warning          => l_delete_warning --           out nocopy boolean
                                                      );


      l_update_status := 'Element Entry End Dated';

     COMMIT;
     
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Delete Element Fallout' || SQLERRM);
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         RAISE SKIP_RECORD;
   END; ---****************End Delete Element Entry *************************------

   --**********           Update Element Entry            *******************
   --************************************************************************------

   PROCEDURE do_update_element_entry (
      v_ssn                     IN     VARCHAR2,
      l_deferral_date           IN     DATE,
      l_business_group_id       IN     NUMBER,
      l_element_entry_id        IN     NUMBER,
      l_object_version_number   IN     NUMBER,
      l_input_value_id          IN     NUMBER,
      l_deferral_pct            IN     NUMBER,
      l_update_status           IN OUT VARCHAR2)
   IS
      l_effective_start_date   DATE;
      l_effective_end_date     DATE;
      l_update_warning         BOOLEAN;
      l_version_number         NUMBER := l_object_version_number;
   BEGIN
      pay_element_entry_api.update_element_entry (
         p_validate                => FALSE,
         p_datetrack_update_mode   => 'UPDATE',
         p_effective_date          => l_deferral_date,
         p_business_group_id       => l_business_group_id,
         p_element_entry_id        => l_element_entry_id,
         p_object_version_number   => l_version_number,
         p_input_value_id1         => l_input_value_id,
         p_entry_value1            => l_deferral_pct--Out Parameters
                                                    -- ,p_object_version_number          => l_object_version_number
         ,
         p_effective_start_date    => l_effective_start_date,
         p_effective_end_date      => l_effective_end_date,
         p_update_warning          => l_update_warning);


      l_update_status := 'Element Entry Updated';


      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errorlog_output :=
            (RPAD (v_ssn, 29) || 'Update Element Fallout' || SQLERRM);
         v_errorlog_count := v_errorlog_count + 1;
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         RAISE SKIP_RECORD;
   END; ----------------End Create Element Entry ********************************************

   --***************************************************************
   --*****                  MAIN Program                       *****
   --***************************************************************
   PROCEDURE main (ERRBUF            OUT VARCHAR2,
                   RETCODE           OUT NUMBER,
                   P_OUTPUT_DIR   IN     VARCHAR2)
   IS
      --
      v_output_dir               VARCHAR2 (240) := P_OUTPUT_DIR;
      l_active_output            VARCHAR2 (242);
      l_termed_output            CHAR (242);
      l_oratermed_output         CHAR (242);
      -- l_errorlog_output     CHAR(242);
      v_oratermed_count          NUMBER := 0;
      v_termed_count             NUMBER := 0;
      v_active_count             NUMBER := 0;
      -- v_errorlog_count    number := 0;

      l_rows_active_read         NUMBER := 0;              -- rows read by api
      l_rows_read                NUMBER := 0;              -- rows read by api
      l_rows_termed_read         NUMBER := 0;              -- rows read by api
      l_rows_active_processed    NUMBER := 0;         -- rows processed by api
      l_rows_termed_processed    NUMBER := 0;         -- rows processed by api
      l_rows_active_skipped      NUMBER := 0;                  -- rows skipped
      l_rows_termed_skipped      NUMBER := 0;                  -- rows skipped
      l_rows_skipped             NUMBER := 0;                  -- rows skipped
      -- l_commit_point             number := 50; -- Commit after X successful rows
      l_module_name              CUST.TTEC_ERROR_HANDLING.MODULE_NAME%TYPE
                                    := 'Main inside loop';
      l_business_group_id        NUMBER := NULL;
      -- update_count               number := 0;

      l_element_name             VARCHAR2 (60);
      l_location_code            VARCHAR2 (150);
      l_employee_number          VARCHAR2 (60);
      l_person_id                NUMBER;
      l_assignment_id            NUMBER;
      l_system_person_type       VARCHAR2 (30) := NULL;
      l_system_person_status     VARCHAR2 (50) := NULL;
      l_element_link_id          NUMBER;
      l_input_value_id1          NUMBER := NULL;
      l_input_value_id2          NUMBER := NULL;
      v_effective_start_date     DATE := NULL;
      l_effective_element_date   DATE := NULL;
      l_element_update_date      DATE := NULL;
      l_pay_basis_id             NUMBER := NULL;
      l_employment_category      VARCHAR2 (10) := NULL;
      l_people_group_id          NUMBER := NULL;
      l_screen_entry_value       NUMBER;
      -- l_update_status            varchar2(150):= 'Did Not Update';
      -- OUT parameters
      --
      l_effective_start_date     DATE;
      l_effective_end_date       DATE;
      l_element_entry_id         NUMBER;
      l_object_version_number    NUMBER;
      l_create_warning           BOOLEAN;
      l_delete_warning           BOOLEAN;
      l_update_warning           BOOLEAN;
      v_todays_date              DATE;                         --varchar2(11);
      --  l_deferral_date              date := to_date('26-MAY-2005');
      l_deferral_date            DATE := TRUNC (SYSDATE);
   BEGIN                                                      ---Starting main
      --  BEGIN
      --  SELECT '/d01/ora'||DECODE(name,'PROD','cle',LOWER(name))
      --  ||'/'||LOWER(name)
      -- ||'appl/teletech/11.5.0/data/BenefitInterface'
      --  INTO v_output_dir
      --  FROM V$DATABASE;
      --  END;

      v_output_dir := TTEC_LIBRARY.GET_DIRECTORY ('CUST_TOP');         -- v2.0
      v_output_dir := v_output_dir || '/data/BenefitInterface';        -- v2.0

      ---------------------------------------------------------------------------------------------------------------


      -------------------------------------------------------------------------------------------------------------
      BEGIN
         SELECT DISTINCT attribute3
           INTO v_todays_date
           --FROM CUST.ttec_us_deferral_tbl	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   FROM APPS.ttec_us_deferral_tbl	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
          WHERE t_type = '1';
      END;

      -------------------------------------------------------------------------------------------------------------

      --***************************************Termed Employees**************************************************
      BEGIN
         v_errorlog_file :=
            UTL_FILE.FOPEN (v_output_dir, p_deferral_errorlog, 'w');
         v_termed_file :=
            UTL_FILE.FOPEN (v_output_dir, p_deferral_termed, 'w');

         l_termed_output :=
               RPAD (' ', 20)
            || ('401(k)  ')
            || LPAD (TO_CHAR (v_todays_date, 'MM/DD/YYYY'), 10);
         UTL_FILE.put_line (v_termed_file, l_termed_output);
         l_termed_output := ('Wachovia Terminations');
         UTL_FILE.put_line (v_termed_file, l_termed_output);
         l_termed_output :=
            (   RPAD (' ', 47)
             || 'System'
             || RPAD (' ', 10)
             || 'Wachovia'
             || RPAD (' ', 2)
             || 'Oracle'
             || RPAD (' ', 54)
             || '401k');
         UTL_FILE.put_line (v_termed_file, l_termed_output);
         l_termed_output :=
            (   RPAD (' ', 24)
             || 'SSN'
             || RPAD (' ', 6)
             || 'Oracle ID'
             || RPAD (' ', 4)
             || 'Date'
             || RPAD (' ', 6)
             || 'New %'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 16)
             || 'Elig Date '
             || RPAD (' ', 6)
             || 'Location'
             || RPAD (' ', 13)
             || 'Plan ID');
         UTL_FILE.put_line (v_termed_file, l_termed_output);


         ----*************************** Writing Error Log Title *********************************
         l_errorlog_output :=
               RPAD (' ', 20)
            || ('401(k)  ')
            || LPAD (TO_CHAR (v_todays_date, 'MM/DD/YYYY'), 10);
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         l_errorlog_output := ('Error Log');
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         l_errorlog_output :=
            (   RPAD (' ', 47)
             || 'System'
             || RPAD (' ', 10)
             || 'Wachovia'
             || RPAD (' ', 2)
             || 'Oracle'
             || RPAD (' ', 52)
             || '401k');
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         l_errorlog_output :=
            (   RPAD (' ', 24)
             || 'SSN'
             || RPAD (' ', 6)
             || 'Oracle ID'
             || RPAD (' ', 4)
             || 'Date'
             || RPAD (' ', 6)
             || 'New %'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 17)
             || 'Elig Date '
             || RPAD (' ', 6)
             || 'Location'
             || RPAD (' ', 12)
             || 'Plan ID');
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);

         ----***************************** End Writing Error Log Title ************************


         FOR termed IN csr_termed_def
         LOOP
            BEGIN
               get_termed_assignment_id (termed.social_number,
                                         l_employee_number,
                                         l_assignment_id,
                                         l_business_group_id,
                                         l_effective_start_date,
                                         l_effective_end_date);
               -- dbms_output.put_line('Employee Number '||l_employee_number||' SSN: '||termed.social_number);

               get_termed_location (termed.social_number,
                                    termed.unit_division,
                                    l_location_code);

               --dbms_output.put_line('Employee Unit '||termed.unit_division||'Location Code '||l_location_code);

               get_termed_status (termed.social_number,
                                  l_system_person_status);
               -- get_employee_status(termed.social_number,l_system_person_status);

               l_termed_output :=
                  (   RPAD (' ', 20)
                   || RPAD (termed.social_number, 11)
                   || RPAD (' ', 2)
                   || LPAD (l_employee_number, 9)
                   || RPAD (' ', 2)
                   || LPAD (TO_CHAR (termed.deferral_date, 'MM/DD/YYYY'), 10)
                   || RPAD (' ', 2)
                   || LPAD (termed.deferral_pct, 3)
                   || RPAD (' ', 5)
                   || RPAD (termed.status_code, 4)
                   || RPAD (' ', 5)
                   || RPAD (l_system_person_status, 20)
                   || RPAD (' ', 2)
                   || LPAD (TO_CHAR (termed.plan_entry_date, 'MM/DD/YYYY'),
                            10)
                   || RPAD (' ', 2)
                   || RPAD (l_location_code, 25)
                   || RPAD (' ', 2)
                   || RPAD (termed.plan_type_id, 4));
               v_termed_count := v_termed_count + 1;
               UTL_FILE.put_line (v_termed_file, l_termed_output);
            EXCEPTION
               WHEN SKIP_RECORD3
               THEN
                  NULL;
            END;
         END LOOP;
      --end;

      END;

      --************************************** End Termed Employees **************************************

      --****************************** Begin Loading data into Oracle *****************************************
      BEGIN                                       ---begin loading into oracle
         v_active_file :=
            UTL_FILE.FOPEN (v_output_dir, p_deferral_active, 'w');
         v_oratermed_file :=
            UTL_FILE.FOPEN (v_output_dir, p_deferral_oratermed, 'w');

         ----*************************** Opening Active Report and Writing Report Title **************************
         l_active_output :=
               RPAD (' ', 20)
            || ('401(k)  ')
            || LPAD (TO_CHAR (v_todays_date, 'MM/DD/YYYY'), 10);
         UTL_FILE.put_line (v_active_file, l_active_output);
         l_active_output := ('Oracle Actives');
         UTL_FILE.put_line (v_active_file, l_active_output);
         l_active_output :=
            (   RPAD (' ', 45)
             || 'System'
             || RPAD (' ', 12)
             || 'Wachovia'
             || RPAD (' ', 2)
             || 'Oracle'
             || RPAD (' ', 109)
             || '401k');
         UTL_FILE.put_line (v_active_file, l_active_output);
         l_active_output :=
            (   RPAD (' ', 24)
             || 'SSN'
             || RPAD (' ', 6)
             || 'Oracle ID'
             || RPAD (' ', 4)
             || 'Date'
             || RPAD (' ', 6)
             || 'New %'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 17)
             || 'Elig Date '
             || RPAD (' ', 10)
             || 'Location'
             || RPAD (' ', 10)
             || 'Pre Tax Load Status'
             || RPAD (' ', 8)
             || 'Pre Tax CatchUp Status'
             || RPAD (' ', 4)
             || 'Plan ID');
         UTL_FILE.put_line (v_active_file, l_active_output);
         ---***************************************** Oracle Termed Employees ***************************

         l_oratermed_output :=
               RPAD (' ', 20)
            || ('401(k)  ')
            || LPAD (TO_CHAR (v_todays_date, 'MM/DD/YYYY'), 10);
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
         l_oratermed_output := ('Oracle Termed');
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
         l_oratermed_output :=
            (   RPAD (' ', 45)
             || 'System'
             || RPAD (' ', 12)
             || 'Wachovia'
             || RPAD (' ', 2)
             || 'Oracle'
             || RPAD (' ', 55)
             || '401k');
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
         l_oratermed_output :=
            (   RPAD (' ', 24)
             || 'SSN'
             || RPAD (' ', 6)
             || 'Oracle ID'
             || RPAD (' ', 4)
             || 'Date'
             || RPAD (' ', 6)
             || 'New %'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 3)
             || 'Status'
             || RPAD (' ', 17)
             || 'Elig Date '
             || RPAD (' ', 14)
             || 'Location'
             || RPAD (' ', 6)
             || 'Plan ID');
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);

         ----********************************** Start Processing Active Employees ***************************************
         FOR sel IN csr_deferral
         LOOP
            /*
            FOR update_count IN 1 .. 2 LOOP

                if update_count = 1 then
                  l_element_name := g_elementnew_name;
                end if;
                if update_count = 2 then
                  l_element_name := g_elementcatchup_name;
                end if;
            */
            BEGIN
               -- handle status code TRES
               IF sel.status_code = 'TRES'
               THEN
                  l_errorlog_output :=
                     (RPAD (sel.social_number, 29) || 'Status Code is TRES.');
                  v_errorlog_count := v_errorlog_count + 1;
                  UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
                  RAISE SKIP_RECORD;
               END IF;

               -- dbms_output.put_line('Rows Read '||l_rows_read);
               get_assignment_id (sel.social_number,
                                  l_employee_number,
                                  l_assignment_id,
                                  l_business_group_id,
                                  l_effective_start_date,
                                  l_effective_end_date);
               -- dbms_output.put_line('Employee Number '||l_employee_number);

               get_location (sel.social_number,
                             sel.unit_division,
                             l_location_code);

               --dbms_output.put_line('Employee Unit '||sel.unit_division||'Location Code '||l_location_code);

               get_person_type (sel.social_number,
                                l_person_id,
                                l_assignment_id,
                                l_pay_basis_id,
                                l_employment_category,
                                l_people_group_id,
                                l_system_person_type);


               get_employee_status (sel.social_number,
                                    l_system_person_status);

               --  dbms_output.put_line('Employee Number '||l_employee_number||'Empl Category '||l_employment_category||'Person Type '||l_system_person_type);

               IF l_system_person_status = 'Terminate - Process'
               THEN
                  l_oratermed_output :=
                     (   RPAD (' ', 20)
                      || RPAD (sel.social_number, 11)
                      || RPAD (' ', 2)
                      || LPAD (l_employee_number, 9)
                      || RPAD (' ', 2)
                      || LPAD (TO_CHAR (sel.deferral_date, 'MM/DD/YYYY'), 10)
                      || RPAD (' ', 2)
                      || LPAD (sel.deferral_pct, 3)
                      || RPAD (' ', 5)
                      || RPAD (sel.status_code, 4)
                      || RPAD (' ', 5)
                      || RPAD (l_system_person_status, 20)
                      || RPAD (' ', 2)
                      || LPAD (TO_CHAR (sel.plan_entry_date, 'MM/DD/YYYY'),
                               10)
                      || RPAD (' ', 2)
                      || LPAD (l_location_code, 25)
                      || RPAD (' ', 2)
                      || RPAD (sel.plan_type_id, 4));
                  v_oratermed_count := v_oratermed_count + 1;
                  UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
               END IF;

               IF l_system_person_status <> 'Terminate - Process'
               THEN
                  FOR update_count IN 1 .. 2
                  LOOP
                     IF update_count = 1
                     THEN
                        l_element_name := g_elementnew_name;
                     END IF;

                     IF update_count = 2
                     THEN
                        l_element_name := g_elementcatchup_name;
                     END IF;



                     l_rows_read := l_rows_read + 1;

                     BEGIN
                        SELECT input.input_value_id
                          INTO l_input_value_id1
						  --START R12.2 Upgrade Remediation
                          /*FROM hr.pay_input_values_f input,
                               hr.pay_element_types_f etypes*/
							FROM apps.pay_input_values_f input,
                               apps.pay_element_types_f etypes   
						  --End R12.2 Upgrade Remediation		
                         WHERE etypes.element_type_id = input.element_type_id
                               AND etypes.element_name = l_element_name
                               AND input.name = 'Percentage'   ---g_input_name
                               AND ( (etypes.effective_end_date >= SYSDATE)
                                    OR (etypes.effective_end_date IS NULL)) --  v2.0 Wasim added this
                               AND input.business_group_id = 325;
                     EXCEPTION
                        WHEN OTHERS
                        THEN                          -- Christiane check this
                           UTL_FILE.put_line (
                              v_errorlog_file,
                              'Error in get element query ' || l_element_name);
                           RAISE SKIP_RECORD;         -- v2.0 Wasim added this
                     END;

                     get_element_link_id (sel.social_number,
                                          l_element_name,
                                          l_business_group_id,
                                          l_pay_basis_id,
                                          l_employment_category,
                                          l_people_group_id,
                                          l_element_link_id);
                     -- dbms_output.put_line('Employee Number     ' ||l_employee_number ||'Element Name '||g_element_name||' Element Link '||l_element_link_id||' Input Value '||l_input_value_id1);


                     ----*************************** Decide if this is a new entry ask Nancy or Cathy if new entry always has *********

                     get_element_entry_id (sel.social_number,
                                           l_element_name,
                                           l_object_version_number,
                                           l_element_update_date,
                                           l_effective_element_date,
                                           l_element_entry_id,
                                           g_validate,
                                           sel.deferral_date,
                                           l_business_group_id,
                                           l_assignment_id,
                                           l_element_link_id,
                                           l_input_value_id1,
                                           sel.deferral_pct);

                     -- dbms_output.put_line('Employee SSN ' ||sel.social_number ||'Input Value Id '||l_input_value_id1);

                     --    keeping track of datetrack issues ----
                     -- EAO   -- if (l_effective_element_date < sel.deferral_date  and trunc(sysdate) > l_element_update_date) then
                     IF (l_effective_element_date < sel.deferral_date
                         AND sel.deferral_date > l_element_update_date)
                     THEN
                        --  dbms_output.put_line('Social SN'||sel.social_number ||'Object Version Number  '||l_object_version_number||' '||'Element Entry id ' || l_element_entry_id);

                        BEGIN  -----Delete or Update Element Entry -----------
                           --  dbms_output.put_line('Element Entry id ' || l_element_entry_id);

                           l_update_status := 'Did Not Update';

                -- v2.1         IF ( (sel.deferral_pct = 0)
                -- v2.1            OR (sel.status_code IN
                -- v2.1                  ('DISB',
                -- v2.1                   'INAC',
                -- v2.1                    'INEL',
                -- v2.1                    'ELND',
                -- v2.1                       'LEAV',
                -- v2.1                      'RETD',
                -- v2.1                      'SUSC')))
                -- v2.1          THEN
                -- v2.1             do_delete_element_entry (
                -- v2.1                sel.social_number,
                -- v2.1                sel.deferral_date,
                -- v2.1                l_element_entry_id,
                -- v2.1                l_object_version_number,
                -- v2.1                l_update_status);
                -- v2.1          --  dbms_output.put_line('For DELETE '||'employee number-> '||l_employee_number||'Benefit Start Date->'||sel.deferral_date);
                -- v2.1          ELSIF (sel.deferral_pct > 0
                -- v2.1                 AND sel.status_code = 'ACTV')
                -- v2.1          THEN
                              do_update_element_entry (
                                 sel.social_number,
                                 sel.deferral_date,
                                 l_business_group_id,
                                 l_element_entry_id,
                                 l_object_version_number,
                                 l_input_value_id1,
                                 sel.deferral_pct,
                                 l_update_status);
                           --  dbms_output.put_line('For UPDATE '||'employee number-> '||l_employee_number||'Benefit Start Date->'||sel.deferral_date);
               -- v2.1           END IF;
                        END; ----- End Delete or Update Element Entry -----------
                     -----*********************************Print Active Files *****************************************--------

                     END IF;      --    keeping track of datetrack issues ----

                     IF update_count = 1
                     THEN
                        l_active_output :=
                           (   RPAD (' ', 20)
                            || RPAD (sel.social_number, 11)
                            || RPAD (' ', 2)
                            || LPAD (l_employee_number, 9)
                            || RPAD (' ', 2)
                            || LPAD (
                                  TO_CHAR (sel.deferral_date, 'MM/DD/YYYY'),
                                  10)
                            || RPAD (' ', 2)
                            || LPAD (sel.deferral_pct, 3)
                            || RPAD (' ', 5)
                            || RPAD (sel.status_code, 4)
                            || RPAD (' ', 5)
                            || RPAD (l_system_person_status, 20)
                            || RPAD (' ', 2)
                            || LPAD (
                                  TO_CHAR (sel.plan_entry_date, 'MM/DD/YYYY'),
                                  10)
                            || RPAD (' ', 2)
                            || LPAD (l_location_code, 25)
                            || RPAD (' ', 2)
                            || RPAD (l_update_status, 25)
                            || RPAD (' ', 2)--     ||rpad(sel.plan_type_id,4)
                                            --     ||rpad(' ',2)
                                            --     ||(l_element_name)
                           );
                     --  utl_file.put_line(v_active_file,l_active_output);
                     END IF;

                     IF update_count = 2
                     THEN
                        l_active_output :=
                              l_active_output
                           || RPAD (l_update_status, 25)
                           || RPAD (' ', 3)
                           -- ||(l_element_name)
                           || RPAD (sel.plan_type_id, 4);


                        v_active_count := v_active_count + 1;
                        UTL_FILE.put_line (v_active_file, l_active_output);
                     END IF;
                  --            v_active_count := v_active_count + 1;
                  --      utl_file.put_line(v_active_file,l_active_output);
                  END LOOP;
               ---**********************************************************************************************************
               END IF;                 -- end current employee element entries
            EXCEPTION
               WHEN SKIP_RECORD
               THEN
                  NULL;
            END;
         --END LOOP;
         END LOOP;

         COMMIT;                                      -- commit any final rows

         ---************************************ Summary of Active Employees **************************--------
         l_active_output := RPAD (' ', 24);
         UTL_FILE.put_line (v_active_file, l_active_output);
         l_active_output :=
            ('Total' || RPAD (' ', 20) || RPAD (v_active_count, 4));
         UTL_FILE.put_line (v_active_file, l_active_output);


         ---***********************************End Summary of Active Employees ****************************--------

         ---************************************** Summary of Error Records ***************************---------

         l_errorlog_output := RPAD (' ', 24);
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);
         l_errorlog_output :=
            (   'Records with Errors'
             || RPAD (' ', 20)
             || RPAD (v_errorlog_count, 4));
         UTL_FILE.put_line (v_errorlog_file, l_errorlog_output);


         l_termed_output := RPAD (' ', 24);
         UTL_FILE.put_line (v_termed_file, l_termed_output);
         l_termed_output :=
            ('Total' || RPAD (' ', 20) || RPAD (v_termed_count, 4));
         UTL_FILE.put_line (v_termed_file, l_termed_output);

         --  UTL_FILE.FCLOSE(v_termed_file);

         -----*********************************** End Summary of Error Records ************************-----------
         ---**************************************** Summary of Oracle Termed ********************--

         l_oratermed_output := RPAD (' ', 24);
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
         l_oratermed_output :=
            ('Oracle Termed' || RPAD (' ', 20) || RPAD (v_oratermed_count, 4));
         UTL_FILE.put_line (v_oratermed_file, l_oratermed_output);
      --*******************************************************************************************---


      -- ********************************************End Element Entries   ----------

      END;                                           --end loading into oracle

      --exception
      --     WHEN SKIP_RECORD THEN
      -- null;
      UTL_FILE.FCLOSE (v_termed_file);

      UTL_FILE.FCLOSE (v_active_file);

      -- UTL_FILE.FCLOSE(v_errorlog_file);
      UTL_FILE.FCLOSE (v_oratermed_file);

      UTL_FILE.FCLOSE (v_errorlog_file);
   ----today 05/ 03 /31 addition
   --exception
   --      WHEN SKIP_RECORD THEN
   -- null;

   END;                                                --ending main procedure
--***************************************************************
--*****                  Call Main procedure                *****
--***************************************************************

BEGIN
   main (ERRBUF, RETCODE, P_OUTPUT_DIR);
EXCEPTION
   WHEN SKIP_RECORD2
   THEN
      NULL;
END;
/
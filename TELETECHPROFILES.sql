/* Formatted on 8/6/2012 1:49:39 PM (QP5 v5.163.1008.3004) */
--********************************************************************************** ************************--
--*Program Name: ttec_teletechprofile.sql                                                                   *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Desciption: This program will write one interface report for LMS:                                        *--
--*            Active and recently termed employee Interface                                                *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Input/Output Parameters                                                                                  *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Created By: Elizur Alfred-Ockiya                                                                         *--
--*Date: 24-MAY-2005                                                                                        *--
--*                                                                                                         *--
--*Modification Log:                                                                                        *--
--* Version Developer             Date        Description                                                   *--
--* ------- ---------            ----        -----------                                                    *--
--*  1.0    E.Alfred-Ockiya     24-MAY-2005    File created                                                    *--
--*  1.1    Andy Becker         14-NOV-2005    Updated with new base script to account                         *--
--*                                           for both null and multiple client codes                            *--
--*  1.2    Andy Becker         05-JAN-2006    Updated to properly assign active/term code                     *--
--*                                           based on multiple employee types (i.e.                            *--
--*                                           Employee and Applicant vs. just Employee                        *--
--*  1.3    W Manasfi       09-21-2008        Added current_employee_flag to query                            *--
--*  1.4    Kaushik Babu    01-29-2009      Commenting the condition on the queries                         *--
--*                                         This is because of new change on Spain COA that is causing this *--
--*                                         issue. The code is currently hard coded to use the old Spain    *--
--*                                         Value set TELETECH_ESP_CLIENT' but after the change it's        *--
--*                                         pointing to TELETECH_CLIENT
--* 1.5      W Manasfi       04-06-2009     Removed / and commas   from output file                         *--
--* 1.6      K Gonuguntla    10-13-2009     Added new logic and query on to the cursor to get missing employee *--
--* 1.7      J Keener         12-01-2011     R12 upgrade, modified output directory to choose $CUST_TOP from instance*--
--* 1.8      K Gonuguntla    04-12-2012     Fixed the performance issue on the query TTSD I 1094551         *--
--* 1.9      KGonuguntla    05-10-2012     Rewrite the whole to resolve missing employee, supervisor and organization structure issue TTSD I 1094551*--
--* 2.0      Kgonuguntla    16-05-2012     Changed the descriptions for orgnamaes and location names     *--
--*  2.1     Kgonuguntla    28-06-2012    Changed code to remove special charaters from file and ignore null values from the file TTSD R 1513710*--
--*  2.2     Kgonuguntla    05-07-2012    Added more validation to remove employees from the file who have null values in Full_part_time, *--
--*                                       location_id, client_id and department_id columns TTSD R 1513710*
--* 2.3     Rajaponnuswamy 08-06-2012  Chnaged code to include future dated hires fior upto 5 days*--
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
--***********************************************************************************************************--

SET LINESIZE 5000
SET SERVEROUTPUT ON

DECLARE
   /***Variables used by Common Error Procedure***/
   p_profile          VARCHAR2 (50) := 'teletechprofiles.csv';
   l_profile_code     VARCHAR2 (1);
   l_profile_status   VARCHAR2 (1);
   v_profile_file     UTL_FILE.file_type;
   errbuf             VARCHAR2 (50);
   retcode            NUMBER;
   l_profile_output   VARCHAR2 (20000) DEFAULT NULL;
   v_client           VARCHAR2 (2000);
   v_clientid         VARCHAR2 (500);

   /***************************************** Cursor declaration ******************************************/
   CURSOR csr_emp
   IS
        SELECT val.person_id,
               val.oracleid,
               val.firstname,
               val.lastname,
               val.middlename,
               val.email,
               val.status,
               val.supervisor_id,
               job_code,
               title,
               val.full_part_time,
               val.employee_status,
               val.termed_date,
               val.manager_level,
               val.attribute5,
               val.assignment_id,
               val.location_id,
               val.location_code,
               val.org_name,
               val.org_id,
               val.cost_allocation_id,
               pcak1.segment2 clientid
          FROM (  SELECT papf.person_id,
                         papf.employee_number oracleid,
                         NVL (papf.first_name, papf.last_name) firstname,
                         papf.last_name lastname,
                         papf.middle_names middlename,
                         papf.email_address email,
                         papf.current_employee_flag status,
                         papfs.employee_number supervisor_id,
                         SUBSTR (pj.NAME, 1, INSTR (pj.NAME, '.') - 1) job_code,
                         SUBSTR (pj.NAME, INSTR (pj.NAME, '.') + 1) title,
                         SUBSTR (paaf.employment_category, 0, 1) full_part_time,
                         ppt.user_person_type employee_status,
                         ppos.actual_termination_date termed_date,
                         pj.attribute6 manager_level,
                         pj.attribute5,
                         paaf.assignment_id,
                         hla.attribute2 location_id,
                         hla.location_code,
                         hou.NAME org_name,
                         pcak.segment3 org_id,
                         MAX (pcaf.cost_allocation_id) cost_allocation_id
                    FROM apps.per_all_people_f papf,
                         apps.per_all_assignments_f paaf,
                         apps.per_periods_of_service ppos,
                         apps.per_all_people_f papfs,
                         apps.per_jobs pj,
                         apps.per_person_types ppt,
                         apps.hr_locations hla,
                         apps.hr_organization_units hou,
                         apps.pay_cost_allocation_keyflex pcak,
                         apps.pay_cost_allocations_f pcaf
                   WHERE     papf.person_id = paaf.person_id
                         AND paaf.person_id = ppos.person_id
                         AND paaf.supervisor_id = papfs.person_id(+)
                         AND paaf.primary_flag = 'Y'
                         AND papf.business_group_id <> 0
                         AND papf.current_employee_flag = 'Y'
                         AND paaf.job_id = pj.job_id(+)
                         AND paaf.location_id = hla.location_id
                         AND paaf.organization_id = hou.organization_id
                         AND hou.cost_allocation_keyflex_id =
                                pcak.cost_allocation_keyflex_id(+)
                         AND paaf.assignment_id = pcaf.assignment_id(+)
                         AND papf.person_type_id = ppt.person_type_id
                         AND TRUNC (SYSDATE) + 5 BETWEEN papf.effective_start_date
                                                     AND papf.effective_end_date
                         AND TRUNC (SYSDATE) + 5 BETWEEN paaf.effective_start_date
                                                     AND paaf.effective_end_date
                         AND TRUNC (SYSDATE) + 5 BETWEEN pcaf.effective_start_date(+)
                                                     AND pcaf.effective_end_date(+)
                         AND TRUNC (SYSDATE) + 5 BETWEEN papfs.effective_start_date(+)
                                                     AND papfs.effective_end_date(+)
                         AND TRUNC (SYSDATE) + 5 BETWEEN ppos.date_start
                                                     AND NVL (
                                                            ppos.actual_termination_date,
                                                            TRUNC (SYSDATE) + 5)
                         AND paaf.location_id <> 115
                GROUP BY papf.person_id,
                         papf.employee_number,
                         NVL (papf.first_name, papf.last_name),
                         papf.last_name,
                         papf.middle_names,
                         papf.email_address,
                         papf.current_employee_flag,
                         papfs.employee_number,
                         SUBSTR (pj.NAME, 1, INSTR (pj.NAME, '.') - 1),
                         SUBSTR (pj.NAME, INSTR (pj.NAME, '.') + 1),
                         SUBSTR (paaf.employment_category, 0, 1),
                         ppt.user_person_type,
                         ppos.actual_termination_date,
                         pj.attribute6,
                         pj.attribute5,
                         hla.attribute2,
                         paaf.assignment_id,
                         hla.location_code,
                         hou.NAME,
                         pcak.segment3) val,
               apps.pay_cost_allocations_f pcaf1,
               apps.pay_cost_allocation_keyflex pcak1
         WHERE val.cost_allocation_id = pcaf1.cost_allocation_id(+)
               AND pcaf1.cost_allocation_keyflex_id =
                      pcak1.cost_allocation_keyflex_id(+)
               AND TRUNC (SYSDATE) BETWEEN pcaf1.effective_start_date(+)
                                       AND pcaf1.effective_end_date(+)
      ORDER BY val.oracleid;
--***************************************************************
BEGIN
   DBMS_OUTPUT.ENABLE (NULL);
   v_profile_file := UTL_FILE.fopen ('&&1', p_profile, 'w');

   BEGIN
      FOR empag IN csr_emp
      LOOP
         l_profile_output := NULL;

         IF empag.employee_status LIKE 'Ex-employee%'
         THEN
            l_profile_status := 0;
         ELSIF empag.employee_status LIKE '%Employee%'
         THEN
            l_profile_status := 1;
         END IF;

         IF empag.attribute5 = 'Agent'
         THEN
            l_profile_code := 'A';
         ELSIF empag.manager_level <> 'Non-Manager'
         THEN
            l_profile_code := 'S';
         ELSIF empag.manager_level = 'Non-Manager'
         THEN
            l_profile_code := 'O';
         END IF;

         IF empag.clientid IS NOT NULL
         THEN
            v_clientid := empag.clientid;
         ELSE
            BEGIN
               SELECT tepa.clt_cd
                 INTO v_clientid
                 --FROM cust.ttec_emp_proj_asg tepa		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				 FROM apps.ttec_emp_proj_asg tepa	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                WHERE tepa.person_id = empag.person_id
                      AND tepa.proportion =
                             (SELECT MAX (proportion)
                                --FROM cust.ttec_emp_proj_asg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
								FROM apps.ttec_emp_proj_asg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                               WHERE person_id = empag.person_id
                                     AND TRUNC (SYSDATE) + 5 BETWEEN prj_strt_dt
                                                                 AND prj_end_dt)
                      AND TRUNC (SYSDATE) + 5 BETWEEN tepa.prj_strt_dt
                                                  AND tepa.prj_end_dt;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_clientid := NULL;
            END;
         END IF;

         BEGIN
              SELECT DISTINCT t.description
                INTO v_client
                FROM fnd_flex_values v,
                     fnd_flex_value_sets s,
                     fnd_flex_values_tl t
               WHERE     flex_value_set_name LIKE 'TELETECH_CLIENT'
                     AND s.flex_value_set_id = v.flex_value_set_id
                     AND t.flex_value_id = v.flex_value_id
                     AND v.flex_value = v_clientid
                     AND t.LANGUAGE = 'US'
            ORDER BY v.flex_value;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_client := NULL;
         END;

         IF (    v_client IS NOT NULL
             AND empag.title IS NOT NULL
             AND empag.location_code IS NOT NULL
             AND empag.org_name IS NOT NULL
             AND empag.supervisor_id IS NOT NULL
             AND empag.location_id IS NOT NULL
             AND empag.org_id IS NOT NULL
             AND v_clientid IS NOT NULL
             AND empag.full_part_time IS NOT NULL)
         THEN
            l_profile_output :=
               (   TRIM (empag.oracleid)
                || '|'
                || ttec_library.remove_non_ascii (empag.firstname)
                || '|'
                || ttec_library.remove_non_ascii (empag.lastname)
                || '|'
                || ttec_library.remove_non_ascii (empag.middlename)
                || '|'
                || ttec_library.remove_non_ascii (empag.email)
                || '|'
                || TRIM (l_profile_status)
                || '|'
                || ttec_library.remove_non_ascii (empag.title)
                || '|'
                || ttec_library.remove_non_ascii (empag.full_part_time)
                || '|'
                || TRIM (empag.supervisor_id)
                || '|'
                || TRIM (v_clientid)
                || '|'
                || ttec_library.remove_non_ascii (v_client)
                || '|'
                || TRIM (empag.location_id)
                || '|'
                || ttec_library.remove_non_ascii (empag.location_code)
                || '|'
                || TRIM (empag.org_id)
                || '|'
                || ttec_library.remove_non_ascii (empag.org_name)
                || '|'
                || TRIM (l_profile_code));
            l_profile_output :=
               REPLACE (REPLACE (l_profile_output, '/', ' '), ',', ' ');
            UTL_FILE.put_line (v_profile_file, TRIM (l_profile_output));
         ELSE
            l_profile_output :=
               (   TRIM (empag.oracleid)
                || '|'
                || ttec_library.remove_non_ascii (empag.firstname)
                || '|'
                || ttec_library.remove_non_ascii (empag.lastname)
                || '|'
                || ttec_library.remove_non_ascii (empag.middlename)
                || '|'
                || ttec_library.remove_non_ascii (empag.email)
                || '|'
                || TRIM (l_profile_status)
                || '|'
                || ttec_library.remove_non_ascii (empag.title)
                || '|'
                || ttec_library.remove_non_ascii (empag.full_part_time)
                || '|'
                || TRIM (empag.supervisor_id)
                || '|'
                || TRIM (v_clientid)
                || '|'
                || ttec_library.remove_non_ascii (v_client)
                || '|'
                || TRIM (empag.location_id)
                || '|'
                || ttec_library.remove_non_ascii (empag.location_code)
                || '|'
                || TRIM (empag.org_id)
                || '|'
                || ttec_library.remove_non_ascii (empag.org_name)
                || '|'
                || TRIM (l_profile_code));
            l_profile_output :=
               REPLACE (REPLACE (l_profile_output, '/', ' '), ',', ' ');
            DBMS_OUTPUT.put_line (l_profile_output);
         END IF;
      END LOOP;
   END;

   UTL_FILE.fclose (v_profile_file);
EXCEPTION
   WHEN OTHERS
   THEN
      UTL_FILE.fclose (v_profile_file);
      DBMS_OUTPUT.put_line (
         'Error from main procedure - ' || SQLCODE || '-' || SQLERRM);
END;
/
/* Formatted on 2013/01/22 09:51 (Formatter Plus v4.8.8) */
--********************************************************************************** ************************--
--*Program Name: TELETECHMATCHPOINT.sql                                                                   *--   
--*                                                                                                         *--
--*                                                                                                         *--
--*Desciption: This program will write one interface report for Match point Vendor:                         *--
--*            Active and termed employee Interface                                                         *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Input/Output Parameters                                                                                  *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Created By: Kaushik                                                                                      *--
--*Date: 24-AUG-2012                                                                                        *--
--*                                                                                                         *--
--*Modification Log:                                                                                        *--
--* Version Developer             Date        Description                                                   *--
--* ------- ---------            ----        -----------                                                    *--
--*  1.0    Kaushik          09-AUG-2012    File created                                                 *--
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            				|
--***********************************************************************************************************--

SET LINESIZE 5000
SET SERVEROUTPUT ON

DECLARE
   /***Variables used by Common Error Procedure***/
   p_profile            VARCHAR2 (200)
        := 'telematchpoint' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS')
           || '.csv';
   v_profile_file       UTL_FILE.file_type;
   errbuf               VARCHAR2 (50);
   retcode              NUMBER;
   l_profile_output     VARCHAR2 (20000)   DEFAULT NULL;
   v_clientid           VARCHAR2 (500);
   v_mgr_level          NUMBER             DEFAULT NULL;
   v_mgr_role           VARCHAR2 (100)     DEFAULT NULL;
   v_val_exists         VARCHAR2 (1)       DEFAULT NULL;
   v_person_id          NUMBER             DEFAULT NULL;
   v_current_run_date   DATE;
   v_cut_off_date       DATE;

/***************************************** Cursor declaration ******************************************/
   CURSOR c_qry_record (p_start_date DATE, p_end_date DATE)
   IS
      SELECT   person_id
          FROM (SELECT DISTINCT papfe.person_id
                           FROM apps.per_all_people_f papfe
                          WHERE (   TRUNC (papfe.creation_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                 OR TRUNC (papfe.last_update_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                )
                            AND papfe.business_group_id <> 0
                UNION
                SELECT DISTINCT paafe.person_id
                           FROM apps.per_all_assignments_f paafe
                          WHERE (   TRUNC (paafe.creation_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                 OR TRUNC (paafe.last_update_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                )
                            AND paafe.business_group_id <> 0
                UNION
                SELECT DISTINCT paaf.person_id
                           FROM apps.pay_cost_allocations_f pcf,
                                per_all_assignments_f paaf
                          WHERE paaf.primary_flag = 'Y'
                            AND paaf.assignment_id = pcf.assignment_id
                            AND paaf.business_group_id <> 0
                            AND (   TRUNC (pcf.creation_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                 OR TRUNC (pcf.last_update_date)
                                       BETWEEN p_start_date
                                           AND p_end_date
                                )
                            AND (   v_cut_off_date
                                       BETWEEN paaf.effective_start_date
                                           AND paaf.effective_end_date
                                 OR paaf.effective_start_date
                                       BETWEEN p_start_date
                                           AND p_end_date
                                 OR paaf.effective_end_date BETWEEN p_start_date
                                                                AND p_end_date
                                )) DUAL
         WHERE person_id IS NOT NULL
           --AND person_id = 29459 
      ORDER BY 1;

   CURSOR csr_emp (p_person_id NUMBER)
   IS
      SELECT   val.person_id, val.oracleid, val.first_name, val.lastname,
               val.email, val.country, val.state, val.town_or_city,
               val.location_code, val.location_id, val.job_family,
               val.job_code, val.title, val.org_code, val.start_date,
               val.end_date, val.manager_level, val.cost_allocation_id,
               pcak1.segment2 clientid
          FROM (SELECT   papf.person_id, papf.employee_number oracleid,
                         papf.first_name, papf.last_name lastname,
                         papf.email_address email, hla.country,
                         DECODE (hla.country,
                                 'BR', hla.region_2,
                                 'CA', hla.region_1,
                                 'CR', hla.region_1,
                                 'ES', hla.region_1,
                                 'UK', '',
                                 'MX', hla.region_1,
                                 'PH', hla.region_1,
                                 'US', hla.region_2,
                                 'NZ', ''
                                ) state,
                         hla.town_or_city,
                         NVL (pcak.segment1, hla.attribute2) location_code,
                         hla.location_id, pj.attribute5 job_family,
                         SUBSTR (pj.NAME, 1,
                                 INSTR (pj.NAME, '.') - 1) job_code,
                         SUBSTR (pj.NAME, INSTR (pj.NAME, '.') + 1) title,
                         NVL (pcak.segment3, pcak_org.segment3) org_code,
                         TRUNC (paaf.effective_start_date) start_date,
                         TRUNC (NVL (ppos.actual_termination_date, SYSDATE + 5)
                               ) end_date,
                         pj.attribute6 manager_level,
                         MAX (pcaf.cost_allocation_id) cost_allocation_id
                    FROM apps.per_all_people_f papf,
                         apps.per_all_assignments_f paaf,
                         apps.per_periods_of_service ppos,
                         apps.per_jobs pj,
                         apps.hr_locations hla,
                         apps.hr_organization_units hou,
                         apps.pay_cost_allocations_f pcaf,
                         apps.pay_cost_allocation_keyflex pcak,
                         apps.pay_cost_allocation_keyflex pcak_org
                   WHERE papf.person_id = paaf.person_id
                     AND paaf.person_id = ppos.person_id
                     AND paaf.primary_flag = 'Y'
                     AND papf.business_group_id <> 0
                     AND papf.current_employee_flag = 'Y'
                     AND paaf.job_id = pj.job_id(+)
                     AND paaf.location_id = hla.location_id
                     AND papf.person_id = p_person_id
                     AND paaf.organization_id = hou.organization_id(+)
                     AND hou.cost_allocation_keyflex_id = pcak_org.cost_allocation_keyflex_id(+)
                     AND pcaf.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id(+)
                     AND paaf.assignment_id = pcaf.assignment_id(+)
                     AND NVL (ppos.actual_termination_date,
                              TRUNC (SYSDATE) + 5)
                            BETWEEN papf.effective_start_date
                                AND papf.effective_end_date
                     AND NVL (ppos.actual_termination_date,
                              TRUNC (SYSDATE) + 5)
                            BETWEEN paaf.effective_start_date
                                AND paaf.effective_end_date
                     AND TRUNC (SYSDATE) + 5 BETWEEN pcaf.effective_start_date(+) AND pcaf.effective_end_date(+)
                     AND NVL (ppos.actual_termination_date,
                              TRUNC (SYSDATE) + 5) BETWEEN ppos.date_start
                                                       AND NVL
                                                             (ppos.actual_termination_date,
                                                                TRUNC (SYSDATE)
                                                              + 5
                                                             )
                GROUP BY papf.person_id,
                         papf.employee_number,
                         papf.first_name,
                         papf.last_name,
                         papf.email_address,
                         hla.country,
                         DECODE (hla.country,
                                 'BR', hla.region_2,
                                 'CA', hla.region_1,
                                 'CR', hla.region_1,
                                 'ES', hla.region_1,
                                 'UK', '',
                                 'MX', hla.region_1,
                                 'PH', hla.region_1,
                                 'US', hla.region_2,
                                 'NZ', ''
                                ),
                         hla.town_or_city,
                         NVL (pcak.segment1, hla.attribute2),
                         hla.location_id,
                         pj.attribute5,
                         SUBSTR (pj.NAME, 1, INSTR (pj.NAME, '.') - 1),
                         SUBSTR (pj.NAME, INSTR (pj.NAME, '.') + 1),
                         NVL (pcak.segment3, pcak_org.segment3),
                         paaf.effective_start_date,
                         ppos.actual_termination_date,
                         pj.attribute6) val,
               apps.pay_cost_allocations_f pcaf1,
               apps.pay_cost_allocation_keyflex pcak1
         WHERE val.cost_allocation_id = pcaf1.cost_allocation_id(+)
           AND pcaf1.cost_allocation_keyflex_id = pcak1.cost_allocation_keyflex_id(+)
           AND TRUNC (SYSDATE) + 5 BETWEEN pcaf1.effective_start_date(+) AND pcaf1.effective_end_date(+)
           AND NVL (val.end_date, TRUNC (SYSDATE) + 5) >= TRUNC (SYSDATE) + 5
      ORDER BY val.oracleid;
--***************************************************************
BEGIN
   DBMS_OUTPUT.ENABLE (NULL);
   v_profile_file := UTL_FILE.fopen ('&&1', p_profile, 'w');
   v_cut_off_date := TO_DATE ('&&3', 'YYYY/MM/DD HH24:MI:SS');
   v_current_run_date := TO_DATE ('&&4', 'YYYY/MM/DD HH24:MI:SS');

   IF '&&2' = 'Y'
   THEN
      BEGIN
         v_person_id := NULL;

         FOR empag IN csr_emp (v_person_id)
         LOOP
            v_mgr_level := NULL;
            v_clientid := NULL;

            IF empag.clientid IS NOT NULL
            THEN
               v_clientid := empag.clientid;
            ELSE
               BEGIN
                  SELECT tepa.clt_cd
                    INTO v_clientid
                    --FROM cust.ttec_emp_proj_asg tepa	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
					FROM apps.ttec_emp_proj_asg tepa	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                   WHERE tepa.person_id = empag.person_id
                     AND tepa.proportion =
                            (SELECT MAX (proportion)
                               --FROM cust.ttec_emp_proj_asg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
							   FROM apps.ttec_emp_proj_asg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                              WHERE person_id = empag.person_id
                                AND NVL (empag.end_date, TRUNC (SYSDATE) + 5)
                                       BETWEEN prj_strt_dt
                                           AND prj_end_dt)
                     AND NVL (empag.end_date, TRUNC (SYSDATE) + 5)
                            BETWEEN tepa.prj_strt_dt
                                AND tepa.prj_end_dt;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_clientid := NULL;
               END;
            END IF;

            IF empag.manager_level IS NOT NULL
            THEN
               BEGIN
                  SELECT ffv.attribute20
                    INTO v_mgr_level
					--START R12.2 Upgrade Remediation
                    /*FROM applsys.fnd_flex_value_sets ffvs,
                         applsys.fnd_flex_values ffv*/
					FROM apps.fnd_flex_value_sets ffvs,
                         apps.fnd_flex_values ffv	 
					--End R12.2 Upgrade Remediation	 
                   WHERE ffvs.flex_value_set_name =
                                                   'TELETECH_MANAGER_LEVEL_VS'
                     AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                     AND ffv.flex_value = empag.manager_level;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_mgr_level := NULL;
                  WHEN TOO_MANY_ROWS
                  THEN
                     v_mgr_level := NULL;
                  WHEN OTHERS
                  THEN
                     v_mgr_level := NULL;
               END;
            ELSE
               v_mgr_level := NULL;
            END IF;

            BEGIN
               v_val_exists := NULL;
               v_mgr_role := NULL;

               SELECT 'Y', NVL (pucif.VALUE, 'Site Talent Acquisition')
                 INTO v_val_exists, v_mgr_role
                 FROM pay_user_tables put,
                      pay_user_columns puc,
                      pay_user_rows_f pur,
                      pay_user_column_instances_f pucif
                WHERE put.user_table_name = 'MatchPoint Users'
                  AND puc.user_column_name = empag.org_code
                  AND (   pur.row_low_range_or_name = v_clientid
                       OR pur.row_low_range_or_name = v_mgr_level
                       OR pur.row_low_range_or_name IS NULL
                      )
                  AND put.user_table_id = puc.user_table_id
                  AND put.user_table_id = puc.user_table_id
                  AND pucif.user_row_id = pur.user_row_id(+)
                  AND puc.user_column_id = pucif.user_column_id(+)
                  AND TRUNC (SYSDATE) BETWEEN pur.effective_start_date(+) AND pur.effective_end_date(+)
                  AND TRUNC (SYSDATE) BETWEEN pucif.effective_start_date(+) AND pucif.effective_end_date(+);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_val_exists := 'N';
                  v_mgr_role := NULL;
               WHEN TOO_MANY_ROWS
               THEN
                  v_val_exists := 'N';
                  v_mgr_role := NULL;
               WHEN OTHERS
               THEN
                  v_val_exists := 'N';
                  v_mgr_role := NULL;
            END;

            IF v_val_exists = 'Y'
            THEN
               l_profile_output :=
                  (   '|'
                   || TRIM (empag.oracleid)
                   || '|'
                   || 'NA'
                   || '|'
                   || ttec_library.remove_non_ascii (empag.first_name)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.lastname)
                   || '|'
                   || TRIM (empag.oracleid)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.email)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.country)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.state)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.town_or_city)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.location_id)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.job_family)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.job_code)
                   || '|'
                   || ttec_library.remove_non_ascii (empag.org_code)
                   || '|'
                   || TRIM (empag.start_date)
                   || '|'
                   || TRIM (empag.end_date)
                   || '|'
                   || ttec_library.remove_non_ascii (v_mgr_role)
                   || '|'
                  );
               l_profile_output :=
                      REPLACE (REPLACE (l_profile_output, '/', ' '), ',', ' ');
               UTL_FILE.put_line (v_profile_file, TRIM (l_profile_output));
            END IF;
         END LOOP;
      END;
   ELSE
      BEGIN
         FOR r_qry_record IN c_qry_record (v_cut_off_date,
                                           v_current_run_date)
         LOOP
            fnd_file.put_line (fnd_file.LOG,
                               'PERSON_ID' || r_qry_record.person_id
                              );

            FOR empag IN csr_emp (r_qry_record.person_id)
            LOOP
               v_mgr_level := NULL;
               v_clientid := NULL;

               IF empag.clientid IS NOT NULL
               THEN
                  v_clientid := empag.clientid;
               ELSE
                  BEGIN
                     SELECT tepa.clt_cd
                       INTO v_clientid
                       --FROM cust.ttec_emp_proj_asg tepa	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
					   FROM apps.ttec_emp_proj_asg tepa	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                      WHERE tepa.person_id = empag.person_id
                        AND tepa.proportion =
                               (SELECT MAX (proportion)
                                  --FROM cust.ttec_emp_proj_asg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
								  FROM apps.ttec_emp_proj_asg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                 WHERE person_id = empag.person_id
                                   AND NVL (empag.end_date,
                                            TRUNC (SYSDATE) + 5)
                                          BETWEEN prj_strt_dt
                                              AND prj_end_dt)
                        AND NVL (empag.end_date, TRUNC (SYSDATE) + 5)
                               BETWEEN tepa.prj_strt_dt
                                   AND tepa.prj_end_dt;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_clientid := NULL;
                  END;
               END IF;

               fnd_file.put_line (fnd_file.LOG, 'Client_id -' || v_clientid);

              IF empag.manager_level IS NOT NULL
               THEN
                  BEGIN
                     SELECT ffv.attribute20
                       INTO v_mgr_level
					   --START R12.2 Upgrade Remediation
                       /*FROM applsys.fnd_flex_value_sets ffvs,
                            applsys.fnd_flex_values ffv*/
						FROM apps.fnd_flex_value_sets ffvs,
                            apps.fnd_flex_values ffv	
					   --End R12.2 Upgrade Remediation		
                      WHERE ffvs.flex_value_set_name =
                                                   'TELETECH_MANAGER_LEVEL_VS'
                        AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                        AND ffv.flex_value = empag.manager_level;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_mgr_level := NULL;
                     WHEN TOO_MANY_ROWS
                     THEN
                        v_mgr_level := NULL;
                     WHEN OTHERS
                     THEN
                        v_mgr_level := NULL;
                  END;
               ELSE
                  v_mgr_level := NULL;
               END IF;

               fnd_file.put_line (fnd_file.LOG,
                                  'Manager_Level -' || v_mgr_level
                                 );

                BEGIN
                  v_val_exists := NULL;
                  v_mgr_role := NULL;

                  SELECT 'Y', NVL (pucif.VALUE, 'Site Talent Acquisition')
                    INTO v_val_exists, v_mgr_role
                    FROM pay_user_tables put,
                         pay_user_columns puc,
                         pay_user_rows_f pur,
                         pay_user_column_instances_f pucif
                   WHERE put.user_table_name = 'MatchPoint Users'
                     AND puc.user_column_name = empag.org_code
                     AND (   pur.row_low_range_or_name = v_clientid
                          OR pur.row_low_range_or_name = v_mgr_level
                          OR pur.row_low_range_or_name IS NULL
                         )
                     AND put.user_table_id = puc.user_table_id
                     AND put.user_table_id = puc.user_table_id
                     AND pucif.user_row_id = pur.user_row_id(+)
                     AND puc.user_column_id = pucif.user_column_id(+)
                     AND TRUNC (SYSDATE) BETWEEN pur.effective_start_date(+) AND pur.effective_end_date(+)
                     AND TRUNC (SYSDATE) BETWEEN pucif.effective_start_date(+) AND pucif.effective_end_date(+);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_val_exists := 'N';
                     v_mgr_role := NULL;
                  WHEN TOO_MANY_ROWS
                  THEN
                     v_val_exists := 'N';
                     v_mgr_role := NULL;
                  WHEN OTHERS
                  THEN
                     v_val_exists := 'N';
                     v_mgr_role := NULL;
               END;

               fnd_file.put_line (fnd_file.LOG, v_val_exists || v_mgr_role);

               IF v_val_exists = 'Y'
               THEN
                  l_profile_output :=
                     (   '|'
                      || TRIM (empag.oracleid)
                      || '|'
                      || 'NA'
                      || '|'
                      || ttec_library.remove_non_ascii (empag.first_name)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.lastname)
                      || '|'
                      || TRIM (empag.oracleid)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.email)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.country)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.state)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.town_or_city)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.location_id)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.job_family)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.job_code)
                      || '|'
                      || ttec_library.remove_non_ascii (empag.org_code)
                      || '|'
                      || TRIM (empag.start_date)
                      || '|'
                      || TRIM (empag.end_date)
                      || '|'
                      || ttec_library.remove_non_ascii (v_mgr_role)
                      || '|'
                     );
                  l_profile_output :=
                      REPLACE (REPLACE (l_profile_output, '/', ' '), ',', ' ');
                  UTL_FILE.put_line (v_profile_file, TRIM (l_profile_output));
               END IF;
            END LOOP;
         END LOOP;
      END;
   END IF;

   UTL_FILE.fclose (v_profile_file);
EXCEPTION
   WHEN OTHERS
   THEN
      UTL_FILE.fclose (v_profile_file);
      DBMS_OUTPUT.put_line (   'Error from main procedure - '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
END;
/
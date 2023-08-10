/* Formatted on 2012/11/05 16:09 (Formatter Plus v4.8.8) */
--********************************************************************************** ************************--
--*Program Name: TELETECHMATCHPOINT.sql                                                                     *--   
--*                                                                                                         *--
--*                                                                                                         *--
--*Desciption: This program will write data for Benefit employees for both                                  *--
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
--*  1.0    Kaushik          09-OCT-2012    File created 
--*  1.1    Arpita           14-JUL-2016    File updated                                                     
--   1.0   NXGARIKAPATI(ARGANO)  21-JULY-2023      R12.2 Upgrade Remediation                                                           *--
--***********************************************************************************************************--
SET LINESIZE 5000;
SET SERVEROUTPUT ON;

DECLARE
   /***Variables used by Common Error Procedure***/
   errbuf         VARCHAR2 (50);
   retcode        NUMBER;
   v_ben_file     UTL_FILE.file_type;
   v_file_name    VARCHAR2 (200)
            := 'telebenefits' || TO_CHAR (SYSDATE, 'MMDDYYHH24MISS')
               || '.txt';
   v_ben_output   VARCHAR2 (20000)   DEFAULT NULL;
   v_start_date   DATE;
   v_end_date     DATE;
   v_date_format varchar2(100); /* v1.1 changes */

   CURSOR c_emp
   IS
      SELECT   pap.person_id, pap.full_name, pap.employee_number,
               hrl.location_code, ppos.date_start,
               ppos.actual_termination_date, papm.employee_number supervisor,
               papm.full_name supervisor_name
          --START R12.2 Upgrade Remediation
		  /*FROM hr.per_all_people_f pap,
               hr.hr_locations_all hrl,
               hr.per_all_assignments_f paa,
               hr.hr_all_organization_units hou,
               hr.per_periods_of_service ppos,
               hr.per_all_people_f papm*/
	      FROM apps.per_all_people_f pap,
               apps.hr_locations_all hrl,
               apps.per_all_assignments_f paa,
               apps.hr_all_organization_units hou,
               apps.per_periods_of_service ppos,
               apps.per_all_people_f papm	
		  --End R12.2 Upgrade Remediation	   
         WHERE pap.business_group_id = '&&2'
           AND paa.primary_flag = 'Y'
           AND pap.current_employee_flag = 'Y'
           AND pap.person_id = paa.person_id
           AND paa.location_id = hrl.location_id
           AND paa.organization_id = hou.organization_id
           AND paa.person_id = ppos.person_id
           AND pap.employee_number = NVL ('&&3', pap.employee_number)
           AND papm.person_id = paa.supervisor_id(+)
           --   AND pap.employee_number = '3048147'
           AND paa.period_of_service_id = ppos.period_of_service_id
           AND TRUNC (NVL (hrl.inactive_date,
                           NVL (ppos.actual_termination_date, SYSDATE)
                          )
                     ) >= TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
                  BETWEEN hou.date_from
                      AND TRUNC (NVL (hou.date_to,
                                      NVL (ppos.actual_termination_date,
                                           SYSDATE
                                          )
                                     )
                                )
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE)) BETWEEN papm.effective_start_date(+)
                                                                       AND papm.effective_end_date(+)
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
                  BETWEEN paa.effective_start_date
                      AND paa.effective_end_date
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
                  BETWEEN pap.effective_start_date
                      AND pap.effective_end_date
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
                  BETWEEN ppos.date_start
                      AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
           AND ppos.period_of_service_id =
                                          (SELECT MAX (period_of_service_id)
                                             FROM per_periods_of_service
                                            WHERE person_id = ppos.person_id)
           AND TRUNC (NVL (ppos.actual_termination_date, SYSDATE))
                  BETWEEN v_start_date
                      AND v_end_date
      ORDER BY 2;

   CURSOR c_ben_stat (p_person_id NUMBER)
   IS
      SELECT ler.NAME, pil.lf_evt_ocrd_dt, pil.ntfn_dt, fu.user_name,
             pil.procd_dt, pil.per_in_ler_stat_cd, flv.meaning
        --START R12.2 Upgrade Remediation
		/*FROM ben.ben_ler_f ler,
             ben.ben_per_in_ler pil,*/
		FROM apps.ben_ler_f ler,
             apps.ben_per_in_ler pil,	 
		--End R12.2 Upgrade Remediation	 
             apps.fnd_user fu,
             apps.fnd_lookup_values flv
       WHERE pil.per_in_ler_stat_cd = 'STRTD'
         AND flv.lookup_code = pil.per_in_ler_stat_cd
         AND flv.lookup_type = 'BEN_PER_IN_LER_STAT'
         AND flv.LANGUAGE = 'US'
         AND pil.person_id = p_person_id                              --603890
         AND pil.ler_id = ler.ler_id
         AND pil.business_group_id = '&&2'
         AND pil.created_by = fu.user_id
         AND ler.NAME <> 'Unrestricted'
         AND ler.NAME NOT LIKE 'CWB%'
         AND ler.effective_end_date = '31-DEC-4712';

   CURSOR c_ben_stat2 (p_person_id NUMBER)
   IS
      SELECT pil.person_id, ler.NAME, pec.enrt_perd_strt_dt,
             pec.enrt_perd_end_dt, pil.per_in_ler_stat_cd, pec.procg_end_dt,
             flv.meaning
        --START R12.2 Upgrade Remediation
		/*FROM ben.ben_ler_f ler,
             ben.ben_per_in_ler pil,*/
		FROM apps.ben_ler_f ler,
             apps.ben_per_in_ler pil,	
		--End R12.2 Upgrade Remediation		
             apps.ben_pil_elctbl_chc_popl pec,
             apps.fnd_lookup_values flv
       WHERE pil.per_in_ler_stat_cd = 'STRTD'
         AND pil.person_id = p_person_id                              --882145
         AND pil.ler_id = ler.ler_id
         AND pil.business_group_id = '&&2'
         AND pec.pgm_id IS NOT NULL
         AND pec.pgm_id IN (83, 122,162)
         AND pec.pil_elctbl_popl_stat_cd = 'STRTD'
         AND flv.lookup_code = pec.pil_elctbl_popl_stat_cd
         AND flv.lookup_type = 'BEN_PER_IN_LER_STAT'
         AND flv.LANGUAGE = 'US'
         AND pec.per_in_ler_id = pil.per_in_ler_id
         AND ler.NAME <> 'Unrestricted'
         AND ler.NAME NOT LIKE 'CWB%'
         AND ler.effective_end_date = '31-DEC-4712';

   CURSOR c_ben_stat3 (p_person_id NUMBER)
   IS
      SELECT DISTINCT ler.NAME, perl.lf_evt_ocrd_dt, perl.ntfn_dt,
                      perl.ptnl_ler_for_per_stat_cd, flv.meaning
                 --START R12.2 Upgrade Remediation
				 /*FROM ben.ben_ler_f ler,
                      ben.ben_ptnl_ler_for_per perl,*/
				 FROM apps.ben_ler_f ler,
                      apps.ben_ptnl_ler_for_per perl,	  
				 --End R12.2 Upgrade Remediation	  
                      apps.fnd_lookup_values flv
                WHERE perl.ptnl_ler_for_per_stat_cd IN
                                                  ('DTCTD', 'UNPROCD', 'MNL')
                  AND flv.lookup_code = perl.ptnl_ler_for_per_stat_cd
                  AND flv.lookup_type = 'BEN_PTNL_LER_FOR_PER_STAT'
                  AND flv.LANGUAGE = 'US'
                  AND perl.person_id = p_person_id
                  AND perl.ler_id = ler.ler_id
                  AND perl.business_group_id = '&&2'
                  AND ler.NAME <> 'Unrestricted'
                  AND ler.NAME NOT LIKE 'CWB%'
                  AND ler.effective_end_date = '31-DEC-4712';
BEGIN
   DBMS_OUTPUT.ENABLE (NULL);
   --v_ben_file := UTL_FILE.fopen ('&&1', v_file_name, 'w');
   v_start_date := TO_DATE ('&&4', 'YYYY/MM/DD HH24:MI:SS');
   v_end_date := TO_DATE ('&&5', 'YYYY/MM/DD HH24:MI:SS');
   v_ben_output :=
         'EMPLOYEE_NUM'
      || '|'
      || 'EMP_FULL_NAME'
      || '|'
      || 'SUPERVISOR_NUM'
      || '|'
      || 'SUPERVISOR_NAME'
      || '|'      
      || 'LOCATION'
      || '|'
      || 'EMP_START_DATE'
      || '|'
      || 'EMP_TERM_DATE'
      || '|'
      || 'EMP_LIFE_EVENT_NAME'
      || '|'
      || 'LIFE_EVENT_STATUS'
      || '|'
      || 'LF_EVT_OCRD_DT'
      || '|'
      || 'NTFN_DT'
      || '|'
      || 'ENRT_PERD_STRT_DT'
      || '|'
      || 'ENRT_PERD_END_DT';
   --  UTL_FILE.put_line (v_ben_file, TRIM (v_ben_output));
   fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));
 /* v1.1 changes Start */
BEGIN
   SELECT fnd_profile.value_specific ('ICX_DATE_FORMAT_MASK', fnd_global.user_id)
     INTO v_date_format
     FROM dual;
EXCEPTION
   WHEN OTHERS
   THEN
      v_date_format := 'DD-MON-RRRR';
END;
 /* v1.1 changes End */

   FOR r_emp IN c_emp
   LOOP
      FOR r_ben_stat IN c_ben_stat (r_emp.person_id)
      LOOP
         v_ben_output :=
               TRIM (r_emp.employee_number)
            || '|'
            || ttec_library.remove_non_ascii (TRIM (r_emp.full_name))   
            || '|'            
            || TRIM (r_emp.supervisor)
            || '|'
            || TRIM (r_emp.supervisor_name)
            || '|'
            || ttec_library.remove_non_ascii (r_emp.location_code)
            || '|'
            || TO_CHAR (TO_DATE (r_emp.date_start), v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_emp.actual_termination_date),
                        v_date_format) /* v1.1 changes */
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat.NAME)
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat.meaning)
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat.lf_evt_ocrd_dt), v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat.ntfn_dt), v_date_format); /* v1.1 changes */
         --        UTL_FILE.put_line (v_ben_file, TRIM (v_ben_output));
         fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));
      END LOOP;

      FOR r_ben_stat3 IN c_ben_stat3 (r_emp.person_id)
      LOOP
         v_ben_output :=
               TRIM (r_emp.employee_number)
            || '|'
            || ttec_library.remove_non_ascii (TRIM (r_emp.full_name))   
            || '|'  
            || TRIM (r_emp.supervisor)
            || '|'
            || TRIM (r_emp.supervisor_name)
            || '|'
            || ttec_library.remove_non_ascii (r_emp.location_code)
            || '|'
            || TO_CHAR (TO_DATE (r_emp.date_start), v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_emp.actual_termination_date),
                        v_date_format) /* v1.1 changes */
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat3.NAME)
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat3.meaning)
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat3.lf_evt_ocrd_dt), v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat3.ntfn_dt), v_date_format); /* v1.1 changes */
         --        UTL_FILE.put_line (v_ben_file, TRIM (v_ben_output));
         fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));
      END LOOP;

      FOR r_ben_stat2 IN c_ben_stat2 (r_emp.person_id)
      LOOP
         v_ben_output :=
               TRIM (r_emp.employee_number)
            || '|'
            || ttec_library.remove_non_ascii (TRIM (r_emp.full_name))   
            || '|'  
            || TRIM (r_emp.supervisor)
            || '|'
            || TRIM (r_emp.supervisor_name)
            || '|'
            || ttec_library.remove_non_ascii (r_emp.location_code)
            || '|'
            || TO_CHAR (TO_DATE (r_emp.date_start), v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_emp.actual_termination_date),
                        v_date_format) /* v1.1 changes */
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat2.NAME)
            || '|'
            || ttec_library.remove_non_ascii (r_ben_stat2.meaning)
            || '|'
            || ' '
            || '|'
            || ' '
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat2.enrt_perd_strt_dt),
                        v_date_format) /* v1.1 changes */
            || '|'
            || TO_CHAR (TO_DATE (r_ben_stat2.enrt_perd_end_dt), v_date_format); /* v1.1 changes */
         --        UTL_FILE.put_line (v_ben_file, TRIM (v_ben_output));
         fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));
      END LOOP;
   END LOOP;
END;
/
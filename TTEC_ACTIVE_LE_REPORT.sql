/* Formatted on 2012/11/05 16:09 (Formatter Plus v4.8.8) */
--********************************************************************************** ************************--
--*Program Name: TELETECHMATCHPOINT.sql                                                                     *--   
--*                                                                                                         *--
--*                                                                                                         *--
--*Desciption: This program will get all the events exception the one with                                  *--
--*            status void in the range of start date and end date for a paraticular business group         *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Input/Output Parameters                                                                                  *--
--*                                                                                                         *--
--*                                                                                                         *--
--*Created By: Prachi R                                                                                      *--
--*Date: 16-May-2017                                                                                        *--
--*                                                                                                         *--
--*Modification Log:                                                                                        *--
--* Version Developer             Date        Description                                                   *--
--* ------- ---------            ----        -----------                                                    *--
--*  1.0    Prachi R          16-May-2017    Initial Version                                                *--
--*  1.1    Hari Varma        09-Dec-2019    Added ttec_get_rank_classification                             *--
--   1.0   NXGARIKAPATI(ARGANO) 21-JULY-2023      R12.2 Upgrade Remediation       
--***********************************************************************************************************--
SET LINESIZE 5000;
SET SERVEROUTPUT ON;

DECLARE
   /***Variables used by Common Error Procedure***/
   errbuf         VARCHAR2 (50);
   retcode        NUMBER;
   v_ben_file     UTL_FILE.file_type;
   v_file_name    VARCHAR2 (200)
            := 'TeleEventBenefits' || TO_CHAR (SYSDATE, 'MMDDYYHH24MISS')
               || '.txt';
   v_ben_output   VARCHAR2 (20000)   DEFAULT NULL;
   v_start_date   DATE;
   v_end_date     DATE;
   v_date_format varchar2(100);
   v_status      varchar2(100);   

   CURSOR c_emp(v_start_date DATE,v_end_date DATE)
   IS
      SELECT pap.person_id
      ,pap.full_name
      ,pap.employee_number
      ,ppos.date_start latest_st_dt
      ,ppos1.date_start date_first_hired
	  ,pap.ORIGINAL_DATE_OF_HIRE
      ,ppos.adjusted_svc_date adjusted_service_date
      ,ppos.actual_termination_date actual_termination_date
      ,hrl.location_code
      ,ppt.USER_PERSON_TYPE person_type
      ,bengr.name benefit_group
      ,pj.attribute5 job_family
      ,pj.ATTRIBUTE19 staffing_ratio
      ,sup.EMPLOYEE_NUMBER supervisor
      ,sup.full_name supervisor_name
      ,ler.name life_event_name
      ,bplfp.lf_evt_ocrd_dt lf_evt_ocrd_dt
      ,bplfp.ntfn_dt ntfn_dt
      ,bplfp.dtctd_dt detected_date
      ,bplfp.procd_dt proccsd_date
      ,DECODE (ptnl_ler_for_per_stat_cd
              ,'PROCD', bpil.per_in_ler_stat_cd
              ,bplfp.ptnl_ler_for_per_stat_cd
              ) status
  --         , ppos1.actual_termination_date
      ,pec.ENRT_PERD_STRT_DT
      ,pec.ENRT_PERD_END_DT
	--  ,decode(&&2,1517,ttec_benefit_reports_pkg.get_rank_classification(pap.person_id,sysdate,ppb.name,pj.attribute6,325),'NA') rank_classification
	  ,decode(&&2,1517,ttec_get_rank_classification(pap.person_id,sysdate,ppb.name,pj.attribute6,325),'NA') rank_classification
--START R12.2 Upgrade Remediation
/*FROM   hr.per_all_people_f pap
      ,hr.per_periods_of_service ppos
      ,hr.per_periods_of_service ppos1
      ,hr_locations_all hrl
      ,hr.per_all_assignments_f paaf
	  ,hr.per_pay_bases ppb
      ,hr.per_person_type_usages_f pptuf
      ,hr.per_person_types ppt
      ,ben.BEN_BENFTS_GRP bengr
      ,per_jobs pj
      ,per_all_people_f sup
      ,ben.ben_pil_elctbl_chc_popl pec
      ,ben.ben_ler_f ler
      ,ben.ben_per_in_ler bpil
      ,ben.ben_ptnl_ler_for_per bplfp*/
FROM   apps.per_all_people_f pap
      ,apps.per_periods_of_service ppos
      ,apps.per_periods_of_service ppos1
      ,hr_locations_all hrl
      ,apps.per_all_assignments_f paaf
	  ,apps.per_pay_bases ppb
      ,apps.per_person_type_usages_f pptuf
      ,apps.per_person_types ppt
      ,apps.BEN_BENFTS_GRP bengr
      ,per_jobs pj
      ,per_all_people_f sup
      ,apps.ben_pil_elctbl_chc_popl pec
      ,apps.ben_ler_f ler
      ,apps.ben_per_in_ler bpil
      ,apps.ben_ptnl_ler_for_per bplfp   	  
--End R12.2 Upgrade Remediation	  
 WHERE pap.business_group_id = &&2 --p_business_group_id
   and paaf.person_id = pap.person_id
   and paaf.location_id = hrl.location_id
   and paaf.pay_basis_id = ppb.pay_basis_id
   and ppb.business_group_id = paaf.business_group_id
   and paaf.primary_flag = 'Y'
   and pptuf.person_id = pap.person_id
   and ppt.person_type_id = pptuf.person_type_id
   --and ppt.person_type_id = pap.person_type_id
   and ppt.business_group_id = pap.business_group_id
   and pap.benefit_group_id = bengr.BENFTS_GRP_ID(+)
   and pj.business_group_id = paaf.business_group_id
   and paaf.job_id = pj.job_id
   and paaf.supervisor_id = sup.person_id
   --and bengr.business_group_id = pap.business_group_id
   --AND pap.employee_number =  3186159 --3138431 --3122878 --3241020
   --AND pap.current_employee_flag = 'Y'
   AND  TRUNC(SYSDATE) BETWEEN pap.effective_start_date AND pap.effective_end_date
   and  TRUNC(SYSDATE) between paaf.effective_start_date AND paaf.effective_end_date
   and TRUNC(SYSDATE) between pptuf.effective_start_date and pptuf.effective_end_date
   and paaf.effective_start_date between sup.effective_start_date and sup.effective_end_date
   AND ppos.period_of_service_id = (SELECT MAX (period_of_service_id)
                                      FROM per_periods_of_service
                                     WHERE person_id = pap.person_id                                     
                                     and bplfp.lf_evt_ocrd_dt between date_start and nvl(actual_termination_date+1,to_date('31-DEC-4712','DD-MON-RRRR'))
                                    )   
   AND ppos1.person_id = pap.person_id
   AND ppos1.period_of_service_id = (SELECT MIN (period_of_service_id)
                                       FROM per_periods_of_service
                                      WHERE person_id = ppos.person_id)
   AND ler.business_group_id = pap.business_group_id
   AND ler.NAME <> 'Unrestricted'
   --AND ler.NAME NOT LIKE 'CWB%'                                   
   AND ler.ler_id = bplfp.ler_id
   AND pap.person_id = bplfp.person_id
   --AND ler.ler_id in (select ler_id from BEN.ben_ler_f -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
   AND ler.ler_id in (select ler_id from apps.ben_ler_f 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                    where business_group_ID = &&2
                    and ler_id = NVL('&&3',ler_id)
                    and bplfp.lf_evt_ocrd_dt between effective_start_date and effective_end_Date)
   AND bplfp.lf_evt_ocrd_dt BETWEEN ler.effective_start_date AND ler.effective_end_date
   --and sysdate between papf.effective_start_date and papf.effective_end_Date
   AND bplfp.lf_evt_ocrd_dt BETWEEN TO_DATE (v_start_date, 'DD-MON-RRRR') AND TO_DATE (v_end_date, 'DD-MON-RRRR')
   AND bplfp.ptnl_ler_for_per_stat_cd <> 'VOIDD'
   AND bpil.ptnl_ler_for_per_id(+) = bplfp.ptnl_ler_for_per_id
   AND NVL (bpil.per_in_ler_stat_cd, 'PROCD') NOT IN ('VOIDD','BCKDT') 
   AND ppt.user_person_type <> 'Participant'
   --and ( hrl.inactive_date is null or (bplfp.lf_evt_ocrd_dt<= hrl.inactive_date)) 
   --AND pec.pgm_id IS NOT NULL
   --AND pec.pgm_id IN (83, 122,162)
  -- AND pec.pil_elctbl_popl_stat_cd = 'STRTD'
   AND pec.per_in_ler_id(+) = nvl(bpil.per_in_ler_id,-1)  
   ORDER BY 3,16;  
    
BEGIN
   DBMS_OUTPUT.ENABLE (NULL);
   --v_ben_file := UTL_FILE.fopen ('&&1', v_file_name, 'w');
   v_start_date := TO_DATE (NVL('&&4',TRUNC(SYSDATE,'RRRR')),'YYYY/MM/DD HH24:MI:SS');
   v_end_date := TO_DATE (nvl('&&5',SYSDATE),'YYYY/MM/DD HH24:MI:SS');
   v_status := '&&6' ;
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
      || 'EMP_LATEST_ST_DT'
      || '|'
      || 'EMP_DATE_FIRST_HIRED'
      || '|'
      || 'EMP_ADJ_SVC_DATE'
      || '|'
      || 'EMP_ACT_TERM_DATE'
      || '|'
      || 'PERSON_TYPE'
      || '|'
      || 'BENEFIT_GROUP'
      || '|'
      || 'STAFFING_RATIO'
      || '|'
      || 'EMP_LIFE_EVENT_NAME'
      || '|'
      || 'LIFE_EVENT_STATUS'
      || '|'
      || 'LF_EVT_OCRD_DT'
      || '|'
      || 'NTFN_DT'
      || '|'
      || 'DETECTED_DT'
      || '|'
      || 'PROCD_DT'
      || '|'      
      || 'ENRT_PERD_STRT_DT'
      || '|'
      || 'ENRT_PERD_END_DT'
      || '|'
      || 'RANK CLASSIFICATION';
   --  UTL_FILE.put_line (v_ben_file, TRIM (v_ben_output));
   fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));

BEGIN
   SELECT fnd_profile.value_specific ('ICX_DATE_FORMAT_MASK', fnd_global.user_id)
   INTO v_date_format
   FROM dual;
EXCEPTION
   WHEN OTHERS
   THEN
      v_date_format := 'DD-MON-RRRR';
END;

   FOR r_emp IN c_emp(v_start_date,v_end_date)
   LOOP
        if (
		     ( r_emp.status <> 'PROCD' and trim(nvl(v_status,r_emp.status)) = trim(r_emp.status) )  
            OR 
		   ( NVL(v_status,'NA') = 'PROCD' and trim(r_emp.status)='PROCD')
            OR
           ( NVL(v_status,'NA') ='ALL' and trim(r_emp.status)in ('PROCD','STRTD','DTCTD','MNL','UNPROCD'))		
		)then
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
				|| TO_CHAR (TO_DATE (r_emp.latest_st_dt), v_date_format) 
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.ORIGINAL_DATE_OF_HIRE), v_date_format) 
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.adjusted_service_date), v_date_format)  
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.actual_termination_date), v_date_format) 
				|| '|'
				|| ttec_library.remove_non_ascii (r_emp.person_type)
				|| '|'
				|| ttec_library.remove_non_ascii (r_emp.benefit_group)
				|| '|'
				|| ttec_library.remove_non_ascii (r_emp.staffing_ratio)
				|| '|'
				|| ttec_library.remove_non_ascii (r_emp.life_event_name)
				|| '|'
				|| ttec_library.remove_non_ascii (r_emp.status)
				|| '|'            
				|| TO_CHAR (TO_DATE (r_emp.lf_evt_ocrd_dt), v_date_format)  
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.ntfn_dt), v_date_format)
				|| '|'            
				|| TO_CHAR (TO_DATE (r_emp.detected_date), v_date_format)  
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.proccsd_date), v_date_format)
				|| '|'            
				|| TO_CHAR (TO_DATE (r_emp.ENRT_PERD_STRT_DT), v_date_format)  
				|| '|'
				|| TO_CHAR (TO_DATE (r_emp.ENRT_PERD_END_DT), v_date_format)				
                                || '|'
				|| ttec_library.remove_non_ascii (r_emp.rank_classification);  				
	 
			 fnd_file.put_line (fnd_file.output, TRIM (v_ben_output));  
		end if;
       
   END LOOP;
END;
/
--
-- Program Name:  TTEC_ACT_ACT_ITEM_AUDIT_RPT
-- /* $Header: TTEC_ACT_ACT_ITEM_AUDIT_RPT.sql 1.0 2016/09/06  aaslam ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Amir Aslam
--      Date: 07-Sep-2016
--
--
--
--     Parameter Description:
--
--
--       p_as_Of_dt            : As Of Date if no value, will default to SYSDATE
--
--       Oracle Standard Parameters:
--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      3.0  05/04/15   AAslam   Initial Version 
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation       

DECLARE

        p_buss_grp_id   number := '';
        -- p_as_Of_dt      date := '';
        p_as_Of_dt      varchar2(100) := '';
		p_act_typ_id    number := '';
        --v_user_id       number;
        --l_req_count     number;

    CURSOR c_user IS
		select distinct pap.full_name,
         pap.employee_number,
         hrl.location_code,
         pln.name Plan_name,
         eat.Name Action_Item_name,
         pea.rqd_flag,
         pea.due_dt
--START R12.2 Upgrade Remediation
/*from   hr.per_all_people_f pap,
         ben.ben_prtt_enrt_rslt_f pen,
         ben.ben_actn_typ eat,
         ben.ben_prtt_enrt_actn_f pea,
         ben.ben_pl_f pln,
         hr.per_all_assignments_f paa,
         hr.hr_locations_all hrl*/
from   apps.per_all_people_f pap,
         apps.ben_prtt_enrt_rslt_f pen,
         apps.ben_actn_typ eat,
         apps.ben_prtt_enrt_actn_f pea,
         apps.ben_pl_f pln,
         apps.per_all_assignments_f paa,
         apps.hr_locations_all hrl		 
--End R12.2 Upgrade Remediation		 
where  pea.prtt_enrt_rslt_id = pen.prtt_enrt_rslt_id
         and pen.person_id = pap.person_id
         and pap.person_id = paa.person_id
         and paa.location_id = hrl.location_id
         and sysdate between pap.effective_start_date and pap.effective_end_date
         and sysdate between paa.effective_start_date and paa.effective_end_date 
         --and to_date('01-Jan-2016','dd-mon-yyyy' ) between pen.effective_start_date and pen.effective_end_date
         --and to_date('01-Jan-2016','dd-mon-yyyy' )between pen.enrt_cvg_strt_dt and pen.enrt_cvg_thru_dt
         and pen.prtt_enrt_rslt_stat_cd is Null
         and pen.pl_id = pln.pl_id
         and pea.actn_typ_id = eat.actn_typ_id
         -- and to_date('01-Jan-2016','dd-mon-yyyy' ) between pea.effective_start_date and pea.effective_end_date
         --and pea.rqd_flag = 'Y'
         and pea.cmpltd_dt is Null
--         and pen.pgm_id = 83
		 and CURRENT_EMPLOYEE_FLAG = 'Y'
and pap.business_group_id =	nvl(p_buss_grp_id,pap.business_group_id)
and SYSDATE  between nvl(pea.effective_start_date,SYSDATE) and nvl(pea.effective_end_date,SYSDATE)
and SYSDATE  between nvl(pln.effective_start_date,SYSDATE) and nvl(pln.effective_end_date,SYSDATE)
-- AND NVL(p_as_Of_dt,TRUNC(SYSDATE)) BETWEEN nvl(pea.effective_start_date,SYSDATE) AND nvl(pea.effective_end_date,sysdate)
--AND nvl(fnd_date.canonical_to_date(p_as_Of_dt),SYSDATE) BETWEEN nvl(pea.effective_start_date,SYSDATE) AND nvl(pea.effective_end_date,SYSDATE)
AND nvl(fnd_date.canonical_to_date(p_as_Of_dt),SYSDATE) >= nvl(pea.due_dt,SYSDATE)
and eat.ACTN_TYP_ID = nvl(p_act_typ_id,eat.ACTN_TYP_ID)
and due_dt >= to_date('01-Jan-2016','dd-mon-yyyy' )
order by location_code,full_name;

BEGIN

        p_buss_grp_id   := '&1';
        p_as_Of_dt      := '&2';
        p_act_typ_id    := '&3';
		 
		 
       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech Active Action Item Audit Report');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');


       FND_FILE.PUT_LINE(FND_FILE.log,'TeleTech Active Action Item Audit Report - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS')||'  As Of Date: '||NVL(p_as_Of_dt,TRUNC(SYSDATE)));
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Full Name'          ||'|'||
                                         'Employee Number'             ||'|'||
                                         'Location Code'               ||'|'||
                                         'Plan Name'    ||'|'|| 
                                         'Action Item Name'       ||'|'||
                                         'Req Flag'         ||'|'||                                        
                                         'Due Date'
                                          );
										  
       FOR v_user IN c_user LOOP

		   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_user.full_name || '|' || v_user.employee_number || '|'  || v_user.location_code || '|'  || v_user.Plan_name || '|'  || v_user.Action_Item_name || '|'  ||  v_user.rqd_flag || '|'  || v_user.due_dt  );
	   
	   END LOOP;

EXCEPTION 
    WHEN OTHERS THEN
       NULL;
      FND_FILE.PUT_LINE(FND_FILE.LOG,  'Error from main procedure - '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );
END;
/
	   
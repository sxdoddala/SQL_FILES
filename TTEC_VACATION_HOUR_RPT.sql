--
-- Program Name:  TTEC_VACATION_HOUR_RPT
-- /* $Header: TTEC_VACATION_HOUR_RPT.sql 1.0 2015/01/13  Aaslam ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Amir Aslam
--      Date: 05-feb-2018
--
-- Call From: Concurrent Program -> TTEC_VACATION_HOUR_RPT
--      Desc: These reports will be used by HC track down the Balance Hour by.
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
--      1.0  01/04/18   AAslam    Initial Version - 
--      1.0   21-JULY-2023   NXGARIKAPATI(ARGANO)   R12.2 Upgrade Remediation      

DECLARE

        p_payroll_id   number := '';
        p_as_Of_dt     varchar2(100) := '';



    CURSOR c_user IS
select Employee_number , Full_name ,
Assignment_number,assignment_id,
--(select action_information6 from HR.PAY_ACTION_INFORMATION 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
(select action_information6 from apps.PAY_ACTION_INFORMATION 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    where assignment_id=paaf.assignment_id 
    and action_information_category='EMPLOYEE ACCRUALS' 
    and action_information4='Vacation' 
    --and trunc(effective_date) = trunc(to_date('18-JAN-2018'))
    --and trunc(effective_date) = nvl(fnd_date.canonical_to_date(p_as_Of_dt),SYSDATE)
	and trunc(effective_date) = TRUNC(fnd_date.canonical_to_date(p_as_Of_dt))
    and rownum<2
    ) as Curr_Vacation_Hours,
--(   select action_information6 from HR.PAY_ACTION_INFORMATION  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
(   select action_information6 from apps.PAY_ACTION_INFORMATION  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    where assignment_id=paaf.assignment_id 
    and action_information_category='EMPLOYEE OTHER INFORMATION' 
    and action_information4='Vacation Bank' 
    --and trunc(effective_date) = trunc(to_date('18-JAN-2018'))
    and trunc(effective_date) = nvl(fnd_date.canonical_to_date(p_as_Of_dt),SYSDATE)
    and rownum<2) as Curr_Vacation_Bank
,--
--(select action_information6 from HR.PAY_ACTION_INFORMATION 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
(select action_information6 from apps.PAY_ACTION_INFORMATION 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    where assignment_id=paaf.assignment_id 
    and action_information_category='EMPLOYEE ACCRUALS' 
    and action_information4='Vacation' 
    --and trunc(effective_date) = trunc(to_date('18-JAN-2018'))
    and trunc(effective_date) = ( fnd_date.canonical_to_date(p_as_Of_dt) -14 )
    and rownum<2
    ) as Prev_Vacation_Hours,
--(   select action_information6 from HR.PAY_ACTION_INFORMATION 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
(   select action_information6 from apps.PAY_ACTION_INFORMATION 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    where assignment_id=paaf.assignment_id 
    and action_information_category='EMPLOYEE OTHER INFORMATION' 
    and action_information4='Vacation Bank' 
    --and trunc(effective_date) = trunc(to_date('18-JAN-2018'))
    and trunc(effective_date) = ( fnd_date.canonical_to_date(p_as_Of_dt) -14 )
    and rownum<2) as Prev_Vacation_Bank
from Per_all_people_f papf , per_all_assignments_f paaf
where payroll_id= p_payroll_id -- 782
and papf.person_id = paaf.person_id
and trunc(sysdate) between papf.effective_start_date and papf.effective_end_date
and trunc(sysdate) between paaf.effective_start_date and paaf.effective_end_date;

-- AND nvl(fnd_date.canonical_to_date(p_as_Of_dt),SYSDATE) >= nvl(pea.due_dt,SYSDATE)


BEGIN

        p_payroll_id   := '&1';
        p_as_Of_dt     := '&2';

       FND_FILE.PUT_LINE(FND_FILE.Log,' p_as_Of_dt is' || trunc(fnd_date.canonical_to_date(p_as_Of_dt)));
		
       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech vacatino Hour Report');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');

       FND_FILE.PUT_LINE(FND_FILE.log,'TeleTech vacatino Hour Report - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS')||'  As Of Date: '||NVL(p_as_Of_dt,TRUNC(SYSDATE)));
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Full Name'           ||'|'||
                                         'Employee Number'     ||'|'||
                                        -- 'ASSIGNMENT_NUMBER'   ||'|'|| 
                                         'ASSIGNMENT_ID'       ||'|'||
                                         'CURR_VACATION_HOURS' ||'|'||
                                         'CURR_VACATION_BANK'  ||'|'||
                                         'PREV_VACATION_HOURS' ||'|'||
                                         'PREV_VACATION_BANK'  
                                          );

										  
       FOR v_user IN c_user 
	   LOOP
		    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_user.full_name || '|' || v_user.employee_number  || '|'  || v_user.Assignment_id || '|'  || v_user.Curr_Vacation_Hours || '|'  ||  v_user.Curr_Vacation_Bank || '|'  || v_user.PREV_VACATION_HOURS || '|'  || v_user.PREV_VACATION_BANK );
		   --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_user.full_name || '|' || v_user.employee_number || '|'  || v_user.Assignment_number || '|'  || v_user.Assignment_id ); -- || '|'  || v_user.Curr_Vacation_Hours || '|'  ||  v_user.Curr_Vacation_Bank || '|'  || v_user.PREV_VACATION_HOURS || '|'  || v_user.PREV_VACATION_BANK );
	   
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




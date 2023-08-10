--
-- Program Name:  TTEC_AMEX_CARD_MISSMATCH
-- /* $Header: TTEC_AMEX_CARD_MISSMATCH.sql 1.0 2016/10/10 chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 10-OCT-2016
--
-- Call From: Concurrent Program -> TeleTech Credit Card Setup Mismatched
--      Desc: These reports will be used by Corporate Card Administrator
--
--
--     Parameter Description:
--
--        
--
--       Oracle Standard Parameters:
--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      1.0  10/10  CChan     Initial Version -
--      1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)  R12.2 Upgrade Remediation     
--
DECLARE

    --
    -- Credit Card Mismatched
    --
    CURSOR c_list IS
    SELECT ac.employee_id 
           ||'|'|| hla.location_code 
           ||'|'|| papf.employee_number 
           ||'|'|| papf.full_name 
           ||'|'|| substr(cc.ccnumber,9) 
           ||'|'|| paaf.set_of_books_id 
           ||'|'|| (SELECT ou.set_of_books_id
                      FROM apps.hr_operating_units ou
                     WHERE ou.organization_id = ac.org_id) 
           ||'|'|| emp_hou.NAME  
           ||'|'|| (SELECT l.NAME
                      FROM apps.hr_operating_units ou,
                           --gl.gl_ledgers l	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						   apps.gl_ledgers l	-- Apps code by NXGARIKAPATI-ARGANO, 21/07/2023 
                     WHERE ou.organization_id = ac.org_id
                       AND l.ledger_id = ou.set_of_books_id) 
           ||'|'|| card_brand_lookup_code 
           ||'|'|| acpa.attribute4 
           ||'|'|| acpa.card_program_name 
           ||'|'|| ac.last_update_date 
           ||'|'|| ac.inactive_date 
           ||'|'|| cl_hou.NAME  
           ||'|'|| b.responsibility_name 
           ||'|'|| u.user_name 
           ||'|'|| a.start_date 
           ||'|'|| a.end_date line
      FROM --ap.ap_card_programs_all acpa,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.ap_card_programs_all acpa,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
           apps.ap_cards_all ac,
           apps.iby_creditcard cc,
           per_all_people_f papf,
           per_all_assignments_f paaf,
           --hr.hr_locations_all hla,	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.hr_locations_all hla,	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
           apps.fnd_user_resp_groups_direct a,
           --applsys.fnd_user u,  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.fnd_user u,   -- Addeed code by NXGARIKAPATI-ARGANO, 21/07/2023 
           apps.fnd_responsibility_vl b,
           apps.hr_operating_units cl_hou,
           --gl.gl_ledgers emp_hou	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.gl_ledgers emp_hou	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
     WHERE hla.location_id = paaf.location_id
       AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                               AND papf.effective_end_date
       AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                               AND paaf.effective_end_date
       AND paaf.person_id = papf.person_id
       AND papf.person_id = ac.employee_id
       AND cl_hou.organization_id = acpa.org_id
       AND emp_hou.ledger_id = paaf.set_of_books_id
       AND papf.current_employee_flag = 'Y'
       AND NVL (ac.inactive_date, '31-DEC-4012') >= TRUNC (SYSDATE)
       AND a.responsibility_id = b.responsibility_id
       AND a.user_id = u.user_id
       AND cc.instrid = ac.card_reference_id
       AND u.employee_id = ac.employee_id
       AND b.responsibility_name LIKE '%Internet%Expen%'
       AND ac.card_program_id = acpa.card_program_id
       AND (   acpa.card_brand_lookup_code = 'MasterCard'
            OR (    acpa.card_brand_lookup_code = 'American Express'
                AND acpa.attribute4 IS NOT NULL
               )
           )
       AND TRUNC (ac.creation_date) >= TRUNC (SYSDATE) - 365
       AND TRUNC (SYSDATE) BETWEEN a.start_date AND NVL (a.end_date,
                                                         '31-DEC-4712')
       AND paaf.set_of_books_id != (SELECT ou.set_of_books_id
                                      FROM apps.hr_operating_units ou
                                     WHERE ou.organization_id = ac.org_id);
        
BEGIN

       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech Credit Card Setup Mismatched ');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TeleTech Credit Card Setup Mismatched  - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));                                          

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Employee ID'
                                 ||'|'|| 'Current Location Code'
                                 ||'|'|| 'Employee Number'   
                                 ||'|'|| 'Employee Fullname'  
                                 ||'|'|| 'Last 7 Digits CC Number'                                                                                                 
                                 ||'|'|| 'Emp HR SOB'
                                 ||'|'|| 'Card Linked SOB'
                                 ||'|'|| 'Employee HR SOB Name'
                                 ||'|'|| 'Card Linked SOB Name'
                                 ||'|'|| 'Card Type'                                 
                                 ||'|'|| 'AMEX BCA'
                                 ||'|'|| 'Card Program Assigned'
                                 ||'|'|| 'CP Last Updated Date'
                                 ||'|'|| 'CP Inactive Date'
                                 ||'|'|| 'Card Linked OU'
                                 ||'|'|| 'Resp currently Assigned'
                                 ||'|'|| 'User Name'
                                 ||'|'|| 'Resp Start Date'
                                 ||'|'|| 'Resp End Date'                                              
                                          );                                          
                                          
       FOR v_list IN c_list LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line );

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

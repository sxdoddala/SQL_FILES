--
-- Program Name:  TTEC_CreditCard_TRX_DETAIL
-- /* $Header: TTEC_CreditCard_TRX_DETAIL.sql 1.0 2016/10/10 chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 10-OCT-2016
--
-- Call From: Concurrent Program -> TeleTech CreditCard TRX Detail
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
--   1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)    R12.2 Upgrade Remediation
--
DECLARE

        p_emp_no           number := '';
        p_person_id        number := '';
        p_first_name       varchar2(100) := '';
        p_last_name        varchar2(100) := '';

    --
    -- Employee HR detail
    --
    CURSOR c_emp IS
    SELECT papf.person_id, papf.first_name,papf.last_name,
           papf.business_group_id
           ||'|'|| papf.full_name
           ||'|'|| papf.employee_number
           ||'|'|| papf.first_name
           ||'|'|| papf.last_name
           ||'|'|| hla.location_code
           --||'|'|| (select name from gl.gl_ledgers where ledger_id = paaf.SET_OF_BOOKS_ID) line  	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   ||'|'|| (select name from apps.gl_ledgers where ledger_id = paaf.SET_OF_BOOKS_ID) line  	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
      FROM per_all_people_f papf,
           per_all_assignments_f paaf,
           --hr.hr_locations_all hla	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.hr_locations_all hla	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
     WHERE hla.location_id = paaf.location_id
       AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                               AND papf.effective_end_date
       AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                               AND paaf.effective_end_date
       AND paaf.person_id = papf.person_id
       AND papf.employee_number = p_emp_no;

    --
    -- Credit Card 
    --
    CURSOR c_card IS
    SELECT cc.chname
           ||'|'|| substr(cc.ccnumber,9)
           ||'|'|| cc.last_update_date line
      FROM apps.iby_creditcard cc
     WHERE UPPER (cc.chname) LIKE '%' || UPPER (p_first_name) || '%' || UPPER (p_last_name) || '%'
     ORDER BY cc.last_update_date desc,cc.ccnumber desc;    
        
    --
    -- Card Linking
    --

    CURSOR c_card_link IS    
    SELECT acpa.card_program_name
           ||'|'|| ac.org_id
           ||'|'|| cc.creation_date            
           ||'|'|| ac.creation_date
           ||'|'|| ac.last_updated_by          
           ||'|'|| cc.last_update_date
           ||'|'|| cc.chname
           ||'|'''|| substr(cc.ccnumber,9) 
           ||'|'|| ac.inactive_date line
      FROM apps.ap_cards_all ac,
           apps.iby_creditcard cc,
           --ap.ap_card_programs_all acpa  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		   apps.ap_card_programs_all acpa  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
     WHERE ac.card_reference_id = cc.instrid
       AND acpa.card_program_id = ac.card_program_id
       AND ac.employee_id = p_person_id;
    
    --
    -- CC TRX Detail
    --
    CURSOR c_cc_trx IS    
    SELECT     accta.creation_date 
       ||'|'|| transaction_date
       ||'|'|| transaction_amount     
       ||'|'|| validate_code       
       ||'|'|| report_header_id
       ||'|'|| billed_date
       ||'|'|| billed_amount         
       ||'|'|| currency_conversion_rate
       ||'|'''|| reference_number
       ||'|'|| merchant_name1
       ||'|'|| merchant_name2
       ||'|'|| merchant_city
       ||'|'|| merchant_province_state 
       ||'|'|| merchant_country             
       ||'|'|| folio_type line
        FROM apps.ap_credit_card_trxns_all accta
       WHERE accta.card_id IN (SELECT ac.card_id
                                 FROM apps.ap_cards_all ac
                                WHERE ac.employee_id = p_person_id --785339 --
                                )
    ORDER BY transaction_date DESC;
            
    --
    -- Emp Access/Link TRX Detail
    --
    CURSOR c_cc_trx_det IS  
    SELECT     papf.EMPLOYEE_NUMBER
       ||'|'|| papf.FULL_NAME
       ||'|'|| hla.LOCATION_CODE 
       --paaf.SET_OF_BOOKS_ID "Emp HR SOB", 
       ||'|'|| emp_hou.name 
       ||'|'|| u.user_name
       ||'|'|| b.responsibility_name 
       ||'|'|| a.START_DATE
       ||'|'|| a.END_DATE          
         --ac.ORG_ID, 
         --cl_hou.name "Card Linked to Oracle OU",  
         --accta.ORG_ID,
       ||'|'|| feed_hou.name         
       ||'|'|| acpa.CARD_PROGRAM_NAME  
       ||'|'|| ac.CREATION_DATE 
       ||'|'|| ac.last_update_DATE  
       ||'|'|| ac.INACTIVE_DATE                 
       ||'|'''|| substr(cc.ccnumber,9)
       ||'|'|| accta.TRANSACTION_DATE
       ||'|'|| accta.TRANSACTION_AMOUNT 
       ||'|'|| accta.VALIDATE_CODE
       ||'|'|| REPORT_HEADER_ID 
       ||'|'|| accta.BILLED_CURRENCY_CODE
       ||'|'|| accta.BILLED_AMOUNT
       ||'|'|| CURRENCY_CONVERSION_RATE    line
    FROM APPS.AP_CREDIT_CARD_TRXNS_ALL accta
       --, AP.AP_CARD_PROGRAMS_ALL acpa	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   , APPS.AP_CARD_PROGRAMS_ALL acpa	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
       , APPS.AP_CARDS_ALL AC
       , APPS.IBY_CREDITCARD cc
       , PER_ALL_PEOPLE_F papf
       , PER_ALL_ASSIGNMENTS_F paaf
       , HR.HR_LOCATIONS_ALL hla
       , apps.FND_USER_RESP_GROUPS_DIRECT  a 
       --, applsys.fnd_user u		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   , apps.fnd_user u		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
       , apps.FND_RESPONSIBILITY_vl b 
       , apps.hr_operating_units cl_hou  
       --, gl.gl_ledgers emp_hou   	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
	   , APPS.gl_ledgers emp_hou   	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
       , apps.hr_operating_units feed_hou    
    WHERE hla.LOCATION_ID = paaf.LOCATION_ID
    and accta.TRANSACTION_DATE BETWEEN papf.EFFECTIVE_START_DATE AND papf.EFFECTIVE_END_DATE
    and accta.TRANSACTION_DATE BETWEEN paaf.EFFECTIVE_START_DATE AND paaf.EFFECTIVE_END_DATE
    and paaf.PERSON_ID = papf.PERSON_ID
    and papf.PERSON_ID = ac.EMPLOYEE_ID
    AND cl_hou.ORGANIZATION_ID = acpa.ORG_ID
    AND emp_hou.LEDGER_ID = paaf.SET_OF_BOOKS_ID
    and feed_hou.ORGANIZATION_ID = accta.ORG_ID
    and a.RESPONSIBILITY_ID = b.RESPONSIBILITY_ID
    and a.USER_ID = u.USER_ID
    and cc.INSTRID = ac.CARD_REFERENCE_ID
    and u.employee_id = ac.EMPLOYEE_ID
    and b.responsibility_name like '%Internet%Expen%'
    and ac.card_program_id = acpa.CARD_PROGRAM_ID
    --and ac.ORG_ID = 161
    and ac.CARD_ID = accta.CARD_ID
    --and ac.ORG_ID in ( select org_id
    --from ap.ap_card_programs_all
    --where card_brand_lookup_code = 'American Express' )--'MasterCard') 
    --and  papf.EMPLOYEE_NUMBER = '3099958' -- '3099958' 
    and papf.person_id = p_person_id 
    and transaction_date is not null
    and accta.TRANSACTION_DATE BETWEEN a.START_DATE  AND nvl(a.END_DATE,'31-DEC-4712')
    Order by    accta.TRANSACTION_DATE desc      ;
        
BEGIN
     
       p_emp_no     := '&1';
       p_first_name := '&2';
       p_last_name  := '&3';       
       
       p_person_id  := '';
              
              
       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech CreditCard TRX Detail');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'         p_emp_no: '||p_emp_no);
       FND_FILE.PUT_LINE(FND_FILE.Log,'     p_first_name: '||p_first_name);
       FND_FILE.PUT_LINE(FND_FILE.Log,'      p_last_name: '||p_last_name);              


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TeleTech CreditCard TRX Detail - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));                                          
    
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Card Holder - Employee Information');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Business Group ID'
                                           ||'|'|| 'Employee Full Name' 
                                           ||'|'|| 'Employee Number'                                            
                                           ||'|'|| 'Employee First Name'
                                           ||'|'|| 'Employee Last Name' 
                                           ||'|'|| 'Location Code'
                                           ||'|'|| 'SOB Name'                                                                                      
                                          );                                                                               
                                          
       FOR v_list IN c_emp LOOP

           p_person_id := v_list.person_id;
           
           IF p_first_name is null THEN
              p_first_name := v_list.first_name;
           END IF;

           IF p_last_name is null THEN
              p_last_name := v_list.last_name;
           END IF;
                      
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line);

       END LOOP;

           
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Credit Card(s) Information');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Card Holder Name' 
                                           ||'|'|| 'Last 7 Digits CC Number'                                            
                                           ||'|'|| 'Last Updated Date'                                                                                    
                                          );                                          
                                                                                    
       FOR v_list IN c_card LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line);

       END LOOP;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Card Linking Information');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Card Program Name Linked To' 
                                           ||'|'|| 'Card Link ORG ID'     
                                           ||'|'|| 'Card Load/Creation Date'                                                                                  
                                           ||'|'|| 'Card Link Creation Date'
                                           ||'|'|| 'Card Link Last Updated By'
                                           ||'|'|| 'Card Link Last Updated Date'                                           
                                           ||'|'|| 'Card Holder Name'
                                           ||'|'|| 'Last 7 Digits CC Number'                                           
                                           ||'|'|| 'Card Link Inactive Date'                                                                                     
                                          );                                          
         
                                          
       FOR v_list IN c_card_link LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line );

       END LOOP;
       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Credit Card Transactions');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Oracle Load Date'
                                           ||'|'|| 'Transaction Date' 
                                           ||'|'|| 'Transaction Amount' 
                                           ||'|'|| 'Validation Code'
                                           ||'|'|| 'Report Hearder ID'
                                           ||'|'|| 'Billed Date'      
                                           ||'|'|| 'Billed Amount'                                                                                    
                                           ||'|'|| 'Currency Conversion Rate'
                                           ||'|'|| 'TRX Reference Number'
                                           ||'|'|| 'Merchant Name 1'
                                           ||'|'|| 'Merchant Name 2'
                                           ||'|'|| 'Merchant City'
                                           ||'|'|| 'Merchant State/Province'
                                           ||'|'|| 'Merchant Country'
                                           ||'|'|| 'Folio Type'                                                                                                                               
                                          );                                          
                                          
       FOR v_list IN c_cc_trx LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line );

       END LOOP;       
                                  
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Credit Card Transactions Details');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
      
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Employee Number'
                                           ||'|'|| 'Employee Full Name' 
                                           ||'|'|| 'Location Code'   
                                           ||'|'|| 'Employee HR SOB Name' 
                                           ||'|'|| 'User Name'
                                           ||'|'|| 'Responsibility Assigned'   
                                           ||'|'|| 'Resp Start Date' 
                                           ||'|'|| 'Resp End Date'      
                                           ||'|'|| 'AMEX Feed From BCA'
                                           ||'|'|| 'Card Linked To'
                                           ||'|'|| 'Card Link On'
                                           ||'|'|| 'Card Link Last Updated'
                                           ||'|'|| 'Card Link Inactive Date'
                                           ||'|'|| 'Last 7 Digits CC Number'                                                                                                                                                                      
                                           ||'|'|| 'Transaction Date' 
                                           ||'|'|| 'Transaction Amount' 
                                           ||'|'|| 'Validation Code'
                                           ||'|'|| 'Report Hearder ID'
                                           ||'|'|| 'Billed Currency Code'      
                                           ||'|'|| 'Billed Amount'                                                                                    
                                           ||'|'|| 'Currency Conversion Rate'                                                                                                                               
                                          );                                          
                                          
       FOR v_list IN c_cc_trx_det LOOP

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

--
-- Program Name:  TTEC_AMEX_CARD_PROGRAM
-- /* $Header: TTEC_AMEX_CARD_PROGRAM.sql 1.0 2016/10/10 chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 10-OCT-2016
--
-- Call From: Concurrent Program -> TeleTech AMEX Card Programs
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
--      1.0   21-JULY-2023   NXGARIKAPATI(ARGANO)   R12.2 Upgrade Remediation    
--
DECLARE

        p_sob_id           number := '';
        p_as_of_dt         date := '';

    --
    -- US Travel Card
    --
    CURSOR c_list IS
    SELECT acpa.org_id 
           ||'|'|| hou.name 
           ||'|'|| acpa.gl_program_name 
           ||'|'|| acpa.card_program_name
           ||'|'|| acpa.card_type_lookup_code 
           ||'|'|| acpa.card_program_currency_code
           ||'|'|| acpa.attribute1  
           ||'|'|| acpa.attribute2  
           ||'|'|| acpa.attribute3 
           ||'|'|| acpa.attribute4 
           ||'|'|| acpa.attribute5 
           ||'|'|| acpa.attribute1 
           ||'|'|| assa.vendor_site_code line
      --START R12.2 Upgrade Remediation
	  /*FROM ap.ap_card_programs_all acpa, 
           ap.ap_supplier_sites_all assa,*/
	  FROM apps.ap_card_programs_all acpa, 
           apps.ap_supplier_sites_all assa,	   
	  --End R12.2 Upgrade Remediation	   
           apps.hr_operating_units hou
    where card_brand_lookup_code = 'American Express'
    AND hou.ORGANIZATION_ID = acpa.ORG_ID
    and assa.VENDOR_SITE_ID = acpa.VENDOR_SITE_ID
    and card_type_lookup_code = 'TRAVEL'
    and acpa.attribute4 is not null
    and card_program_name not LIKE 'PCARD%'
    and gl_program_name is null;
    
    --
    -- Global Card
    --
    CURSOR c_list_1 IS
    SELECT acpa.org_id 
           ||'|'|| hou.name 
           ||'|'|| acpa.gl_program_name 
           ||'|'|| acpa.card_program_name
           ||'|'|| acpa.card_type_lookup_code 
           ||'|'|| acpa.card_program_currency_code
           ||'|'|| acpa.attribute1  
           ||'|'|| acpa.attribute2  
           ||'|'|| acpa.attribute3 
           ||'|'|| acpa.attribute4 
           ||'|'|| acpa.attribute5 
           ||'|'|| acpa.attribute1 
           ||'|'|| assa.vendor_site_code line
      --START R12.2 Upgrade Remediation
	  /*FROM ap.ap_card_programs_all acpa, 
           ap.ap_supplier_sites_all assa,*/
	   FROM apps.ap_card_programs_all acpa, 
            apps.ap_supplier_sites_all assa,	   
	  --End R12.2 Upgrade Remediation	   
           apps.hr_operating_units hou
    where card_brand_lookup_code = 'American Express'
    AND hou.ORGANIZATION_ID = acpa.ORG_ID
    and assa.VENDOR_SITE_ID = acpa.VENDOR_SITE_ID
    and card_type_lookup_code = 'TRAVEL'
    --and attribute4 is not null
    and card_program_name not LIKE 'PCARD%'
    and gl_program_name is not null;
    
    --
    -- PCard
    --
    CURSOR c_list_2 IS
    SELECT acpa.org_id 
           ||'|'|| hou.name 
           ||'|'|| acpa.gl_program_name 
           ||'|'|| acpa.card_program_name
           ||'|'|| acpa.card_type_lookup_code 
           ||'|'|| acpa.card_program_currency_code
           ||'|'|| acpa.attribute1  
           ||'|'|| acpa.attribute2  
           ||'|'|| acpa.attribute3 
           ||'|'|| acpa.attribute4 
           ||'|'|| acpa.attribute5 
           ||'|'|| acpa.attribute1 
           ||'|'|| assa.vendor_site_code line
	  --START R12.2 Upgrade Remediation	   
      /*FROM ap.ap_card_programs_all acpa, 
           ap.ap_supplier_sites_all assa,*/
	  FROM apps.ap_card_programs_all acpa, 
           apps.ap_supplier_sites_all assa,	   
	  --End R12.2 Upgrade Remediation	   
           apps.hr_operating_units hou
    where card_brand_lookup_code = 'American Express'
    AND hou.ORGANIZATION_ID = acpa.ORG_ID
    and assa.VENDOR_SITE_ID = acpa.VENDOR_SITE_ID
    and card_type_lookup_code = 'TRAVEL'
    AND card_program_name LIKE 'PCARD%';
            
BEGIN

       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech AMEX Card Programs ');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
--       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
--       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
--       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
--       FND_FILE.PUT_LINE(FND_FILE.Log,'         SPB/Ledger ID: '||p_sob_id);


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TeleTech AMEX Card Programs  - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));                                          

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'List Of AMEX - US Travel Cards');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ORG ID'
                                           ||'|'|| 'Operationg Unit Name' 
                                           ||'|'|| 'GL Program Name'                                            
                                           ||'|'|| 'Card Program Name'
                                           ||'|'|| 'Card Type' 
                                           ||'|'|| 'Card Program Currency Code'
                                           ||'|'|| 'Load Number'
                                           ||'|'|| 'CID'
                                           ||'|'|| 'Book Number'
                                           ||'|'|| 'BCA Number'
                                           ||'|'|| 'ISO Currency Code'
                                           ||'|'|| 'ISO Country Code'
                                           ||'|'|| 'Vendor Site Code'                                          
                                          );                                          
                                          
       FOR v_list IN c_list LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line );

       END LOOP;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'List Of AMEX - Global Cards');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ORG ID'
                                           ||'|'|| 'Operationg Unit Name' 
                                           ||'|'|| 'GL Program Name'                                            
                                           ||'|'|| 'Card Program Name'
                                           ||'|'|| 'Card Type' 
                                           ||'|'|| 'Card Program Currency Code'
                                           ||'|'|| 'Load Number'
                                           ||'|'|| 'CID'
                                           ||'|'|| 'Book Number'
                                           ||'|'|| 'BCA Number'
                                           ||'|'|| 'ISO Currency Code'
                                           ||'|'|| 'ISO Country Code'
                                           ||'|'|| 'Vendor Site Code'                                          
                                          );                                          
                                          
       FOR v_list IN c_list_1 LOOP

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_list.line );

       END LOOP;

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'List Of AMEX - PCards');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ORG ID'
                                           ||'|'|| 'Operationg Unit Name' 
                                           ||'|'|| 'GL Program Name'                                            
                                           ||'|'|| 'Card Program Name'
                                           ||'|'|| 'Card Type' 
                                           ||'|'|| 'Card Program Currency Code'
                                           ||'|'|| 'Load Number'
                                           ||'|'|| 'CID'
                                           ||'|'|| 'Book Number'
                                           ||'|'|| 'BCA Number'
                                           ||'|'|| 'ISO Currency Code'
                                           ||'|'|| 'ISO Country Code'
                                           ||'|'|| 'Vendor Site Code'                                          
                                          );                                          
                                          
       FOR v_list IN c_list_2 LOOP

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

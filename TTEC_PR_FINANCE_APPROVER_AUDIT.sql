--
-- Program Name:  TTEC_PR_FINANCE_APPROVER_AUDIT
-- /* $Header: TTEC_PR_FINANCE_APPROVER_AUDIT.sql 1.0 2014/08/29  chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 29-AUG-2014
--
-- Call From: Concurrent Program -> TeleTech Purchase Requisition Finance Approver Audit
--      Desc: These reports will be used by Purchase department to identify which PR's 
--            are not routed to Finance and to all level of approvers 
--
--     Parameter Description:
--
--       Oracle Standard Parameters:
--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      1.0  08/29/14   CChan     Initial Version
--     1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)     R12.2 Upgrade Remediation   

DECLARE
--       p_org_id  NUMBER(10):='';
--       p_pr_no  VARCHAR2(30):='';
--       p_dt_fr  DATE:='';
--       p_dt_to  DATE:='';
       p_preparer_id  NUMBER(20):='';

	  CURSOR c_pr_dtl IS
            SELECT  mcv.CATEGORY_CONCAT_SEGS
                 -- , prha.REQUISITION_HEADER_ID     
                  ||'|'|| prha.SEGMENT1 --requisition_no --  ,poah.ACTION_DATE    
                  ||'|'|| prha.CREATION_DATE           
                  ||'|'|| prha.ORG_ID
                  ||'|'|| o.name line                  
            from HR_ORGANIZATION_UNITS o
               , apps.mtl_categories_v mcv
			   --START R12.2 Upgrade Remediation	
               /*, po.po_action_history poah   
               , po.PO_REQ_DISTRIBUTIONS_ALL prda
               , po.PO_REQUISITION_LINES_ALL prla
               , po.PO_REQUISITION_HEADERS_ALL prha*/
			   , apps.po_action_history poah   
               , apps.PO_REQ_DISTRIBUTIONS_ALL prda
               , apps.PO_REQUISITION_LINES_ALL prla
               , apps.PO_REQUISITION_HEADERS_ALL prha
			   --End R12.2 Upgrade Remediation	
            where  o.organization_id = prha.ORG_ID   
            and mcv.structure_name = 'PO Item Category' 
            and mcv.CATEGORY_ID = prla.CATEGORY_ID
            and prda.PROJECT_ID is NULL -- restricted to this, since project doesn't require Finance approval     
            and prda.REQUISITION_LINE_ID = prla.REQUISITION_LINE_ID
            and prla.REQUISITION_HEADER_ID = prha.REQUISITION_HEADER_ID 
            and poah.object_id = prha.requisition_header_id
            and trunc(poah.ACTION_DATE) >= TO_DATE('14-SEP-2013') -- Live Date with Finance approver Lookup Code
            AND trunc(prha.CREATION_DATE) >= TO_DATE('14-SEP-2013') -- Live Date with Finance approver Lookup Code
            --and prha.SEGMENT1 in ('11724', '48466', '23036')
            --and prha.ORG_ID = NVL(p_org_id,prha.ORG_ID)
            and mcv.CATEGORY_CONCAT_SEGS in
            (
             select flv.meaning --, flv.lookup_type,flv.lookup_code         
             --FROM apps.FND_LOOKUP_VALUES_VL flv, apps.fnd_lookup_types_VL fltv, hr.PER_ALL_PEOPLE_F PAPF	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			 FROM apps.FND_LOOKUP_VALUES_VL flv, apps.fnd_lookup_types_VL fltv, apps.PER_ALL_PEOPLE_F PAPF	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
             WHERE  fltv.lookup_type = flv.lookup_type
                      AND fltv.description In ( 'TTEC_AME_SOURCE_APPROVER', 'TTEC_AME_FIN_APPROVER')            
                      AND PAPF.EMPLOYEE_NUMBER = fltv.meaning
                      AND TRUNC(SYSDATE) BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
                      AND CURRENT_EMPLOYEE_FLAG = 'Y'
            )
            HAVING  ( SELECT  count(*)         
                       --FROM apps.FND_LOOKUP_VALUES_VL flv, apps.fnd_lookup_types_VL fltv, hr.PER_ALL_PEOPLE_F PAPF	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
					   FROM apps.FND_LOOKUP_VALUES_VL flv, apps.fnd_lookup_types_VL fltv, apps.PER_ALL_PEOPLE_F PAPF	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                      WHERE fltv.lookup_type = flv.lookup_type
                        and fltv.description = 'TTEC_AME_FIN_APPROVER'            
                        AND PAPF.EMPLOYEE_NUMBER = fltv.meaning
                        AND papf.person_id in ( SELECT  poah1.employee_id -- Just added this one to ensure that the approver is the finance approver
                                                --FROM po.po_action_history poah1  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
												FROM apps.po_action_history poah1  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                                where poah1.object_id = prha.requisition_header_id )          
                        AND TRUNC(SYSDATE) BETWEEN papf.EFFECTIVE_START_DATE AND papf.EFFECTIVE_END_DATE
                        --AND papf.CURRENT_EMPLOYEE_FLAG = 'Y' -- Approver on old PR may no longer work for TTEC
                        --and flv.meaning = mcv.CATEGORY_CONCAT_SEGS --category is not important, as long as we have a finance approver
                        )  = 0
            GROUP BY mcv.CATEGORY_CONCAT_SEGS
                  ,  prha.requisition_header_id
                  ,  prha.SEGMENT1  --  ,poah.ACTION_DATE  
                  ,  prha.CREATION_DATE
                  ,  prha.ORG_ID      
                  ,  o.name;

BEGIN

       --mo_global.set_policy_context('S',16899);
       --apps.FND_CLIENT_INFO.set_org_context(apps.FND_PROFILE.value('ORG_ID'));

       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech Purchase Requition Finance Approver Audit');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');


       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Category Concat Segments'		||'|'||
                                         'Requisition No'               ||'|'||
                                         'PR Creation Date'             ||'|'||                                         
                                         'ORG ID'    	                ||'|'||                 
                                         'Organization Name'      	         
                                          );

       FOR v_pr_dtl IN c_pr_dtl LOOP
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_pr_dtl.line);
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



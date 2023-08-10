--
-- Program Name:  TTEC_PR_APPROVAL_HISTORY
-- /* $Header: TTEC_PR_APPROVAL_HISTORY.sql 1.0 2014/03/14  chchan ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Christiane Chan
--      Date: 13-MAR-2014
--
-- Call From: Concurrent Program -> TeleTech Purchase Requisition Approval History
--      Desc: These reports will be used by Purchase department to analyse the life time of purchase requisition
--            from creation until all approvals are obtained 
--
--     Parameter Description:
--
--
--         p_pr_no            : Purchase Requisition No
--
--       Oracle Standard Parameters:
--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      1.0  03/13/14   CChan     Initial Version
--      1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)     R12.2 Upgrade Remediation            |

DECLARE
       p_org_id  NUMBER(10):='';
       p_pr_no  VARCHAR2(30):='';
       p_dt_fr  DATE:='';
       p_dt_to  DATE:='';
       p_preparer_id  NUMBER(20):='';

	  CURSOR c_org IS
          select distinct rha.org_id
          --FROM po.po_requisition_headers_all rha  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023  
		  FROM apps.po_requisition_headers_all rha   -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
           where trunc(rha.creation_date) between NVL(to_date(p_dt_fr),trunc(rha.creation_date)) and NVL(to_date(p_dt_to),trunc(rha.creation_date))
           and rha.org_id = NVL(p_org_id,rha.org_id)         
           order by 1;

	  CURSOR c_pr_dtl IS
          SELECT rha.org_id                 ||'|'||
                 to_char(rha.creation_date,'DD-MON-YYYY HH24:MI:SS' )            ||'|'||
                 rha.segment1               ||'|'||
                 to_char(ah.sequence_num,'000')      	    ||'|'||                 
                 rha.authorization_status   ||'|'||
                 apps.po_inq_sv.get_person_name(rha.preparer_id)  ||'|'||
                 --ah.created_by    	    	||'|'||
                 --ah.employee_id    		||'|'||
                 to_char(ah.action_date,'DD-MON-YYYY HH24:MI:SS' )              ||'|'||
                 ah.action_code_dsp         ||'|'||
                 ah.employee_name           ||'|'||
                 ttec_library.remove_non_ascii (TRIM(TRANSLATE(NVL(ah.note,'NONE'),'???~!@#$%^&*()+{}|:"<>?=[]\/"',' ' )))                 ||'|'||
                 (select segment1
                 from po_vendors
                 where VENDOR_NAME = rla.suggested_vendor_name
                 and rownum <2 )            ||'|'||                 
                 rla.suggested_vendor_name  ||'|'||
                 rla.suggested_vendor_location    ||'|'||
                 to_char(rla.need_by_date,'DD-MON-YYYY HH24:MI:SS' )            ||'|'||
                 rla.line_num               ||'|'||
                 rla.quantity               ||'|'||
                 rla.uom_class_dsp          ||'|'||
                 rla.quantity_received      ||'|'||
                 rla.quantity_delivered     ||'|'||
                 rla.quantity_cancelled     ||'|'||
                 rla.urgent                 ||'|'||
                 rla.requesting_org         ||'|'||
                 rla.purchasing_org         ||'|'||
                 rla.dest_organization      ||'|'||
                 rla.deliver_to_location    ||'|'||
                 rla.attribute6             ||'|'||
                (select employee_number
                 from per_all_people_f
                 where person_id =  rla.to_person_id
                 and trunc(rha.creation_date) between effective_start_date and effective_end_date
                 and rownum <2                 
                 )                          ||'|'||
                 apps.po_inq_sv.get_person_name(rla.to_person_id)  ||'|'||                                         
                 ttec_library.remove_non_ascii (TRIM(TRANSLATE(NVL(rla.req_description,'NONE'),'???~!@#$%^&*()+{}|:"<>?=[]\/"',' ' ))) ||'|'||
                 ttec_library.remove_non_ascii (TRIM(TRANSLATE(NVL(rla.item_description,'NONE'),'???~!@#$%^&*()+{}|:"<>?=[]\/"',' ' )))                                        
                  line    
                 --ias.item_key    ||'|'||
                 --ias.begin_date    ||'|'||
                 --ias.end_date    ||'|'||
                 --ias.activity_result_code RESULT    ||'|'||
           FROM apps.po_action_history_v ah,
                po_requisition_lines_inq_v rla,
                --po.po_requisition_headers_all rha	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				apps.po_requisition_headers_all rha	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                --applsys.wf_item_activity_statuses ias
          WHERE ah.object_id = rha.requisition_header_id
            AND rla.requisition_header_id = rha.requisition_header_id
            --AND trunc(rha.creation_date) between p_dt_fr and p_dt_to
            AND trunc(rha.creation_date) between NVL(to_date(p_dt_fr),trunc(rha.creation_date)) and NVL(to_date(p_dt_to),trunc(rha.creation_date)) 
            AND rha.preparer_id = NVL(p_preparer_id,rha.preparer_id)
            --AND rha.wf_item_key = ias.item_key(+)
            AND rla.org_id = rha.org_id
            AND object_type_code = 'REQUISITION'
            AND rha.segment1 = NVL(p_pr_no,rha.segment1)
            --AND ias.item_type (+) = 'REQAPPRV'
            --AND rha.org_id = p_org_id
        ORDER BY 1;

BEGIN
       p_org_id := '&1';
       p_pr_no  := '&2';
       p_dt_fr  := '&3';
       p_dt_to  := '&4';
       p_preparer_id  := '&5';


       --mo_global.set_policy_context('S',16899);
       --apps.FND_CLIENT_INFO.set_org_context(apps.FND_PROFILE.value('ORG_ID'));

       FND_FILE.PUT_LINE(FND_FILE.Log,'TeleTech Purchase Requition Approval History');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'             Org ID: '||p_org_id);       
       FND_FILE.PUT_LINE(FND_FILE.Log,'              PR No: '||p_pr_no);
       FND_FILE.PUT_LINE(FND_FILE.Log,'          From Date: '||p_dt_fr);
       FND_FILE.PUT_LINE(FND_FILE.Log,'            To Date: '||p_dt_to);
       FND_FILE.PUT_LINE(FND_FILE.Log,'        Preparer ID: '||p_preparer_id);

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ORG ID'		                ||'|'||
                                         'PR Creation Date'             ||'|'||
                                         'Requisition No'               ||'|'||
                                         'Action Sequence no'    	||'|'||                                         
                                         'Authorization Status'         ||'|'||
                                         'Preparer'			        ||'|'||
                                         'Action Date'             	||'|'||
                                         'Action Code'	          	||'|'||
                                         'Approver'             	||'|'||
                                         'Note'                    	||'|'||
                                         'Suggested Vendor Number'  ||'|'||
                                         'Suggested Vendor Name'  	||'|'||
                                         'Suggested Vendor Location'    ||'|'||
                                         'Need By Date'           	||'|'||
                                         'Line No'               	||'|'||                                         
                                         'Quantity'	                ||'|'||
                                         'UOM Class'		        ||'|'||
                                         'Quantity Received'      	||'|'||
                                         'Quantity Delivered'     	||'|'||
                                         'Quantity Cancelled'    	||'|'||
                                         'Urgent'                 	||'|'||
                                         'Requesting Org'         	||'|'||
                                         'Purchasing Org'        	||'|'||
                                         'Dest Organization'      	||'|'||
                                         'Deliver To Location'    	||'|'||
                                         'GL Department Code'    	||'|'||
                                         'Requestor Employee NO'    ||'|'||
                                         'Requestor'                ||'|'||
                                         'Requisition Description'  ||'|'||
                                         'Item Description'	        
                                          );

       FOR v_org IN c_org LOOP
           mo_global.set_policy_context('S',v_org.org_id);
           FND_FILE.PUT_LINE(FND_FILE.Log,'Processing Org ID: '||v_org.org_id);
           FOR v_pr_dtl IN c_pr_dtl LOOP
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_pr_dtl.line);
           END LOOP;
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



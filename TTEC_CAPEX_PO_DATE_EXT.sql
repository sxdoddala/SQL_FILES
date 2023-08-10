--
-- Program Name:  TTEC_CAPEX_PO_DATE_EXT.sql
-- /* $Header: TTEC_CAPEX_PO_DATE_EXT.sql 1.0 2015/01/13 aaslam ship $ */
--
-- /*== START ================================================================================================*\
--    Author: Amir Aslam
--
--
--     Parameter Description:
--
--
--       p_as_Of_dt            : As Of Date if no value, will default to SYSDATE
--       p_as_to_dt            : As to Date.

--
--   Modification History:
--
--  Version    Date     Author   Description (Include Ticket--)
--  -------  --------  --------  ------------------------------------------------------------------------------
--      1.0  03/27/19   AAslam    Initial Version
--      1.0   21-JULY-2023 NXGARIKAPATI(ARGANO)     R12.2 Upgrade Remediation           

DECLARE

        p_as_Of_dt      date := '';
        p_end_date      date := '';

    CURSOR c_user IS
SELECT
       sob.name "SET_OF_BOOKS",
       ph.segment1 "PO_NUM",
       pl.line_num "LINE_NUM",
        haou.name "ORG_NAME",
       ph.authorization_status "STATUS",
       ph.creation_date "HEADER_CREATION_DATE",
       ph.type_lookup_code "TYPE",
       ph.currency_code "CURRENCY_CODE",
       (SELECT ap.vendor_name
          from apps.ap_suppliers ap
         WHERE ap.vendor_id = ph.vendor_id) "VENDOR_NAME",
       (SELECT aps.vendor_site_code
          from apps.ap_supplier_sites_all aps
         WHERE aps.vendor_id = ph.vendor_id
           AND aps.vendor_site_id = ph.vendor_site_id) "VENDOR_SITE_NAME",
       pl.item_description "ITEM_DESC",
       (SELECT mck.concatenated_segments
          FROM apps.mtl_categories_kfv mck
         where mck.category_id = pl.category_id) "CATEGORY_NAME",
       pl.unit_price "UNIT_PRICE",
       pd.quantity_ordered - pd.quantity_cancelled "QUANTITY",
       pl.unit_meas_lookup_code "UOM",
       (pd.quantity_ordered - pd.quantity_cancelled) * pl.unit_price "AMOUNT",
          decode(ph.currency_code,'USD',1,
               (select conversion_rate
         --from gl.gl_daily_rates gdr	-- Commented code by NXGARIKAPATI-ARGANO, 24/07/2023 
		 from apps.gl_daily_rates gdr	-- Added code by NXGARIKAPATI-ARGANO, 24/07/2023 
         where gdr.FROM_CURRENCY = ph.currency_code
         and gdr.TO_CURRENCY = 'USD'
         and gdr.CONVERSION_TYPE = 'Spot'
         and gdr.conversion_date = trunc(sysdate) ) )  "RATE",
       ROUND(((pd.quantity_ordered - pd.quantity_cancelled) * pl.unit_price ) * decode(ph.currency_code,'USD',1,
               (select conversion_rate
         --from gl.gl_daily_rates gdr  -- Commented code by NXGARIKAPATI-ARGANO, 24/07/2023 
		 from apps.gl_daily_rates gdr  -- Added code by NXGARIKAPATI-ARGANO, 24/07/2023 
         where gdr.FROM_CURRENCY = ph.currency_code
         and gdr.TO_CURRENCY = 'USD'
         and gdr.CONVERSION_TYPE = 'Spot'
         and gdr.conversion_date = trunc(sysdate) )  )
       , 2) "AMOUNT_USD",       
       pll.line_location_id "LINE_LOCATION_ID",
       -- gcc.code_combination_id "CODE COMBINATION ID",
      gcc.segment1 "LOCATION",
      gcc.segment2 "CLIENT",
      gcc.segment3 "DEPARTMENT",
      gcc.segment4 "ACCOUNT",
      gcc.segment5 "INTERCOMPANY",
      gcc.segment6 "FUTURE",
      gcc.segment1|| '.' ||gcc.segment2|| '.' ||gcc.segment3|| '.' ||gcc.segment4|| '.' ||gcc.segment5|| '.' ||gcc.segment6 "CHARGE_ACCOUNT",
(
                    select substr('Req Num [' ||r.segment1||'] Justification -> ' ||   
                            REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(r.NOTE_TO_AUTHORIZER,CHR(10)),CHR(12)),CHR(13)),CHR(27)),'~'), '[^[:alnum:] ]*', ''), 1,400)
                    --START R12.2 Upgrade Remediation
					/*from po.po_headers_all p,   
                    po.po_distributions_all d,  
                    po.po_req_distributions_all rd,   
                    po.po_requisition_lines_all rl,  
                    po.po_requisition_headers_all r   */
					from apps.po_headers_all p,   
                    apps.po_distributions_all d,  
                    apps.po_req_distributions_all rd,   
                    apps.po_requisition_lines_all rl,  
                    apps.po_requisition_headers_all r   
					--End R12.2 Upgrade Remediation
                    where p.po_header_id = d.po_header_id   
                    and d.req_distribution_id = rd.distribution_id   
                    and rd.requisition_line_id = rl.requisition_line_id   
                    and rl.requisition_header_id = r.requisition_header_id  
                    and p.segment1 = ph.SEGMENT1
                    and rownum < 2
                     ) "JUSTIFICATION"
  --START R12.2 Upgrade Remediation
  /*FROM po.po_headers_all              ph,
       po.po_lines_all                pl,
       po.po_line_locations_all       pll,
       po.po_distributions_all        pd,
       gl.gl_code_combinations        gcc,*/
	FROM apps.po_headers_all              ph,	
       apps.po_lines_all                pl,
       apps.po_line_locations_all       pll,
       apps.po_distributions_all        pd,
       apps.gl_code_combinations        gcc,	   
  --End R12.2 Upgrade Remediation	   
       apps.hr_all_organization_units haou,
       apps.gl_sets_of_books sob
WHERE ph.po_header_id = pl.po_header_id
   AND pll.po_line_id = pl.po_Line_id
   AND pl.po_line_id = pd.po_line_id
   AND gcc.code_combination_id = pd.code_combination_id
   AND haou.organization_id = ph.org_id
   AND sob.set_of_books_id = pd.set_of_books_id
   AND pd.distribution_type = 'STANDARD'
   AND NVL( pl.cancel_flag, 'N' ) = 'N'
   AND ph.type_lookup_code = 'STANDARD'
   AND NVL( ph.cancel_flag, 'N' ) = 'N'
   AND ph.authorization_status NOT IN ('REJECTED', 'CANCELLED')
   /* Parameter section - replace NULL by desired value */
   /*	AND TRUNC(ph.creation_date)  between '01-JAN-2016' and '31-DEC-2016'	*/
   AND TRUNC(ph.creation_date) between p_as_Of_dt and p_end_date
   ORDER BY 1,2,3;


BEGIN
       p_as_Of_dt := '&1';
       p_end_date := '&2';


       --mo_global.set_policy_context('S',16899);
       --apps.FND_CLIENT_INFO.set_org_context(apps.FND_PROFILE.value('ORG_ID'));

       FND_FILE.PUT_LINE(FND_FILE.Log,'TTEC CAPEX PO Data Extract Report');
       FND_FILE.PUT_LINE(FND_FILE.Log,'Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
       FND_FILE.PUT_LINE(FND_FILE.Log,'');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'     Parameters');
       FND_FILE.PUT_LINE(FND_FILE.Log,'==========================');
       FND_FILE.PUT_LINE(FND_FILE.Log,'         Start Date: '||p_as_Of_dt);
       FND_FILE.PUT_LINE(FND_FILE.Log,'         End   Date: '||p_end_date);

       -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'TTEC CAPEX PO Data Extract Report - Submitted On: ' ||to_char(SYSDATE,'DD-MON-RRRR HH24:MI:SS')||'  As Of Date: '||NVL(p_as_Of_dt,TRUNC(SYSDATE)));
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SET_OF_BOOKS'     ||'|'||
                                         'PO_Number'        ||'|'||
                                         'LINE NUM'         ||'|'||
                                         'ORG Name' 	   	||'|'|| 
                                         'STATUS'  	    	||'|'||
                                         'Header_Creation_Date'   ||'|'||                                        
                                         'Type'        ||'|'||
                                         'Currency'          ||'|'||
                                         'Vendor_Name'      ||'|'||
                                         'Vendor_Site_Name' ||'|'||       
                                         'Item_Desc'      ||'|'||
                                         'Category Name'      ||'|'||
                                         'Unit Price'      ||'|'||
                                         'Quantity'      ||'|'||
                                         'UOM'      ||'|'||
                                         'Amount'      ||'|'||
                                         'Conversion_Rate'      ||'|'||			
                                         'USD-Amount'      ||'|'||
                                         'Line LOC ID'      ||'|'||
                                         'Location'      ||'|'||
                                         'Client'      ||'|'||
                                         'Department'      ||'|'||
                                         'Account'      ||'|'||
                                         'Intercompany'      ||'|'||
                                         'Future'      ||'|'||
                                         'Charge Account'      ||'|'||
                                         'Justification'
                                          );

    FOR v_user IN c_user LOOP

		   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_user.SET_OF_BOOKS || '|' || 
											v_user.PO_NUM	|| '|' || 
											v_user.LINE_NUM	|| '|' || 
											v_user.ORG_NAME	|| '|' || 
											v_user.STATUS	|| '|' || 
											v_user.HEADER_CREATION_DATE	|| '|' || 
											v_user.TYPE				|| '|' || 
											v_user.CURRENCY_CODE	|| '|' || 
											v_user.VENDOR_NAME		|| '|' || 
											v_user.VENDOR_SITE_NAME	|| '|' || 
											v_user.ITEM_DESC		|| '|' || 
											v_user.CATEGORY_NAME	|| '|' || 
											v_user.UNIT_PRICE		|| '|' || 
											v_user.QUANTITY			|| '|' ||
											v_user.UOM				|| '|' ||
											v_user.AMOUNT			|| '|' ||
											v_user.RATE				|| '|' ||
											v_user.AMOUNT_USD		|| '|' ||
											v_user.LINE_LOCATION_ID	|| '|' ||
											v_user.LOCATION			|| '|' || 
											v_user.CLIENT			|| '|' || 
											v_user.DEPARTMENT		|| '|' || 
											v_user.ACCOUNT			|| '|' || 
											v_user.INTERCOMPANY		|| '|' || 
											v_user.FUTURE			|| '|' || 
											v_user.CHARGE_ACCOUNT	|| '|' || 
											v_user.JUSTIFICATION
												);	   

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
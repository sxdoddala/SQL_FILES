/* Formatted on 2014/12/15 14:10 (Formatter Plus v4.8.8) */
/** Author : Kaushik Babu G - December 15 2014  Version 1.0**/
/** Desc: This particular report is used for reconcilation of TSG AR Invoices
       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
    
**/

/*** Format for Header Record **/
SET pagesize 0;
SET linesize 400;
SET wrap off;
SET feedback off;
SET verify off;
SET echo off;
SET heading off
SET termout off
SET serveroutput on

SELECT   'tsg_po_num_file'
       || '|'
       || 'tsg_part_num_file'
       || '|'
       || 'tsg_line_num_file'
       || '|'
       || 'vendor_name_file'
       || '|'
       || 'Qty_file'
       || '|'
       || 'po_num'
       || '|'
       || 'line_num'
       || '|'
       || 'line_location_id'
       || '|'
       || 'distribution_num'
       || '|'
       || 'vendor_id'
       || '|'
       || 'ship_to_location_id'
       || '|'
       || 'tsg_po_num_att'
       || '|'
       || 'tsg_po_part_att'       
       || '|'
       || 'tsg_line_num_att'
       || '|'
       || 'status_file'
       || '|'
       || 'error_desc_file'
  FROM DUAL
UNION ALL
/**** Format for Detail Record ***/
SELECT    cst.tsg_po_num
       || '|'
       || cst.tsg_part_num
       || '|'
       || cst.tsg_line_num
       || '|'
       || cst.vendor_name
       || '|'
       || cst."Qty"
       || '|'
       || cst."po_num"
       || '|'
       || cst.line_num
       || '|'
       || cst.line_location_id
       || '|'
       || cst.distribution_num
       || '|'
       || cst.vendor_id
       || '|'
       || cst.ship_to_location_id
       || '|'
       || cst."tsg_po_num_att"
       || '|'
       || cst."tsg_po_part_att"
       || '|'
       || cst."tsg_line_num_att"
       || '|'
       || cst.status
       || '|'
       || cst.error_desc
  FROM (SELECT   tpu.tsg_po_num, tpu.tsg_part_num, tpu.line_num tsg_line_num,
                 tpu.vendor_name, NVL (pla.quantity, 0) "Qty",
                 poh.segment1 "po_num", pla.line_num, plla.line_location_id,
                 pda.distribution_num, poh.vendor_id,
                 plla.ship_to_location_id, poh.attribute1 "tsg_po_num_att",
                 pla.attribute1 "tsg_po_part_att",
                 pla.attribute2 "tsg_line_num_att", tpu.status,
                 tpu.error_desc
            --START R12.2 Upgrade Remediation
			/*FROM cust.ttec_po_us_tsg_stg tpu,
                 po.po_headers_all poh,*/
			FROM apps.ttec_po_us_tsg_stg tpu,
                 apps.po_headers_all poh,
			--End R12.2 Upgrade Remediation
                 po_lines_all pla,
                 po_line_locations_all plla,
                 po_distributions_all pda
           WHERE tpu.tsg_po_num = poh.attribute1(+)
             AND poh.po_header_id = pla.po_header_id(+)
             AND pla.po_line_id = plla.po_line_id(+)
             AND pla.po_header_id = plla.po_header_id(+)
             AND pla.po_header_id = pda.po_header_id(+)
             AND pla.po_line_id = pda.po_line_id(+)
             AND tpu.create_request_id =
                                     (SELECT MAX (create_request_id)
                                        --FROM cust.ttec_po_rcpt_tsg_stg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
										FROM apps.ttec_po_rcpt_tsg_stg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       WHERE effective_date = TRUNC (SYSDATE))
        ORDER BY 1) cst;
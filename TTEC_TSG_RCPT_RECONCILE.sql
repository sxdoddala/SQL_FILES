/* Formatted on 2014/12/16 13:36 (Formatter Plus v4.8.8) */
/** Author : Kaushik Babu G - December 15 2014  Version 1.0**/
/** Desc: This particular report is used for reconcilation of TSG Receipts
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

SELECT    'transaction_id'
       || '|'
       || 'transaction_date'
       || '|'
       || 'po_unit_price'
       || '|'
       || 'destination_type_code'
       || '|'
       || 'quantity'
       || '|'
       || 'tsg_po_num'
       || '|'
       || 'tsg_part_num'
       || '|'
       || 'tsg_po_line_num'
       || '|'
       || 'vendor_id'
  FROM DUAL
UNION ALL
/**** Format for Detail Record ***/
SELECT    cst.transaction_id
       || '|'
       || cst.transaction_date
       || '|'
       || cst.po_unit_price
       || '|'
       || cst.destination_type_code
       || '|'
       || cst.quantity
       || '|'
       || cst.tsg_po_num
       || '|'
       || cst.tsg_part_num
       || '|'
       || cst.tsg_po_line_num
       || '|'
       || cst.vendor_id
  FROM (SELECT   rcvt.transaction_id, rcvt.transaction_date,
                 rcvt.po_unit_price, rcvt.destination_type_code,
                 rcvt.quantity, tprt.tsg_po_num, tprt.tsg_part_num,
                 tprt.tsg_po_line_num, tprt.vendor_id
            --FROM apps.rcv_transactions rcvt, cust.ttec_po_rcpt_tsg_stg tprt	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			FROM apps.rcv_transactions rcvt, apps.ttec_po_rcpt_tsg_stg tprt	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
           WHERE rcvt.po_header_id(+) = tprt.po_hdr_id
             AND rcvt.po_line_id(+) = tprt.po_line_id
             AND rcvt.po_line_location_id(+) = tprt.line_loc_id
             AND rcvt.po_distribution_id(+) = tprt.po_dis_id
             AND tprt.create_request_id =
                                     (SELECT MAX (create_request_id)
                                        --FROM cust.ttec_po_rcpt_tsg_stg	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
										FROM apps.ttec_po_rcpt_tsg_stg	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                                       WHERE effective_date = TRUNC (SYSDATE))
        ORDER BY 1) cst;
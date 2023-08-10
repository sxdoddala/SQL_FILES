/* Formatted on 2014/12/15 12:01 (Formatter Plus v4.8.8) */
/** Author : Kaushik Babu G - December 15 2014  Version 1.0**/
/** Desc: This particular report is used for reconcilation of TSG Customer imports

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

SELECT    'customer_name'
       || '|'
       || 'file_customer'
       || '|'
       || 'customer_number'
       || '|'
       || 'account_number'
       || '|'
       || 'status'
       || '|'
       || 'LOCATION'
       || '|'
       || 'site_use_code'
       || '|'
       || 'profile_name'
       || '|'
       || 'address1'
       || '|'
       || 'address2'
       || '|'
       || 'address3'
       || '|'
       || 'city'
       || '|'
       || 'state'
       || '|'
       || 'postal_code'
       || '|'
       || 'operating_unit'
       || '|'
       || 'client'
  FROM DUAL
UNION ALL
/**** Format for Detail Record ***/
SELECT    cst.customer_name
       || '|'
       || cst.file_customer
       || '|'
       || cst.customer_number
       || '|'
       || cst.account_number
       || '|'
       || cst.status
       || '|'
       || cst.LOCATION
       || '|'
       || cst.site_use_code
       || '|'
       || cst.profile_name
       || '|'
       || cst.address1
       || '|'
       || cst.address2
       || '|'
       || cst.address3
       || '|'
       || cst.city
       || '|'
       || cst.state
       || '|'
       || cst.postal_code
       || '|'
       || cst.operating_unit
       || '|'
       || cst.client
  FROM (SELECT DISTINCT hp.party_name customer_name,
                        ttcd.customer file_customer,
                        hp.party_number customer_number, hca.account_number,
                        hcsu.LOCATION, hcsu.site_use_code,
                        hcpc.NAME profile_name, hl.address1, hl.address2,
                        hl.address3, hl.city, hl.state, hl.postal_code,
                        hou.NAME operating_unit, hca.attribute1 client
                   FROM apps.hz_parties hp,
                        apps.hz_party_sites hps,
                        apps.hz_locations hl,
                        apps.hz_cust_accounts_all hca,
                        apps.hz_cust_acct_sites_all hcas,
                        apps.hz_cust_site_uses_all hcsu,
                        apps.hz_customer_profiles hcp,
                        apps.hz_cust_profile_classes hcpc,
                        apps.hr_operating_units hou,
                        --cust.ttec_tsg_customer_data ttcd	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						apps.ttec_tsg_customer_data ttcd	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                  WHERE hp.party_id = hca.party_id(+)
                    AND hp.party_id = hcp.party_id
                    AND hp.party_id = hps.party_id
                    AND hps.party_site_id = hcas.party_site_id
                    AND hps.location_id = hl.location_id
                    AND hca.cust_account_id = hcas.cust_account_id
                    AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                    AND hca.cust_account_id = hcp.cust_account_id
                    AND hcp.profile_class_id = hcpc.profile_class_id
                    AND hcsu.org_id = hou.organization_id
                    --AND hca.attribute_category = 'TSG'
                    AND UPPER (TRIM (hp.party_name)) = UPPER (TRIM (ttcd.customer(+)))
                    AND hou.organization_id = 30633
               ORDER BY 1) cst;
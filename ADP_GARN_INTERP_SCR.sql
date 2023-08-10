

-- +------------------------------------------------------------------------------------+
-- |                                                                                    |
-- | SQL*Plus Script "adp_garn_interp_scr.sql"                                          |
-- |                                                                                    |
-- | Purpose: Creates outbound Notification file resulting from Interpretation process  |
-- |                                                                                    |
-- | Parameters:                                                                        |
-- |    1) output_path: Full path to data file creation folder                          |
-- |                                                                                    |
-- | Created 10/6/2005 by Tom Ghali                                                     |
-- |                                                                                    |
-- | Copyright (c) 2005 Automatic Data Processing, Inc. All rights reserved             |
-- |                                                                                    |
-- +------------------------------------------------------------------------------------+
-- |                                                                                    |
-- | Change Log:                                                                        |
-- |                                                                                    |
-- | Date        Change                                                                 |
-- | ----------  --------------------------------------------------------------------   |
-- | 05/10/06    Removed test mode logic, set echo off, removed whenever, added exit    |
-- | 11/27/07    Compliance with ADP file naming specifications                         |
-- | 12/06/07    Compliance with ADP file naming specifications                         |
-- | 12/04/12    V 1.0 Modified by TTEC C. Chan to adopt TTEC environment               |
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
-- +------------------------------------------------------------------------------------+

-- establish date_stamp
column date_stamp_col new_value date_stamp noprint

select to_char(sysdate, 'YYYYMMDDHH24MISS') date_stamp_col
from dual;

-- define script parms
DEFINE output_path  = &1

-- define data output filename
column dat_path_col new_value dat_path noprint
         
/* V1.0 Commented out   
select decode(name
             ,'PROD'
             ,'&output_path/p_'||lower('TTH1')||'_wgps_&date_stamp'
             ,'&output_path/c_'||lower('TTH1')||'_wgps_test_&date_stamp'
             )  dat_path_col
  from v$database
;
*/

/* V 1.0 begin */
 select decode(HOST_NAME,ttec_library.XX_TTEC_PROD_HOST_NAME
             ,'&output_path/p_'||lower('TTH1')||'_wgps_&date_stamp'
             ,'&output_path/c_'||lower('TTH1')||'_wgps_test_&date_stamp'
             )  dat_path_col
 from v$INSTANCE; 
/* V 1.0 end */

-- set settings
set termout off
set feedback off
set verify off
set echo off
set serveroutput on size 1000000
set heading off
set linesize 500
set pagesize 0
set space 0
set wrap off
set trimspool on

-- create data file
SPOOL &dat_path..ntf

select           rtrim(substr(nvl(site_id,' ')                              ,1,4),' ')
       || '|' || rtrim(substr(nvl(ee_last_name,' ')                         ,1,14),' ')
       || '|' || rtrim(substr(nvl(ee_first_name,' ')                        ,1,17),' ')
       || '|' || rtrim(substr(nvl(ee_middle_initial,' ')                    ,1,1),' ')
       || '|' || rtrim(substr(nvl(ssn_no_dashes,' ')                        ,1,9),' ')
       || '|' || rtrim(substr(nvl(ssn_dashes,' ')                           ,1,11),' ')
       || '|' || rtrim(substr(nvl(lien_type,' ')                            ,1,1),' ')
       || '|' || rtrim(substr(nvl(lien_subtype,' ')                         ,1,1),' ')
       || '|' || rtrim(substr(nvl(case_id,' ')                              ,1,20),' ')
       || '|' || rtrim(substr(nvl(court_order_state,' ')                    ,1,2),' ')
       || '|' || rtrim(substr(nvl(to_char(lien_number),' ')                 ,1,2),' ')
       || '|' || rtrim(substr(nvl(lien_status,' ')                          ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(lien_start_date,'MM/DD/YYYY'),' '),1,10),' ')
       || '|' || rtrim(substr(nvl(to_char(lien_end_date,'MM/DD/YYYY')  ,' '),1,10),' ')
       || '|' || rtrim(substr(nvl(to_char(round(goal_amt,0)),' ')           ,1,8),' ')
       || '|' || rtrim(substr(nvl(to_char(round(deducted_amt,0)),' ')       ,1,11),' ')
       || '|' || rtrim(substr(nvl(deduction_freq,' ')                       ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(round(deducted_pct,0)),' ')       ,1,5),' ')
       || '|' || rtrim(substr(nvl(to_char(round(monthly_limit,0)),' ')      ,1,8),' ')
       || '|' || rtrim(substr(nvl(deduction_calc,' ')                       ,1,1),' ')
       || '|' || rtrim(substr(nvl(garn_rule,' ')                            ,1,180),' ')
       || '|' || rtrim(substr(nvl(garn_support_type,' ')                    ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(round(agency_fee_amt,0)),' ')     ,1,6),' ')
       || '|' || rtrim(substr(nvl(to_char(agency_fee_pct),' ')              ,1,5),' ')
       || '|' || rtrim(substr(nvl(fips_code,' ')                            ,1,7),' ')
       || '|' || rtrim(substr(nvl(to_char(payee_code),' ')                  ,1,5),' ')
       || '|' || rtrim(substr(nvl(short_user_name,' ')                      ,1,10),' ')
       || '|' || rtrim(substr(nvl(payee_name_1,' ')                         ,1,45),' ')
       || '|' || rtrim(substr(nvl(payee_name_2,' ')                         ,1,45),' ')
       || '|' || rtrim(substr(nvl(payee_address_line_1,' ')                 ,1,45),' ')
       || '|' || rtrim(substr(nvl(payee_address_line_2,' ')                 ,1,45),' ')
       || '|' || rtrim(substr(nvl(payee_city,' ')                           ,1,24),' ')
       || '|' || rtrim(substr(nvl(payee_state,' ')                          ,1,2),' ')
       || '|' || rtrim(substr(nvl(payee_zip_code,' ')                       ,1,9),' ')
       || '|' || rtrim(substr(nvl(check_payable_to,' ')                     ,1,1),' ')
       || '|' || rtrim(substr(nvl(obligee_name,' ')                         ,1,24),' ')
       || '|' || rtrim(substr(nvl(payee_contact_name,' ')                   ,1,20),' ')
       || '|' || rtrim(substr(nvl(payee_contact_phone,' ')                  ,1,10),' ')
       || '|' || rtrim(substr(nvl(to_char(round(exempt_amt,0)),' ')         ,1,8),' ')
       || '|' || rtrim(substr(nvl(freq,' ')                                 ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(dep_ex_count),' ')                ,1,3),' ')
       || '|' || rtrim(substr(nvl(memo_line_1,' ')                          ,1,40),' ')
       || '|' || rtrim(substr(nvl(memo_line_2,' ')                          ,1,40),' ')
       || '|' || rtrim(substr(nvl(payment_schedule,' ')                     ,1,3),' ')
       || '|' || rtrim(substr(nvl(to_char(round(accruing_amt,0)),' ')       ,1,6),' ')
       || '|' || rtrim(substr(nvl(to_char(accruing_period),' ')             ,1,3),' ')
       || '|' || rtrim(substr(nvl(to_char(round(employer_fee_amt,0)),' ')   ,1,5),' ')
       || '|' || rtrim(substr(nvl(to_char(round(employer_fee_pct,0)),' ')   ,1,5),' ')
       || '|' || rtrim(substr(nvl(court_name,' ')                           ,1,30),' ')
       || '|' || rtrim(substr(nvl(future_use,' ')                           ,1,1),' ')
       || '|' || rtrim(substr(nvl(priority,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(round(pro_ration_pct,0)),' ')     ,1,5),' ')
       || '|' || rtrim(substr(nvl(to_char(round(pro_ration_amt,0)),' ')     ,1,5),' ')
       || '|' || rtrim(substr(nvl(notification_indicator,' ')               ,1,1),' ')
       || '|' || rtrim(substr(nvl(interogatory_indicator,' ')               ,1,1),' ')
       || '|' || rtrim(substr(nvl(utl_indicator,' ')                        ,1,1),' ')
       || '|' || rtrim(substr(nvl(ee_address,' ')                           ,1,45),' ')
       || '|' || rtrim(substr(nvl(ee_city,' ')                              ,1,24),' ')
       || '|' || rtrim(substr(nvl(ee_state,' ')                             ,1,2),' ')
       || '|' || rtrim(substr(nvl(ee_zip,' ')                               ,1,9),' ')
       || '|' || rtrim(substr(nvl(ee_status,' ')                            ,1,16),' ')
       || '|' || rtrim(substr(nvl(employed,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(status_date,'MMDDYYYY'),' ')      ,1,8),' ')
       || '|' || rtrim(substr(nvl(to_char(round(gross_wages,0)),' ')        ,1,11),' ')
       || '|' || rtrim(substr(nvl(to_char(round(disposable_wages,0)),' ')   ,1,11),' ')
       || '|' || rtrim(substr(nvl(pay_freq,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(company_name,' ')                         ,1,45),' ')
       || '|' || rtrim(substr(nvl(company_street,' ')                       ,1,30),' ')
       || '|' || rtrim(substr(nvl(company_city,' ')                         ,1,20),' ')
       || '|' || rtrim(substr(nvl(company_state,' ')                        ,1,2),' ')
       || '|' || rtrim(substr(nvl(company_zip,' ')                          ,1,9),' ')
       || '|' || rtrim(substr(nvl(company_address_line_2,' ')               ,1,30),' ')
       || '|' || rtrim(substr(nvl(ee_address_line_2,' ')                    ,1,45),' ')
  --from TT_ADP.ADP_TTEC_ADP_GARN_NOTIF_STG		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  from ADP_TTEC_ADP_GARN_NOTIF_STG		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
;


spool off

exit


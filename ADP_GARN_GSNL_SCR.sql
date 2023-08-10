-- +------------------------------------------------------------------------------------+
-- |                                                                                    |
-- | SQL*Plus Script "adp_garn_gsnl_scr.sql"                                            |
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
-- | 5/13/09     Compliance with GSNL specs. Also added header and trailer              |
-- | 8/20/10     Increased linesize to 1000 characters                                  |
-- | 7/17/12     Fixed issues with pass-prod-database-name to sync with existing        |
-- |             concurrtne program parm definition with standard option                |
-- | 12/12/12    Added transmission-method-AS2 option                                   |
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |  
-- +------------------------------------------------------------------------------------+

-- establish date_stamp
column date_stamp_col new_value date_stamp noprint

select to_char(sysdate, 'YYYYMMDDHH24MISS') date_stamp_col
from dual;

-- define script parms   
DEFINE output_path  = &1
DEFINE prod_database_name  = &2      

-- define data output path and filename
column dat_path_col new_value dat_path noprint
           
select decode(name            
             ,'&prod_database_name'            
             ,'&output_path/p.'||lower('TTH1')||'.wgps.&date_stamp'
             ,'&output_path/c.'||lower('TTH1')||'.wgps.test.&date_stamp'            
             )  dat_path_col
  from v$database
;
   

-- set settings
set termout off
set feedback off
set verify off
set echo off
set serveroutput on size 1000000
set heading off
set linesize 1000
set pagesize 0
set space 0
set wrap off
set trimspool on

-- create data file
SPOOL &dat_path..ntf   

-- kp 190430 April 2019 release commented out starting...
/******************************************************************************
--select 'H WGPS LD'||substr('&date_stamp',1,8)||'TTH1' from dual; -- kp 160430 April 2016 release - replace line with below
-- kp 160430 April 2016 release starting
select 'H WGPS LD'||substr('&date_stamp',1,8)||'TTH1' || '   '              --position 1 - 24
    || 'FV='   || APPS.ADP_GARN_PKG.get_file_version  --positon 25 - 120 optional free format --spec file version
    || 'SV='   || APPS.ADP_GARN_PKG.get_spec_version  --package specification version
    || 'BV='   || APPS.ADP_GARN_PKG.get_body_version  --package body version
    || 'USER=' || substr(FND_GLOBAL.USER_NAME,1,10)                                               --request submit user
    || 'RQID=' || to_char(fnd_global.conc_request_id)                                             --request id
    || 'TIME=' || to_char(sysdate,'YYYYMMDD HH24:MI:SS')     
from dual;
-- kp 160430 April 2016 release finishing
***********************************************************************************/
-- kp 190430 April 2019 release commented out finishing...

-- kp 211031 Fall 2021 release commented out
/**********************************************************************************
-- kp 190430 April 2019 release starting -- to include ERP name, ERP version
select 'H WGPS LD'||substr('&date_stamp',1,8)||'TTH1' || '   '              --position 1 - 24
    || 'FV='   || trim(APPS.ADP_GARN_PKG.get_file_version)  --positon 25 - 120 optional free format --spec file version
    || ' SV='   || APPS.ADP_GARN_PKG.get_spec_version  --package specification version
    || ' BV='   || APPS.ADP_GARN_PKG.get_body_version  --package body version
    || ' ERP=Oracle EBS'
    || ' V' || fnd_release.release_name
    || ' TIME=' || to_char(sysdate,'YYMMDD HH24:MI:SS')     
from dual;
-- kp 190430 April 2019 release finishing
*******************************************************************************/
-- kp 211031 Fall 2021 release commented out

-- kp 211031 Fall 2021 release starting
select 'H WGPS LD'||substr('&date_stamp',1,8)||'TTH1' || '   '                            --position 1 - 24
    || rpad('SV='      || APPS.ADP_GARN_PKG.get_spec_version        --position 25 - 120
    ||      ' BV='     || APPS.ADP_GARN_PKG.get_body_version        --position 25 - 120
    ||      ' TIME='   || to_char(sysdate,'YYMMDD HH24:MI:SS'), 96, ' ')                                        --position 25 - 120
    || ' '                                                                                                      --position 121
    || 'Oracle E-Business Suite  '                                                                              --position 122 - 146
    || rpad(trim(fnd_release.release_name), 25, ' ')                                                            --position 147 - 171   
--  || lpad(trim(APPS.ADP_GARN_PKG.get_file_version), 5, ' ')       --position 172 - 176  -- removed lpad
    || trim(APPS.ADP_GARN_PKG.get_file_version)                     --position 172 - 176
from dual;                              
-- kp 211031 Fall 2021 release finishing

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
       -- kp 161031 commented and replaced with line below -- October 2016 release
       --|| '|' || rtrim(substr(nvl(to_char(lien_number),' ')                 ,1,2),' ')    -- October 2016 release
       -- kp 161031 to make zero filled format of lien number -- October 2016 release
       || '|' || LPAD(substr(nvl(to_char(lien_number),'  ')                 ,1,2), 2, '0')  -- October 2016 release
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
       -- kp 161031 commented and replaced with line below -- October 2016 release
       --|| '|' || rtrim(substr(nvl(to_char(payee_code),' ')                  ,1,5),' ')      -- October 2016 release
       -- kp 161031 to make zero filled format of payee coder -- October 2016 release
       || '|' || LPAD(substr(nvl(to_char(payee_code),'     ')               ,1,5), 5, '0')    -- October 2016 release
       || '|' || rtrim(substr(nvl(short_user_name,' ')                      ,1,10),' ')    -- field #27 per fiel spec v1.28, Filler size 10 optional, short_user_name is null
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
       || '|' || rtrim(substr(nvl(future_use,' ')                           ,1,26),' ')
       || '|' || rtrim(substr(nvl(priority,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(round(pro_ration_pct,0)),' ')     ,1,5),' ')
       || '|' || rtrim(substr(nvl(to_char(round(pro_ration_amt,0)),' ')     ,1,5),' ')
       || '|' || rtrim(substr(nvl(notification_indicator,' ')               ,1,1),' ')
       || '|' || rtrim(substr(nvl(interogatory_indicator,' ')               ,1,1),' ')
       || '|' || rtrim(substr(nvl(doc_id,' ')                               ,1,16),' ')
       || '|' || rtrim(substr(nvl(bankruptcy_indicator,' ')                 ,1,1),' ')
       || '|' || rtrim(substr(nvl(address_type,' ')                         ,1,1),' ')     -- field #58
       || '|' || rtrim(nvl(future_use1,' '),' ')                                           -- field #59 per file spec version 1.34, it is used for arrears greater than 12 weeks indicator -- kp 210131
       || '|' || replace(replace(rtrim(nvl(trim(future_use2),' '),' '),chr(13),''),chr(10),'')
       || '|' || rtrim(nvl(future_use3,' '),' ')                                           -- field #61 per file spec v1.28, Filler max size 45 optional
       || '|' || rtrim(nvl(future_use4,' '),' ')                                           -- field #62 error warning messages   
       || '|' || rtrim(nvl(future_use5,' '),' ')
       || '|' || rtrim(substr(nvl(utl_indicator,' ')                        ,1,1),' ')
       || '|' || rtrim(substr(nvl(ee_address,' ')                           ,1,45),' ')
       || '|' || rtrim(substr(nvl(ee_city,' ')                              ,1,24),' ')
       || '|' || rtrim(substr(nvl(ee_state,' ')                             ,1,2),' ')
       || '|' || rtrim(substr(nvl(ee_zip,' ')                               ,1,9),' ')     -- field #69 per file spec v1.28, size 9
       || '|' || rtrim(decode(substr(nvl(ee_status,' ')                     ,1,16), 'TERMED WITH PAY', 'TERMINATED', ee_status),' ')   
       || '|' || rtrim(substr(nvl(employed,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(status_date,'MMDDYYYY'),' ')      ,1,8),' ')
       || '|' || rtrim(substr(nvl(to_char(round(gross_wages,0)),' ')        ,1,11),' ')
       || '|' || rtrim(substr(nvl(to_char(round(disposable_wages,0)),' ')   ,1,11),' ')
       || '|' || rtrim(substr(nvl(pay_freq,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(company_name,' ')                         ,1,45),' ')    -- field #75 per file spec v1.28, max size 44, schema size 45
       || '|' || rtrim(substr(nvl(company_street,' ')                       ,1,30),' ')    -- field #76 per file spec v1.28, max size 45, schema size 30 
       || '|' || rtrim(substr(nvl(company_city,' ')                         ,1,20),' ')
       || '|' || rtrim(substr(nvl(company_state,' ')                        ,1,2),' ')
       || '|' || rtrim(substr(nvl(company_zip,' ')                          ,1,9),' ')
       || '|' || rtrim(substr(nvl(company_address_line_2,' ')               ,1,30),' ')
       || '|' || rtrim(substr(nvl(ee_address_line_2,' ')                    ,1,45),' ')
       || '|' || substr(lpad(to_char(round(nvl(mandatory_ret_ded,0)*100,0)),11,'0'),1,11)
       || '|' || rtrim(substr(nvl(pay_type,' ')                             ,1,1),' ')
       || '|' || rtrim(substr(nvl(to_char(last_check_date,'MMDDYYYY'),' ')                    ,1,45),' ')
       || '|' || rtrim(substr(nvl(to_char(last_pay_period_begin,'MMDDYYYY'),' ')                    ,1,45),' ')
       || '|' || rtrim(substr(nvl(to_char(last_pay_period_end,'MMDDYYYY'),' ')                    ,1,45),' ')
       || '|' || rtrim(substr(nvl(to_char(next_check_date,'MMDDYYYY'),'')||';'||nvl(to_char(next_check_date2,'MMDDYYYY'),''),1,17),' ')
     --|| '|' || substr(lpad(to_char(round(nvl(dependant_count,0),0)),11,'0'),1,11)      -- field #88 changed to max size to 2 commented and replaced with line below
       || '|' || substr(lpad(to_char(round(nvl(dependant_count,0),0)),2,'0'),1,2)      -- field #88 changed to max size to 2 --181030
       || '|' || substr(lpad(to_char(round(nvl(disability_earnings,0)*100,0)),11,'0'),1,11)
       || '|' || substr(lpad(to_char(round(nvl(retirement_earnings,0)*100,0)),11,'0'),1,11)
       || '|' || substr(lpad(to_char(round(nvl(annual_salary,0)*100,0)),11,'0'),1,11)
       || '|' || substr(lpad(to_char(round(nvl(total_payroll_taxes,0)*100,0)),8,'0'),1,8)
       || '|' || substr(lpad(to_char(round(nvl(federal_income_taxes,0)*100,0)),8,'0'),1,8)
       || '|' || substr(lpad(to_char(round(nvl(state_income_taxes,0)*100,0)),8,'0'),1,8)
       || '|' || substr(lpad(to_char(round(nvl(fica_taxes,0)*100,0)),8,'0'),1,8)
  --from TT_ADP.ADP_TTEC_ADP_GARN_NOTIF_STG		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  from ADP_TTEC_ADP_GARN_NOTIF_STG		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
;

--select 'F'||lpad(to_char(count(1)),10,'0') from TT_ADP.ADP_TTEC_ADP_GARN_NOTIF_STG;	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 	
select 'F'||lpad(to_char(count(1)),10,'0') from ADP_TTEC_ADP_GARN_NOTIF_STG;		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

spool off
   

exit


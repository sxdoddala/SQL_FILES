

-- +------------------------------------------------------------------------------------+
-- |                                                                                    |
-- | SQL*Plus Script "adp_garn_disb_scr.sql"                                            |
-- |                                                                                    |
-- | Purpose: Creates outbound ADP lien disbursement file                               |
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
-- | 05/10/06    Set echo off, removed whenever, added exit                             |
-- | 11/27/07    Compliance with ADP file naming specifications                         |
-- | 12/06/07    Compliance with ADP file naming specifications                         |
-- | 12/12/12    Added transmission-method-AS2 option                                   |   
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |                                                          |
-- +------------------------------------------------------------------------------------+

-- establish date_stamp
column date_stamp_col new_value date_stamp noprint

select to_char(sysdate, 'YYYYMMDDHH24MISS') date_stamp_col
from dual;

-- define script parms
DEFINE output_path  = &1
   
-- define data output filename
column dat_path_col new_value dat_path noprint
         
select decode(name
             ,'TECP'           
             ,'&output_path/p.'||lower('TTH1')||'.wgps.&date_stamp'
             ,'&output_path/c.'||lower('TTH1')||'.wgps.test.&date_stamp'            
             )  dat_path_col
  from v$database
;

-- create data file
set termout off
set feedback off
set verify off
set echo off
set serveroutput on size 1000000
set heading off
set linesize 160
set pagesize 0
set space 0
set wrap off
set trimspool on

SPOOL &dat_path..grn   

select record_text
  --from TT_ADP.ADP_TTEC_ADP_GARN_DISB_OUT  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  from ADP_TTEC_ADP_GARN_DISB_OUT   -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
order by line_number
;

spool off
   

exit


-- +------------------------------------------------------------------------------------+
-- |                                                                                    |
-- | SQL*Plus Script "adp_garn_id_report_scr.sql"                             |
-- |                                                                                    |
-- | Purpose: Wrapper script for ADP Garnishment Historical Interface                   |
-- |                                                                                    |
-- | Parameters:                                                                        |
-- |    1) output_path: Full path to data file creation folder                          |
-- |    2)                                                                              |
-- |    3)                                                                              |
-- |    4)                                                                              |
-- |                                                                                    |
-- | Created 4/30/2016 by Ken P.                                                        |
-- |                                                                                    |
-- | Copyright (c) 2005 Automatic Data Processing, Inc. All rights reserved             |
-- |                                                                                    |
-- | Date        Change                                                                 |
-- | ----------  --------------------------------------------------------------------   |                           |
-- |                                                                                    |
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
-- +------------------------------------------------------------------------------------+


-- establish date_stamp
column date_stamp_col new_value date_stamp noprint

select to_char(sysdate, 'YYYYMMDDHH24MISS') date_stamp_col
from dual;


-- define script parms
DEFINE output_path = &1

-- open log spool
spool &output_path/AssociateIDreport_&date_stamp..txt


-- Set settings
set serveroutput on
set termout on
set space 1
set heading on
set feedback on
set wrap off


-- print small report
set lines 200
set pagesize 65
clear breaks
clear columns

ttitle center 'List of Garnishment Record With Blank/Null value of Doc ID'

column employee_number      heading "AssociateID" format A30
column first_name           heading "FirstName" format A30
column last_name            heading "LastName" format A30
column lien_number          heading "LienNumber" format A10
column element_name         heading "ElementName" format A30
column element_effective_start_date     heading "StartDate" format A11
column element_effective_end_date       heading "EndDate" format A11

select rpad(employee_number,30,' ')                         employee_number
     , rpad(substr(first_name,1,30),30,' ')                 first_name
     , rpad(substr(last_name,1,30),30,' ')                  last_name
     , rpad(substr(to_char(lien_number),1,10),10,' ')       lien_number
     , rpad(substr(element_name,1,30),30,' ')               element_name
     , rpad(to_char(element_effective_start_date,'DD-MON-YYYY'),11,' ') element_effective_start_date
     , rpad(to_char(element_effective_end_date,'DD-MON-YYYY'),11,' ')   element_effective_end_date
  --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  from ADP_TTEC_ADP_LIEN_ID_REPORT		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
 where doc_id is null
   and ( 
           ( trunc(sysdate) between trunc(element_effective_start_date) and trunc(element_effective_end_date) )
        OR ( trunc(element_effective_start_date) > trunc(sysdate) ) 
       )
order by employee_number, first_name, last_name, lien_number, element_name, element_effective_start_date
;

set pagesize 65
clear breaks
clear columns

ttitle center 'List Of The Same Assoicate ID Value Is Used For Multiple Employees'

column employee_number      heading "AssociateID" format A30
column first_name           heading "FirstName" format A30
column last_name            heading "LastName" format A30
column person_id            heading "PersonID" format A10

-- FOR THE SAME EMPLOYEE NUMBER IS USED FOR MULTIPLE PERSONS/EMPLOYEES
select distinct 
       rpad(a.xyz,30,' ')                                  employee_number
    --,a.record_cnt                                        record_count
      ,rpad(substr(alir.first_name,1,30),30,' ')           first_name
      ,rpad(substr(alir.last_name,1,30),30,' ')            last_name
      ,rpad(substr(to_char(alir.person_id),1,10),10,' ')   person_id
--from  TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from  ADP_TTEC_ADP_LIEN_ID_REPORT alir  	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 	
      ,(select alir2.employee_number xyz,	
               count(*) record_cnt
          --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir2 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  from ADP_TTEC_ADP_LIEN_ID_REPORT alir2		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
         where alir2.person_id = alir2.person_id
           and alir2.employee_number = alir2.employee_number
           and ( 
                   ( trunc(sysdate) between trunc(alir2.element_effective_start_date) and trunc(alir2.element_effective_end_date) )
                OR ( trunc(alir2.element_effective_start_date) > trunc(sysdate) ) 
               )
         group by alir2.employee_number) a
  where a.record_cnt > (select count(*) 
                          --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir3	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						  from ADP_TTEC_ADP_LIEN_ID_REPORT alir3		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                         where alir3.person_id = alir.person_id
                           and ( 
                                   ( trunc(sysdate) between trunc(alir3.element_effective_start_date) and trunc(alir3.element_effective_end_date) )
                                OR ( trunc(alir3.element_effective_start_date) > trunc(sysdate) ) 
                               )                  
                       )
    and alir.employee_number = a.xyz
    and ( 
            ( trunc(sysdate) between trunc(alir.element_effective_start_date) and trunc(alir.element_effective_end_date) )
         OR ( trunc(alir.element_effective_start_date) > trunc(sysdate) ) 
        ) 
order by employee_number
;

set pagesize 65
clear breaks
clear columns

ttitle center 'List Of Multiple Associate ID Values Are Used For One Employee'

column employee_number      heading "AssociateID" format A30
column first_name           heading "FirstName" format A30
column last_name            heading "LastName" format A30
column person_id            heading "PersonID" format A10

-- FOR THE PERSON/EMPLOYEE USES FOR MULTIPLE/DIFFERENT EMPLOYEE NUMBERS
select distinct  
       rpad(a.xyz,30,' ')                                  employee_number
    --,a.record_cnt                                        record_count
      ,rpad(substr(alir.first_name,1,30),30,' ')           first_name
      ,rpad(substr(alir.last_name,1,30),30,' ')            last_name
      ,rpad(substr(to_char(alir.person_id),1,10),10,' ')   person_id
--from  TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
from  ADP_TTEC_ADP_LIEN_ID_REPORT alir	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
      ,(select alir2.employee_number xyz,
               count(*) record_cnt
          --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir2	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		  from ADP_TTEC_ADP_LIEN_ID_REPORT alir2		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
         where alir2.person_id = alir2.person_id
           and alir2.employee_number = alir2.employee_number
           and ( 
                   ( trunc(sysdate) between trunc(alir2.element_effective_start_date) and trunc(alir2.element_effective_end_date) )
                OR ( trunc(alir2.element_effective_start_date) > trunc(sysdate) ) 
               )
         group by alir2.employee_number) a
  where a.record_cnt < (select count(*) 
                          --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT alir3	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
						  from ADP_TTEC_ADP_LIEN_ID_REPORT alir3	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
                         where alir3.person_id = alir.person_id
                           and ( 
                                   ( trunc(sysdate) between trunc(alir3.element_effective_start_date) and trunc(alir3.element_effective_end_date) )
                                OR ( trunc(alir3.element_effective_start_date) > trunc(sysdate) ) 
                               )                  
                       ) 
    and alir.employee_number = a.xyz
    and ( 
            ( trunc(sysdate) between trunc(alir.element_effective_start_date) and trunc(alir.element_effective_end_date) )
         OR ( trunc(alir.element_effective_start_date) > trunc(sysdate) ) 
        ) 
order by employee_number, person_id
;

-- close rpt spool
spool off


-- create data file
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


spool &output_path/AssociateIDquery_&date_stamp..dat

select           rtrim(substr(nvl(doc_id,' ')                               ,1,16),' ')
       || '|' || rtrim(substr(nvl(employee_number,' ')                      ,1,30),' ')
       || '|' || rtrim(substr(nvl(last_name,' ')                            ,1,40),' ')
       || '|' || rtrim(substr(nvl(first_name,' ')                           ,1,40),' ')
     --|| '|'
  --from TT_ADP.ADP_TTEC_ADP_LIEN_ID_REPORT		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  from ADP_TTEC_ADP_LIEN_ID_REPORT		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
 where doc_id is not null
   and ( 
           ( trunc(sysdate) between trunc(element_effective_start_date) and trunc(element_effective_end_date) )
        OR ( trunc(element_effective_start_date) > trunc(sysdate) ) 
       )
 order by doc_id, employee_number
;


spool off

exit

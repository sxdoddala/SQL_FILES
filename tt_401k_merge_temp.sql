-- Program Name:  FIRST_UNION_401K
--
-- Description:  This program will provide an extract of the Oracle HR and Payroll system 
-- to be provided to First Union. The extracted data will contain employment, load and
-- 401K information for employees.
--
-- Input/Output Parameters: 
--
-- Oracle Tables Accessed:  HR_LOCATIONS_ALL
--                          PAY_BLANCE_TYPES
--                          PER_ALL_PEOPLE_F
--                          PER_ADDRESSES
--                          PER_ALL_ASSIGNMENTS_F
--                          PER_ANALYSIS_CRITERIA
--                          PER_PERSON_ANALSES
--                          PER_PERSON_TYPES
--				            PER_PERIODS_OF_SERVICE
--                          XKB_BALANCES
--                          XKB_BALANCE_DETAILS
--
-- Tables Modified:  N/A
--
-- Procedures Called:  TTEC_PROCESS_ERROR
--
-- Created By:  C.Boehmer
-- Date: August 13, 2002
--
-- Modification Log:
-- Developer    Date       Description
-- ----------  --------   --------------------
-- CBoehmer    03-SEP-02  Remove unused procedures
-- CBoehmer    01-OCT-02  Added calls to call_Balance_user_exit_401k to get ytd comp results
-- CBoehmer    03-OCT-02  Converted code to use XKB (Kbace) tables for pay balance amounts
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            
SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
-- Global Variables ---------------------------------------------------------------------------------
g_plan_1 VARCHAR2(50):= 'wachovia';

g_transaction_type				 varchar2(1) := 'P';
g_header_type					 varchar2(1) := 'H';
g_trailer_type					 varchar2(1) := 'T';
g_payroll_date                   date := '17-FEB-2003';   --  sysdate;
g_plan_id  						 varchar2(8) := '00000TTI';

-- Variables used by Common Error Procedure
--START R12.2 Upgrade Remediation
/*g_application_code               CUST.TTEC_error_handling.application_code%TYPE := '401';
g_interface                      CUST.TTEC_error_handling.interface%TYPE := 'PAY-INT-01';
g_program_name                   CUST.TTEC_error_handling.program_name%TYPE := 'WACHOVIA_401K';
g_initial_status                 CUST.TTEC_error_handling.status%TYPE := 'INITIAL';
g_warning_status                 CUST.TTEC_error_handling.status%TYPE := 'WARNING';
g_failure_status                 CUST.TTEC_error_handling.status%TYPE := 'FAILURE';*/
g_application_code               APPS.TTEC_error_handling.application_code%TYPE := '401';
g_interface                      APPS.TTEC_error_handling.interface%TYPE := 'PAY-INT-01';
g_program_name                   APPS.TTEC_error_handling.program_name%TYPE := 'WACHOVIA_401K';
g_initial_status                 APPS.TTEC_error_handling.status%TYPE := 'INITIAL';
g_warning_status                 APPS.TTEC_error_handling.status%TYPE := 'WARNING';
g_failure_status                 APPS.TTEC_error_handling.status%TYPE := 'FAILURE';  
--End R12.2 Upgrade Remediation
g_effective_date				 DATE := to_date(sysdate,'DD-MON-YYYY');

-- Filehandle Variables              
p_FileDir VARCHAR2(100)          := '&1';     
p_FileName VARCHAR2(50)          := 'wachovia_401k_'||to_char(sysdate, 'YYYYMMDD_HH24MISS')||'.txt';
v_daily_file UTL_FILE.FILE_TYPE;


-----------------------------------------------------------------------------------------------------
-- Cursor declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
CURSOR c_emp_data IS
SELECT *
--FROM   cust.tt_temp_401k	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
FROM   apps.tt_temp_401k	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023
WHERE  trx_type <> 'T';
--WHERE 
--SSN = '610-50-3125' ;  -- ('251-37-0531','231-13-1347');


-----------------------------------------------------------------------------------------------------
-- Record declarations ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
TYPE T_HEADER_INFO IS RECORD
(
  hdr_transaction_type   varchar2(1) := 'H'
, hdr_payroll_date 	     varchar2(10) 
, hdr_plan_id            varchar2(8) := '00000TTI'
);


TYPE T_TRAILER_INFO IS RECORD
(
  trl_transaction_type   varchar2(1) := 'T'
, trl_hours_ytd          varchar2(100) := NULL
, trl_cum_hours          varchar2(100) := NULL
, trl_prior_months       varchar2(100) := 0
, trl_money_type1        varchar2(100) := NULL
, trl_money_type2        varchar2(100) := NULL
, trl_money_type3        varchar2(10) := NULL
, trl_money_type4        varchar2(10) := NULL
, trl_money_type5        varchar2(10) := NULL
, trl_money_type6        varchar2(10) := NULL
, trl_money_type7        varchar2(10) := NULL
, trl_money_type8        varchar2(10) := NULL
, trl_money_type9        varchar2(10) := NULL
, trl_money_type10        varchar2(10) := NULL
, trl_money_type11        varchar2(10) := NULL
, trl_money_type12        varchar2(10) := NULL
, trl_money_type13        varchar2(10) := NULL
, trl_money_type14        varchar2(10) := NULL
, trl_money_type15        varchar2(10) := NULL
, trl_loan1               varchar2(100) := NULL
, trl_loan2               varchar2(100) := NULL
, trl_loan3               varchar2(10) := NULL
, trl_loan4               varchar2(10) := NULL
, trl_loan5               varchar2(10) := NULL
, trl_loan6               varchar2(10) := NULL
, trl_loan7               varchar2(10) := NULL
, trl_loan8               varchar2(10) := NULL
, trl_loan9               varchar2(10) := NULL
, trl_loan10              varchar2(10) := NULL
, trl_comp_amount1        varchar2(100) := NULL
, trl_comp_amount2        varchar2(100) := NULL
, trl_comp_amount3        varchar2(10) := NULL
);


-----------------------------------------------------------------------------------------------------
-- Begin format_number ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
FUNCTION format_number (p_amount IN VARCHAR2) RETURN NUMBER IS


i NUMBER := 0;

BEGIN
  SELECT substr(p_amount,instr(p_amount,'-'))
  INTO   i
  FROM   DUAL;
  
  Return i;
  
EXCEPTION
   when others then
     raise;
  
END;

-----------------------------------------------------------------------------------------------------
-- Begin display_number ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
FUNCTION display_number (p_amount IN NUMBER) RETURN VARCHAR2 IS


i VARCHAR2(10) := 0;

BEGIN

If p_amount < 0 then
   i  :=  '-' ||  substr(lpad(-p_amount,9,'0'),1,9)  ;
Elsif p_amount >= 0 then 
   i  :=  substr(lpad(p_amount,10,'0'),1,10);
Else  
   i  := lpad('0',10,'0');
End If;

  
  Return i;
  
EXCEPTION
   when others then
     raise;
  
END;
-----------------------------------------------------------------------------------------------------
-- Begin main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
PROCEDURE main IS

-- Declare variables
--emp 	   	 	T_EMPLOYEE_INFO;
trl 	   	 	T_TRAILER_INFO;
--depn 	   	 	T_DEPENDENT_INFO;
l_emp_output 	VARCHAR2(2000);
l_depn_output	CHAR(555);
v_rows 			VARCHAR2(555);
l_wachovia_status varchar2(15);
l_assignment_action_id   NUMBER;

--l_module_name CUST.TTEC_error_handling.module_name%type := '401';		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
l_module_name APPS.TTEC_error_handling.module_name%type := '401';		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

l_rehire_months number := 0;      
l_money_type1 number := 0;
l_money_type2 number := 0;
l_loan1 number := 0 ;
l_comp_amount0 number := 0;
l_comp_amount1 number := 0;
l_comp_amount00 number := 0;

l_comp_ind     number := 0;

t_hours_ytd number := 0;
t_rehire_months number := 0;      
t_money_type1 number := 0;
t_money_type2 number := 0;
t_loan1 number := 0 ;
t_comp_amount1 number := 0;
t_comp_amount2 number := 0;


v_emp_status varchar2(4);

l_ssn    varchar2(20);

v_plan_entry  varchar2(10);
v_birth_date varchar2(10);
v_hire_date  varchar2(10);
v_rehire_date varchar2(10);
v_term_date   varchar2(10);

BEGIN  
dbms_output.put_line('Opening file...');
  v_daily_file := UTL_FILE.FOPEN(p_FileDir, p_FileName, 'w');
  

  -- Employee Data Extract --
  BEGIN
    FOR rec_emp IN  c_emp_data LOOP
	
	If rec_emp.trx_type = 'H' then  
      
	  -- Header Information --
      BEGIN
        --l_emp_output := (g_header_type || to_char(g_payroll_date,'MM/DD/YYYY') || g_plan_id);
		l_emp_output := rec_emp.trx_type||rec_emp.ssn||rec_emp.first_name;
		utl_file.put_line(v_daily_file, l_emp_output);
      END;
	 
    Else
	 
      BEGIN
		
		l_money_type1 := 0;
		l_money_type2 := 0;
		l_loan1 := 0; 
		l_comp_amount0 := 0;
		l_comp_amount1 := 0;
		l_comp_amount00 := 0;
		
		v_plan_entry  := null;
		v_birth_date := null;
		v_hire_date  := null;
		v_rehire_date := null;
		v_term_date   := null;

         BEGIN
          v_rows := 'XX';
		  
		  l_ssn  := rec_emp.ssn;
		  --dbms_output.put_line('1');
		  
		  v_plan_entry := to_char(to_date(rec_emp.plan_entry,'MM/DD/YYYY'),'MM/DD/YYYY');
		  --dbms_output.put_line('21');
		  v_birth_date := to_char(to_date(rec_emp.birth_date,'MM/DD/YYYY'),'MM/DD/YYYY');
		  --dbms_output.put_line('22');
		  v_hire_date  := to_char(to_date(rec_emp.hire_date,'MM/DD/YYYY'),'MM/DD/YYYY');
		  --dbms_output.put_line('23');
          v_rehire_date := to_char(to_date(rec_emp.rehire_date,'MM/DD/YYYY'),'MM/DD/YYYY');
		  --dbms_output.put_line('24');
		  v_term_date   := to_char(to_date(rec_emp.term_date,'MM/DD/YYYY'),'MM/DD/YYYY');
		  
	      -- Calculate summary totals for trailer record
		  t_hours_ytd :=  t_hours_ytd + nvl(format_number(rec_emp.hours_ytd),0); 
		  --dbms_output.put_line('25');
		  t_rehire_months := t_rehire_months + nvl(format_number(rec_emp.rehire_months),0);   
		  --dbms_output.put_line('26');   
		  t_money_type1 := t_money_type1 + nvl(format_number(rec_emp.money_type1),0);
		  --dbms_output.put_line('27');
		  t_money_type2 := t_money_type2 + nvl(format_number(rec_emp.money_type2),0);
		  --dbms_output.put_line('28');
		  t_loan1 := t_loan1 + nvl(format_number(rec_emp.loan1),0) ;
		  -- ikonak 06/10/03  comp amounts are zero fill per Andy Becker       
		  --t_comp_amount1 := t_comp_amount1 + nvl(format_number(rec_emp.comp1),0);
		  --t_comp_amount2 := t_comp_amount2 + nvl(format_number(rec_emp.comp2),0);

 		  --dbms_output.put_line('2');
		  
		  
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
		--    dbms_output.put_line('DID NOT FIND DATA SOMEWHERE');
            v_rows := NULL;
          WHEN TOO_MANY_ROWS THEN
            v_rows := 'not null';
          WHEN OTHERS THEN
		    dbms_output.put_line(sqlerrm);
            RAISE;        
        END;
  
        IF (v_rows is not null) THEN
        l_emp_output := (rec_emp.trx_type
                         || nvl(substr(rpad(rec_emp.ssn,11,' '),1,11),'999-99-9999')
                         || nvl(substr(rpad(UPPER(rec_emp.first_name),15,' '),1,15),rpad(' ',15,' '))	
                         || nvl(substr(rpad(UPPER(rec_emp.last_name),30,' '),1,30), rpad(' ',30,' '))	
						 || nvl(rpad(rec_emp.sort1,30,' '),rpad(' ',30,' '))		 
                         || nvl(substr(rpad(UPPER(rec_emp.address1),30,' '),1,30),rpad(' ',30,' '))
                         || nvl(substr(rpad(UPPER(rec_emp.address2),30,' '),1,30),rpad(' ',30,' '))
                         || nvl(substr(rpad(UPPER(rec_emp.city),23,' '),1,23),rpad(' ',23,' '))
                         || nvl(substr(rpad(UPPER(rec_emp.state),2,' '),1,2),rpad(' ',2,' '))
                         || nvl(substr(rpad(rec_emp.zip,10,' '),1,10),lpad(' ',10,' '))
						 || nvl(substr(lpad(rec_emp.division_code1,5,'0'),1,5),lpad('0',5,'0'))
                         || nvl(substr(rpad(rec_emp.division_code2,5,' '),1,5),rpad(' ',5,' '))
						 || nvl(substr(rpad(UPPER(rec_emp.status),4,' '),1,4),rpad(' ',4,' '))
						 || rec_emp.high_comp    --nvl(substr(rpad(emp.emp_highly_comp,1,' '),1,1),' ')
						 || nvl(substr(rpad(rec_emp.key_stat,1,' '),1,1),' ')
						 || nvl(substr(rpad(v_plan_entry,10,' '),1,10), rpad(' ',10,' '))             -- date of plan entry (blank)
						 || nvl(substr(rpad(v_birth_date,10,' '),1,10), rpad(' ',10,' '))
						 || nvl(substr(rpad(v_hire_date,10,' '),1,10),rpad(' ',10,' '))
						 || nvl(substr(rpad(v_rehire_date,10,' '),1,10),rpad(' ',10,' '))
						 || nvl(substr(rpad(' ',10,' '),1,10),rpad(' ',10,' '))               -- filler field 239-248
						 || nvl(substr(rpad(v_term_date,10,' '),1,10),rpad(' ',10,' '))
						 || nvl(substr(rpad(rec_emp.payroll_cycle_code,3,' '),1,3),rpad(' ',3,' '))
						 || nvl(substr(lpad(rec_emp.hours_ytd,4,'0'),1,4),lpad('0',4,'0'))
						 || nvl(substr(lpad(rec_emp.cum_hours,4,'0'),1,4),lpad('0',4,'0'))
						 || nvl(substr(lpad(rec_emp.rehire_months,3,'0'),1,3),lpad('0',3,'0'))
						 || nvl(substr(lpad(rec_emp.money_type1,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(rec_emp.money_type2,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type3
					 	 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type4
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type5
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type6
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type7
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type8
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type9	
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type10
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type11
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type12
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type13
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type14
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  -- money_type15
						 || nvl(substr(lpad(rec_emp.loan1,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan2
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan3
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan4
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan5
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan6
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))   	  --  loan7
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  --  loan8
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  --  loan9
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))	  --  loan10 
						 || nvl(substr(lpad(rec_emp.comp1,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(rec_emp.comp2,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(NULL,10,'0'),1,10),lpad('0',10,'0'))  	   --  emp.emp_comp_amount5
                        );
        utl_file.put_line(v_daily_file, l_emp_output);
 
        END IF;  
      END;
	  
	 End If;
	 
    END LOOP;
	
  END;
  
  	   BEGIN
	   
  --dbms_output.put_line('3');

  -- Trailer Information --
          trl.trl_hours_ytd  :=  t_hours_ytd;
  		  trl.trl_prior_months := t_rehire_months;
		  -- ikonak 06/10/03  comp amounts are zero fill per Andy Becker         
		  trl.trl_money_type1 := t_money_type1;
		  trl.trl_money_type2 := t_money_type2;
		  trl.trl_loan1 := t_loan1;
		  --trl.trl_comp_amount1 := t_comp_amount1;
		  --trl.trl_comp_amount2 := t_comp_amount2;
		  
          l_emp_output := (g_trailer_type
                         || rpad(' ',237,' ')
						 || nvl(substr(lpad(trl.trl_hours_ytd,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_cum_hours,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_prior_months,10,'0'),1,10),lpad('0',10,'0'))
						 || display_number(trl.trl_money_type1)
						 || display_number(trl.trl_money_type2)
						 || nvl(substr(lpad(trl.trl_money_type3,10,'0'),1,10),lpad('0',10,'0'))
					 	 || nvl(substr(lpad(trl.trl_money_type4,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type5,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type6,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type7,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type8,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type9,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type10,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type11,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type12,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type13,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type14,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_money_type15,10,'0'),1,10),lpad('0',10,'0'))
						 || display_number(trl.trl_loan1)
						 || nvl(substr(lpad(trl.trl_loan2,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan3,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan4,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan5,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan6,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan7,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan8,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan9,10,'0'),1,10),lpad('0',10,'0'))
						 || nvl(substr(lpad(trl.trl_loan10,10,'0'),1,10),lpad('0',10,'0')) 
						 || lpad('0',10,'0')  --display_number(trl.trl_comp_amount0)  
						 || lpad('0',10,'0')  --display_number(trl.trl_comp_amount0)  
						 || nvl(substr(lpad(trl.trl_comp_amount3,10,'0'),1,10),lpad('0',10,'0'))  
                        );
        utl_file.put_line(v_daily_file, l_emp_output);
	END;
	
  --dbms_output.put_line('4');
		
  COMMIT;
  UTL_FILE.FCLOSE(v_daily_file);
  
EXCEPTION
 WHEN UTL_FILE.INVALID_OPERATION THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20051, p_FileName ||':  Invalid Operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20052, p_FileName ||':  Invalid File Handle');
  WHEN UTL_FILE.READ_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20053, p_FileName ||':  Read Error');
  WHEN UTL_FILE.INVALID_PATH THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20054, p_FileName ||':  Invalid Path');
  WHEN UTL_FILE.INVALID_MODE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20055, p_FileName ||':  Invalid Mode');
  WHEN UTL_FILE.WRITE_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20056, p_FileName ||':  Write Error');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20057, p_FileName ||':  Internal Error');
  WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
		UTL_FILE.FCLOSE(v_daily_file);
		RAISE_APPLICATION_ERROR(-20058, p_FileName ||':  Maxlinesize Error');
  WHEN OTHERS THEN
		UTL_FILE.FCLOSE(v_daily_file);
		dbms_output.put_line('ERROR');
        dbms_output.put_line(l_ssn);
		dbms_output.put_line(t_rehire_months);      
		dbms_output.put_line(t_money_type1);
		dbms_output.put_line(t_money_type2);
		dbms_output.put_line(t_loan1);
		dbms_output.put_line(t_comp_amount1);
		dbms_output.put_line(t_comp_amount2);
    CUST.TTEC_PROCESS_ERROR (g_application_code, g_interface, g_program_name, l_module_name,
                         'FAILURE', SQLCODE, SQLERRM);
		RAISE;

END; 
-----------------------------------------------------------------------------------------------------
-- Calls main Procedure -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
BEGIN
   main;
END;
/

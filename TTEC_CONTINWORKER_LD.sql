-- Program Name:  	TTEC_contngWorker_load.sql
--
-- Description:   This program will process each record in the
--                 TTEC_ContingentWORKER_load
--		    	-- loads the Contingent Worker  Information
--
-- Input/Output
-- Parameters:    	N/A
--
-- Tables Accessed:	TTEC_ContingentWORKER_load
--					PER_ALL_PEOPLE_F
-- 					PER_ALL_ASSIGNMENTS_F
--
-- Tables Modified: PER_ALL_PEOPLE_F
-- 					PER_ALL_ASSIGNMENTS_F
--
--                  CUST.ttec_error_handling
--               --
-- Procedures Called: 
--
-- Created By:    	Wasim Manasfi 
-- Date:	    	09/10/2005
--
-- Modification Log:
--
-- Developer		         Date	   Description
-- --------------------      ----      -----------------------
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation  
SET TIMING ON
SET SERVEROUTPUT ON SIZE 1000000;

-- Declare variables
DECLARE

--Globals
g_validate BOOLEAN := false;
g_business_group_id NUMBER := 325;
g_person_type_id NUMBER := 166;

-- Variables used by Common Error Procedure
--START R12.2 Upgrade Remediation
/*c_application_code            CUST.ttec_error_handling.application_code%TYPE := 'HR';
c_interface                   CUST.ttec_error_handling.interface%TYPE := 'TeleTech';
c_program_name                CUST.ttec_error_handling.program_name%TYPE := 'ttec_contingentWorker';
c_initial_status              CUST.ttec_error_handling.status%TYPE := 'INITIAL';
c_warning_status              CUST.ttec_error_handling.status%TYPE := 'WARNING';
c_failure_status              CUST.ttec_error_handling.status%TYPE := 'FAILURE';*/
c_application_code            apps.ttec_error_handling.application_code%TYPE := 'HR';
c_interface                   apps.ttec_error_handling.interface%TYPE := 'TeleTech';
c_program_name                apps.ttec_error_handling.program_name%TYPE := 'ttec_contingentWorker';
c_initial_status              apps.ttec_error_handling.status%TYPE := 'INITIAL';
c_warning_status              apps.ttec_error_handling.status%TYPE := 'WARNING';
c_failure_status              apps.ttec_error_handling.status%TYPE := 'FAILURE';
--End R12.2 Upgrade Remediation
-- Exceptions
SKIP_RECORD   EXCEPTION;
SKIP_RECORD2  EXCEPTION;
-- Cursor declarations

-- Pulls the Contingent Worker  Information
CURSOR 	c_contworker_emp IS
SELECT
hire_date,		     
Last_NAME ,           
First_NAME ,      		
NATIONAL_ID ,
Agency,
PassToKronos,
Org_name,			
JOB_CODE,             
LOCATION_Name,       
Assig_cat,         
npw_sup,             
AssgRateName,         
AssgRateBasis,        
AssgRateType ,        
Currency,             
Hourly_rate,           
Client_code           
from
TTEC_ContingentWORKER_load;

-- Control totals
g_total_records_read       NUMBER := 0;
g_total_records_processed  NUMBER := 0;
g_commit_point  		   NUMBER := 100; 
g_commit_pt_ctr  		   NUMBER := 0;
g_primary_column           VARCHAR2(60):= NULL;

-- Procedure declarations


PROCEDURE ttec_add_sal_assignment
		  		 		(p_assignment_id    IN NUMBER 
					   ,p_business_group_id IN NUMBER
					   ,p_rate_id       	IN NUMBER
                       ,p_start_date     	IN  date
					   ,p_proposed_sal     IN varchar2
					   ,p_GRADE_RULE_ID    IN out NUMBER) IS


v_validate BOOLEAN;
v_row_id varchar2(240);
v_grade_rule_id number;
v_mode varchar2 (80) ;
v_rate_type varchar2(80);
v_rate_id number;


BEGIN

v_mode := 'A';
v_row_id := NULL;
v_rate_type := 'A';
v_validate := TRUE;

 v_GRADE_RULE_ID := p_GRADE_RULE_ID;



        PAY_GRADE_RULES_PKG.CHECK_UNIQUENESS ( v_GRADE_RULE_ID
                           			  ,p_assignment_id       --  P_GRADE_OR_SPINAL_POINT_ID NUMBER,
									  ,v_rate_type 			 --  P_RATE_TYPE  VARCHAR2,
									  ,p_rate_id   		 	 --  P_RATE_ID   NUMBER,
            						  ,p_BUSINESS_GROUP_ID   --  P_BUSINESS_GROUP_ID NUMBER,
            						  ,v_mode); 
            													
            													   -- P_MODE                              VARCHAR2)
      --  dbms_output.put_line('New ID Grade Rule ID  '          ||  v_GRADE_RULE_ID);
  
      PAY_GRADE_RULES_PKG.INSERT_ROW(v_row_id  -- P_ROWID IN OUT NOCOPY                  VARCHAR2,
                   ,v_grade_rule_id 		   -- P_GRADE_RULE_ID                        NUMBER,
                   ,p_start_date  			   -- P_EFFECTIVE_START_DATE                 DATE,
            	   ,(sysdate + 365)			   -- P_EFFECTIVE_END_DATE                   DATE,
				   ,p_BUSINESS_GROUP_ID		   -- P_BUSINESS_GROUP_ID                    NUMBER,
            	   ,v_rate_type 			   -- P_RATE_TYPE                            VARCHAR2,
            	   ,p_assignment_id            -- P_GRADE_OR_SPINAL_POINT_ID             NUMBER,
            	   ,p_rate_id 				   -- P_RATE_ID                              NUMBER,
            	   ,'50' 					   -- P_MAXIMUM                              VARCHAR2,
            	   ,'25' 					   -- P_MID_VALUE                            VARCHAR2,
            	   ,'1'						   -- P_MINIMUM                              VARCHAR2,
            	   ,0 						   -- P_SEQUENCE                             NUMBER,
            	   ,p_proposed_sal      	   -- P_VALUE                                VARCHAR2,
             	   ,Fnd_Global.conc_request_id -- P_REQUEST_ID                           NUMBER,
             	   ,fnd_global.PROG_APPL_ID    -- P_PROGRAM_APPLICATION_ID               NUMBER,
             	   ,fnd_global.CONC_PROGRAM_ID -- P_PROGRAM_ID                           NUMBER,
             	   ,sysdate 				   -- P_PROGRAM_UPDATE_DATE                  DATE,
            	   ,'USD');   				   -- P_CURRENCY_CODE                        VARCHAR2)
				   
				   p_GRADE_RULE_ID := v_GRADE_RULE_ID;
  				   
 
				   							   
END ttec_add_sal_assignment;

Procedure TTEC_add_SIT (p_person_id IN   NUMBER
                       ,p_business_group_id IN NUMBER
                       ,p_id_flex_num IN NUMBER
                       ,p_hire_date IN date
                       ,p_segment1 IN VARCHAR2
                       ,p_segment2 IN VARCHAR2
                       ,p_segment3 IN VARCHAR2
                       
                       
                       ) is
                       
                       
 v_validate   BOOLEAN := FALSE; 					--              in     boolean default false          
 
  
v_analysis_criteria_id     NUMBER; --  in out nocopy numbe                  
v_person_analysis_id       NUMBER; -- out nocopy    number                  
v_pea_object_version_number NUMBER; -- out nocopy    number     
V_SEGMENT1_4 VARCHAR2 (8);
 
begin


 
  dbms_output.put_line('-----  SIT ENTRY   : Person_id' || p_person_id 
                       ||'BUS_GROUP_ID' || p_business_group_id 
                       ||'Flex Num ' ||p_id_flex_num 
                       ||'Hire Date' ||p_hire_date 
                       ||'Segment1 ' ||p_segment1 
                       ||'Segment1 ' ||p_segment2 
                       ||'Segment1 ' ||p_segment3); 
                        				

v_analysis_criteria_id   := NULL;        
v_person_analysis_id := NULL;        
v_pea_object_version_number := NULL;        


V_SEGMENT1_4 := SUBSTR (P_SEGMENT1, 8,4);


per_anc_ins.ins_or_sel
         (V_segment1_4             -- in  varchar2 default null,
          ,p_segment2             -- in  varchar2 default null,
          ,p_segment3             -- in  varchar2 default null,
          , null -- p_segment4              in  varchar2 default null,
          , null -- p_segment5              in  varchar2 default null,
          , null -- p_segment6              in  varchar2 default null,
          , null -- p_segment7              in  varchar2 default null,
          , null -- p_segment8              in  varchar2 default null,
          , null -- p_segment9              in  varchar2 default null,
          , null -- p_segment10             in  varchar2 default null,
          , null -- p_segment11             in  varchar2 default null,
          , null -- p_segment12             in  varchar2 default null,
          , null -- p_segment13             in  varchar2 default null,
          , null -- p_segment14             in  varchar2 default null,
          , null -- p_segment15             in  varchar2 default null,
          , null -- p_segment16             in  varchar2 default null,
          , null -- p_segment17             in  varchar2 default null,
          , null -- p_segment18             in  varchar2 default null,
          , null -- p_segment19             in  varchar2 default null,
          , null -- p_segment20             in  varchar2 default null,
          , null -- p_segment21             in  varchar2 default null,
          , null -- p_segment22             in  varchar2 default null,
          , null -- p_segment23             in  varchar2 default null,
          , null -- p_segment24             in  varchar2 default null,
          , null -- p_segment25             in  varchar2 default null,
          , null -- p_segment26             in  varchar2 default null,
          , null -- p_segment27             in  varchar2 default null,
          , null -- p_segment28             in  varchar2 default null,
          , null -- p_segment29             in  varchar2 default null,
          , null -- p_segment30             in  varchar2 default null,
          ,P_business_group_id     --in  number,
          ,P_id_flex_num          -- in  number,
          ,V_analysis_criteria_id -- out number,
          ,false); --              in  boolean default false);






 hr_sit_api.create_sit                                       
   (v_validate                --   in     boolean default false
   ,p_person_id               --  in     number               
   ,p_business_group_id       --   in     number               
   ,p_id_flex_num             --   in     number               
   ,p_hire_date        		  --        _effective_date            in     date                 
   ,NULL 					  -- comments                --   in     varchar2 default null
   ,p_hire_date               -- p_date_from               --   in     date     default null
   ,(p_hire_date + 365)       --   in     date     default null
   ,fnd_global.conc_request_id   --   in     number   default null
   ,fnd_global.PROG_APPL_ID      --   in     number   default null
   ,fnd_global.CONC_PROGRAM_ID   --   in     number   default null
   ,sysdate     --   in     date     default null
   ,NULL       --   in     varchar2 default null
   ,NULL -- p_attribute1              --   in     varchar2 default null
   ,NULL -- p_attribute2              --   in     varchar2 default null
   ,NULL -- p_attribute3              --   in     varchar2 default null
   ,NULL -- p_attribute4              --   in     varchar2 default null
   ,NULL -- p_attribute5              --   in     varchar2 default null
   ,NULL -- p_attribute6              --   in     varchar2 default null
   ,NULL -- p_attribute7              --   in     varchar2 default null
   ,NULL -- p_attribute8              --   in     varchar2 default null
   ,NULL -- p_attribute9              --   in     varchar2 default null
   ,NULL -- p_attribute10             --   in     varchar2 default null
   ,NULL -- p_attribute11             --   in     varchar2 default null
   ,NULL -- p_attribute12             --   in     varchar2 default null
   ,NULL -- p_attribute13             --   in     varchar2 default null
   ,NULL -- p_attribute14             --   in     varchar2 default null
   ,NULL -- p_attribute15             --   in     varchar2 default null
   ,NULL -- p_attribute16             --   in     varchar2 default null
   ,NULL -- p_attribute17             --   in     varchar2 default null
   ,NULL -- p_attribute18             --   in     varchar2 default null
   ,NULL -- p_attribute19             --   in     varchar2 default null
   ,NULL -- p_attribute20             --   in     varchar2 default null
   ,NULL -- p_segment1                --   in     varchar2 default null
   ,p_segment2                --   in     varchar2 default null
   ,p_segment3                --   in     varchar2 default null
   ,NULL -- p_segment4                --   in     varchar2 default null
   ,NULL -- p_segment5                --   in     varchar2 default null
   ,NULL -- p_segment6                --   in     varchar2 default null
   ,NULL -- p_segment7                --   in     varchar2 default null
   ,NULL -- p_segment8                --   in     varchar2 default null
   ,NULL -- p_segment9                --   in     varchar2 default null
   ,NULL -- p_segment10               --   in     varchar2 default null
   ,NULL -- p_segment11               --   in     varchar2 default null
   ,NULL -- p_segment12               --   in     varchar2 default null
   ,NULL -- p_segment13               --   in     varchar2 default null
   ,NULL -- p_segment14               --   in     varchar2 default null
   ,NULL -- p_segment15               --   in     varchar2 default null
   ,NULL -- p_segment16               --   in     varchar2 default null
   ,NULL -- p_segment17               --   in     varchar2 default null
   ,NULL -- p_segment18               --   in     varchar2 default null
   ,NULL -- p_segment19               --   in     varchar2 default null
   ,NULL -- p_segment20               --   in     varchar2 default null
   ,NULL -- p_segment21               --   in     varchar2 default null
   ,NULL -- p_segment22               --   in     varchar2 default null
   ,NULL -- p_segment23               --   in     varchar2 default null
   ,NULL -- p_segment24               --   in     varchar2 default null
   ,NULL -- p_segment25               --   in     varchar2 default null
   ,NULL -- p_segment26               --   in     varchar2 default null
   ,NULL -- p_segment27               --   in     varchar2 default null
   ,NULL -- p_segment28               --   in     varchar2 default null
   ,NULL -- p_segment29               --   in     varchar2 default null
   ,NULL -- p_segment30               --   in     varchar2 default null
   , NULL -- p_concat_segments         --   in     varchar2 default null
   ,v_analysis_criteria_id    --   in out nocopy number        
   ,v_person_analysis_id      --   out nocopy    number        
   ,v_pea_object_version_number -- out nocopy    number        
   );     
   
   
end TTEC_add_SIT;


Procedure TTEC_add_Cost_Allocation (p_assignment_id IN NUMBER
                        ,p_business_group_id IN NUMBER
                        ,p_hire_date IN date
                        ,p_segment2 IN VARCHAR2       
                       ) is
                       
                       
 v_validate   BOOLEAN := FALSE; 					--              in     boolean default false          
 v_proportion hr.pay_cost_allocations_f.proportion%TYPE;
 
v_combination_name            varchar2(240);     
v_cost_allocation_id          number;      
v_effective_start_date        date;     
v_effective_end_date          date;     
v_cost_allocation_keyflex_id  number;   
v_object_version_number       number;   

   
 
v_analysis_criteria_id     NUMBER; --  in out nocopy number                  
v_person_analysis_id       NUMBER; -- out nocopy    number                  
v_pea_object_version_number NUMBER; -- out nocopy    number     
 
begin



v_validate := FALSE;
v_proportion         := 1;

-- v_segment2 := '0068';


PAY_COST_ALLOCATION_API.CREATE_COST_ALLOCATION
  (v_validate                     -- in     boolean  default false
  ,p_hire_date               -- in     date
  ,p_assignment_id                -- in     number
  ,v_proportion                   -- in     number
  ,p_business_group_id            -- in     number
  ,NULL -- p_segment1                      in     varchar2 default null
  ,p_segment2                    --    in     varchar2 default null
  ,NULL -- p_segment3                      in     varchar2 default null
  ,NULL          --          in     varchar2 default null
  , NULL -- p_segment5                      in     varchar2 default null
  , NULL -- p_segment6                      in     varchar2 default null
  , NULL -- p_segment7                      in     varchar2 default null
  , NULL -- p_segment8                      in     varchar2 default null
  , NULL -- p_segment9                      in     varchar2 default null
  , NULL -- p_segment10                     in     varchar2 default null
  , NULL -- p_segment11                     in     varchar2 default null
  , NULL -- p_segment12                     in     varchar2 default null
  , NULL -- p_segment13                     in     varchar2 default null
  , NULL -- p_segment14                     in     varchar2 default null
  , NULL -- p_segment15                     in     varchar2 default null
  , NULL -- p_segment16                     in     varchar2 default null
  , NULL -- p_segment17                     in     varchar2 default null
  , NULL -- p_segment18                     in     varchar2 default null
  , NULL -- p_segment19                     in     varchar2 default null
  , NULL -- p_segment20                     in     varchar2 default null
  , NULL -- p_segment21                     in     varchar2 default null
  , NULL -- p_segment22                     in     varchar2 default null
  , NULL -- p_segment23                     in     varchar2 default null
  , NULL -- p_segment24                     in     varchar2 default null
  , NULL -- p_segment25                     in     varchar2 default null
  , NULL -- p_segment26                     in     varchar2 default null
  , NULL --p_segment27                     in     varchar2 default null
  , NULL --p_segment28                     in     varchar2 default null
  , NULL --p_segment29                     in     varchar2 default null
  , NULL --p_segment30                     in     varchar2 default null
  , '.'||p_segment2||'....'     --p_concat_segments               in     varchar2 default null
  ,v_combination_name            --     out nocopy varchar2
  ,v_cost_allocation_id           --    out nocopy number
  ,v_effective_start_date         --    out nocopy date
  ,v_effective_end_date            --   out nocopy date
  ,v_cost_allocation_keyflex_id     --  out nocopy number
  ,v_object_version_number  --          out nocopy number
  );
/* dbms_output.put_line('Total Records Read '          || v_combination_name||
  v_cost_allocation_id ||
  v_effective_start_date ||
  v_effective_end_date   ||
  v_cost_allocation_keyflex_id||
  v_object_version_number  );
  */

end TTEC_add_Cost_Allocation;


 
/********************MAIN BODY***************************************************/
PROCEDURE main IS

v_business_group_id            number;
v_person_type_id               number;
v_employee_number              varchar2(30);

v_person_id                    number;
v_assignment_id                number;
v_per_object_version_number    number;
v_asg_object_version_number    number;
v_per_effective_start_date     date;
v_per_effective_end_date       date;
v_full_name                    varchar2(240);
v_per_comment_id               number;
v_assignment_sequence          number;
v_assignment_number            varchar2(30);
v_name_combination_warning     boolean;
v_assign_payroll_warning       boolean;

v_line                         varchar2(2000);
v_validate boolean := FALSE ;


v_rate_id number;

v_hire_date    TTEC_ContingentWORKER_load.hire_date%TYPE;   
v_First_NAME  			TTEC_ContingentWORKER_load.first_name%TYPE;
v_Last_NAME   			TTEC_ContingentWORKER_load.last_name%TYPE;   
v_NATIONAL_num 			TTEC_ContingentWORKER_load.national_id%TYPE;
v_Agency      			TTEC_ContingentWORKER_load.agency%TYPE;      
v_PassToKronos 			TTEC_ContingentWORKER_load.passtokronos%TYPE;  
v_Org_name				TTEC_ContingentWORKER_load.org_name%TYPE;			
v_JOB_CODE 				TTEC_ContingentWORKER_load.job_code%TYPE;      
v_LOCATION_Name 		TTEC_ContingentWORKER_load.location_name%TYPE;  
v_Assignement  			TTEC_ContingentWORKER_load.assig_cat%TYPE; 
v_npw_sup				TTEC_ContingentWORKER_load.npw_sup%TYPE; 
v_AssgRateName 			TTEC_ContingentWORKER_load.assgRateName%TYPE;  
v_AssgRateBasis 		TTEC_ContingentWORKER_load.assgRateBasis%TYPE;  
v_AssgRateType 			TTEC_ContingentWORKER_load.AssgRateType%Type;  
v_Currency     			TTEC_ContingentWORKER_load.currency%TYPE;  
v_Hourly_rate  			TTEC_ContingentWORKER_load.Hourly_Rate%TYPE;  
v_Client_code  			TTEC_ContingentWORKER_load.Client_code%TYPE;  				--


-- v_npw_sup_num  			TTEC_ContingentWORKER_load.npw_sup%TYPE;  				--
v_location_id hr.per_all_assignments_f.location_id%type;
v_org_id hr.per_all_assignments_f.organization_id%type; 
v_national_id hr.per_all_people_f.national_identifier%type;
v_sup_id  hr.per_all_people_f.person_id%type;
v_WorkingHrs hr.per_all_assignments_f.normal_hours%type;
v_frequency hr.per_all_assignments_f.frequency%type;
v_job_id    hr.per_jobs.JOB_ID%type;
v_temp TTEC_ContingentWORKER_load.Hourly_Rate%TYPE;

-- output parameters
v_myassign varchar2(80); 
v_id_flex_num  applsys.fnd_id_flex_segments.id_flex_num%TYPE;
v_npw_number varchar2(240);

w_person_id                        NUMBER;
w_per_object_version_number        number;
w_per_effective_start_date         date;
w_per_effective_end_date           date;
w_pdp_object_version_number        number;
w_full_name                        varchar2(240);
w_comment_id                       number;
w_assignment_id                    number;
w_asg_object_version_number        number;
w_assignment_sequence              number;
w_assignment_number                varchar2(80);
w_name_combination_warning         boolean;
w_GRADE_RULE_ID                    number;

l_module_name CUST.ttec_error_handling.module_name%TYPE := 'Main';


BEGIN
g_total_records_read := 0;

-- Open and fetch Salaries information from staging table

begin

select A.id_flex_num into v_id_flex_num 
from fnd_id_flex_segments a, fnd_id_flexs b 
where a.application_id = b.application_Id
and a.application_id = 800
and a.id_flex_code = b.id_flex_code
and a.id_flex_code = 'PEA'
and b.id_flex_name = 'Personal Analysis Flexfield'
and a.segment_name = 'CWK Agency/Firm Name';

exception

     WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('- No location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name);					
--           RAISE SKIP_RECORD;
     	v_location_id  := NULL;	      
     WHEN TOO_MANY_ROWS THEN
     dbms_output.put_line('- Too many  location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name );					
   --                 RAISE SKIP_RECORD;
   	  v_location_id  := NULL;	 
     WHEN OTHERS THEN
          dbms_output.put_line('- Others error on location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name	);					          
    --      RAISE SKIP_RECORD;
		v_location_id  := NULL;	 

end;




FOR c_sel IN c_contworker_emp LOOP
    g_total_records_read := g_total_records_read + 1;
-- 	g_primary_column := sel.ss_number;

    BEGIN
	  
	  v_First_NAME  			:= NULL;

	  v_Last_NAME  			:= NULL;
	  v_NATIONAL_ID 			:= NULL;
	  v_Agency      			:= NULL;
	  v_PassToKronos 			:= NULL;
	  v_Org_name				:= NULL;
	  v_JOB_CODE 				:= NULL;
	 v_npw_number  := NULL;
	  v_LOCATION_Name 		:= NULL;
	  v_Assignement  			:= NULL;
	  v_WorkingHrs			:= NULL;
	  v_FREQUENCY    			:= NULL;
	  v_AssgRateName 			:= NULL;
	  v_AssgRateBasis 		:= NULL;
	  v_AssgRateType 			:= NULL;
	  v_Currency     			:= NULL;
	  v_Hourly_rate  			:= NULL;
	  v_Client_code  			:= NULL;
	  v_business_group_Id := 325;
	  v_person_type_id := 166;
	  
	  

	  v_hire_date      := c_sel.hire_date;  
v_First_NAME  	 := c_sel.first_name; 
v_Last_NAME   	 := c_sel.last_name;  
v_NATIONAL_num   := c_sel.national_id;
v_Agency      	 := c_sel.agency;     
v_PassToKronos   := c_sel.passtokronos;
v_Org_name			 := c_sel.org_name;   
v_JOB_CODE 			 := c_sel.job_code;   
v_LOCATION_Name  := c_sel.location_name;
v_Assignement    := c_sel.assig_cat;  
v_npw_sup				 := c_sel.npw_sup;    
v_AssgRateName   := c_sel.AssgRateName;
v_AssgRateBasis  := c_sel.AssgRateBasis;
v_AssgRateType   := c_sel.AssgRateType;
v_Currency       := c_sel.Currency  ;  
v_Hourly_rate    := c_sel.Hourly_rate; 
v_Client_code    := substr( c_sel.Client_code, 1,4);
 
 
 -- dbms_output.put_line ('>>>>>>>>>>' ||v_Client_code);
    -- Initialize values
   
   
   
      if length (v_national_num) = 4 then
	  	  	 v_national_id :='000-00-' || v_national_num;
	  else
	  	  	 v_national_id :='000-00-0000';
			 
     dbms_output.put_line('--- Social Security Number does not exist -- set to 000-00-0000' );
	  end if;	  	 
	
   --   dbms_output.put_line('$$$$$$---'|| v_HourlY_rate);
	  
	     if (instr(v_Hourly_rate, '$',1,1) > 0) then
		     
   	 	   v_temp :=  substr(v_Hourly_rate, 2, 10);
		   -- dbms_output.put_line('$$$$$$ v_temp ---'|| v_temp);
		   v_Hourly_rate := v_temp;
		end if;   
     -- dbms_output.put_line('$$$$$$---'|| v_HourlY_rate);
		  
      dbms_output.put_line('First Procesing :'|| v_last_name || ' ' || v_first_name || ' ' || v_national_id);
	  
      hr_contingent_worker_api.create_cwk 
  (v_validate                 --   in     boolean  default false
  ,v_hire_date                   -- p_start_date                    --in     date
  ,v_business_group_Id		  --p_business_group_id            -- in     number
  ,v_last_name                --in     varchar2
  ,v_person_type_id   -- let it default to CW  v_person_type_id           --in     number   default null
  ,v_npw_number               --in out nocopy varchar2
  ,NULL							--p_background_check_status       --in     varchar2 default null
  ,NULL							--p_background_date_check         --in     date     default null
  ,NULL							--p_blood_type                    --in     varchar2 default null
  ,NULL  						-- p_comments              --in     varchar2 default null
  ,NULL 						--p_correspondence_language       --in     varchar2 default null
  ,NULL 						--_country_of_birth              --in     varchar2 default null
  ,NULL 						--p_date_of_birth                 --in     date     default null
  ,NULL							--p_date_of_death                 --in     date     default null
  ,NULL 						--p_dpdnt_adoption_date           --in     date     default null
  ,NULL 						-- p_dpdnt_vlntry_svce_flag        --in     varchar2 default null
  ,NULL 						--p_email_address                 --in     varchar2 default null
  ,v_first_name                  --in     varchar2 default null
  ,NULL 						--p_fte_capacity                  --in     number   default null
  ,NULL 						--p_honors                        --in     varchar2 default null
  ,NULL -- v_internal_location          --in     varchar2 default null
  ,NULL 						--p_known_as                      --in     varchar2 default null
  ,NULL 						--p_last_medical_test_by          --in     varchar2 default null
  ,NULL 						--p_last_medical_test_date        --in     date     default null
  ,NULL 						--p_mailstop                      --in     varchar2 default null
  ,NULL 						--p_marital_status                --in     varchar2 default null
  ,NULL                         -- in     varchar2 default null
  ,v_national_id 				-- p_national_identifier           --in     varchar2 default null
  ,NULL							--p_nationality                   --in     varchar2 default null
  ,NULL 						--p_office_number                 --in     varchar2 default null
  ,NULL 						--p_on_military_service           --in     varchar2 default null
  ,NULL 						--p_party_id                      --in     number   default null
  ,NULL 						--p_pre_name_adjunct              --in     varchar2 default null
  ,NULL 						--p_previous_last_name            --in     varchar2 default null
  ,NULL 						--p_projected_placement_end       --in     date     default null
  ,NULL 						 -- p_receipt_of_death_cert_date    --in     date     default null
  ,NULL  						 -- p_region_of_birth               --in     varchar2 default null
  ,NULL 						 -- p_registered_disabled_flag      --in     varchar2 default null
  ,NULL 						 -- p_resume_exists                 --in     varchar2 default null
  ,NULL 						 -- p_resume_last_updated           --in     date     default null
  ,NULL 						 -- p_second_passport_exists        --in     varchar2 default null
  ,NULL 						 -- p_sex                           --in     varchar2 default null
  ,NULL 						 -- p_student_status                --in     varchar2 default null
  ,NULL 						 -- p_suffix                        --in     varchar2 default null
  ,NULL 						 -- p_title                         --in     varchar2 default null
  ,NULL 				-- p_town_of_birth                 --in     varchar2 default null
  ,NULL 				-- p_uses_tobacco_flag             --in     varchar2 default null
  ,NULL 				-- p_vendor_id                     --in     number   default null
  ,NULL 				-- p_work_schedule                 --in     varchar2 default null
  ,NULL 				-- p_work_telephone                --in     varchar2 default null
  ,NULL 				-- p_exp_check_send_to_address     --in     varchar2 default null
  ,NULL 				-- p_hold_applicant_date_until     --in     date     default null
  ,NULL 				-- p_date_employee_data_verified   --in     date     default null
  ,NULL 				-- p_benefit_group_id              --in     number   default null
  ,NULL 				-- p_coord_ben_med_pln_no          --in     varchar2 default null
  ,NULL 				-- p_coord_ben_no_cvg_flag         --in     varchar2 default null
  ,v_hire_date 			-- p_original_date_of_hire         --in     date     default null
  ,NULL 				-- p_attribute_category            --in     varchar2 default null
  ,NULL 				-- p_attribute1                    --in     varchar2 default null
  ,NULL 				-- p_attribute2                    --in     varchar2 default null
  ,NULL 				-- p_attribute3                    --in     varchar2 default null
  ,NULL 				-- p_attribute4                    --in     varchar2 default null
  ,NULL 				-- p_attribute5                    --in     varchar2 default null
  ,NULL 				-- p_attribute6                    --in     varchar2 default null
  ,NULL 				-- p_attribute7                    --in     varchar2 default null
  ,NULL 				-- p_attribute8                    --in     varchar2 default null
  ,NULL 				-- p_attribute9                    --in     varchar2 default null
  ,NULL 				-- p_attribute10                   --in     varchar2 default null
  ,NULL 				-- p_attribute11                   --in     varchar2 default null
  ,NULL 				-- p_attribute12                   --in     varchar2 default null
  ,NULL 				-- p_attribute13                   --in     varchar2 default null
  ,NULL 				-- p_attribute14                   --in     varchar2 default null
  ,NULL 				-- p_attribute15                   --in     varchar2 default null
  ,NULL 				-- p_attribute16                   --in     varchar2 default null
  ,NULL 				-- p_attribute17                   --in     varchar2 default null
  ,NULL 				-- p_attribute18                   --in     varchar2 default null
  ,NULL 				-- p_attribute19                   --in     varchar2 default null
  ,NULL 				-- p_attribute20                   --in     varchar2 default null
  ,NULL 				-- p_attribute21                   --in     varchar2 default null
  ,NULL 				-- p_attribute22                   --in     varchar2 default null
  ,NULL 				-- p_attribute23                   --in     varchar2 default null
  ,NULL 				-- p_attribute24                   --in     varchar2 default null
  ,NULL 				-- p_attribute25                   --in     varchar2 default null
  ,NULL 				-- p_attribute26                   --in     varchar2 default null
  ,NULL 				-- p_attribute27                   --in     varchar2 default null
  ,NULL 				-- p_attribute28                   --in     varchar2 default null
  ,NULL 				-- p_attribute29                   --in     varchar2 default null
  ,NULL 				-- p_attribute30                   --in     varchar2 default null
  ,NULL 				-- p_per_information_category      --in     varchar2 default null
  ,NULL 				-- p_per_information1              --in     varchar2 default null
  ,NULL 				-- p_per_information2              --in     varchar2 default null
  ,NULL 				-- p_per_information3              --in     varchar2 default null
  ,NULL 				-- p_per_information4              --in     varchar2 default null
  ,NULL 				-- p_per_information5              --in     varchar2 default null
  ,NULL 				-- p_per_information6              --in     varchar2 default null
  ,NULL 				-- p_per_information7              --in     varchar2 default null
  ,NULL 				-- p_per_information8              --in     varchar2 default null
  ,NULL 				-- p_per_information9              --in     varchar2 default null
  ,NULL 				-- p_per_information10             --in     varchar2 default null
  ,NULL 				-- p_per_information11             --in     varchar2 default null
  ,NULL 				-- p_per_information12             --in     varchar2 default null
  ,NULL 				-- p_per_information13             --in     varchar2 default null
  ,NULL 				-- p_per_information14             --in     varchar2 default null
  ,NULL 				-- p_per_information15             --in     varchar2 default null
  ,NULL 				-- p_per_information16             --in       varchar2 default null
  ,NULL 				-- p_per_information17             --in       varchar2 default null
  ,NULL 				-- p_per_information18             --in       varchar2 default null
  ,NULL 				-- p_per_information19             --in       varchar2 default null
  ,NULL 				-- p_per_information20             --in       varchar2 default null
  ,NULL 				-- p_per_information21             --in       varchar2 default null
  ,NULL 				-- p_per_information22             --in       varchar2 default null
  ,NULL 				-- p_per_information23             --in       varchar2 default null
  ,NULL 				-- p_per_information24             --in       varchar2 default null
  ,NULL 				-- p_per_information25             --in       varchar2 default null
  ,NULL 				-- p_per_information26             --in       varchar2 default null
  ,NULL 				-- p_per_information27             --in       varchar2 default null
  ,NULL 				-- p_per_information28             --in       varchar2 default null
  ,NULL 				-- p_per_information29             --in       varchar2 default null
  ,NULL 				-- p_per_information30             --in       varchar2 default null
  ,w_person_id                
  ,                         w_per_object_version_number
  ,                         w_per_effective_start_date 
  ,                         w_per_effective_end_date   
  ,                         w_pdp_object_version_number
  ,                         w_full_name                
  ,                         w_comment_id               
  ,                         w_assignment_id            
  ,                         w_asg_object_version_number
  ,                         w_assignment_sequence      
  ,                        w_assignment_number        
  ,                        w_name_combination_warning );

  /*
        EXCEPTION

        WHEN SKIP_RECORD2 THEN
        --    NULL;
		            
            CUST.TTEC_PROCESS_ERROR
                (c_application_code, c_interface, c_program_name,
                 l_module_name, c_failure_status, SQLCODE, SQLERRM,'Emp No', g_primary_column);
		 NULL;		 
   
       WHEN OTHERS THEN
            
            CUST.TTEC_PROCESS_ERROR
                (c_application_code, c_interface, c_program_name,
                 l_module_name, c_failure_status, SQLCODE, SQLERRM,'Emp No', g_primary_column);
				 
         raise;
*/

    END;


  				--update hr.per_all_people_f 	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
				update apps.per_all_people_f 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
				SET person_type_id  =  166	
		  		WHERE  person_id = w_person_id;
				
				commit;
				
--			update hr.per_all_people_f 
--				SET person_type_id  =  166	
--		  		WHERE  person_id = w_person_id;
		  		
		   v_myassign := 'PT';

		   if v_Assignement = 'Fulltime-Temporary' then
		       v_myassign := 'FT';
		   end if; 
			   		
			

begin
			select location_id into v_location_id 
			--from hr.hr_locations_all -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			from apps.hr_locations_all -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
			where location_code like v_LOCATION_Name;			


exception

     WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('- No location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name);					
--           RAISE SKIP_RECORD;
     	v_location_id  := NULL;	      
     WHEN TOO_MANY_ROWS THEN
     dbms_output.put_line('- Too many  location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name );					
   --                 RAISE SKIP_RECORD;
   	  v_location_id  := NULL;	 
     WHEN OTHERS THEN
          dbms_output.put_line('- Others error on location found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_LOCATION_Name	);					          
    --      RAISE SKIP_RECORD;
		v_location_id  := NULL;	 

end;




begin

 			select job_id into v_job_id
			--from  hr.per_jobs	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			from  apps.per_jobs	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
			where business_group_id = 325 and name  like v_job_code||'%';

exception
	
     WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('- No JOB found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_job_code);				
--           RAISE SKIP_RECORD;
      v_job_id := NULL;
     WHEN TOO_MANY_ROWS THEN
     dbms_output.put_line('- Too many  JOB found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_job_code);					
   --                 RAISE SKIP_RECORD;
   v_job_id := NULL;
     WHEN OTHERS THEN
          dbms_output.put_line('- Others error on JOB found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_job_code);					          
    --      RAISE SKIP_RECORD;
	v_job_id := NULL;
end;





begin
	 		select organization_id into v_org_id
			from  apps.hr_organization_units  
			where business_group_id = 325 and name like v_org_name;
			

exception
    
     WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('- No Organization found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_org_name);				
--           RAISE SKIP_RECORD;
     v_org_id := NULL;     
     WHEN TOO_MANY_ROWS THEN
     dbms_output.put_line('- Too many  Organization found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_org_Name);					
   --                 RAISE SKIP_RECORD;
   v_org_id := NULL;
     WHEN OTHERS THEN
          dbms_output.put_line('- Others error on Organization found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_org_Name);					          
    --      RAISE SKIP_RECORD;
	v_org_id := NULL;
end;


BEGIN

      SELECT person_id
        INTO v_sup_id
        FROM per_all_people_f
      WHERE (employee_number = v_npw_sup  or npw_number = v_npw_sup)
         AND TRUNC (SYSDATE) BETWEEN effective_start_date AND effective_end_date
         AND ROWNUM < 2;
			

exception
     
     WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('- No SUPERVISOR found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_npw_sup);				
--           RAISE SKIP_RECORD;
     v_sup_id := NULL;     
     WHEN TOO_MANY_ROWS THEN
     dbms_output.put_line('- Too many  SUPERVISOR found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_npw_sup);					
   --                 RAISE SKIP_RECORD;
   v_sup_id := NULL;
     WHEN OTHERS THEN
     dbms_output.put_line('- Others error on SUPERVISOR found for  : '|| v_last_name|| ' ' || v_first_name || ' ' || v_npw_sup);					          
    --      RAISE SKIP_RECORD;
	v_sup_id := NULL;

end;

commit;

		  	  --update hr.per_all_assignments_f -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  update apps.per_all_assignments_f 	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
			  SET frequency =  'W'
		      , normal_hours = 40
		      , employment_category  = v_myassign 
		      , location_id = v_location_id
			  , organization_id = v_org_id
			  , supervisor_id = v_sup_id
			  , job_id = v_job_id
		  	  WHERE  assignment_id  = w_assignment_id ;
			  
	commit;
			  v_rate_id := 64;
			  w_GRADE_RULE_ID := 4096;
/* dbms_output.put_line (' ---- ' || 'aasig' || w_assignment_id|| 
					  'business group' || v_business_group_id
					  || 'rate_id' || v_rate_id       	
                       ||'hire_date' || v_hire_date     	
					   || 'hourly rate' || v_Hourly_rate ); */
					        
	--		dbms_output.put_line (' ---- '    || 'grade' || w_GRADE_RULE_ID    );		
					   
			  ttec_add_sal_assignment(w_assignment_id    
					   ,v_business_group_id
					   ,v_rate_id       	
                       ,v_hire_date     	
					   ,v_Hourly_rate      
					   ,w_GRADE_RULE_ID    );			
-- dbms_output.put_line (' afteri' ||  'grade' || w_GRADE_RULE_ID    );

-- dbms_output.put_line (' afteri' ||  'grade' || w_GRADE_RULE_ID    );

-- dbms_output.put_line (' before' || w_person_id ||v_business_group_id ||v_id_flex_num||v_hire_date||v_agency);

-- dbms_output.put_line (' before' || w_person_id ||v_business_group_id ||v_id_flex_num||v_hire_date||v_agency);

TTEC_add_Cost_Allocation (w_assignment_id 
                        ,v_business_group_id 
                        ,v_hire_date
                        ,v_client_code        
                       );


TTEC_add_SIT (w_person_id 
                       ,v_business_group_id
                       ,v_id_flex_num 
                       ,v_hire_date 
                       ,v_NATIONAL_ID
                       ,v_agency
                       ,'Y' );
                       

       
		      g_total_records_processed := g_total_records_processed + 1;
    commit; 
			dbms_output.put_line (' ---- '       );
						dbms_output.put_line (' ---- '       );                                   	
END LOOP;


-- <<<<<<<<<<<<<< COMMIT;    

commit;


-- Display control totals
dbms_output.put_line('Total Records Read ' || to_char(g_total_records_read));
dbms_output.put_line('Total Records Processed ' || to_char(g_total_records_processed));
dbms_output.put_line (' Total Records Rejected = '|| to_char(g_total_records_read - g_total_records_processed));        



END;     -- Main Body

/***********************************************************************/

BEGIN
     -- Call main procedure
     main;

EXCEPTION

    WHEN OTHERS THEN
         CUST.TTEC_PROCESS_ERROR
             (c_application_code, c_interface, c_program_name,
              'Calling main procedure', c_failure_status, SQLCODE, SQLERRM);
    
    RAISE;
END;
/

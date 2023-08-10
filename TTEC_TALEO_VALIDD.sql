--
-- Purpose: SQL script to insert default values that come through TALEO's inbound interface
--          Values need to group by Business Group ID and to be inserted into
--          TTEC_TALEO_DEFAULTS table. There will be API calls from a different process to 
--          populates the remaing fields upon the country's legislation.
--          
-- Creation Date: Feb 22,2007
--
-- Created By:    Christiane Chan
-- Modified By:   Marcela Lagostena - To include new fields for ZA and ARG Integration
-- NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation 
--

TRUNCATE TABLE cust.ttec_taleo_defaults;

--INSERT INTO cust.TTEC_TALEO_DEFAULTS	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
INSERT INTO APPS.TTEC_TALEO_DEFAULTS	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
(    Business_group_id     
  --  Email                          
,    Address                        
,    Address2                        
,    City                           
,    ZipCode                         
,    HomePhone                       
,    WorkPhone                      
,    MobilePhone                     
,    SSNumber                       
,    BirthdayDate                   
,    InternalCandId                  
  --  Country                         
,    CountryCode                     
  --  StateProvinceDes              
,    StateProvinceCode               
,    EEO12_GenderId                  
  --  EEO12VeteranId                  
  --  EEO12DisabledVeteranId        
,    EEO1RaceEthnicityId             
,    DepartmentNumber                
,    RecruiterOwnerEmployeeID        
,    Recruter_EmailAddress           
,    HiringManagerEmployeeID         
,    ReqOrgCustomerCode               
,    ReqLocCustomerCode              
,    ReqJobCode                      
,    OfferActualStart                
  --  OfferStockPackage              
,    Marital_Status_US              
,    Marital_Status_PH              
,    ReqClientProgram               
,    ReqAssigCat                    
,    ReqSalaryBasis                 
,    ReqTimecardRequired            
,    ReqProbLength                  
,    ReqProbationUnits              
,    ReqProbEndDate                 
,    ReqWorkingHours                
,    ReqFrequency                   
,    ReqGradeID                     
,    ReqPeopleGroup                 
,    ReqSupervisoryPos              
,    ReqWorking_Home                
,    Offer_Salary_Change_Value      
,    Offer_Salary_Basis              
,    actual_start_date               
 --   req_salary_basis_id          
 --   timecard_required             
,    people_group                    
,   superviosry_flag              
,COUNTY
,PAYROLLID
,GREID
,SETOFBOOKSID
,EXPENSEACCOUNTID
,EXPENSEACCOUNT
,SuperUserEmail
--UK  Begin 
, nationality 
, religion
, legacy_employee_number
, employee_category
, review_salary
, review_salary_frequency
, review_performance
, review_performance_frequency
-- UK End  
,    creation_date                   
,    last_update_date
-- ARG Begin
, unionaffiliation
, industry
-- ARG End              
    )
       SELECT put.business_group_id
	    --    ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) -- Business_group_id     NUMBER (8),
	    --    ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) -- Email                          Varchar2 (160),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Address Line 1',pui.VALUE,NULL)) --     Address                        Varchar2(160),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Address Line 2',pui.VALUE,NULL)) --     Address2                       Varchar2(160),
	        ,MIN(DECODE(pur.row_low_range_or_name,'City',pui.VALUE,NULL)) --     City                           Varchar2 (160),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Postal Code',pui.VALUE,NULL)) --     ZipCode                        Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Home Phone',pui.VALUE,NULL)) --     HomePhone                      Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Work Phone',pui.VALUE,NULL)) --     WorkPhone                      Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Mobile Phone',pui.VALUE,NULL)) --     MobilePhone                    Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'National Identifier',pui.VALUE,NULL)) --     SSNumber                       Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Date of Birth',TO_DATE(TO_CHAR(pui.VALUE),'YYYY-MM-DD'),NULL)) --     BirthdayDate                   date ,  -- date
	        ,MIN(DECODE(pur.row_low_range_or_name,'Internal Candidate Indicator',pui.VALUE,NULL)) --     InternalCandId                 Varchar2(1),
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     Country                        Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Country',pui.VALUE,NULL)) --     CountryCode                    Varchar2 (3),
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     StateProvinceDes               Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'State',pui.VALUE,NULL)) --     StateProvinceCode              Varchar2 (4),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Gender',pui.VALUE,NULL)) --     EEO12_GenderId                 Number(1),
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     EEO12VeteranId                 Number(1),
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     EEO12DisabledVeteranId         Number(1),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Ethnicity',pui.VALUE,NULL)) --     EEO1RaceEthnicityId            Number(1),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Department',pui.VALUE,NULL)) --     DepartmentNumber               Varchar2(25),
	        ,MIN(DECODE(pur.row_low_range_or_name,'RecruiterEmployeeID',pui.VALUE,NULL)) --     RecruiterOwnerEmployeeID       Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'RecruiterEmailAddress',pui.VALUE,NULL)) --     Recruter_EmailAddress          Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Supervisor',pui.VALUE,NULL)) --     HiringManagerEmployeeID        Varchar2 (256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Department',pui.VALUE,NULL)) --     ReqOrgCustomerCode             Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'LocationID',pui.VALUE,NULL)) --     ReqLocCustomerCode             Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Job',pui.VALUE,NULL)) --     ReqJobCode                     Varchar2 (64),
	        ,SYSDATE --     OfferActualStart               Date,
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     OfferStockPackage              Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'MaritalStatus',pui.VALUE,NULL)) --     Marital_Status_US              Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'MaritalStatus',pui.VALUE,NULL)) --     Marital_Status_PH              Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Client Program Project',pui.VALUE,NULL)) --     ReqClientProgram               Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'AssignmentCategory',pui.VALUE,NULL)) --     ReqAssigCat                    Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Salary Basis',pui.VALUE,NULL)) --     ReqSalaryBasis                 Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'TimecardRequired',pui.VALUE,NULL)) --     ReqTimecardRequired            Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'ProbationLength',pui.VALUE,NULL)) --     ReqProbLength                  Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Probation Unit',pui.VALUE,NULL)) --     ReqProbationUnits              Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'ReqProbEndDate',pui.VALUE,NULL)) --     ReqProbEndDate                 Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'WorkingHours',pui.VALUE,NULL)) --     ReqWorkingHours                Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Frequency',pui.VALUE,NULL)) --     ReqFrequency                   Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'GradeID',pui.VALUE,NULL)) --     ReqGradeID                     Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'ReqPeopleGroup',pui.VALUE,NULL)) --     ReqPeopleGroup                 Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Supervisory',pui.VALUE,NULL)) --     ReqSupervisoryPos              Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'WorkingAtHome',pui.VALUE,NULL)) --     ReqWorking_Home                Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Salary Change Value',pui.VALUE,NULL)) --     Offer_Salary_Change_Value      Varchar2(256),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Salary Basis',pui.VALUE,NULL)) --     Offer_Salary_Basis             Varchar2(256), 
	     --   ,MIN(DECODE(pur.row_low_range_or_name,'LocationID',pui.VALUE,NULL)) --     location_id                    NUMBER(8),                                      
	        ,SYSDATE --     actual_start_date              date,
     	 --  ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     req_salary_basis_id            number,
	     --  ,MIN(DECODE(pur.row_low_range_or_name,'Business Group ID',pui.VALUE,NULL)) --     timecard_required              Varchar2 (64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'People Group',pui.VALUE,NULL)) --     people_group                   varchar2(64), 
	        ,MIN(DECODE(pur.row_low_range_or_name,'Supervisory',pui.VALUE,NULL)) --     superviosry_flag               varchar2(64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'County',pui.VALUE,NULL)) --     County               varchar2(64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Payroll',pui.VALUE,NULL)) --     payroll id               varchar2(64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'GRE',pui.VALUE,NULL)) --     GRE               varchar2(64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'Set of Books',pui.VALUE,NULL)) --     Set of Books  id             varchar2(64),
	        ,MIN(DECODE(pur.row_low_range_or_name,'DefaultCodeCombID',pui.VALUE,NULL)) --     Expense Account                varchar2(64),
 	        ,MIN(DECODE(pur.row_low_range_or_name,'Default Expense Account',pui.VALUE,NULL)) --     Expense Account                varchar2(64),
 	        ,MIN(DECODE(pur.row_low_range_or_name,'SuperUserEmail',pui.VALUE,NULL)) --     SuperUser                varchar2(256),
			--UK Begin  			 
			,MIN(DECODE(pur.row_low_range_or_name,'Nationality',pui.VALUE,NULL))			 
			,MIN(DECODE(pur.row_low_range_or_name,'Religion',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Legacy Employee Number',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Employee Category',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Review Salary',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Review Salary Frequency',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Review Performance',pui.VALUE,NULL))
			,MIN(DECODE(pur.row_low_range_or_name,'Review Performance Frequency',pui.VALUE,NULL))	
			-- UK End  														
	        ,SYSDATE  --     creation_date                  date,
	        ,SYSDATE  --     last_update_date               date 	
            -- ARG Begin
            ,MIN(DECODE(pur.row_low_range_or_name,'Unionaffiliation',pui.VALUE,NULL))
            ,MIN(DECODE(pur.row_low_range_or_name,'Industry',pui.VALUE,NULL))
            -- ARG End            		
      FROM 
            apps.pay_user_tables put,
            apps.pay_user_columns puc,
            apps.pay_user_column_instances_f pui,
            apps.pay_user_rows_f pur,
            apps.pay_user_rows_f_tl prm
      WHERE put.user_table_name = 'TTEC_TALEO_VALID_DATA'
      AND   put.USER_TABLE_ID = puc.USER_TABLE_ID
      AND   pui.user_column_id = puc.user_column_id
      AND   pur.user_table_id = put.user_table_id
      AND   pui.user_row_id = pur.user_row_id
      AND   pur.user_row_id = prm.user_row_id
      AND   prm.LANGUAGE = 'US'
      AND   TRUNC(SYSDATE) BETWEEN pui.effective_start_date AND pui.effective_end_date
      AND   TRUNC(SYSDATE) BETWEEN pur.effective_start_date AND pur.effective_end_date
      GROUP BY put.business_group_id;

COMMIT;


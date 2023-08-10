 /************************************************************************************
        Program Name: DELETE_TTEC_ERROR_HANDLING_90_DAYS_OLDER.sql

        Description:   

        Developed by : 
        Date         :  

       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
    ****************************************************************************************/
--delete FROM cust.ttec_error_handling	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
delete FROM apps.ttec_error_handling	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
where trunc(creation_date) <= trunc(sysdate) - 90;

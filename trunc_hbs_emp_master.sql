  /************************************************************************************/
  /*                                                                                  */
  /*     Program Name: create_hbs_emp_master.sql  		                                */
  /*                                                                                  */
  /*     Description:  This program backs up the last employee master table and then  */
  /*                   truncates the table for insertion.
  /*                                                                                  */
  /*     Input/Output Parameters:   None                                              */ 
  /*                                                                                  */
  /*     Tables Accessed:  None														                            */
  /*                                                                                  */
  /*     Tables Modified:  NONE 													                            */
  /*                                                                                  */
  /*     Procedures Called: None													                            */
  /*                                                                                  */
  /*     Created by:        Chan Kang                                                 */ 
  /*                        PricewaterhouseCoopers LLP                                */
  /*     Date:              October 15,2002                                           */
  /*                                                                                  */
  /*     Modification Log:                                                            */
  /*     Developer              Date      Description                                 */
  /*     --------------------   --------  --------------------------------            */
  /*                                                                                  */
  -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
  /************************************************************************************/
  
--START R12.2 Upgrade Remediation  
  /*DROP TABLE cust.tt_hbs_emp_master_bk;
       
  CREATE TABLE cust.tt_hbs_emp_master_bk as (select * from cust.tt_hbs_emp_master);

  TRUNCATE TABLE cust.tt_hbs_emp_master;

  DELETE FROM cust.ttec_error_handling where program_name = 'tt_hbs_outbound_interface';*/
  
  DROP TABLE apps.tt_hbs_emp_master_bk;
       
  CREATE TABLE apps.tt_hbs_emp_master_bk as (select * from apps.tt_hbs_emp_master);

  TRUNCATE TABLE apps.tt_hbs_emp_master;

  DELETE FROM apps.ttec_error_handling where program_name = 'tt_hbs_outbound_interface';
--End R12.2 Upgrade Remediation  

  COMMIT;

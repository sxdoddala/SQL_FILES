  /************************************************************************************/
  /*                                                                                  */
  /*     Program Name: trunc_bee_interface_stage.sql                                  */
  /*                                                                                  */
  /*     Description:  This program truncates the BEE interface staging table.        */
  /*                                                                                  */
  /*     Input/Output Parameters:   None                                              */ 
  /*                                                                                  */
  /*     Tables Accessed:  None														  */
  /*                                                                                  */
  /*     Tables Modified:  cust.tt_bee_interface_stage		                          */
  /*                                                                                  */
  /*     Procedures Called: None													  */
  /*                                                                                  */
  /*     Created by:        Chan Kang                                                 */ 
  /*                        PricewaterhouseCoopers LLP                                */
  /*     Date:              October 22,2002                                           */
  /*                                                                                  */
  /*     Modification Log:                                                            */
  /*     Developer              Date      Description                                 */
  /*     --------------------   --------  --------------------------------            */
  /*     IKONAK                 01/06/03   Added business group parameter             */
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
  /************************************************************************************/

  
  --DELETE FROM cust.tt_bee_interface_stage		-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  DELETE FROM apps.tt_bee_interface_stage	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
    WHERE business_group = (select name from hr_organization_units
	                       where organization_id = '&1');

  COMMIT;

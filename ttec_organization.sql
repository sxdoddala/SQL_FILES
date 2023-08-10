-- Program Name			:  ttec_organizatin.sql
--
-- Description			:  This program displays all the organization details based on param
--
-- Input Parameters		:  Organization id 
--
--
-- Procedures Called		:  Teletech Organization  Detail 
--
-- Created By			:  Elango Pandu
-- Date				:  Dec,6 2006

--       Modification Log
--       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
-- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |

--SET TIMING ON

DECLARE

  p_org_id NUMBER;
  p_class_code  hr_organization_information_v.org_information1_meaning%TYPE;

	  CURSOR c_org_dtl IS
		SELECT a.name,a.business_group_id,a.internal_external_meaning mean,DECODE(a.type,'DEPT','Depart/Cost Center','BG','Business Group','CO','Company','EXT','External','GRE','Government Reporting Entity',a.type) type
	        	,a.date_from date_fro,a.date_to dat_to,b.org_information1_meaning class_name,c.concatenated_segments cost_info
	 	--FROM hr_organization_units_v a, hr_organization_information_v b,hr.pay_cost_allocation_keyflex c	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
		FROM hr_organization_units_v a, hr_organization_information_v b,apps.pay_cost_allocation_keyflex c	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
		WHERE a.organization_id = b.organization_id
		AND   a.cost_allocation_keyflex_id = c.cost_allocation_keyflex_id(+)
		AND   NVL(a.date_to, SYSDATE ) >= SYSDATE
		AND   b.org_information1_meaning IS NOT NULL
                --AND   b.org_information1_meaning = NVL(p_class_code,'HR Organization')
		AND   a.ORGANIZATION_ID = NVL(p_org_id,a.ORGANIZATION_ID)
		ORDER BY a.business_group_id;
	

BEGIN

       p_org_id   := '&1';

       --fnd_file.put_line(fnd_file.output,'Error during importing to ttec_glb_hr_data table ');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Name'||'|'||'Business Group Id'||'|'||'Internal or External'||'|'||'Type'||'|'||'Date From'||'|'||'Date To'||'|'||'Classification'||'|'||'Costing Info.');

       FOR v_org_dtl IN c_org_dtl LOOP
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_org_dtl.name||'|'||v_org_dtl.business_group_id||'|'||v_org_dtl.mean||'|'||v_org_dtl.type||'|' ||v_org_dtl.date_fro||'|' ||v_org_dtl.dat_to||'|' ||v_org_dtl.class_name||'|' ||v_org_dtl.cost_info);
       END LOOP;


EXCEPTION 
    WHEN OTHERS THEN
       NULL;
END;
/

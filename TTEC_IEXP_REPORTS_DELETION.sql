 /************************************************************************************
        Program Name: TTEC_IEXP_REPORTS_DELETION.sql

        Description:   

        Developed by : 
        Date         :  

       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
    ****************************************************************************************/
REM +=======================================================================+
REM | FILENAME                                                              |
REM |     ttec_iexp_report_del_TASK3033610.sql                             |
REM |                                                                       |
REM | DESCRIPTION                                                           |
REM |     The following fix script creates Backup and deletes               |
REM |     data from epxense report headers, lines and distributions         |                             
REM +=======================================================================+
set serveroutput on size 1000000;

  INSERT INTO APPS.TTEC_IEXP_REPORTS_HBKUP 
--SELECT * FROM apps.AP_EXPENSE_REPORT_HEADERS_ALL where invoice_num in(select REPORT_NUMBER from CUST.TTEC_IEXP_REPORTS);	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
SELECT * FROM apps.AP_EXPENSE_REPORT_HEADERS_ALL where invoice_num in(select REPORT_NUMBER from apps.TTEC_IEXP_REPORTS);	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

INSERT INTO APPS.TTEC_IEXP_REPORTS_LBKUP 
SELECT * FROM apps.AP_EXPENSE_REPORT_LINES_ALL WHERE REPORT_HEADER_ID
IN (select report_header_id from apps.ap_expense_report_headers_all where 
--invoice_num in (select REPORT_NUMBER from CUST.TTEC_IEXP_REPORTS));-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
invoice_num in (select REPORT_NUMBER from apps.TTEC_IEXP_REPORTS));	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 

INSERT INTO APPS.TTEC_IEXP_REPORTS_DBKUP
SELECT * FROM apps.AP_EXP_REPORT_DISTS_ALL WHERE REPORT_HEADER_ID
IN (
select report_header_id from apps.ap_expense_report_headers_all where 
--invoice_num in (select REPORT_NUMBER from CUST.TTEC_IEXP_REPORTS));	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
invoice_num in (select REPORT_NUMBER from apps.TTEC_IEXP_REPORTS));	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 


Commit;

DECLARE
  P_ReportID NUMBER := NULL;-- report_header_id;
  l_TempReportHeaderID   NUMBER;
  l_TempReportLineID     NUMBER; 
  l_childItemKeySeq      NUMBER;
  l_wf_active		BOOLEAN := FALSE;
  l_wf_exist		BOOLEAN := FALSE;
  l_end_date		wf_items.end_date%TYPE;
  l_child_item_key	varchar2(2000);
  cnt NUMBER:=0;
  cnt1 NUMBER:=0;
  cnt3 NUMBER:=0;
  

  
  
  Cursor c1
  is
  (select report_header_id from apps.ap_expense_report_headers_all where 
   --invoice_num in (select REPORT_NUMBER from CUST.TTEC_IEXP_REPORTS));  -- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
   invoice_num in (select REPORT_NUMBER from apps.TTEC_IEXP_REPORTS));  -- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
  
  
  CURSOR ReportLines(P_ReportID1 NUMBER) IS
    (SELECT REPORT_HEADER_ID, REPORT_LINE_ID FROM APPS.AP_EXPENSE_REPORT_LINES_ALL WHERE REPORT_HEADER_ID = P_ReportID1);
 

BEGIN 

 FOR I IN C1 -- START OF FOR LOOP ADDED FOR TASK1457090
 LOOP
 
 P_ReportID:=I.report_header_id;
 
 cnt:=cnt+1;

 -- DBMS_OUTPUT.PUT_LINE('Start Deleting Report ' || P_ReportID);

  --DBMS_OUTPUT.PUT('Delete Distributions - ');
  DELETE FROM APPS.AP_EXP_REPORT_DISTS_ALL WHERE REPORT_HEADER_ID = P_ReportID;
    cnt1:=cnt1+SQL%ROWCOUNT;
  --DBMS_OUTPUT.PUT('Delete Attendees - ');
  DELETE FROM APPS.OIE_ATTENDEES_ALL oat WHERE oat.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID FROM apps.ap_expense_report_lines_all WHERE  report_header_id = P_ReportID);
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
  --DBMS_OUTPUT.PUT('Delete Add on Mileage Rates - ');
  DELETE FROM APPS.OIE_ADDON_MILEAGE_RATES addon WHERE addon.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID FROM APPS.ap_expense_report_lines_all WHERE  report_header_id = P_ReportID);
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
  --DBMS_OUTPUT.PUT('Delete Perdiem Daily Breakup - ');
  DELETE FROM OIE_PDM_DAILY_BREAKUPS db WHERE db.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID FROM ap_expense_report_lines_all WHERE  report_header_id = P_ReportID);
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
  --DBMS_OUTPUT.PUT('Delete Perdiem Destinations - ');
  DELETE FROM OIE_PDM_DESTINATIONS db WHERE db.REPORT_LINE_ID IN ( SELECT REPORT_LINE_ID FROM ap_expense_report_lines_all WHERE  report_header_id = P_ReportID);
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
  --DBMS_OUTPUT.PUT('Delete Policy Violations - ');
  DELETE FROM AP_POL_VIOLATIONS_ALL WHERE REPORT_HEADER_ID = P_ReportID;
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
  
 -- DBMS_OUTPUT.PUT('Update CC transactions, make them available for future reports - ');
  --UPDATE AP_CREDIT_CARD_TRXNS_ALL SET REPORT_HEADER_ID = NULL, EXPENSED_AMOUNT = 0, CATEGORY = NULL WHERE REPORT_HEADER_ID  = P_ReportID;
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);

  OPEN ReportLines(P_ReportID);
  
 -- DBMS_OUTPUT.PUT_LINE('Delete Attachments');
  LOOP
  
    FETCH ReportLines into l_TempReportHeaderID, l_TempReportLineID;
    EXIT WHEN ReportLines%NOTFOUND;
    
    /* Delete attachments assocated with the line */
    fnd_attached_documents2_pkg.delete_attachments(
      X_entity_name => 'OIE_LINE_ATTACHMENTS',
      X_pk1_value => l_TempReportLineID,
      X_delete_document_flag => 'Y'
    );     
  END LOOP;  
  
  CLOSE ReportLines;

 --DBMS_OUTPUT.PUT('Delete Report Lines - ');
  DELETE FROM ap_expense_report_lines_all WHERE  report_header_id = P_ReportID;
  --DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
cnt3:=cnt3+SQL%ROWCOUNT;
  AP_WEB_NOTES_PKG.DeleteERNotes (
    p_src_report_header_id       => P_ReportID
  );

  fnd_attached_documents2_pkg.delete_attachments(
    X_entity_name => 'OIE_HEADER_ATTACHMENTS',
    X_pk1_value => P_ReportID,
    X_delete_document_flag => 'Y'
  );
  
 -- DBMS_OUTPUT.PUT('Delete Report - ');
  DELETE FROM APPS.ap_expense_report_headers_all WHERE  report_header_id = P_ReportID;
 -- DBMS_OUTPUT.PUT_LINE('Num Of Reports deleted:-'||SQL%ROWCOUNT);
  
  --DBMS_OUTPUT.PUT_LINE('Stop and purge all workflows');
  begin
	select   end_date
	into     l_end_date
	from     apps.wf_items
	where    item_type = 'APEXP'
	and      item_key  = to_char(P_ReportID);
	if l_end_date is NULL then
		l_wf_active := TRUE;
	else
		l_wf_active := FALSE;
	end if;
	l_wf_exist  := TRUE;
  exception
	when no_data_found then
		l_wf_active := FALSE;
		l_wf_exist  := FALSE;
  end;
  IF l_wf_exist THEN
	IF l_wf_active THEN
		wf_engine.AbortProcess (itemtype => 'APEXP',
				itemkey  => to_char(P_ReportID),
				cascade  => TRUE);
	END IF;

	begin
	  l_childItemKeySeq := WF_ENGINE.GetItemAttrNumber('APEXP',
					 P_ReportID,
					 'AME_CHILD_ITEM_KEY_SEQ');
	exception
	  when others then
	     if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
		l_childItemKeySeq := 0;
	     else
		raise;
	     end if;
	end;

	IF (l_childItemKeySeq IS NOT NULL AND l_childItemKeySeq > 0) THEN
		FOR i in 1 .. l_childItemKeySeq LOOP
			l_child_item_key := to_char(P_ReportID) || '-' || to_char(i);
			begin
				select   end_date
				into     l_end_date
				from     apps.wf_items
				where    item_type = 'APEXP'
				and      item_key  = l_child_item_key;
				if l_end_date is NULL then
					l_wf_active := TRUE;
				else
					l_wf_active := FALSE;
				end if;
				l_wf_exist  := TRUE;
			exception
				when no_data_found then
					l_wf_active := FALSE;
					l_wf_exist  := FALSE;
			end;
			IF (l_wf_exist) THEN
				IF l_wf_active THEN
					wf_engine.AbortProcess (itemtype => 'APEXP',
							itemkey  => l_child_item_key,
							cascade  => TRUE);
				END IF;
				wf_purge.Items(itemtype => 'APEXP',
					itemkey  => l_child_item_key);

				wf_purge.TotalPerm(itemtype => 'APEXP',
					itemkey  => l_child_item_key,
					runtimeonly => TRUE);
			END IF;
		END LOOP;
	END IF;

	wf_purge.Items(itemtype => 'APEXP',
			itemkey  => to_char(P_ReportID));

	wf_purge.TotalPerm(itemtype => 'APEXP',
			itemkey  => to_char(P_ReportID),
			runtimeonly => TRUE);
END IF;


--DBMS_OUTPUT.PUT_LINE('Done Deleting Report ' || P_ReportID);

END LOOP; -- END OF FOR LOOP ADDED FOR TASK1457090 

COMMIT;
FND_FILE.PUT_LINE(fnd_file.output,'Number of Reports Deleted:- '||cnt);


--DBMS_OUTPUT.PUT_LINE('Number of Reports Deleted:- '||cnt);
--DBMS_OUTPUT.PUT_LINE('Num of Deleted Distributions - '||cnt3);
--DBMS_OUTPUT.PUT_LINE('Num of Deleted Distributions - '||cnt1);
EXCEPTION
  WHEN OTHERS THEN
 Dbms_Output.put_line(SQLERRM);
FND_FILE.PUT_LINE(FND_FILE.LOG,  'Error from main procedure - '
                            || SQLCODE
                            || '-'
                            || SQLERRM
                           );

END;
/
 /************************************************************************************
        Program Name: TTEC_DISABLE_SUPPLIER.sql

        Description:   

        Developed by : 
        Date         :  

       Modification Log
       Name                  Version #    Date            Description
       -----                 --------     -----           -------------
    -- | NXGARIKAPATI(ARGANO)  1.0   21-JULY-2023      R12.2 Upgrade Remediation            |
    ****************************************************************************************/
DECLARE
  p_api_version          NUMBER;
  p_init_msg_list        VARCHAR2(200);
  p_commit               VARCHAR2(200);
  p_validation_level     NUMBER;
  x_return_status        VARCHAR2(200);
  x_msg_count            NUMBER;
  x_msg_data             VARCHAR2(200);
  lr_vendor_rec          apps.ap_vendor_pub_pkg.r_vendor_rec_type;
  lr_existing_vendor_rec ap_suppliers%ROWTYPE;
  l_msg                  VARCHAR2(200);
  p_vendor_id            NUMBER;
  l_vendor_id            NUMBER;
  l_exists               NUMBER;
  l_deactivate_flag      VARCHAR2(1);

  Cursor de_supp    
  IS 
  --Select * from CUST.TTEC_DEACTIVE_SUPPLIER	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
  Select * from APPS.TTEC_DEACTIVE_SUPPLIER		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
  where status Is NULL;
  -- and rownum < 5;    

BEGIN
 
  -- Initialize apps session
  fnd_global.apps_initialize(1234, 50833, 200);
  mo_global.init('SQLAP');
  fnd_client_info.set_org_context(101);
 
  -- Assign Basic Values
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_true;
  p_commit           := fnd_api.g_true;
  p_validation_level := fnd_api.g_valid_level_full;
  --  p_vendor_id        := 21387;


    BEGIN
    --START R12.2 Upgrade Remediation    
    /*delete from CUST.TTEC_DEACTIVE_SUPPLIER;
    commit;
        
    insert into CUST.TTEC_DEACTIVE_SUPPLIER ( SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER )
    -- Values ( SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER ) 
    select SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER  from CUST.TTEC_DEACTIVE_SUPPLIER_EXT;*/
	delete from apps.TTEC_DEACTIVE_SUPPLIER;
    commit;
        
    insert into apps.TTEC_DEACTIVE_SUPPLIER ( SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER )
    -- Values ( SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER ) 
    select SUPP_NUMBER , SUPP_NAME , LAST_INV_DATE , LAST_INV_LEDGER  from apps.TTEC_DEACTIVE_SUPPLIER_EXT;
	--End R12.2 Upgrade Remediation
    commit; 
        fnd_file.put_line(fnd_file.log,' Data Loaded from EXT table to Temp table '|| sqlerrm);

    EXCEPTION WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,' Data NOT Loaded from EXT table to Temp table '|| sqlerrm);
    
    END;


    FOR  de_supp_rec IN de_supp
    LOOP

      l_deactivate_flag := NULL;
      l_vendor_id       := NULL;    
      -- gather vendor details
      BEGIN
        SELECT vendor_id
          INTO l_vendor_id
          FROM ap_suppliers
         WHERE segment1 = de_supp_rec.supp_number
         and enabled_flag = 'Y';         
      EXCEPTION WHEN OTHERS THEN
          --DBMS_OUTPUT.put_line('Unable to derive the supplier  information for vendor id:' ||  p_vendor_id);
           fnd_file.put_line(fnd_file.log,' Unable to derive the supplier  information for vendor id '|| de_supp_rec.supp_number );

	    NULL;
      END;

    IF l_vendor_id IS NOT NULL
    THEN
     
         -- check if the vendor Exists as a Supplier Or not.
        --         l_exists := NULL;     
        --         Select count(*) 
        --         into   l_exists
        --         from   apps.per_all_people_f 
        --         where  full_name like de_supp_rec.SUPP_FNAME
        --         and    sysdate between effective_start_date and effective_end_date;  


        --         if l_exists = 0 then
        --              DBMS_OUTPUT.put_line('The Vendor is Still active :' || de_supp_rec.SUPP_FNAME );
        --            l_deactivate_flag := 'N';
        --         else
        --            l_deactivate_flag := 'Y';
        --         end if; 

        --IF  l_deactivate_flag = 'Y'
        --THEN                 
          --Deactivate Vendor
          lr_vendor_rec.vendor_id       := l_vendor_id; -- lr_existing_vendor_rec.vendor_id;
          lr_vendor_rec.end_date_active := SYSDATE;
          lr_vendor_rec.enabled_flag    := 'N';
         
          ap_vendor_pub_pkg.update_vendor(p_api_version      => p_api_version,
                                          p_init_msg_list    => p_init_msg_list,
                                          p_commit           => p_commit,
                                          p_validation_level => p_validation_level,
                                          x_return_status    => x_return_status,
                                          x_msg_count        => x_msg_count,
                                          x_msg_data         => x_msg_data,
                                          p_vendor_rec       => lr_vendor_rec,
                                          p_vendor_id        => l_vendor_id); --p_vendor_id);
                                         
          --DBMS_OUTPUT.put_line('X_RETURN_STATUS = ' || x_return_status);
          --DBMS_OUTPUT.put_line('X_MSG_COUNT = ' || x_msg_count);
          --DBMS_OUTPUT.put_line('X_MSG_DATA = ' || x_msg_data);
		 -- fnd_file.put_line(fnd_file.log 'After API call. The x_return_status is:' || x_return_status || '  for Ven ID: ' || p_vendor_id);
         fnd_file.put_line(fnd_file.log,'After API call. The x_return_status is: '|| x_return_status || ' for Vendor: ' || de_supp_rec.supp_number );

		  
          IF (x_return_status <> fnd_api.g_ret_sts_success) THEN
            FOR i IN 1 .. fnd_msg_pub.count_msg 
            LOOP
              l_msg := fnd_msg_pub.get(p_msg_index => i,
                                       p_encoded   => fnd_api.g_false);
              --DBMS_OUTPUT.put_line('The API call failed with error ' || l_msg);
            END LOOP;
            
            --update CUST.TTEC_DEACTIVE_SUPPLIER	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			update apps.TTEC_DEACTIVE_SUPPLIER	-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
            set     status = 'FAIL'
            , error_message = l_msg 
            where  supp_number =  de_supp_rec.supp_number;
			
          ELSE
            -- DBMS_OUTPUT.put_line('The API call ended with SUCESSS status');

            --update CUST.TTEC_DEACTIVE_SUPPLIER	-- Commented code by NXGARIKAPATI-ARGANO, 21/07/2023 
			update apps.TTEC_DEACTIVE_SUPPLIER		-- Added code by NXGARIKAPATI-ARGANO, 21/07/2023 
            set     status = 'SUCCESS'
            where  supp_number =  de_supp_rec.supp_number;

          END IF;
          commit;
        --END IF;    -- l_deactivate_flag = 'Y' 
          

    END IF; -- Vendor_id is NOT NULL 
        

    END LOOP;
    
END;
/

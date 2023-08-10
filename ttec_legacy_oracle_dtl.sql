/* $Header: ttec_legacy_oracle_dtl.sql 2.0 2011/12/16 mdodge ship $ */

/*== START ================================================================================================*\
  Author:  Elango Pandu
    Date:  02-MAR-2006
    Desc:  This program displays legacy id,unique id,employee number,name,location and creation date

  Input Parameters  : business group id
  Procedures Called : Teletech Legacy Oracle Details

  Modification History:

  Mod#    Date     Author   Description (Include Ticket#)
 -----  --------  --------  --------------------------------------------------------------------------------
   1.0  02/03/06  EPandu    Initial Version
   1.1  24/03/06  EPandu    As per Sumana, removing unique id
   1.2  25/05/06  CChan     WO#193889 - Change to make this look for only active employees
   1.3  19/06/06  EPandu    Added the supervisor information and SMTP Server name
   2.0  16/12/11  MDodge    R12 Retrofit: Removed SUBSTR on HOST_NAME to allow to work in R12 environments
   2.1  21/08/15 Lalitha   rehosting changes for smtp
   
\*== END ==================================================================================================*/

DECLARE
  p_business_group_id   NUMBER;
  p_creation_date       DATE;
  p_creation            VARCHAR2( 20 );
  file_handle           UTL_FILE.file_type;
  p_status              NUMBER;
  w_mesg                VARCHAR2( 100 );

  v_type                VARCHAR2( 100 );
  v_code                VARCHAR2( 100 );
  v_smtp                VARCHAR2( 100 );
  v_sup_number          VARCHAR2( 30 );
  v_sup_name            VARCHAR2( 250 );

  v_from_email          VARCHAR2( 500 );
  v_to_email            VARCHAR2( 500 );
  v_cc_email            VARCHAR2( 500 ) := NULL;
  v_file_name           VARCHAR2( 500 );
  v_meaning             VARCHAR2( 50 );

  CURSOR c_emp_dtl IS
      SELECT a.attribute6
           , a.attribute12
           , a.employee_number
           , a.full_name
           , c.description
           , a.creation_date
           , supervisor_id
        FROM apps.per_all_people_f a, apps.per_all_assignments_f b, hr.hr_locations_all c
       WHERE a.person_id = b.person_id
         AND b.location_id = c.location_id
         AND a.current_employee_flag = 'Y'
         AND b.primary_flag = 'Y'
         AND TRUNC( SYSDATE ) BETWEEN a.effective_start_date AND a.effective_end_date
         AND TRUNC( SYSDATE ) BETWEEN b.effective_start_date AND b.effective_end_date
         AND a.business_group_id = p_business_group_id
    ORDER BY a.creation_date;

  CURSOR c_lookup( p_type VARCHAR2, p_code VARCHAR2 ) IS
    SELECT meaning, description
      FROM fnd_lookup_values_vl
     WHERE UPPER( lookup_type ) = UPPER( p_type )
       AND UPPER( lookup_code ) = UPPER( p_code )
       AND enabled_flag = 'Y';

  CURSOR c_super( super_id NUMBER ) IS
    SELECT employee_number, full_name
      FROM per_all_people_f
     WHERE person_id = super_id
       AND TRUNC( SYSDATE ) BETWEEN effective_start_date AND effective_end_date;
BEGIN

  p_business_group_id   := '&1';

  IF p_business_group_id = 2311 THEN
    v_type        := 'TTEC_NZ_EMAIL_LOG';
    file_handle   := UTL_FILE.fopen( '/usr/tmp', 'legacy_dtl_nz.txt', 'W' );
    v_file_name   := '/usr/tmp/legacy_dtl_nz.txt';
  ELSIF p_business_group_id = 2327 THEN
    v_type        := 'TTEC_SGP_EMAIL_LOG';
    file_handle   := UTL_FILE.fopen( '/usr/tmp', 'legacy_dtl_sgp.txt', 'W' );
    v_file_name   := '/usr/tmp/legacy_dtl_sgp.txt';
  ELSIF p_business_group_id = 2328 THEN
    v_type        := 'TTEC_MAL_EMAIL_LOG';
    file_handle   := UTL_FILE.fopen( '/usr/tmp', 'legacy_dtl_mal.txt', 'W' );
    v_file_name   := '/usr/tmp/legacy_dtl_mal.txt';
  ELSIF p_business_group_id = 2287 THEN
    v_type        := 'TTEC_HKG_EMAIL_LOG';
    file_handle   := UTL_FILE.fopen( '/usr/tmp', 'legacy_dtl_hkg.txt', 'W' );
    v_file_name   := '/usr/tmp/legacy_dtl_hkg.txt';
  END IF;


  UTL_FILE.put_line( file_handle, 'Teletech Legacy and Oracle Details' );

  UTL_FILE.put_line( file_handle
                   , 'Legacy id|Oracle Employee Number|Oracle Full Name|Location|Creation Date|Supervisor Number|Supervisor Name' );


  FOR v_emp IN c_emp_dtl LOOP

    v_sup_number   := NULL;
    v_sup_name     := NULL;

    OPEN c_super( v_emp.supervisor_id );

    FETCH c_super
    INTO v_sup_number, v_sup_name;

    CLOSE c_super;

    UTL_FILE.put_line( file_handle
                     , v_emp.attribute12
                       || '|'
                       || v_emp.employee_number
                       || '|'
                       || v_emp.full_name
                       || '|'
                       || v_emp.description
                       || '|'
                       || v_emp.creation_date
                       || '|'
                       || v_sup_number
                       || '|'
                       || v_sup_name );

  END LOOP;

  UTL_FILE.fclose( file_handle );

  IF p_business_group_id IN (2311, 2327, 2328, 2287) THEN

    OPEN c_lookup( v_type, 'CC' );
    FETCH c_lookup
    INTO v_meaning, v_cc_email;
    CLOSE c_lookup;

    OPEN c_lookup( v_type, 'FROM' );
    FETCH c_lookup
    INTO v_meaning, v_from_email;
    CLOSE c_lookup;

    OPEN c_lookup( v_type, 'TO' );
    FETCH c_lookup
    INTO v_meaning, v_to_email;
    CLOSE c_lookup;

    -- 2.0  Removed SUBSTR so that will work in environments with longer SMTP name
    SELECT host_name      --SUBSTR(HOST_NAME,1,10)
      INTO v_smtp 
      FROM v$instance;

    fnd_file.put_line( fnd_file.output
                     , 'SMTP IS'
                       || v_smtp
                       || ' MEANING '
                       || v_meaning
                       || ' FROM '
                       || v_from_email
                       || 'TO '
                       || v_to_email
                       || ' cc '
                       || v_cc_email );

    BEGIN

      send_email( --v_smtp
	   ttec_library.XX_TTEC_SMTP_SERVER /* 2.1 rehosting changes for smtp */

                , v_from_email
                , v_to_email
                , v_cc_email
                , NULL
                , 'TeleTech Legacy and Oracle ID Details'
                , 'Attached is the output of our Scheduled Report TeleTech Oracle ID and Legacy Id Details'
                , NULL
                , NULL
                , NULL
                , NULL
                , v_file_name
                , NULL
                , NULL
                , NULL
                , NULL
                , p_status
                , w_mesg );

      IF p_status <> 0 THEN
        DBMS_OUTPUT.put_line( 'Error in Send mail' );
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line( 'Exception in sendmail' || SUBSTR( SQLERRM, 1, 50 ) );
    END;

  END IF;                                                                                    -- All businee group end if

EXCEPTION
  WHEN OTHERS THEN
    UTL_FILE.fclose( file_handle );
END;
/
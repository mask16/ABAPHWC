*&---------------------------------------------------------------------*
*&  Include           ZCOI_COMMON_01
*&---------------------------------------------------------------------*

TYPE-POOLS: ABAP.

* -- Setting Range Variables--
DEFINE _SET_RANGES.
  &2-SIGN   = &3.
  &2-OPTION = &4.
  &2-LOW    = &5.
  &2-HIGH   = &6.
  APPEND &2 TO &1.
END-OF-DEFINITION.


* -- Constants --------------------------------------------------------
CONSTANTS:  C_X(1)  VALUE 'X',
            C_S(1)  VALUE ' ',
            C_ABAP_TRUE(1) TYPE C VALUE 'X',

            C_KOKRS_1000    TYPE KOKRS VALUE '1000',

            C_WAERS_KRW     TYPE WAERS VALUE 'KRW',
            C_WAERS_USD     TYPE WAERS VALUE 'USD',

            C_PLPROF        TYPE KPP_PLPROF VALUE 'ZSAPALL'.

CONSTANTS:  C_FIELD_COSTELEMGROUP TYPE TABNAME VALUE 'COSTELEMENTGROUP',
            C_ZMOD_CO       TYPE ZMOD VALUE 'CO',
            C_ZMOD_SD       TYPE ZMOD VALUE 'SD'.

* -- Inner Table -----------------------------------------------------


*----------------------------------------------------------------------*
* BDC Processing data ...
*----------------------------------------------------------------------*
DATA: BDCDATA LIKE TABLE OF BDCDATA WITH HEADER LINE,
      MSGDATA LIKE TABLE OF BDCMSGCOLL WITH HEADER LINE.

*&---------------------------------------------------------------------*
*&      Form  bdc_dynpro
*&---------------------------------------------------------------------*
FORM BDC_DYNPRO USING P_DYNBEGIN P_NAME P_VALUE.
  CLEAR BDCDATA.
  IF P_DYNBEGIN EQ 'X'.
    MOVE: P_NAME  TO BDCDATA-PROGRAM,
          P_VALUE TO BDCDATA-DYNPRO,
          'X'     TO BDCDATA-DYNBEGIN.
    APPEND BDCDATA.
  ELSE.
    MOVE: P_NAME  TO BDCDATA-FNAM,
          P_VALUE TO BDCDATA-FVAL.
    APPEND BDCDATA.
  ENDIF.
ENDFORM.                    "bdc_dynpro

*&---------------------------------------------------------------------*
*&      Form  open_group
*&---------------------------------------------------------------------*
FORM OPEN_GROUP USING P_GROUP P_USER P_QID.
  DATA: L_QID TYPE APQ_QUID.
  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      CLIENT = SY-MANDT
      GROUP  = P_GROUP
      USER   = P_USER
      KEEP   = 'X'
    IMPORTING
      QID    = L_QID.
  P_QID = L_QID.
ENDFORM.                    "open_group

*&---------------------------------------------------------------------*
*&      Form  close_group
*&---------------------------------------------------------------------*
FORM CLOSE_GROUP.
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
ENDFORM.                    "close_group

*&---------------------------------------------------------------------*
*&      Form  bdc_insert
*&---------------------------------------------------------------------*
FORM BDC_INSERT USING P_TCODE.
  CALL FUNCTION 'BDC_INSERT'
    EXPORTING
      TCODE     = P_TCODE
*     ctuparams = ps_option
    TABLES
      DYNPROTAB = BDCDATA.
ENDFORM.                    "bdc_insert

*&---------------------------------------------------------------------*
*&      Form  call_transaction
*&---------------------------------------------------------------------*
FORM CALL_TRANSACTION USING P_TCODE P_MODE.
  CLEAR: MSGDATA, MSGDATA[].
  DATA: LS_DEF  LIKE CTU_PARAMS.

  LS_DEF-DISMODE  = P_MODE.
  LS_DEF-UPDMODE  = 'S'.
  LS_DEF-CATTMODE = ' '.
  LS_DEF-DEFSIZE  = 'X'.
  LS_DEF-RACOMMIT = ' '.
  LS_DEF-NOBINPT  = 'X'.
  LS_DEF-NOBIEND  = 'X'.

  CALL TRANSACTION P_TCODE
             USING BDCDATA
              MODE P_MODE
          MESSAGES INTO MSGDATA.
ENDFORM.                    "call_transaction


*&---------------------------------------------------------------------*
*&      Form  build_fieldcatalog
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCATALOG TABLES PT_FIELDCAT TYPE LVC_T_FCAT
                          USING PS_FIELDCAT TYPE LVC_S_FCAT
                                P_GUB
                                P_FNAME
                                P_VALUE.
  DATA: L_NAME(40).
  FIELD-SYMBOLS: <FS> TYPE ANY.

  IF P_GUB EQ 'S'.
    CLEAR PS_FIELDCAT.
  ENDIF.

  CONCATENATE 'PS_FIELDCAT-' P_FNAME INTO L_NAME.
  ASSIGN (L_NAME) TO <FS>.
  <FS> = P_VALUE.

  IF P_GUB EQ 'E'.
    APPEND PS_FIELDCAT TO PT_FIELDCAT.
  ENDIF.
ENDFORM.                    "build_fieldcatalog

*&---------------------------------------------------------------------*
*&      Form  template_table_download
*&---------------------------------------------------------------------*
*       Any other Excel Template by Header, Data...
*----------------------------------------------------------------------*
FORM TEMPLATE_TABLE_DOWNLOAD TABLES PT_HEAD TYPE STANDARD TABLE
                                     PT_DATA TYPE STANDARD TABLE
                              USING P_TITLE.

  DATA: DYN_HEAD    TYPE REF TO DATA,
        DYN_DATA    TYPE REF TO DATA.

  DATA: L_PATH      TYPE STRING,
        L_DFNAME    TYPE LOCALFILE VALUE 'C:\',
        L_FILENAME  TYPE STRING.

  FIELD-SYMBOLS: <DYN_HEAD> TYPE STANDARD TABLE,
                 <DYN_DATA> TYPE STANDARD TABLE.

  CREATE DATA: DYN_HEAD LIKE TABLE OF PT_HEAD,
               DYN_DATA LIKE TABLE OF PT_DATA.
  ASSIGN: DYN_HEAD->* TO <DYN_HEAD>,
          DYN_DATA->* TO <DYN_DATA>.

  <DYN_HEAD>[] = PT_HEAD[].
  <DYN_DATA>[] = PT_DATA[].

  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      PROGRAM_NAME  = SY-REPID
      DYNPRO_NUMBER = SY-DYNNR
    IMPORTING
      FILE_NAME     = L_DFNAME.

  MOVE L_DFNAME TO L_FILENAME.
  IF L_FILENAME IS INITIAL OR
    L_FILENAME EQ 'C:\'.
    MESSAGE 'Check File Path & File Name.' TYPE 'I'.
    STOP.
  ENDIF.


*  Donwload ----------------------------------------------------
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME                = L_FILENAME
      FILETYPE                = 'ASC'
      WRITE_FIELD_SEPARATOR   = 'X'
    TABLES
      DATA_TAB                = <DYN_DATA>
      FIELDNAMES              = <DYN_HEAD>
    EXCEPTIONS
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      OTHERS                  = 22.
*
  IF SY-SUBRC <> 0.
    MESSAGE 'Excel Template Download Error' TYPE 'I'.
    STOP.
  ENDIF.

ENDFORM.                    "template_table_download

*&---------------------------------------------------------------------*
*&      Form  call_confirm_msg
*&---------------------------------------------------------------------*
*       Confrim Popup Dialog Window ..
*----------------------------------------------------------------------*
FORM CALL_CONFIRM_MSG  USING    P_TEXT
                                P_FLAG
                       CHANGING P_ANSWER.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR      = P_TEXT
      TEXT_QUESTION = 'Click Cancel to Exit'
      TEXT_BUTTON_1 = 'YES'
*     icon_button_1 = 'ICON_CHECKED'
      TEXT_BUTTON_2 = 'NO'
*     icon_button_2 = 'ICON_CANCEL'
*     popup_type    = 'ICON_MESSAGE_ERROR'
    IMPORTING
      ANSWER        = P_ANSWER.
  " '1' -> OK, '2' -> Cancel, 'A' -> Abort ..

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    "call_confirm_msg

*&---------------------------------------------------------------------*
*&      Form  get_message_build
*&---------------------------------------------------------------------*
FORM GET_MESSAGE_BUILD USING  P_MSGID P_MSGNO P_MSGV1 P_MSGV2
                              P_MSGV3 P_MSGV4 P_MESSAGE.
  CALL FUNCTION 'MESSAGE_TEXT_BUILD'
    EXPORTING
      MSGID               = P_MSGID
      MSGNR               = P_MSGNO
      MSGV1               = P_MSGV1
      MSGV2               = P_MSGV2
      MSGV3               = P_MSGV3
      MSGV4               = P_MSGV4
    IMPORTING
      MESSAGE_TEXT_OUTPUT = P_MESSAGE.
ENDFORM.                    "get_message_build


*&---------------------------------------------------------------------*
*&      Form  conversion_alpah_input
*&---------------------------------------------------------------------*
FORM CONVERSION_ALPHA_INPUT CHANGING P_INPUT.
  CHECK P_INPUT IS NOT INITIAL.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      INPUT  = P_INPUT
    IMPORTING
      OUTPUT = P_INPUT.
ENDFORM.                    "conversion_alpah_input

*&---------------------------------------------------------------------*
*&      Form  conversion_alpha_output
*&---------------------------------------------------------------------*
FORM CONVERSION_ALPHA_OUTPUT CHANGING P_OUTPUT.
  CHECK P_OUTPUT IS NOT INITIAL.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      INPUT  = P_OUTPUT
    IMPORTING
      OUTPUT = P_OUTPUT.
ENDFORM.                    "conversion_alpha_output

*&---------------------------------------------------------------------*
*&      Form  change_alpha_varialbe
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_INPUT    text
*      -->P_OUTPUT   text
*      -->ENDFORM    text
*----------------------------------------------------------------------*
FORM CHANGE_ALPHA_VARIALBE USING P_INPUT CHANGING P_OUTPUT.
  CHECK P_INPUT IS NOT INITIAL.

  DATA: L_STRING TYPE STRING.
  MOVE P_INPUT TO L_STRING.
  PERFORM CONVERSION_ALPHA_OUTPUT CHANGING L_STRING.
  MOVE L_STRING TO P_OUTPUT.
  PERFORM CONVERSION_ALPHA_INPUT CHANGING P_OUTPUT.
ENDFORM.                    "change_alpha_varialbe
*&---------------------------------------------------------------------*
*&      Form  currency_sap_to_display
*&---------------------------------------------------------------------*
FORM CURRENCY_SAP_TO_DISPLAY USING P_WAERS CHANGING P_AMOUNT.
  DATA: L_FACTOR TYPE P DECIMALS 3.

  CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
    EXPORTING
      CURRENCY          = P_WAERS
    IMPORTING
      FACTOR            = L_FACTOR
    EXCEPTIONS
      TOO_MANY_DECIMALS = 1
      OTHERS            = 2.

  IF SY-SUBRC <> 0.
    EXIT.
  ENDIF.

  P_AMOUNT = P_AMOUNT * L_FACTOR.
ENDFORM.                    "currency_sap_to_display

*&---------------------------------------------------------------------*
*&      Form  currency_display_to_dap
*&---------------------------------------------------------------------*
FORM CURRENCY_DISPLAY_TO_SAP USING P_WAERS CHANGING P_AMOUNT.
  DATA: L_FACTOR TYPE P DECIMALS 3.

  CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
    EXPORTING
      CURRENCY          = P_WAERS
    IMPORTING
      FACTOR            = L_FACTOR
    EXCEPTIONS
      TOO_MANY_DECIMALS = 1
      OTHERS            = 2.

  IF SY-SUBRC <> 0.
    EXIT.
  ENDIF.

  P_AMOUNT = P_AMOUNT / L_FACTOR.
ENDFORM.                    "currency_display_to_dap

*&---------------------------------------------------------------------*
*&      Form  get_money_char
*&---------------------------------------------------------------------*
FORM GET_MONEY_CHAR USING P_AMOUNT P_C_AMOUNT P_WAERS.
  DATA: L_CHAR(30),
*        L_AMOUNT TYPE I,
        L_AMOUNT(15) TYPE P DECIMALS 0,
        L_MINUS(1).

  CLEAR P_C_AMOUNT.

  CASE P_WAERS.
    WHEN 'KRW' OR 'VND' OR 'JPY'.

      MOVE: P_AMOUNT TO L_AMOUNT,
            L_AMOUNT TO L_CHAR.
      CONDENSE L_CHAR.

      IF L_AMOUNT < 0.
        SHIFT L_CHAR UP TO '-' LEFT CIRCULAR.
      ENDIF.

    WHEN OTHERS.

      MOVE: P_AMOUNT TO L_AMOUNT,
            P_AMOUNT TO L_CHAR.
      CONDENSE L_CHAR.
*      MOVE: L_AMOUNT TO L_CHAR.

      IF P_AMOUNT < 0.
        SHIFT L_CHAR UP TO '-' LEFT CIRCULAR.
      ENDIF.

  ENDCASE.

  CONDENSE L_CHAR NO-GAPS.
  MOVE L_CHAR TO P_C_AMOUNT.

  IF P_WAERS IS INITIAL AND P_AMOUNT = 0.
    L_CHAR = 0.
    CONDENSE L_CHAR NO-GAPS.
    MOVE L_CHAR TO P_C_AMOUNT.
  ENDIF.

ENDFORM.                    "currency_display_to_sap

*&---------------------------------------------------------------------*
*&      Form  get_char_by_decimal
*&---------------------------------------------------------------------*
FORM GET_CHAR_BY_DECIMAL USING P_DECIMAL P_VALUE.

ENDFORM.                    "get_char_by_decimal

*&---------------------------------------------------------------------*
*&      Form  GET_FILENAME
*&---------------------------------------------------------------------*
FORM GET_FILENAME  CHANGING P_FILE.
  DATA: LT_FILES  TYPE FILETABLE,
        LS_FILE   TYPE FILE_TABLE,
        L_TITLE   TYPE STRING,
        L_SUBRC   TYPE SYSUBRC.

  L_TITLE = 'File Open'.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      WINDOW_TITLE            = L_TITLE
    CHANGING
      FILE_TABLE              = LT_FILES
      RC                      = L_SUBRC
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      OTHERS                  = 4.

  CHECK SY-SUBRC EQ 0.
  READ TABLE LT_FILES INTO LS_FILE INDEX 1.
  P_FILE = LS_FILE.

ENDFORM.                    " GET_FILENAME

*&---------------------------------------------------------------------*
*&      Form  get_components_fields
*&---------------------------------------------------------------------*
FORM GET_COMPONENT_FIELDS TABLES PT_FIELDS TYPE ABAP_COMPDESCR_TAB
                            USING P_STRUCT_NAME.

  DATA: LK_STRUCTDESCR TYPE REF TO CL_ABAP_STRUCTDESCR,
        LS_COMPDESCR   TYPE ABAP_COMPDESCR,
        LK_ROOT        TYPE REF TO CX_ROOT,
        MSG            TYPE STRING.

  FIELD-SYMBOLS: <FS>.

  TRY.
      ASSIGN (P_STRUCT_NAME) TO <FS>.

      LK_STRUCTDESCR ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( <FS> ).
      PT_FIELDS[] = LK_STRUCTDESCR->COMPONENTS.
    CATCH CX_ROOT INTO LK_ROOT.
      MESSAGE LK_ROOT TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.                    "get_components_fields

*&---------------------------------------------------------------------*
*&      Form  get_component_fields_name
*&---------------------------------------------------------------------*
FORM GET_COMPONENT_FIELDS_NAME TABLES PT_FIELDS TYPE TIHTTPNVP
                                USING P_STRUCT_NAME.
  DATA: LT_DATA TYPE TIHTTPNVP,
        LS_DATA TYPE IHTTPNVP.

  DATA: LT_DD03L TYPE TABLE OF DD03L,
        LS_DD03L TYPE DD03L.

  CLEAR: LT_DATA[].
  SELECT  A~FIELDNAME AS NAME
          B~DDTEXT    AS VALUE
    INTO TABLE LT_DATA
    FROM DD03L AS A INNER JOIN DD04T AS B
                    ON A~ROLLNAME = B~ROLLNAME
                    AND B~DDLANGUAGE = SY-LANGU
                    AND B~AS4LOCAL = 'A'
   WHERE A~TABNAME = P_STRUCT_NAME
     AND A~AS4LOCAL = 'A'
   ORDER BY A~POSITION.

  PT_FIELDS[] = LT_DATA[].
ENDFORM.                    "get_component_fields_name

*&---------------------------------------------------------------------*
*&      Form  get_domain_values
*&---------------------------------------------------------------------*
FORM GET_DOMAIN_VALUES TABLES PT_VALUES TYPE TIHTTPNVP
                        USING P_DOMAIN.
  DATA: L_DOMNAME TYPE DOMNAME,
        LT_DD07T TYPE TABLE OF DD07T,
        LS_DD07T TYPE DD07T.
  L_DOMNAME = P_DOMAIN.

  SELECT  DOMVALUE_L  AS NAME
          DDTEXT      AS VALUE
    INTO TABLE PT_VALUES
    FROM DD07T
   WHERE DOMNAME    = L_DOMNAME
     AND DDLANGUAGE = SY-LANGU.
ENDFORM.                    "get_domain_values

*&---------------------------------------------------------------------*
*&      Form  get_selected_rows_from_grid
*&---------------------------------------------------------------------*
FORM GET_SELECTED_ROWS_FROM_GRID TABLES PT_ROWS TYPE LVC_T_ROW
                               USING P_GRID TYPE REF TO CL_GUI_ALV_GRID.
  DATA: LT_ROWS TYPE LVC_T_ROW.
  CALL METHOD P_GRID->GET_SELECTED_ROWS
    IMPORTING
      ET_INDEX_ROWS = LT_ROWS.

  PT_ROWS[] = LT_ROWS[].
ENDFORM.                    "get_selected_rows_from_grid

*&---------------------------------------------------------------------*
*&      Form  PREV_SETTING_FOR_BDC
*&---------------------------------------------------------------------*
FORM PREV_SETTING_FOR_BDC  USING    P_PLPROF
                                    P_KOKRS.

  DATA: L_TCODE_KP04 TYPE TCODE VALUE 'KP04',
        L_TCODE_OKKS TYPE TCODE VALUE 'OKKS',
        L_MODE(1) VALUE 'N'.

* KP04 -> Profile Setting -------------------------------
  CLEAR: BDCDATA[], BDCDATA, MSGDATA[], MSGDATA.
  PERFORM BDC_DYNPRO USING:
      'X' 'SAPLKPP6'  '1007',
      ' ' 'BDC_OKCODE'    '=CWEI',
      ' ' 'RKPP6-PLPROF'  P_PLPROF.

  CALL TRANSACTION L_TCODE_KP04
             USING BDCDATA
              MODE L_MODE
          MESSAGES INTO MSGDATA.
* -------------------------------------------------------

* OKKS -> Controlling Area Setting by BDC ---------------
  CLEAR: BDCDATA[], BDCDATA, MSGDATA[], MSGDATA.
  PERFORM BDC_DYNPRO USING:
    'X'  'SAPLSPO4'	        '0300',
    ' '  'BDC_OKCODE'	      '=COD1',
    ' '  'SVALD-VALUE(01)'  P_KOKRS.

  CALL TRANSACTION L_TCODE_OKKS
             USING BDCDATA
              MODE L_MODE
          MESSAGES INTO MSGDATA.
* ----------------------------------------------------
ENDFORM.                    " PREV_SETTING_FOR_BDC

*&---------------------------------------------------------------------*
*&      Form  pre_setting_kebc_for_bdc
* 경영단위설정. - T-Code : KEBC.
*&---------------------------------------------------------------------*
FORM PRE_SETTING_KEBC_FOR_BDC USING P_KOKRS.
  DATA: L_TCODE_KEBC TYPE TCODE VALUE 'KEBC',
        L_MODE(1) VALUE 'N'.

  CLEAR: BDCDATA[], BDCDATA, MSGDATA[], MSGDATA.
  PERFORM BDC_DYNPRO USING:
        'X' 'SAPLKEA3'        '0200',
        ' ' 'BDC_OKCODE'      '=ENTE',
        ' ' 'RKEA2-ERKRS'	    P_KOKRS,
        ' ' 'RKEA2-PA_TYPE_1'	'X'.

  CALL TRANSACTION L_TCODE_KEBC
             USING BDCDATA
              MODE L_MODE
          MESSAGES INTO MSGDATA.
ENDFORM.                    "pre_setting_kebc_for_bdc

**&---------------------------------------------------------------------*
**&      Form  SHOW_FIELD_VALUE
**&---------------------------------------------------------------------*
*FORM show_field_value  USING    p_field
*                                p_flag
*                                p_kokrs.
*
*  DATA: l_field TYPE tabname,
*        l_kokrs TYPE kokrs,
*        lt_data TYPE tihttpnvp,
*        ls_data TYPE ihttpnvp.
*
*  DATA: ret_tab LIKE ddshretval OCCURS 0 WITH HEADER LINE.
*  FIELD-SYMBOLS: <fs>.
*
*  IF p_kokrs IS INITIAL. l_kokrs = c_kokrs_1000. ENDIF.
*
*  PERFORM init_new_values USING p_flag p_kokrs.
*  CASE p_flag.
*    WHEN c_field_costelemgroup. lt_data[] = gt_celemgrp[].
*  ENDCASE.
*
*  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*    EXPORTING
*      retfield   = 'NAME'
*      value_org  = 'S'
*    TABLES
*      value_tab  = lt_data
*      return_tab = ret_tab.
*
*  IF sy-subrc EQ 0.
*    MOVE p_field TO l_field.
*    TRANSLATE l_field TO UPPER CASE.
*    ASSIGN (l_field) TO <fs>.
*
*    READ TABLE ret_tab INDEX 1.
*    READ TABLE lt_data INTO ls_data WITH KEY name = ret_tab-fieldval.
*    MOVE: ls_data-name TO <fs>.
*  ENDIF.
*
*ENDFORM.                    " SHOW_FIELD_VALUE

**&---------------------------------------------------------------------*
**&      Form  INIT_NEW_VALUES
**&---------------------------------------------------------------------*
*FORM init_new_values  USING    p_flag p_kokrs.
*  CASE p_flag.
*    WHEN c_field_costelemgroup.
*      CLEAR: gt_celemgrp[].
*      SELECT  a~setname   AS name
*              b~descript  AS value
*        INTO TABLE gt_celemgrp
*        FROM setheader AS a INNER JOIN setheadert AS b
*                            ON  a~setclass = b~setclass
*                            AND a~subclass = b~subclass
*                            AND a~setname  = b~setname
*       WHERE a~setclass = '0102'
*         AND a~subclass = p_kokrs
*         AND a~xuniq    = 'X'.
*
*  ENDCASE.
*ENDFORM.                    " INIT_NEW_VALUES

*&---------------------------------------------------------------------*
*&      Form  CONVERSION_LEDBO_INPUT
*&---------------------------------------------------------------------*
FORM CONVERSION_LEDBO_INPUT  CHANGING P_PALEDGER.
  CHECK P_PALEDGER IS NOT INITIAL.
  CALL FUNCTION 'CONVERSION_EXIT_LEDBO_INPUT'
    EXPORTING
      INPUT  = P_PALEDGER
    IMPORTING
      OUTPUT = P_PALEDGER.
ENDFORM.                    " CONVERSION_LEDBO_INPUT

*&---------------------------------------------------------------------*
*&      Form  conversion_ledbo_output
*&---------------------------------------------------------------------*
FORM CONVERSION_LEDBO_OUTPUT CHANGING P_PALEDGER.
  CHECK P_PALEDGER IS NOT INITIAL.
  CALL FUNCTION 'CONVERSION_EXIT_LEDBO_OUTPUT'
    EXPORTING
      INPUT  = P_PALEDGER
    IMPORTING
      OUTPUT = P_PALEDGER.
ENDFORM.                    "conversion_ledbo_output

*&---------------------------------------------------------------------*
*&      Form  GET_MAKTX
*&---------------------------------------------------------------------*
FORM GET_MAKTX  TABLES   PT_ARTNRT TYPE TIHTTPNVP.
  SELECT  MATNR AS NAME
          MAKTX AS VALUE
    INTO TABLE PT_ARTNRT
    FROM MAKT
   WHERE SPRAS EQ SY-LANGU.
ENDFORM.                    " GET_MAKTX

*&---------------------------------------------------------------------*
*&      Form  GET_PAPH3T
*&---------------------------------------------------------------------*
FORM GET_PAPH3T  TABLES   PT_PAPH3T TYPE TIHTTPNVP.
  SELECT  A~PRODH AS NAME
          B~VTEXT AS VALUE
    INTO TABLE PT_PAPH3T
    FROM T179 AS A INNER JOIN T179T AS B ON A~PRODH = B~PRODH
   WHERE A~STUFE = '3'
     AND B~SPRAS = SY-LANGU.
ENDFORM.                    " GET_PAPH3T

*&---------------------------------------------------------------------*
*&      Form  GET_MVGR1T
*&---------------------------------------------------------------------*
FORM GET_MVGR1T  TABLES   PT_MVGR1T TYPE TIHTTPNVP.
  SELECT  MVGR1 AS NAME
          BEZEI AS VALUE
    INTO TABLE PT_MVGR1T
    FROM TVM1T
   WHERE SPRAS = SY-LANGU.
ENDFORM.                    " GET_MVGR1T

*&---------------------------------------------------------------------*
*&      Form  GET_MVGR2T
*&---------------------------------------------------------------------*
FORM GET_MVGR2T  TABLES   PT_MVGR2T TYPE TIHTTPNVP.
  SELECT  MVGR2 AS NAME
          BEZEI AS VALUE
    INTO TABLE PT_MVGR2T
    FROM TVM2T
   WHERE SPRAS = SY-LANGU.
ENDFORM.                    " GET_MVGR2T

*&---------------------------------------------------------------------*
*&      Form  GET_WERKST
*&---------------------------------------------------------------------*
FORM GET_WERKST  TABLES   PT_WERKST TYPE TIHTTPNVP.
  SELECT  WERKS AS NAME
          NAME1 AS VALUE
    INTO TABLE PT_WERKST
    FROM T001W.
ENDFORM.                    " GET_WERKST

*&---------------------------------------------------------------------*
*&      Form  GET_KNDNRT
*&---------------------------------------------------------------------*
FORM GET_KNDNRT  TABLES   PT_KNDNRT TYPE TIHTTPNVP.
  SELECT  KUNNR AS NAME
          NAME1 AS VALUE
    INTO TABLE PT_KNDNRT
    FROM KNA1.
ENDFORM.                    " GET_KNDNRT

*&---------------------------------------------------------------------*
*&      Form  GET_BZIRKT
*&---------------------------------------------------------------------*
FORM GET_BZIRKT  TABLES   PT_BZIRKT TYPE TIHTTPNVP.
  SELECT  BZIRK AS NAME
          BZTXT AS VALUE
    INTO TABLE PT_BZIRKT
    FROM T171T
   WHERE SPRAS = SY-LANGU.
ENDFORM.                    " GET_BZIRKT
*&---------------------------------------------------------------------*
*&      Form  GET_WARES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_KOKRS  text
*      -->P_GV_WAERS  text
*----------------------------------------------------------------------*
FORM GET_WARES  USING    P_KOKRS
                         P_WAERS.

  CLEAR P_WAERS.

  SELECT SINGLE WAERS INTO P_WAERS
    FROM TKA01
    WHERE KOKRS = P_KOKRS.

ENDFORM.                    " GET_WARES

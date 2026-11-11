*&---------------------------------------------------------------------*
*& PROGRAM     : ZCOR0011.
*& DESCRIPTION : 제품/자재 수불명세서 Program.
*& DEVELOPER   : Kim Hyun Pyo
*& CREATED DATE: 2012.10.15.
*&---------------------------------------------------------------------*
*& HISTORY     : [REF] ZCOR0511 .
*&
*&---------------------------------------------------------------------*

REPORT  zcor0011 MESSAGE-ID zcom.

INCLUDE     <icon>.
INCLUDE     <symbol>.
include zcoi_common_01.
*               *******************************                        *
****************             Tables            *************************
*               *******************************
TABLES: mara,         " 일반자재데이타
        marc,         " 자재에 대한 플랜트데이타
        mbew,         " 자재평가
*        glfunct,
*        bseg,
        zcot0096,    " 제품/자재 수불 집계 관리 HISTORY
        zcot0097.    " 제품/자재 수불 현황

*               *******************************                        *
****************        Selection Screen       *************************
*               *******************************
*---- 선택옵션
SELECTION-SCREEN BEGIN OF BLOCK bk1 WITH FRAME TITLE text-001.
PARAMETERS:      p_bukrs    LIKE zcot0096-bukrs OBLIGATORY. "UP01. -----
SELECT-OPTIONS:  s_spmon    FOR  zcot0096-spmon OBLIGATORY
                                                 NO-EXTENSION,
*                 S_bukrs    FOR  bseg-bukrs,
*                 S_gjahr    FOR  bseg-gjahr,
*                 s_monat    FOR  glfunct-rpmax,
                 s_werks    FOR  zcot0096-werks MEMORY ID wrk,
                 s_mtart    FOR  mara-mtart,
                 s_matkl    FOR  mara-matkl,
                 s_bklas    FOR  mbew-bklas,
                 s_dispo    FOR  marc-dispo,
                 s_prctr    FOR  marc-prctr,
                 s_matnr    FOR  mara-matnr.
SELECTION-SCREEN END OF BLOCK bk1.

*-- 출력 조건
SELECTION-SCREEN BEGIN OF BLOCK bk2 WITH FRAME TITLE text-002.

PARAMETERS: p_form1 RADIOBUTTON GROUP form DEFAULT 'X', "자재별 현황
            p_form2 RADIOBUTTON GROUP form,             "플랜트+평가클래
*            P_FORM3 RADIOBUTTON GROUP FORM,             "플랜트별 계
            p_form4 RADIOBUTTON GROUP form.             "플랜트+손익센터
SELECTION-SCREEN END OF BLOCK bk2.

*               *******************************                        *
****************        Internal   Tables      *************************
*               *******************************                        *
*---- 출력자료 보관 INTERNAL TABLE
*DATA: BEGIN OF st_zcot097 OCCURS 0 .
*        INCLUDE STRUCTURE zcos0003.
*DATA: END   OF st_zcot097.

DATA: BEGIN OF st_zcot097 OCCURS 0 .
        include structure zcos0003.
DATA:   bukrs TYPE bukrs,
      END   OF st_zcot097.

DATA: it_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE,
      wk_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE.

*---- ZCOS003 구조 필드 보관 INTERNAL TABLE
DATA: BEGIN OF it_dd03l OCCURS 0,
        fieldname       TYPE dd03l-fieldname,
        position        TYPE dd03l-position,
        reffield        TYPE dd03l-reffield,
      END OF it_dd03l.

*---- 전역변수 선언
DATA: g_bdatj TYPE mlcd-bdatj,
      g_poper TYPE mlcd-poper,
      g_werks_text TYPE t001w-name1,
      g_maktx    LIKE makt-maktx,
      g_matnr    LIKE zcot0097-matnr,
      g_bwtar    LIKE zcot0097-bwtar,
      g_matkl    LIKE zcos0003-matkl,
      g_mtart    LIKE zcos0003-mtart,
      g_werks    LIKE zcos0003-werks,
      g_bklas    LIKE zcos0003-bklas,
      g_prctr    LIKE zcos0003-prctr,
      g_dispo    LIKE zcos0003-dispo,
      g_meins    LIKE zcot0097-meins,
      g_waers    LIKE zcot0097-waers,
      g_mbasis   LIKE zcot0097-mbasis,
      g_wbasis   LIKE zcot0097-wbasis,
      g_mbwbest  LIKE zcot0097-mbwbest,
      g_wbwbest  LIKE zcot0097-wbwbest,
      g_first(1)      VALUE 'Y',
      g_cpudt          LIKE zcot0096-cpudt,
      g_cputm          LIKE zcot0096-cputm,
      g_spmon          LIKE zcot0096-spmon,
      g_t_cputm(08),
      g_t_cpudt(10).

DATA: gr_fieldname TYPE RANGE OF fieldname.

*               *******************************                        *
****************        Data Declaration       *************************
*               *******************************
*---- ALV GRID 필요 항목
TYPE-POOLS:  slis.
DATA:  it_fieldcat   TYPE  slis_t_fieldcat_alv,  "필드text
       it_sort       TYPE  slis_t_sortinfo_alv,  "sort
       it_sp_group   TYPE  slis_t_sp_group_alv,
       it_events     TYPE  slis_t_event,         "event
       gs_layout     TYPE  slis_layout_alv,      "리포트layout
       gs_light      TYPE  lvc_s_layo,           "상태버튼
       gs_print      TYPE  slis_print_alv,       "print
       g_save              VALUE 'A',            "조회변형 저장
       gx_variant    LIKE disvariant,            "variant
       g_variant     LIKE disvariant.

DATA  g_status  TYPE slis_formname  VALUE '1000'.
*DATA  G_STATUS  TYPE SLIS_FORMNAME  VALUE 'PF_STATUS_SET'.
*---- 상태를 상태명으로 설정
DATA : g_user_command TYPE slis_formname VALUE 'USER_COMMAND'.
*---- user-command 를 form 명으로 설정
DATA : g_lights_fieldname TYPE slis_fieldname VALUE 'LIGHTS'.
*---- 상태버튼은 필드명으로 설정
DATA : g_repid LIKE sy-repid.  " 리포트ID
DATA : gt_list_top_of_page TYPE slis_t_listheader, "top of page
       g_top_of_page  TYPE slis_formname VALUE 'TOP_OF_PAGE'.

DATA : ls_fieldcat  TYPE slis_fieldcat_alv.
DATA : ls_sort      TYPE slis_sortinfo_alv.


* --> POPUP ALV Grid 항목...
DATA: g_docking_container2  TYPE REF TO cl_gui_docking_container,
      g_custom_container2   TYPE REF TO cl_gui_custom_container,
      g_alv_grid2           TYPE REF TO cl_gui_alv_grid,
      gt_fieldcat2          TYPE lvc_t_fcat,
      gt_toolbar2           TYPE ui_functions,
      gs_layout2            TYPE lvc_s_layo,
      g_detail(1).

DATA: BEGIN OF gs_detail,
        hkont   TYPE hkont,     "G/L 계정,
        belnr	  TYPE belnr_d,   "전표번호,
        blart   TYPE blart,     "전표유형,
        awkey   TYPE awkey,     "오브젝트키,
        shkzg   TYPE shkzg,     "차/대변 지시자,
        matnr   TYPE matnr,     "자재,
        ebeln   TYPE ebeln,     "구매문서,
        ebelp   TYPE ebelp,     "구매문서 품목,
        vbel2	  TYPE vbeln_va,  "판매문서,
        posn2	  TYPE posnr_va,  "판매 문서 품목,
        werks   TYPE werks_d,   "플랜트,
        prctr   TYPE prctr,     "손익센터,
        dmbtr   TYPE dmbtr,
        waers   TYPE waers,
      END OF gs_detail,
      gt_detail LIKE TABLE OF gs_detail.

DATA: gt_wzubb_pu   TYPE TABLE OF zcos0005,
      gt_wzubb_po   TYPE TABLE OF zcos0005,
      gt_wzubb_su   TYPE TABLE OF zcos0005,
      gt_wzubb_st   TYPE TABLE OF zcos0005,
      gt_wzubb_et   TYPE TABLE OF zcos0005,
      gt_wzubb_mt   TYPE TABLE OF zcos0005,
      gt_wzubb_pr   TYPE TABLE OF zcos0005,
      gt_wzubb_th   TYPE TABLE OF zcos0005,
      gt_wzubb_co   TYPE TABLE OF zcos0005,
      gt_wzubb_cp   TYPE TABLE OF zcos0005,
      gt_wzubb_ivp  TYPE TABLE OF zcos0005,
      gt_wzubb_ivs  TYPE TABLE OF zcos0005,
      gt_wzubb_sap  TYPE TABLE OF zcos0005,
      gt_wzubb_mlp  TYPE TABLE OF zcos0005,
      gt_wagbb_jr   TYPE TABLE OF zcos0005,
      gt_wagbb_mc   TYPE TABLE OF zcos0005,
      gt_wagbb_ys   TYPE TABLE OF zcos0005,
      gt_wagbb_st   TYPE TABLE OF zcos0005,
      gt_wagbb_mt   TYPE TABLE OF zcos0005,
      gt_wagbb_su   TYPE TABLE OF zcos0005,
      gt_wagbb_et   TYPE TABLE OF zcos0005,
      gt_wagbb_th   TYPE TABLE OF zcos0005,
      gt_wagbb_pi   TYPE TABLE OF zcos0005,
      gt_wagbb_co   TYPE TABLE OF zcos0005.

*               *******************************                        *
****************        Initialization         *************************
*               *******************************                        *
INITIALIZATION.
  PERFORM p0100_initialize_all_data.   "DATA 초기화

*               *******************************                        *
****************        Event Processing       *************************
*               *******************************
AT SELECTION-SCREEN.
  PERFORM p0200_check.
  PERFORM initialize_fieldcat USING it_fieldcat[].
  PERFORM initialize_sort     USING it_sort[].
  PERFORM variant_init.
* PERFORM LAYOUT_INIT USING GS_LAYOUT.
  PERFORM eventtab_build USING it_events[].
  PERFORM comment_build USING gt_list_top_of_page[].

************************
*  Start-of-Selection  *
************************
START-OF-SELECTION.

  PERFORM AUTHORITY_CHECK_BUKRS_PA(ZCOC0070) USING P_BUKRS 'R'.

* UP01. 추가...-----------
* 상세전표는 금액 칸을 눌렀을 때만 그 자재만 읽는다.

*---- 월 수불 자료 READ
  PERFORM p1000_read_zcot097_rtn.

*---- 평가클래스를 재 조정
  LOOP AT it_zcot097 WHERE NOT bwtar EQ ' '.
    SELECT SINGLE bklas INTO it_zcot097-bklas FROM mbew
            WHERE bwtar EQ it_zcot097-bwtar
              AND matnr EQ it_zcot097-matnr.
    MODIFY it_zcot097.
  ENDLOOP.


*---- 기간이 2개월이상인 경우
  READ TABLE s_spmon INDEX 1.
  IF s_spmon-high = space.
    s_spmon-high = s_spmon-low.
  ELSEIF s_spmon-low NE s_spmon-high.
    PERFORM p2000_calc_zcot097_sum.
  ENDIF.

  PERFORM GET_WARES USING P_BUKRS G_WAERS.

*---- 출력양식 선택에 따라 합산
  IF p_form2 = 'X'.             "플랜트+평가클래스별합계
    PERFORM p2500_summation_for_form2.
*  ELSEIF P_FORM3 = 'X'.
*    PERFORM P2500_SUMMATION_FOR_FORM3.
  ELSEIF p_form4 = 'X'.         "플랜트+손익센터별합계
    PERFORM p2500_summation_for_form4.
  ENDIF.

  g_bdatj = s_spmon-high+0(4).
  g_poper = s_spmon-high+4(2).

*** 평가클레스 명으로 출력시
*  LOOP AT IT_ZCOT097.
*    CASE IT_ZCOT097-BKLAS.
*      WHEN '3000'.
*           IT_ZCOT097-BKLAS = '원자재'.
*      WHEN '3001'.
*           IT_ZCOT097-BKLAS = '포장재'.
*      WHEN '3100'.
*           IT_ZCOT097-BKLAS = '상품'.
*      WHEN '7900'.
*           IT_ZCOT097-BKLAS = '반제품'.
*      WHEN '7920'.
*           IT_ZCOT097-BKLAS = '제품'.
*      WHEN OTHERS.
*           IT_ZCOT097-BKLAS = IT_ZCOT097-BKLAS.
*    ENDCASE.
*
*    MODIFY IT_ZCOT097.
*  ENDLOOP.
***
************************
*  End-of-Selection    *
************************
END-OF-SELECTION.
  SET PF-STATUS '1000'.
  PERFORM move_to_alv_grid_rtn.

*&---------------------------------------------------------------------*
*&      Form  P0100_INITIALIZE_ALL_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p0100_initialize_all_data.

  "UP01.------------------
  IF p_bukrs IS INITIAL. p_bukrs = '1000'. ENDIF.
  IF gr_fieldname[] IS INITIAL.
    DATA: ls_fieldname LIKE LINE OF gr_fieldname.
    _set_ranges:  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_PU' '', "입고금액(구매).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_PO' '', "입고금액(생산).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_SU' '', "입고금액(외주가공).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_ST' '', "입고금액(공장이전).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_MT' '', "입고금액(자재간이전).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_ET' '', "입고금액(타계정).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_PR' '', "입고금액(가격변경).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_TH' '', "입고금액(삼자거래).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_CO' '', "입고금액(원가차이).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_CP' '', "입고금액(구매가격차이).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_IVP' '',"입고금액(IV구매).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_IVS' '',"입고금액(IV사급).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_SAP' '',"입고금액(SA정산).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WZUBB_MLP' '',"입고금액(ML정산).

                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_JR' '', "출고금액(재료비).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_MC' '', "출고금액(매출원가).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_YS' '', "출고금액(유상매각).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_ST' '', "출고금액(공장이전).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_MT' '', "출고금액(자재간이전).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_SU' '', "출고금액(사급자재).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_ET' '', "출고금액(타계정).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_TH' '', "출고금액(삼자거래).
                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_PI' ''. "출고금액(실사차이).
*                  gr_fieldname ls_fieldname 'I' 'EQ' 'WAGBB_CO' ''. "출고금액(원가차이).
  ENDIF.

  CHECK g_first = 'Y'.

  s_spmon-low    = sy-datum(6).
  s_spmon-sign   = 'I'.
  s_spmon-option = 'EQ'.
  APPEND s_spmon.

  CLEAR g_first.

  g_repid = sy-repid. " 리포트 ID

ENDFORM.                    " P0100_INITIALIZE_ALL_DATA

*&---------------------------------------------------------------------*
*&      Form  P0200_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p0200_check.

*---- 집계일과 시간 READ
  CLEAR: g_cpudt, g_cputm.

  READ TABLE s_spmon INDEX 1.
  IF s_spmon-high > '000000'.
    g_spmon = s_spmon-high.
  ELSE.
    g_spmon = s_spmon-low.
  ENDIF.

  SELECT SINGLE cpudt cputm
    INTO (g_cpudt, g_cputm)
    FROM zcot0096
    WHERE bukrs =  p_bukrs  "UP01. -------------------
      AND spmon =  g_spmon
      AND werks IN s_werks.

  WRITE g_cpudt TO g_t_cpudt USING EDIT MASK '____.__.__'.
  WRITE g_cputm TO g_t_cputm USING EDIT MASK '__:__:__'.

ENDFORM.                    " P0200_CHECK
*&-----------------------------------------------------------
*
*&      Form  INITIALIZE_FIELDCAT
*&-----------------------------------------------------------
FORM initialize_fieldcat USING    p_it_fieldcat.

  REFRESH: it_fieldcat, it_dd03l.
  DATA     g_lines  TYPE i.
  CLEAR    g_lines.

  SELECT fieldname position reffield
    INTO CORRESPONDING FIELDS OF TABLE it_dd03l
    FROM dd03l
    WHERE tabname = 'ZCOS0003'
    ORDER BY position.
  IF sy-subrc NE 0.
    MESSAGE e000 WITH '구조 ZCOS0003 를 찾지 못했습니다.'.
  ENDIF.

*---- ALV 목록 헤더 ASSIGN
  CLEAR   ls_fieldcat.
  ls_fieldcat-key         = 'X'.
  ls_fieldcat-key_sel     = 'X'.

  LOOP AT it_dd03l.
*---- 기초재고수량부터 DATA 필드
    IF it_dd03l-fieldname = 'MBASIS'.
      CLEAR: ls_fieldcat-key, ls_fieldcat-key_sel.
    ENDIF.

    CLEAR: ls_fieldcat-cfieldname, ls_fieldcat-qfieldname,
           ls_fieldcat-just.
    IF it_dd03l-reffield = 'WAERS'.
      ls_fieldcat-cfieldname = 'WAERS'.
      ls_fieldcat-just       = 'R'.
    ELSEIF it_dd03l-reffield = 'MEINS'.
      ls_fieldcat-qfieldname = 'MEINS'.
      ls_fieldcat-just       = 'R'.
    ENDIF.

*---- 출력길이 DEFINE
    CASE it_dd03l-fieldname.
      WHEN 'MATNR'.
        ls_fieldcat-outputlen = 14.
        ls_fieldcat-key       = 'X'.
      WHEN 'MATKL'.      ls_fieldcat-outputlen =  4.
      WHEN 'BKLAS'.
        ls_fieldcat-outputlen =  6.
        ls_fieldcat-key       = 'X'.
      WHEN 'PRCTR'.      ls_fieldcat-key       = 'X'.
      WHEN 'MTART'.      ls_fieldcat-outputlen =  4.
      WHEN 'MEINS'.      ls_fieldcat-outputlen =  4.
      WHEN 'WAERS'.      ls_fieldcat-outputlen =  4.
      WHEN 'SPMON'.      ls_fieldcat-no_out    = 'X'.
      WHEN 'MZUBB_TH'.   ls_fieldcat-no_out    = 'X'.
      WHEN 'WZUBB_TH'.   ls_fieldcat-no_out    = 'X'.
*      WHEN 'MZUBB_MT'.   ls_fieldcat-no_out    = 'X'.
*      WHEN 'WZUBB_MT'.   ls_fieldcat-no_out    = 'X'.
      WHEN 'WZUBB_IVP'.  ls_fieldcat-no_out    = 'X'.
      WHEN 'WZUBB_IVS'.  ls_fieldcat-no_out    = 'X'.
      WHEN 'WZUBB_SAP'.  ls_fieldcat-no_out    = 'X'.
      WHEN 'MAGBB_TH'.   ls_fieldcat-no_out    = 'X'.
      WHEN 'WAGBB_TH'.   ls_fieldcat-no_out    = 'X'.
*      WHEN 'MAGBB_MT'.   ls_fieldcat-no_out    = 'X'.
*      WHEN 'WAGBB_MT'.   ls_fieldcat-no_out    = 'X'.
      WHEN 'WAERS'.      ls_fieldcat-no_out    = 'X'.
      WHEN 'MAKTX'.      ls_fieldcat-no_out    = 'X'.
      WHEN 'MTART'.      ls_fieldcat-no_out    = 'X'.
      WHEN 'MATKL'.      ls_fieldcat-no_out    = 'X'.
      WHEN 'DISPO'.      ls_fieldcat-no_out    = 'X'.
      WHEN OTHERS.       ls_fieldcat-outputlen = 12.
    ENDCASE.

    ls_fieldcat-fieldname   = it_dd03l-fieldname.
    ls_fieldcat-ddictxt     = 'M'.
    ls_fieldcat-ref_tabname = 'ZCOS0003'.
    APPEND ls_fieldcat TO it_fieldcat.
    CLEAR  ls_fieldcat.
  ENDLOOP.

ENDFORM.                    " INITIALIZE_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  MOVE_TO_ALV_GRID_RTN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_to_alv_grid_rtn.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
*     i_interface_check                 = 'ALV_BACKGROUD'
**   I_BYPASSING_BUFFER                =
**   I_BUFFER_ACTIVE                   = ' '
     i_callback_program                = g_repid
*    I_CALLBACK_PF_STATUS_SET          = G_STATUS
     i_callback_user_command           = g_user_command
**   I_CALLBACK_TOP_OF_PAGE            = ' '
**   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
**   I_CALLBACK_HTML_END_OF_LIST       = ' '
**   I_STRUCTURE_NAME                  =
**   I_BACKGROUND_ID                   = ' '
**   I_GRID_TITLE                      =
**   I_GRID_SETTINGS                   =
*    IS_LAYOUT                         = GS_LAYOUT
     it_fieldcat                       = it_fieldcat
**   IT_EXCLUDING                      =
**   IT_SPECIAL_GROUPS                 =
     it_sort                           = it_sort
**   IT_FILTER                         =
**   IS_SEL_HIDE                       =
**   I_DEFAULT                         = 'X'
     i_save                            = g_save
     is_variant                        = g_variant
     it_events                         = it_events[]
**   IT_EVENT_EXIT                     =
**   IS_PRINT                          =
**   IS_REPREP_ID                      =
**   I_SCREEN_START_COLUMN             = 0
**   I_SCREEN_START_LINE               = 0
**   I_SCREEN_END_COLUMN               = 0
**   I_SCREEN_END_LINE                 = 0
**   IT_ALV_GRAPHICS                   =
**   IT_ADD_FIELDCAT                   =
**   IT_HYPERLINK                      =
** IMPORTING
**   E_EXIT_CAUSED_BY_CALLER           =
**   ES_EXIT_CAUSED_BY_USER            =
    TABLES
      t_outtab                          = it_zcot097.
** EXCEPTIONS
**   PROGRAM_ERROR                     = 1
**   OTHERS                            = 2
*          .
*IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*ENDIF.

ENDFORM.                    " MOVE_TO_ALV_GRID_RTN
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command USING p_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  CASE p_ucomm.
    WHEN '&IC1'.
      READ TABLE it_zcot097 INTO st_zcot097 INDEX rs_selfield-tabindex.
      IF sy-subrc = 0.
        IF     rs_selfield-fieldname = 'MATNR'.
          PERFORM _call_transaction USING st_zcot097-matnr
                                         ' '
                                         ' '
                                         'MAT'
                                         ' '
                                         ' '
                                         'MM03'.
*        ELSEIF rs_selfield-fieldname = 'WERKS'
*            OR rs_selfield-fieldname = 'BKLAS'
*            OR rs_selfield-fieldname = 'PRCTR'.
        ELSE.
          IF rs_selfield-fieldname IN gr_fieldname.
            PERFORM show_detail USING st_zcot097
                                      rs_selfield-fieldname.
          ENDIF.
        ENDIF.
      ELSE.
        MESSAGE s155(gr).
      ENDIF.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " user_command
*&-----------------------------------------------------------
*
*&      Form  INITIALIZE_SORT
*&-----------------------------------------------------------
FORM initialize_sort USING    p_it_sort.

  REFRESH it_sort.
  CLEAR   it_sort.

  PERFORM move_to_it_sort.

ENDFORM.                    " INITIALIZE_SORT
*&---------------------------------------------------------------------*
*&      Form  VARIANT_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM variant_init.

  CLEAR g_variant.
  g_variant-report = g_repid.

  gx_variant = g_variant.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      i_save     = g_save
    CHANGING
      cs_variant = gx_variant
    EXCEPTIONS
      not_found  = 2.
  IF sy-subrc = 0.
*  p_vari = gx_variant-variant.
  ENDIF.

ENDFORM.                    " VARIANT_INIT
*&---------------------------------------------------------------------*
*&      Form  layout_init
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->RS_LAYOUT  text
*----------------------------------------------------------------------*
FORM layout_init USING  rs_layout TYPE slis_layout_alv.
  rs_layout-detail_popup = 'X'.
  rs_layout-lights_fieldname = g_lights_fieldname.
  rs_layout-box_fieldname   = 'SELECTED'.
ENDFORM.                    " layout_init
*&---------------------------------------------------------------------*
*&      Form  MOVE_TO_IT_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_to_it_sort.

*---- SORT 기준
*---- 플랜트
  CLEAR ls_sort.
  ls_sort-spos          =  1.
  ls_sort-fieldname     =  'WERKS'.
  ls_sort-up            =  'X'.
  APPEND ls_sort TO it_sort.

  ls_sort-spos          =  2.
  ls_sort-fieldname     =  'BKLAS'.
  ls_sort-up            =  'X'.
  APPEND ls_sort TO it_sort.


  ls_sort-spos          =  3.
  ls_sort-fieldname     =  'BWTAR'.
  ls_sort-up            =  'X'.
  APPEND ls_sort TO it_sort.

  ls_sort-spos          =  4.
  ls_sort-fieldname     =  'MATNR'.
  ls_sort-up            =  'X'.
  APPEND ls_sort TO it_sort.

ENDFORM.                    " MOVE_TO_IT_SORT
*&---------------------------------------------------------------------*
*&      Form  P1000_READ_ZCOT097_RTN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p1000_read_zcot097_rtn.

  CLEAR : wk_zcot097[], wk_zcot097.
*- Field Add-On: MARC-PRCTR 04.09.24 SMKANG
  SELECT a~werks    a~matnr   a~spmon   a~meins a~bwtar
         a~mbasis  a~wbasis  a~mzubb   a~wzubb
         a~magbb   a~wagbb   a~mbwbest a~wbwbest
         a~mzubb_pu a~wzubb_pu a~mzubb_po a~wzubb_po
         a~mzubb_su a~wzubb_su a~mzubb_st a~wzubb_st a~mzubb_mt a~wzubb_mt
         a~mzubb_et a~wzubb_et a~mzubb_th a~wzubb_th  a~wzubb_sap a~wzubb_mlp
         a~wzubb_pr a~wzubb_co a~wzubb_cp a~wzubb_ivp a~wzubb_ivs
         a~magbb_jr a~wagbb_jr a~magbb_mc a~wagbb_mc
         a~magbb_ys a~wagbb_ys a~magbb_st a~wagbb_st a~magbb_mt a~wagbb_mt
         a~magbb_su a~wagbb_su a~magbb_et a~wagbb_et
         a~magbb_th a~wagbb_th a~wagbb_co
         a~waers
         b~maktx    c~mtart    c~matkl
         d~bklas
         e~dispo    e~prctr

    INTO CORRESPONDING FIELDS OF TABLE wk_zcot097
    FROM zcot0097 AS a INNER JOIN makt AS b
         ON a~matnr = b~matnr AND
            b~spras = sy-langu
      INNER JOIN mara AS c
         ON a~matnr = c~matnr
      INNER JOIN mbew AS d
         ON a~matnr = d~matnr AND
            a~werks = d~bwkey AND
            d~bwtar = ' '
      INNER JOIN marc AS e
         ON a~matnr = e~matnr AND
            a~werks = e~werks

    WHERE a~bukrs EQ p_bukrs  "UP01. ------------------------
      AND a~werks IN s_werks
      AND a~spmon IN s_spmon
      AND a~matnr IN s_matnr
      AND c~mtart IN s_mtart
      AND c~matkl IN s_matkl
      AND a~bklas IN s_bklas
      AND e~dispo IN s_dispo
      AND e~prctr IN s_prctr.

  LOOP AT wk_zcot097.
    MOVE-CORRESPONDING wk_zcot097  TO it_zcot097.
    COLLECT it_zcot097. CLEAR it_zcot097.
  ENDLOOP.


  SORT it_zcot097 BY werks bwtar bklas matnr.

ENDFORM.                    " P1000_READ_ZCOT097_RTN
*&---------------------------------------------------------------------*
*&      Form  TOP_OF_PAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM top_of_page.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      i_logo             = 'ENJOYSAP_LOGO'
      it_list_commentary = gt_list_top_of_page.

ENDFORM.                    "TOP_OF_PAGE
*&---------------------------------------------------------------------*
*&      Form  COMMENT_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM comment_build USING lt_top_of_page TYPE slis_t_listheader.

  DATA: ls_line TYPE slis_listheader.

  REFRESH lt_top_of_page.

*---- LIST HEADING LINE: TYPE H
  CLEAR ls_line.
  ls_line-typ  = 'H'.
* LS_LINE-KEY:  NOT USED FOR THIS TYPE
  ls_line-info = '제품/자재 월 수불명세서'.
  APPEND ls_line TO lt_top_of_page.

**---- STATUS LINE: TYPE S
*  CLEAR LS_LINE.
*  LS_LINE-TYP  = 'S'.
*  LS_LINE-KEY  = '플랜트 :'.
*  CONCATENATE P_WERKS G_WERKS_TEXT INTO LS_LINE-INFO
*              SEPARATED BY SPACE.
*  APPEND LS_LINE TO LT_TOP_OF_PAGE.
*
*---- STATUS LINE: TYPE S
  IF s_spmon-high = space.
    s_spmon-high = s_spmon-low.
  ENDIF.

  CLEAR ls_line.
  ls_line-typ  = 'S'.
  ls_line-key  = '년  월 :'.
  CONCATENATE s_spmon-low '~' s_spmon-high
    INTO ls_line-info SEPARATED BY space.

  APPEND ls_line TO lt_top_of_page.

*---- STATUS LINE: TYPE S
  CLEAR ls_line.
  ls_line-typ  = 'S'.
  ls_line-key  = '집계일 :'.
  ls_line-info+00(10) = g_t_cpudt.
  ls_line-info+14(08) = g_t_cputm.
  APPEND ls_line TO lt_top_of_page.

*---- STATUS LINE: TYPE S
*  CLEAR ls_line.
*  ls_line-typ  = 'S'.
*  ls_line-key  = '평가클래스 :'.
*  ls_line-info = '3000:원자재, 3001:포장재, 3040-3041:저장품,3050:포장재, 3090:부산물
*                , 3100:상품, 3101:상품 매입 완제품, 3102:상품 중국 완제품, 7900:반제품, 7930:방산 완제품'.
*  APPEND ls_line TO lt_top_of_page.

*---- ACTION LINE: TYPE A
*  CLEAR LS_LINE.
*  LS_LINE-TYP  = 'A'.
** LS_LINE-KEY:  NOT USED FOR THIS TYPE
*  LS_LINE-INFO = 'ACTION LINE'.
*  APPEND LS_LINE TO LT_TOP_OF_PAGE.

ENDFORM.                    " COMMENT_BUILD
*&---------------------------------------------------------------------*
*&      Form  EVENTTAB_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM eventtab_build USING rt_events TYPE slis_t_event.

*"Registration of events to happen during list display
  DATA: ls_event TYPE slis_alv_event.
*
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type = 0
    IMPORTING
      et_events   = rt_events.

  READ TABLE rt_events WITH KEY name = slis_ev_top_of_page
                           INTO ls_event.

  IF sy-subrc = 0.
    MOVE g_top_of_page TO ls_event-form.
    APPEND ls_event TO rt_events.
  ENDIF.

ENDFORM.                    "EVENTTAB_BUILD
*&---------------------------------------------------------------------*
*&      Form  P2000_CALC_ZCOT097_SUM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p2000_calc_zcot097_sum.

  DATA: te_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE.

  SORT it_zcot097 BY werks bwtar bklas matnr.

  te_zcot097[] = it_zcot097[].

  REFRESH it_zcot097.

  LOOP AT te_zcot097.
    IF g_matnr NE te_zcot097-matnr.
      g_matnr   = te_zcot097-matnr.
      g_maktx   = te_zcot097-maktx.
      g_mtart   = te_zcot097-mtart.
      g_matkl   = te_zcot097-matkl.
      g_bklas   = te_zcot097-bklas.
      g_meins   = te_zcot097-meins.
      g_waers   = te_zcot097-waers.
    ENDIF.
*---- 자재의 최초월 기초/기말 보관
    IF te_zcot097-spmon = s_spmon-low.
      g_mbasis  = te_zcot097-mbasis.
      g_wbasis  = te_zcot097-wbasis.
    ENDIF.
    IF te_zcot097-spmon = s_spmon-high.
      g_mbwbest = te_zcot097-mbwbest.
      g_wbwbest = te_zcot097-wbwbest.
    ENDIF.

    AT END OF matnr.
      SUM.
      MOVE-CORRESPONDING te_zcot097 TO st_zcot097.
      st_zcot097-matnr     = g_matnr.
      st_zcot097-maktx     = g_maktx.
      st_zcot097-mtart     = g_mtart.
      st_zcot097-matkl     = g_matkl.
      st_zcot097-bklas     = g_bklas.
      st_zcot097-meins     = g_meins.
      st_zcot097-waers     = g_waers.
      st_zcot097-mbasis    = g_mbasis.
      st_zcot097-wbasis    = g_wbasis.
      st_zcot097-mbwbest   = g_mbwbest.
      st_zcot097-wbwbest   = g_wbwbest.
      APPEND st_zcot097 TO it_zcot097.

      CLEAR: g_mbwbest, g_wbwbest, g_mbasis,  g_wbasis.
    ENDAT.
  ENDLOOP.

ENDFORM.                    " P2000_CALC_ZCOT097_SUM
*&---------------------------------------------------------------------*
*&      Form  P2500_SUMMATION_FOR_FORM3
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p2500_summation_for_form3.

  DATA: te_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE.

  SORT it_zcot097 BY werks bklas matnr.

  te_zcot097[] = it_zcot097[].

  REFRESH it_zcot097.

  LOOP AT te_zcot097.
    AT NEW werks.
      g_werks   = te_zcot097-werks.
      g_waers   = 'KRW'.
    ENDAT.
    AT END OF werks.
      SUM.
      MOVE-CORRESPONDING te_zcot097 TO st_zcot097.
      st_zcot097-werks     = g_werks.
      st_zcot097-waers     = g_waers.
      APPEND st_zcot097 TO it_zcot097.
    ENDAT.
  ENDLOOP.

ENDFORM.                    " P2500_SUMMATION_FOR_FORM3
*&---------------------------------------------------------------------*
*&      Form  P2500_SUMMATION_FOR_FORM2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p2500_summation_for_form2.

  DATA: te_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE.

  SORT it_zcot097 BY werks bwtar bklas matnr.

  te_zcot097[] = it_zcot097[].

  REFRESH it_zcot097.

  LOOP AT te_zcot097.
    AT NEW bklas.
      g_werks   = te_zcot097-werks.
      g_bklas   = te_zcot097-bklas.
      g_bwtar   = te_zcot097-bwtar.
*      g_waers   = 'KRW'.
    ENDAT.
    AT END OF bklas.
      SUM.
      MOVE-CORRESPONDING te_zcot097 TO st_zcot097.
      st_zcot097-werks     = g_werks.
      st_zcot097-bklas     = g_bklas.
      st_zcot097-bwtar     = g_bwtar.
      st_zcot097-waers     = g_waers.
      APPEND st_zcot097 TO it_zcot097.
    ENDAT.
  ENDLOOP.

ENDFORM.                    " P2500_SUMMATION_FOR_FORM2
*&---------------------------------------------------------------------*
*&      Form  P2500_SUMMATION_FOR_FORM4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM p2500_summation_for_form4 .

  DATA: te_zcot097 LIKE st_zcot097 OCCURS 0 WITH HEADER LINE.

  SORT it_zcot097 BY werks bwtar bklas prctr matnr.

  te_zcot097[] = it_zcot097[].

  REFRESH it_zcot097.

  LOOP AT te_zcot097.
    AT NEW prctr.
      g_werks   = te_zcot097-werks.
      g_prctr   = te_zcot097-prctr.
      g_bwtar   = te_zcot097-bwtar.
*      g_waers   = 'KRW'.
    ENDAT.
    AT END OF prctr.
      SUM.
      MOVE-CORRESPONDING te_zcot097 TO st_zcot097.
      st_zcot097-werks     = g_werks.
      st_zcot097-prctr     = g_prctr.
      st_zcot097-bwtar     = g_bwtar.
      st_zcot097-waers     = g_waers.
      APPEND st_zcot097 TO it_zcot097.
    ENDAT.
  ENDLOOP.

ENDFORM.                    " P2500_SUMMATION_FOR_FORM4
*&---------------------------------------------------------------------*
*&      Form  CALL_TRANSACTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ITAB01_MATNR  text
*      -->P_0758   text
*      -->P_0759   text
*      -->P_0760   text
*      -->P_0761   text
*      -->P_0762   text
*      -->P_0763   text
*----------------------------------------------------------------------*
FORM _call_transaction  USING    p_v1
                                p_v2
                                p_v3
                                p_p1
                                p_p2
                                p_p3
                                p_tcode.

  SET PARAMETER ID p_p1 FIELD p_v1.

  IF NOT p_p2 IS INITIAL.
    SET PARAMETER ID p_p2 FIELD p_v2.
  ENDIF.

  IF NOT p_p3 IS INITIAL.
    SET PARAMETER ID p_p3 FIELD p_v3.
  ENDIF.

  CALL TRANSACTION p_tcode AND SKIP FIRST SCREEN.

ENDFORM.                    " CALL_TRANSACTION
*&---------------------------------------------------------------------*
*&      Form  CALL_TRANSACTION_1
*&---------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_ST_ZCOT097_MATNR  text
*      -->P_ST_ZCOT097_WERKS  text
*      -->P_0782   text
*      -->P_0783   text
*      -->P_0784   text
*      -->P_0785   text
*      -->P_0786   text
*----------------------------------------------------------------------*
FORM call_transaction_1  USING  p_v1
                                p_v2
                                p_v3
                                p_v4
                                p_p1
                                p_p2
                                p_p3
                                p_p4
                                p_tcode.

  SET PARAMETER ID p_p1 FIELD p_v1.

  IF NOT p_p2 IS INITIAL.
    SET PARAMETER ID p_p2 FIELD p_v2.
  ENDIF.

  IF NOT p_p3 IS INITIAL.
    SET PARAMETER ID p_p3 FIELD p_v3.
  ENDIF.

  IF NOT p_p4 IS INITIAL.
    SET PARAMETER ID p_p4 FIELD p_v4.
  ENDIF.

  CALL TRANSACTION p_tcode. " AND SKIP FIRST SCREEN.

ENDFORM.                    " CALL_TRANSACTION_1

*&---------------------------------------------------------------------*
*&      Form  SHOW_DETAIL
*&---------------------------------------------------------------------*
FORM show_detail  USING    ps_zcot097 LIKE st_zcot097
                           p_fieldname.
  DATA: l_tabname TYPE tabname,
        l_fname   TYPE fieldname,
        lt_fields TYPE abap_compdescr_tab,
        ls_data   TYPE zcos0005,
        dyn_wa    TYPE REF TO data.

  PERFORM get_detail_data USING ps_zcot097-werks
                             ps_zcot097-matnr
                             p_fieldname.
  CLEAR: gt_detail[].

  PERFORM get_component_fields TABLES lt_fields USING 'GS_DETAIL'.

  l_fname = p_fieldname.
  CONDENSE l_fname.
  TRANSLATE l_fname TO UPPER CASE.

  FIELD-SYMBOLS: <dyn_table> TYPE STANDARD TABLE,
                 <fs> TYPE zcos0005.
  CONCATENATE 'GT_' l_fname INTO l_tabname.
  ASSIGN (l_tabname) TO <dyn_table>.

  LOOP AT <dyn_table> INTO ls_data.
    CHECK ls_data-werks EQ ps_zcot097-werks AND
          ls_data-matnr EQ ps_zcot097-matnr.

    MOVE-CORRESPONDING ls_data TO gs_detail.
    APPEND gs_detail TO gt_detail.
    CLEAR: gs_detail, ls_data.
  ENDLOOP.

  CALL SCREEN 50 STARTING AT 30 2.
ENDFORM.                    " SHOW_DETAIL

*&---------------------------------------------------------------------*
*&      Form  GET_DETAIL_DATA
*&---------------------------------------------------------------------*
FORM get_detail_data USING iv_werks TYPE werks_d
                       iv_matnr TYPE matnr
                       iv_col   TYPE fieldname.
  DATA: lt_werks LIKE s_werks OCCURS 0 WITH HEADER LINE,
        lt_matnr LIKE s_matnr OCCURS 0 WITH HEADER LINE,
        lv_high  LIKE s_spmon-low.
  STATICS: sv_werks TYPE werks_d,
           sv_matnr TYPE matnr,
           sv_low   TYPE spmon,
           sv_high  TYPE spmon,
           sv_col   TYPE fieldname,
           sv_ok    TYPE c.
  lv_high = s_spmon-high.
  IF lv_high IS INITIAL.
    lv_high = s_spmon-low.
  ENDIF.
  IF sv_ok = 'X' AND
     sv_werks = iv_werks AND
     sv_matnr = iv_matnr AND
     sv_low = s_spmon-low AND
     sv_high = lv_high AND
     sv_col = iv_col.
    RETURN.
  ENDIF.
  REFRESH: lt_werks, lt_matnr.
  CLEAR: lt_werks, lt_matnr.
  lt_werks-sign = 'I'.
  lt_werks-option = 'EQ'.
  lt_werks-low = iv_werks.
  APPEND lt_werks.
  lt_matnr-sign = 'I'.
  lt_matnr-option = 'EQ'.
  lt_matnr-low = iv_matnr.
  APPEND lt_matnr.
  EXPORT col = iv_col TO MEMORY ID 'ZCOR0011_COL'.
  call function 'ZCOF01_GET_SUBUL_DETAIL'
    EXPORTING
      i_bukrs      = p_bukrs
      i_spmon      = s_spmon-low
      i_epmon      = lv_high
    TABLES
      it_wzubb_pu  = gt_wzubb_pu
      it_wzubb_po  = gt_wzubb_po
      it_wzubb_su  = gt_wzubb_su
      it_wzubb_st  = gt_wzubb_st
      it_wzubb_mt  = gt_wzubb_mt
      it_wzubb_et  = gt_wzubb_et
      it_wzubb_pr  = gt_wzubb_pr
      it_wzubb_th  = gt_wzubb_th
      it_wzubb_co  = gt_wzubb_co
      it_wzubb_cp  = gt_wzubb_cp
      it_wzubb_ivp = gt_wzubb_ivp
      it_wzubb_ivs = gt_wzubb_ivs
      it_wzubb_sap = gt_wzubb_sap
      it_wzubb_mlp = gt_wzubb_mlp
      it_wagbb_jr  = gt_wagbb_jr
      it_wagbb_mc  = gt_wagbb_mc
      it_wagbb_ys  = gt_wagbb_ys
      it_wagbb_st  = gt_wagbb_st
      it_wagbb_mt  = gt_wagbb_mt
      it_wagbb_su  = gt_wagbb_su
      it_wagbb_et  = gt_wagbb_et
      it_wagbb_th  = gt_wagbb_th
      it_wagbb_pi  = gt_wagbb_pi
      it_wagbb_co  = gt_wagbb_co

      it_werks     = lt_werks
      it_matnr     = lt_matnr.
  sv_werks = iv_werks.
  sv_matnr = iv_matnr.
  sv_low = s_spmon-low.
  sv_high = lv_high.
  sv_col = iv_col.
  sv_ok = 'X'.
ENDFORM.                    " GET_DETAIL_DATA


*----------------------------------------------------------------------*
*  MODULE pbo_050 OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE pbo_050 OUTPUT.
  SET: PF-STATUS '050',
       TITLEBAR '050'.

  PERFORM display_grid_050.
ENDMODULE.                 " STATUS_0050  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0050  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_050 INPUT.
  CASE sy-ucomm.
    WHEN 'ESC'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0050  INPUT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_GRID_050
*&---------------------------------------------------------------------*
FORM display_grid_050 .
  IF g_custom_container2 IS INITIAL.
    CREATE OBJECT:  g_custom_container2
                      EXPORTING
                        container_name = 'CUSTOM_CONTAINER2',
                    g_alv_grid2
                      EXPORTING
                        i_parent  = g_custom_container2.

    PERFORM:  build_fieldcat_050,
              build_layout_050,
              build_exclude_toolbar_050.

    CALL METHOD g_alv_grid2->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout2
      CHANGING
        it_fieldcatalog = gt_fieldcat2
        it_outtab       = gt_detail.
  ELSE.
    g_alv_grid2->refresh_table_display( ).
  ENDIF.

  cl_gui_control=>set_focus( g_alv_grid2 ).
ENDFORM.                    " DISPLAY_GRID_050

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT_050
*&---------------------------------------------------------------------*
FORM build_fieldcat_050 .
  DATA: ls_fcat TYPE lvc_s_fcat.

  PERFORM build_fieldcatalog TABLES gt_fieldcat2 USING:
      ls_fcat 'S' 'FIELDNAME' 'WERKS',
      ls_fcat ' ' 'OUTPUTLEN' '6',
      ls_fcat 'E' 'COLTEXT'   '플랜트',

      ls_fcat 'S' 'FIELDNAME' 'PRCTR',
      ls_fcat ' ' 'OUTPUTLEN' '8',
      ls_fcat 'E' 'COLTEXT'   '손익센터',

      ls_fcat 'S' 'FIELDNAME' 'MATNR',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat 'E' 'COLTEXT'   '자재',

      ls_fcat 'S' 'FIELDNAME' 'HKONT',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat 'E' 'COLTEXT'   'G/L 계정',

      ls_fcat 'S' 'FIELDNAME' 'BELNR',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat 'E' 'COLTEXT'   '전표번호',

      ls_fcat 'S' 'FIELDNAME' 'BLART',
      ls_fcat ' ' 'OUTPUTLEN' '8',
      ls_fcat 'E' 'COLTEXT'   '전표유형',

      ls_fcat 'S' 'FIELDNAME' 'AWKEY',
      ls_fcat ' ' 'OUTPUTLEN' '16',
      ls_fcat 'E' 'COLTEXT'   '오브젝트키',

      ls_fcat 'S' 'FIELDNAME' 'SHKZG',
      ls_fcat ' ' 'OUTPUTLEN' '12',
      ls_fcat 'E' 'COLTEXT'   '차/대 지시자',

      ls_fcat 'S' 'FIELDNAME' 'DMBTR',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat ' ' 'CFIELDNAME' 'WAERS',
      ls_fcat 'E' 'COLTEXT'   '금액',

      ls_fcat 'S' 'FIELDNAME' 'WAERS',
      ls_fcat ' ' 'OUTPUTLEN' '6',
      ls_fcat 'E' 'COLTEXT'   '통화키',

      ls_fcat 'S' 'FIELDNAME' 'EBELN',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat 'E' 'COLTEXT'   '구매문서',

      ls_fcat 'S' 'FIELDNAME' 'EBELP',
      ls_fcat ' ' 'OUTPUTLEN' '12',
      ls_fcat 'E' 'COLTEXT'   '구매문서품목',

      ls_fcat 'S' 'FIELDNAME' 'VBEL2',
      ls_fcat ' ' 'OUTPUTLEN' '10',
      ls_fcat 'E' 'COLTEXT'   '판매문서',

      ls_fcat 'S' 'FIELDNAME' 'POSN2',
      ls_fcat ' ' 'OUTPUTLEN' '12',
      ls_fcat 'E' 'COLTEXT'   '판매문서품목'.

ENDFORM.                    " BUILD_FIELDCAT_050

*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT_050
*&---------------------------------------------------------------------*
FORM build_layout_050 .
  CLEAR gs_layout2.
  gs_layout2-zebra       = 'X'.
  gs_layout2-cwidth_opt  = 'X'.
*  gs_layout2-no_toolbar  = 'X'.
  gs_layout2-sel_mode    = 'A'.
ENDFORM.                    " BUILD_LAYOUT_050

*&---------------------------------------------------------------------*
*&      Form  BUILD_TOOLBAR_050
*&---------------------------------------------------------------------*
FORM build_exclude_toolbar_050 .
  CLEAR: gt_toolbar2[].

  PERFORM append_exclude_functions
        TABLES  gt_toolbar2
         USING :
               cl_gui_alv_grid=>mc_fc_loc_undo, "
                 cl_gui_alv_grid=>mc_fc_auf,      " 소계확장 &AUF
                 cl_gui_alv_grid=>mc_fc_average,  " &AVERAGE
                cl_gui_alv_grid=>mc_fc_back_classic,
                cl_gui_alv_grid=>mc_fc_call_abc, " &ABC
                cl_gui_alv_grid=>mc_fc_call_chain,
                cl_gui_alv_grid=>mc_fc_call_crbatch,
                cl_gui_alv_grid=>mc_fc_call_crweb,
                cl_gui_alv_grid=>mc_fc_call_lineitems,
                cl_gui_alv_grid=>mc_fc_call_master_data,
                cl_gui_alv_grid=>mc_fc_call_more,
                cl_gui_alv_grid=>mc_fc_call_report,
                cl_gui_alv_grid=>mc_fc_call_xint,
                cl_gui_alv_grid=>mc_fc_call_xxl,
*                cl_gui_alv_grid=>mc_fc_col_invisible,
*                cl_gui_alv_grid=>mc_fc_col_optimize,
*                cl_gui_alv_grid=>mc_fc_current_variant,
                cl_gui_alv_grid=>mc_fc_data_save,
                cl_gui_alv_grid=>mc_fc_delete_filter,
                cl_gui_alv_grid=>mc_fc_deselect_all,
*                 cl_gui_alv_grid=>mc_fc_detail,
                cl_gui_alv_grid=>mc_fc_expcrdata,
                cl_gui_alv_grid=>mc_fc_expcrdesig,
                cl_gui_alv_grid=>mc_fc_expcrtempl,
                cl_gui_alv_grid=>mc_fc_expmdb,
                cl_gui_alv_grid=>mc_fc_extend,
                cl_gui_alv_grid=>mc_fc_f4,
*                cl_gui_alv_grid=>mc_fc_filter,
*                cl_gui_alv_grid=>mc_fc_find,
*                cl_gui_alv_grid=>mc_fc_fix_columns,
                 cl_gui_alv_grid=>mc_fc_graph,
                cl_gui_alv_grid=>mc_fc_help,
*                 cl_gui_alv_grid=>mc_fc_info,
*                cl_gui_alv_grid=>mc_fc_load_variant,
                 cl_gui_alv_grid=>mc_fc_loc_copy,          " 행 카피
                cl_gui_alv_grid=>mc_fc_html,
                 cl_gui_alv_grid=>mc_fc_loc_copy_row,      " 행 카피
                 cl_gui_alv_grid=>mc_fc_loc_cut,           " 가위
                 cl_gui_alv_grid=>mc_fc_loc_delete_row,    " 행삭제
                 cl_gui_alv_grid=>mc_fc_loc_insert_row,    " 행삽입
                cl_gui_alv_grid=>mc_fc_loc_move_row,
                 cl_gui_alv_grid=>mc_fc_loc_append_row,    " 라인생성
                 cl_gui_alv_grid=>mc_fc_loc_paste,         " 겹쳐쓰기
                 cl_gui_alv_grid=>mc_fc_loc_paste_new_row, " 겹쳐쓰기
*                cl_gui_alv_grid=>mc_fc_maintain_variant,
                 cl_gui_alv_grid=>mc_fc_maximum,
                 cl_gui_alv_grid=>mc_fc_minimum,
                cl_gui_alv_grid=>mc_fc_pc_file,
                 cl_gui_alv_grid=>mc_fc_print,
                 cl_gui_alv_grid=>mc_fc_print_back,
                 cl_gui_alv_grid=>mc_fc_print_prev,
                cl_gui_alv_grid=>mc_fc_reprep,
                cl_gui_alv_grid=>mc_fc_save_variant,
                cl_gui_alv_grid=>mc_fc_select_all,
                cl_gui_alv_grid=>mc_fc_send,
*                cl_gui_alv_grid=>mc_fc_separator,
*                cl_gui_alv_grid=>mc_fc_sort,
*                cl_gui_alv_grid=>mc_fc_sort_asc,
*                cl_gui_alv_grid=>mc_fc_sort_dsc,
*                 cl_gui_alv_grid=>mc_fc_subtot,
*                 cl_gui_alv_grid=>mc_fc_sum,
                cl_gui_alv_grid=>mc_fc_to_office,
                cl_gui_alv_grid=>mc_fc_to_rep_tree,
                cl_gui_alv_grid=>mc_fc_unfix_columns,
                cl_gui_alv_grid=>mc_fc_views,
                cl_gui_alv_grid=>mc_fc_view_crystal,
                cl_gui_alv_grid=>mc_fc_view_excel,
                cl_gui_alv_grid=>mc_fc_view_grid,
                cl_gui_alv_grid=>mc_fc_word_processor,
                 cl_gui_alv_grid=>mc_fc_refresh,
                 cl_gui_alv_grid=>mc_fc_check.
ENDFORM.                    " BUILD_TOOLBAR_050

*&---------------------------------------------------------------------*
*&      Form  APPEND_EXCLUDE_FUNCTIONS
*&---------------------------------------------------------------------*
FORM append_exclude_functions  TABLES   pt_toolbar TYPE ui_functions
                               USING    p_value.
  DATA: ls_exclude  TYPE ui_func.
  ls_exclude = p_value.
  APPEND ls_exclude TO pt_toolbar.
ENDFORM.                    " APPEND_EXCLUDE_FUNCTIONS

*GUI Texts
*----------------------------------------------------------
* 050 --> 제품/자재 수불명세서 상세내역

*Text elements
*----------------------------------------------------------
* 001 선택조건


*Selection texts
*----------------------------------------------------------
* P_BUKRS         회사코드
* P_FORM1         자재별 현황
* P_FORM2         플랜트+평가클래스
* P_FORM4         플랜트+손익센터
* S_BKLAS         평가클래스
* S_DISPO         MRP관리자
* S_MATKL         자재그룹
* S_MATNR         자재코드
* S_MTART         자재유형
* S_PRCTR         손익센터
* S_SPMON         분석기간
* S_WERKS         플랜트


*Messages
*----------------------------------------------------------
*
* Message class: GR
*155   유효한 열에 커서를 놓으십시오.
*
* Message class: Hard coded
*   Check File Path & File Name.
*
* Message class: ZCOM
*000   & & & &

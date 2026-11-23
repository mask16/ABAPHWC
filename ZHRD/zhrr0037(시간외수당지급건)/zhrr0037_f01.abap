*&---------------------------------------------------------------------*
*&  Include           ZHRR0037_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  SET_FCAT
*&---------------------------------------------------------------------*
FORM set_fcat .

  DATA : ls_fcat TYPE slis_fieldcat_alv.

  CLEAR : gt_fcat[].

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'ENAME'.
  ls_fcat-seltext_l = '이름'.
  ls_fcat-seltext_m = '이름'.
  ls_fcat-seltext_s = '이름'.
  ls_fcat-outputlen = 20.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'PERNR'.
  ls_fcat-seltext_l = '사번'.
  ls_fcat-seltext_m = '사번'.
  ls_fcat-seltext_s = '사번'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LGART'.
  ls_fcat-seltext_l = '임금유형'.
  ls_fcat-seltext_m = '임금유형'.
  ls_fcat-seltext_s = '임금유형'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BEGDA'.
  ls_fcat-seltext_l = '시작일'.
  ls_fcat-seltext_m = '시작일'.
  ls_fcat-seltext_s = '시작일'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'ENDDA'.
  ls_fcat-seltext_l = '종료일'.
  ls_fcat-seltext_m = '종료일'.
  ls_fcat-seltext_s = '종료일'.
  ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BETRG'.
  ls_fcat-seltext_l = '금액'.
  ls_fcat-seltext_m = '금액'.
  ls_fcat-seltext_s = '금액'.
  ls_fcat-outputlen = 15.
  ls_fcat-cfieldname = 'WAERS'.
  ls_fcat-do_sum = 'X'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'WAERS'.
  ls_fcat-seltext_l = '통화단위'.
  ls_fcat-seltext_m = '통화단위'.
  ls_fcat-seltext_s = '통화'.
  ls_fcat-outputlen = 8.
  APPEND ls_fcat TO gt_fcat.

ENDFORM.                    " SET_FCAT

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data .

  REFRESH gt_pay.
  CLEAR gt_pay.

  SELECT pernr lgart begda endda betrg waers
    INTO CORRESPONDING FIELDS OF TABLE gt_pay
    FROM pa0015
    WHERE pernr = pernr-pernr
      AND lgart IN s_lgart
      AND begda <= gv_to
      AND endda >= gv_from.

  LOOP AT gt_pay.
    CLEAR gt_data.
    gt_data-ename = pernr-ename.
    gt_data-pernr = gt_pay-pernr.
    gt_data-lgart = gt_pay-lgart.
    gt_data-begda = gt_pay-begda.
    gt_data-endda = gt_pay-endda.
    gt_data-betrg = gt_pay-betrg.
    gt_data-waers = gt_pay-waers.
    APPEND gt_data.
  ENDLOOP.

ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  ZDISPLAY
*&---------------------------------------------------------------------*
FORM zdisplay .
  gv_repid = sy-repid.             "현재 운영되는 program id
  gs_layout-zebra = 'X'.
  gs_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = gv_repid
      i_callback_pf_status_set = gv_pf_status
      i_callback_user_command  = gv_user_command
      is_layout                = gs_layout
      it_fieldcat              = gt_fcat[]
      i_save                   = 'A'
    TABLES
      t_outtab                 = gt_data.

ENDFORM.                    " ZDISPLAY

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&---------------------------------------------------------------------*
FORM user_command  USING    r_ucomm   LIKE  sy-ucomm
                            rs_selfield TYPE  slis_selfield.
  CASE r_ucomm.
    WHEN '&F03' OR '&F15' OR '&F12'.
      SET SCREEN 0.
  ENDCASE.

ENDFORM.                    " USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  SET_STATUS
*&---------------------------------------------------------------------*
FORM set_status USING rt_extab TYPE slis_t_extab .          "#EC *

  SET PF-STATUS 'STANDARD' OF PROGRAM 'SAPLKKBL'
                            EXCLUDING rt_extab.

ENDFORM.                    "set_status

*&---------------------------------------------------------------------*
*&      Form  SORT_TABLE
*&---------------------------------------------------------------------*
FORM sort_table .

  SORT gt_data BY pernr begda lgart.

ENDFORM.                    " SORT_TABLE

*&---------------------------------------------------------------------*
*&      Form  SET_PERIOD
*&---------------------------------------------------------------------*
FORM set_period.

  gv_from = s_date-low.
  gv_to = s_date-high.
  IF gv_to IS INITIAL.
    gv_to = gv_from.
  ENDIF.

  pnpbegda = gv_from.
  pnpendda = gv_to.
  pn-begda = gv_from.
  pn-endda = gv_to.

ENDFORM.                    " SET_PERIOD

*&---------------------------------------------------------------------*
*&      Form  HIDE_KEYDATE
*&---------------------------------------------------------------------*
FORM hide_keydate.

  LOOP AT SCREEN.
    IF screen-name CP '*BEGDA*'
    OR screen-name CP '*ENDDA*'
    OR screen-name CP '*PNPTIM*'
    OR screen-name CP '*PNPDATE*'
    OR screen-name CP '*KEYDT*'
    OR screen-name CP '*KEYDA*'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " HIDE_KEYDATE

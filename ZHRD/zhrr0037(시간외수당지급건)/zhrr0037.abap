*&---------------------------------------------------------------------*
*& Report  ZHRR0037
************************************************************************
*& Program ID  :
*& Title       :  시간외수당지급건
*& Created By  :
*& Created On  :
*& Frequency   :
*& Category    :  conversion program
*& Description :
************************************************************************
*& Change History
************************************************************************
*& Mod. # |Date       |Developer |Description (Reason)
************************************************************************
************************************************************************
REPORT  zhrr0037  MESSAGE-ID zhrm01 NO STANDARD PAGE HEADING LINE-SIZE 255.

*----------------------------------------------------------------------*
* INCLUDE.
*----------------------------------------------------------------------*
INCLUDE zhrr0037_top.
INCLUDE zhrr0037_f01.


*----------------------------------------------------------------------
*   INITIALIZATION.
*----------------------------------------------------------------------
INITIALIZATION.

* 사용자의 국가그룹핑/ 국가그룹핑에 따른 인사영역
  PERFORM get_user_mol_werks  TABLES   gt_user_werks
                              CHANGING gv_user_molga.

  LOOP AT gt_user_werks.
    pnpwerks-sign = 'I'.
    pnpwerks-option = 'EQ'.
    pnpwerks-low = gt_user_werks-persa.
    APPEND pnpwerks.
  ENDLOOP.

  gv_dtxt = '조회기간'.
  gv_ltxt = '임금유형'.
  s_date-sign = 'I'.
  s_date-option = 'BT'.
  CONCATENATE sy-datum(6) '01' INTO s_date-low.
  s_date-high = sy-datum.
  APPEND s_date.

  pnpbegda = s_date-low.
  pnpendda = s_date-high.

AT SELECTION-SCREEN OUTPUT.
  PERFORM hide_keydate.

AT SELECTION-SCREEN.
  PERFORM set_period.

*----------------------------------------------------------------------*
* START-OF-SELECTION.
*----------------------------------------------------------------------*
START-OF-SELECTION.

** field catalog
  PERFORM set_fcat.

  pnp-sw-ignorelockedrecords = 'N'.  "  잠금 DATA도 조회 가능
  PERFORM set_period.

*----------------------------------------------------------------------*
* PERNR EVENT.
*----------------------------------------------------------------------*
GET pernr.

* 작업 STATUS 표시
  CONCATENATE pernr-pernr '(' pernr-ename ')' '조회 중'
              INTO gv_status_text SEPARATED BY space.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      text = gv_status_text.

  PERFORM get_data.

*----------------------------------------------------------------------*
* END-OF-SELECTION.
*----------------------------------------------------------------------*
END-OF-SELECTION.
  PERFORM sort_table.
  CLEAR l_cnt.
  DESCRIBE TABLE gt_data LINES l_cnt.
  IF l_cnt = 0.
    MESSAGE i029.
  ELSE.
    MESSAGE s030 WITH l_cnt.

    PERFORM zdisplay.

  ENDIF.

***********************************************************************
*    AT USER-COMMAND
***********************************************************************
AT USER-COMMAND.
  PERFORM user_command USING sy-ucomm    rs_selfield.     " SET_SPECIAL_STATUS.

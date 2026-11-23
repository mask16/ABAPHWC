*&---------------------------------------------------------------------*
*&  Include           ZHRR0037_TOP
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
* INFOTYPE 선언
*----------------------------------------------------------------------*
INCLUDE zhr_common_inc.

TYPE-POOLS: slis.

TABLES : pernr.

DATA: gt_fcat     TYPE slis_t_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv,
      gv_repid    LIKE sy-repid,
      rs_selfield TYPE slis_selfield.

DATA gv_lgart LIKE pa0015-lgart.

SELECTION-SCREEN BEGIN OF BLOCK bper WITH FRAME TITLE gv_dtxt.
SELECT-OPTIONS s_date FOR sy-datum OBLIGATORY NO-EXTENSION.
SELECTION-SCREEN END OF BLOCK bper.

SELECTION-SCREEN BEGIN OF BLOCK blga WITH FRAME TITLE gv_ltxt.
SELECT-OPTIONS s_lgart FOR gv_lgart.
SELECTION-SCREEN END OF BLOCK blga.

DATA : BEGIN OF gt_data OCCURS 0,
              ename      LIKE p0001-ename,    "이름
              pernr      LIKE p0001-pernr,    "사번
              lgart      LIKE pa0015-lgart,   "임금유형
              begda      LIKE pa0015-begda,   "시작일
              endda      LIKE pa0015-endda,   "종료일
              betrg      LIKE pa0015-betrg,   "금액
              waers      LIKE pa0015-waers,   "통화단위
       END OF gt_data.

DATA : BEGIN OF gt_pay OCCURS 0,
              pernr      LIKE p0001-pernr,
              lgart      LIKE pa0015-lgart,
              begda      LIKE pa0015-begda,
              endda      LIKE pa0015-endda,
              betrg      LIKE pa0015-betrg,
              waers      LIKE pa0015-waers,
       END OF gt_pay.

DATA : gv_pf_status     TYPE slis_formname VALUE 'SET_STATUS',
       gv_user_command  TYPE slis_formname VALUE 'USER_COMMAND'.

DATA : gv_from         LIKE pa0015-begda,
       gv_to           LIKE pa0015-endda,
       l_cnt           TYPE i,
       gv_status_text(100).

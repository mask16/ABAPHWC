*&---------------------------------------------------------------------*
*& Include ZSDR5054_S01
*&---------------------------------------------------------------------*
*& 기준월 : ZSDR0410 PA_SPMON
*& 플랜트/자재/자재유형 : ZSDR0065
*& 납품처/MRP관리자 : ZSDR0410
*&---------------------------------------------------------------------*

DATA: gv_werks TYPE werks_d,
      gv_mtart TYPE mtart,
      gv_matnr TYPE matnr,
      gv_dispo TYPE dispo,
      gv_kunnr TYPE kunnr.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-b01.
PARAMETERS p_spmon TYPE zsdt0400-spmon OBLIGATORY.
SELECT-OPTIONS so_werks FOR gv_werks OBLIGATORY DEFAULT '1010'.
SELECT-OPTIONS so_mtart FOR gv_mtart DEFAULT 'FERT'.
SELECT-OPTIONS so_matnr FOR gv_matnr.
SELECT-OPTIONS so_dispo FOR gv_dispo.
SELECT-OPTIONS so_kunnr FOR gv_kunnr.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b99 WITH FRAME TITLE text-b99.
PARAMETERS p_vari TYPE disvariant-variant.
SELECTION-SCREEN END OF BLOCK b99.

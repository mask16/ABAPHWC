*&---------------------------------------------------------------------*
*& Include ZSDR5054_T01
*&---------------------------------------------------------------------*
*& 판매계획 : ZSDR0400 이 생성하고 ZSDR0410 이 수정하는 ZSDT0400
*& 수주/생산/출하/재고 : ZSDR0065 수불 계산을 조회월에 맞춰 사용
*& 화면 열은 첨부 양식과 같다.
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_data,
         matnr        TYPE matnr,
         spmon        TYPE spmon,
         werks        TYPE werks_d,
         dispo_txt    TYPE char40,
         name1        TYPE name1_gp,
         maktx        TYPE maktx,
         plan_qty     TYPE kwmeng,
         open_qty     TYPE kwmeng,
         ord_qty      TYPE kwmeng,
         ord_sum      TYPE kwmeng,
         gi_qty       TYPE kwmeng,
         ord_rem      TYPE kwmeng,
         gr_qty       TYPE kwmeng,
         stock_qty    TYPE labst,
         rate_prod    TYPE char10,
         rate_plan_ord TYPE char10,
         rate_plan_gi TYPE char10,
         rate_ord_gi  TYPE char10,
         dispo        TYPE dispo,
         kunnr        TYPE kunnr,
         meins        TYPE meins,
         celltab      TYPE lvc_t_styl,
       END OF ty_data.

TYPES: BEGIN OF ty_ord,
         matnr  TYPE matnr,
         werks  TYPE werks_d,
         vbeln  TYPE vbeln_va,
         posnr  TYPE posnr_va,
         kwmeng TYPE kwmeng,
       END OF ty_ord.

TYPES: BEGIN OF ty_del,
         vbeln TYPE vbeln_va,
         posnr TYPE posnr_va,
         lfimg TYPE lfimg,
       END OF ty_del.

TYPES: BEGIN OF ty_mov,
         matnr TYPE matnr,
         werks TYPE werks_d,
         budat TYPE budat,
         bwart TYPE bwart,
         shkzg TYPE shkzg,
         menge TYPE menge_d,
       END OF ty_mov.

TYPES: BEGIN OF ty_mard,
         matnr TYPE matnr,
         werks TYPE werks_d,
         labst TYPE labst,
       END OF ty_mard.

DATA: gt_data TYPE STANDARD TABLE OF ty_data,
      gs_data TYPE ty_data.

DATA: gv_spdat TYPE zsdt0400-spdat,
      gv_first TYPE datum,
      gv_last  TYPE datum,
      gv_to    TYPE datum.

CLASS lcl_event_receiver DEFINITION DEFERRED.

DATA: gv_ok_code        TYPE sy-ucomm,
      gv_save_ok        TYPE sy-ucomm,
      gv_repid          TYPE sy-repid,
      gv_cntr_0100      TYPE REF TO cl_gui_custom_container,
      gv_grid_0100      TYPE REF TO cl_gui_alv_grid,
      gv_event_receiver TYPE REF TO lcl_event_receiver,
      gs_variant        TYPE disvariant,
      gs_layout         TYPE lvc_s_layo,
      gt_fcat           TYPE lvc_t_fcat,
      gs_fcat           TYPE lvc_s_fcat,
      g_refto           TYPE REF TO data,
      gt_sort           TYPE lvc_t_sort,
      gs_sort           TYPE lvc_s_sort,
      gt_filter         TYPE lvc_t_filt,
      gt_exclude        TYPE ui_functions.

FIELD-SYMBOLS <fcat> TYPE lvc_t_fcat.

DATA: r_gr TYPE RANGE OF bwart,
      r_gi TYPE RANGE OF bwart.

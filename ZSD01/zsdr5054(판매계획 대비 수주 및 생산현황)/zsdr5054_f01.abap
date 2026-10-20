*&---------------------------------------------------------------------*
*& Include ZSDR5054_F01
*&---------------------------------------------------------------------*
*& 판매계획     : ZSDR0410 과 동일. ZSDT0401 최종 SPDAT, ZSDT0400-SPMNG
*& 당월 수주량      : 조회월 오더수량. VBAK-TRVOG = 0
*& 전월 미출하 수주량: 조회월 이전, 납품 미완료 오더수량 (납품수량 차감 없음)
*& 수주 합계    : 미출하 + 당월수주
*& 출하량       : 601/602, 조회월 1일 ~ 전일 (과거월은 말일)
*& 수주 잔량    : 수주합계 - 출하량
*& 당월 생산량  : 101/102/131/132, 같은 기간. ZSDR0065 생산(구매)입고
*& 재고량       : 전일 가용재고. ZSDR0065 기말재고
*& 비율         : 열 이름 기준, 반올림, 분모 0 이면 0%
*&---------------------------------------------------------------------*

FORM init_screen.
  IF p_spmon IS INITIAL.
    p_spmon = sy-datum(6).
  ENDIF.
ENDFORM.

FORM f4_variant.
  DATA ls_vari TYPE disvariant.
  ls_vari-report = sy-repid.
  CALL FUNCTION 'LVC_VARIANT_F4'
    EXPORTING
      is_variant = ls_vari
      i_save     = 'A'
    IMPORTING
      es_variant = ls_vari
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2.
  IF sy-subrc = 0.
    p_vari = ls_vari-variant.
  ENDIF.
ENDFORM.

FORM set_date_range.
  CONCATENATE p_spmon '01' INTO gv_first.
  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      day_in            = gv_first
    IMPORTING
      last_day_of_month = gv_last
    EXCEPTIONS
      day_in_no_date    = 1
      OTHERS            = 2.
  IF sy-subrc <> 0.
    gv_last = gv_first.
  ENDIF.
  gv_to = sy-datum - 1.
  IF gv_to > gv_last.
    gv_to = gv_last.
  ENDIF.
ENDFORM.

FORM set_bwart.
  DATA ls_bwart LIKE LINE OF r_gr.
  REFRESH: r_gr, r_gi.
  ls_bwart-sign   = 'I'.
  ls_bwart-option = 'EQ'.
  ls_bwart-low = '101'. APPEND ls_bwart TO r_gr.
  ls_bwart-low = '102'. APPEND ls_bwart TO r_gr.
  ls_bwart-low = '131'. APPEND ls_bwart TO r_gr.
  ls_bwart-low = '132'. APPEND ls_bwart TO r_gr.
  ls_bwart-low = '601'. APPEND ls_bwart TO r_gi.
  ls_bwart-low = '602'. APPEND ls_bwart TO r_gi.
ENDFORM.

FORM get_data.
  REFRESH gt_data.
  PERFORM set_bwart.
  PERFORM get_plan.
  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM fill_filter.
  PERFORM fill_order.
  PERFORM fill_stock.
  PERFORM fill_rate.
ENDFORM.

*& ZSDR0410: ZSDT0401 의 조회월 최종 SPDAT.
*& 계획수량은 ZSDT0400-SPMNG. 조회월 + 자재 + 플랜트 합계.
FORM get_plan.
  TYPES: BEGIN OF ty_plan,
           matnr TYPE matnr,
           werks TYPE werks_d,
           kunnr TYPE kunnr,
           spmng TYPE zsdt0400-spmng,
           meins TYPE meins,
         END OF ty_plan.
  DATA: lt_plan TYPE STANDARD TABLE OF ty_plan,
        ls_plan TYPE ty_plan,
        lt_best TYPE STANDARD TABLE OF ty_data,
        ls_best TYPE ty_data,
        lv_tabix TYPE sy-tabix.

  SELECT MAX( spdat )
    FROM zsdt0401
    INTO gv_spdat
    WHERE spmon = p_spmon.
  IF gv_spdat IS INITIAL.
    RETURN.
  ENDIF.

  SELECT matnr werks kunnr spmng meins
    FROM zsdt0400
    INTO TABLE lt_plan
    WHERE spdat = gv_spdat
      AND spmon = p_spmon
      AND matnr IN so_matnr
      AND werks IN so_werks
      AND kunnr IN so_kunnr.

  LOOP AT lt_plan INTO ls_plan.
    READ TABLE gt_data INTO gs_data
      WITH KEY matnr = ls_plan-matnr
               werks = ls_plan-werks.
    IF sy-subrc <> 0.
      CLEAR gs_data.
      gs_data-matnr    = ls_plan-matnr.
      gs_data-werks    = ls_plan-werks.
      gs_data-spmon    = p_spmon.
      gs_data-kunnr    = ls_plan-kunnr.
      gs_data-meins    = ls_plan-meins.
      IF gs_data-meins IS INITIAL.
        gs_data-meins = 'KG'.
      ENDIF.
      gs_data-plan_qty = ls_plan-spmng.
      APPEND gs_data TO gt_data.
      CLEAR ls_best.
      ls_best-matnr    = ls_plan-matnr.
      ls_best-werks    = ls_plan-werks.
      ls_best-kunnr    = ls_plan-kunnr.
      ls_best-plan_qty = ls_plan-spmng.
      APPEND ls_best TO lt_best.
    ELSE.
      lv_tabix = sy-tabix.
      gs_data-plan_qty = gs_data-plan_qty + ls_plan-spmng.
      READ TABLE lt_best INTO ls_best
        WITH KEY matnr = ls_plan-matnr
                 werks = ls_plan-werks.
      IF sy-subrc = 0 AND ls_plan-spmng > ls_best-plan_qty.
        gs_data-kunnr    = ls_plan-kunnr.
        ls_best-kunnr    = ls_plan-kunnr.
        ls_best-plan_qty = ls_plan-spmng.
        MODIFY lt_best FROM ls_best INDEX sy-tabix.
      ENDIF.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM fill_filter.
  TYPES: BEGIN OF ty_mara,
           matnr TYPE matnr,
           mtart TYPE mtart,
         END OF ty_mara,
         BEGIN OF ty_makt,
           matnr TYPE matnr,
           maktx TYPE maktx,
         END OF ty_makt,
         BEGIN OF ty_kna,
           kunnr TYPE kunnr,
           name1 TYPE name1_gp,
         END OF ty_kna,
         BEGIN OF ty_marc,
           matnr TYPE matnr,
           werks TYPE werks_d,
           dispo TYPE dispo,
         END OF ty_marc,
         BEGIN OF ty_t024,
           werks TYPE werks_d,
           dispo TYPE dispo,
           dsnam TYPE dsnam,
         END OF ty_t024.
  DATA: lt_mara TYPE SORTED TABLE OF ty_mara WITH UNIQUE KEY matnr,
        ls_mara TYPE ty_mara,
        lt_makt TYPE SORTED TABLE OF ty_makt WITH UNIQUE KEY matnr,
        ls_makt TYPE ty_makt,
        lt_kna  TYPE SORTED TABLE OF ty_kna WITH UNIQUE KEY kunnr,
        ls_kna  TYPE ty_kna,
        lt_marc TYPE SORTED TABLE OF ty_marc WITH UNIQUE KEY matnr werks,
        ls_marc TYPE ty_marc,
        lt_t024 TYPE SORTED TABLE OF ty_t024 WITH UNIQUE KEY werks dispo,
        ls_t024 TYPE ty_t024,
        lv_tabix TYPE sy-tabix,
        lv_wrap  TYPE char40.

  CHECK gt_data[] IS NOT INITIAL.

  SELECT matnr mtart
    FROM mara
    INTO TABLE lt_mara
    FOR ALL ENTRIES IN gt_data
    WHERE matnr = gt_data-matnr.

  SELECT matnr maktx
    FROM makt
    INTO TABLE lt_makt
    FOR ALL ENTRIES IN gt_data
    WHERE matnr = gt_data-matnr
      AND spras = sy-langu.

  SELECT kunnr name1
    FROM kna1
    INTO TABLE lt_kna
    FOR ALL ENTRIES IN gt_data
    WHERE kunnr = gt_data-kunnr.

  SELECT matnr werks dispo
    FROM marc
    INTO TABLE lt_marc
    FOR ALL ENTRIES IN gt_data
    WHERE matnr = gt_data-matnr
      AND werks = gt_data-werks.

  SELECT werks dispo dsnam
    FROM t024d
    INTO TABLE lt_t024
    WHERE werks IN so_werks.

  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    READ TABLE lt_mara INTO ls_mara WITH KEY matnr = gs_data-matnr.
    IF so_mtart[] IS NOT INITIAL.
      IF sy-subrc <> 0 OR ls_mara-mtart NOT IN so_mtart.
        CLEAR gs_data-matnr.
        MODIFY gt_data FROM gs_data INDEX lv_tabix.
        CONTINUE.
      ENDIF.
    ENDIF.
    READ TABLE lt_makt INTO ls_makt WITH KEY matnr = gs_data-matnr.
    IF sy-subrc = 0.
      gs_data-maktx = ls_makt-maktx.
    ENDIF.
    READ TABLE lt_kna INTO ls_kna WITH KEY kunnr = gs_data-kunnr.
    IF sy-subrc = 0.
      gs_data-name1 = ls_kna-name1.
    ENDIF.
    READ TABLE lt_marc INTO ls_marc
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks.
    IF sy-subrc = 0.
      gs_data-dispo = ls_marc-dispo.
    ENDIF.
    IF so_dispo[] IS NOT INITIAL AND gs_data-dispo NOT IN so_dispo.
      CLEAR gs_data-matnr.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
      CONTINUE.
    ENDIF.
    IF gs_data-dispo IS NOT INITIAL.
      READ TABLE lt_t024 INTO ls_t024
        WITH KEY werks = gs_data-werks
                 dispo = gs_data-dispo.
      IF sy-subrc = 0.
        CONDENSE ls_t024-dsnam.
        CONCATENATE '(' ls_t024-dsnam ')' INTO lv_wrap.
        CONCATENATE gs_data-dispo lv_wrap INTO gs_data-dispo_txt
          SEPARATED BY space.
      ENDIF.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.
  DELETE gt_data WHERE matnr IS INITIAL.
ENDFORM.

*& 전월 미출하 = 조회월 이전 오더수량. 당월 수주 = 조회월 오더수량.
*& 자재인덱스 VAPMA 로 읽고, 자재+플랜트별로 합산한다.
FORM fill_order.
  TYPES: BEGIN OF ty_qty,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           kwmeng TYPE kwmeng,
         END OF ty_qty,
         BEGIN OF ty_sum,
           matnr TYPE matnr,
           werks TYPE werks_d,
           menge TYPE kwmeng,
         END OF ty_sum.
  DATA: lt_pack TYPE STANDARD TABLE OF ty_data,
        lt_qty  TYPE STANDARD TABLE OF ty_qty,
        ls_qty  TYPE ty_qty,
        lt_open TYPE SORTED TABLE OF ty_sum WITH UNIQUE KEY matnr werks,
        lt_ord  TYPE SORTED TABLE OF ty_sum WITH UNIQUE KEY matnr werks,
        ls_sum  TYPE ty_sum,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i,
        lv_tabix TYPE sy-tabix.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  DESCRIBE TABLE gt_data LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 399.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_pack.
    APPEND LINES OF gt_data FROM lv_from TO lv_to TO lt_pack.

    REFRESH lt_qty.
    SELECT a~matnr a~werks b~kwmeng
      FROM vapma AS a
      INNER JOIN vbap AS b
        ON b~vbeln = a~vbeln
       AND b~posnr = a~posnr
      INNER JOIN vbak AS c
        ON c~vbeln = a~vbeln
      INNER JOIN vbup AS f
        ON f~vbeln = a~vbeln
       AND f~posnr = a~posnr
      INTO TABLE lt_qty
      FOR ALL ENTRIES IN lt_pack
      WHERE a~matnr = lt_pack-matnr
        AND a~werks = lt_pack-werks
        AND c~erdat < gv_first
        AND c~trvog = '0'
        AND b~abgru = space
        AND f~lfsta <> 'C'.
    LOOP AT lt_qty INTO ls_qty.
      READ TABLE lt_open INTO ls_sum
        WITH KEY matnr = ls_qty-matnr
                 werks = ls_qty-werks.
      IF sy-subrc = 0.
        ls_sum-menge = ls_sum-menge + ls_qty-kwmeng.
        MODIFY lt_open FROM ls_sum INDEX sy-tabix.
      ELSE.
        ls_sum-matnr = ls_qty-matnr.
        ls_sum-werks = ls_qty-werks.
        ls_sum-menge = ls_qty-kwmeng.
        INSERT ls_sum INTO TABLE lt_open.
      ENDIF.
    ENDLOOP.

    REFRESH lt_qty.
    SELECT a~matnr a~werks b~kwmeng
      FROM vapma AS a
      INNER JOIN vbap AS b
        ON b~vbeln = a~vbeln
       AND b~posnr = a~posnr
      INNER JOIN vbak AS c
        ON c~vbeln = a~vbeln
      INTO TABLE lt_qty
      FOR ALL ENTRIES IN lt_pack
      WHERE a~matnr = lt_pack-matnr
        AND a~werks = lt_pack-werks
        AND c~erdat BETWEEN gv_first AND gv_last
        AND c~trvog = '0'
        AND b~abgru = space.
    LOOP AT lt_qty INTO ls_qty.
      READ TABLE lt_ord INTO ls_sum
        WITH KEY matnr = ls_qty-matnr
                 werks = ls_qty-werks.
      IF sy-subrc = 0.
        ls_sum-menge = ls_sum-menge + ls_qty-kwmeng.
        MODIFY lt_ord FROM ls_sum INDEX sy-tabix.
      ELSE.
        ls_sum-matnr = ls_qty-matnr.
        ls_sum-werks = ls_qty-werks.
        ls_sum-menge = ls_qty-kwmeng.
        INSERT ls_sum INTO TABLE lt_ord.
      ENDIF.
    ENDLOOP.

    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    CLEAR: gs_data-open_qty, gs_data-ord_qty.
    READ TABLE lt_open INTO ls_sum
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks.
    IF sy-subrc = 0.
      gs_data-open_qty = ls_sum-menge.
    ENDIF.
    READ TABLE lt_ord INTO ls_sum
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks.
    IF sy-subrc = 0.
      gs_data-ord_qty = ls_sum-menge.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.
ENDFORM.

FORM fill_stock.
  TYPES: BEGIN OF ty_stk,
           matnr TYPE matnr,
           werks TYPE werks_d,
           labst TYPE labst,
           grqty TYPE kwmeng,
           giqty TYPE kwmeng,
         END OF ty_stk.
  DATA: lt_pack TYPE STANDARD TABLE OF ty_data,
        lt_mard TYPE STANDARD TABLE OF ty_mard,
        ls_mard TYPE ty_mard,
        lt_mov  TYPE STANDARD TABLE OF ty_mov,
        ls_mov  TYPE ty_mov,
        lt_stk  TYPE SORTED TABLE OF ty_stk WITH UNIQUE KEY matnr werks,
        ls_stk  TYPE ty_stk,
        r_bw    TYPE RANGE OF bwart,
        ls_bw   LIKE LINE OF r_bw,
        lv_after TYPE datum,
        lv_yest  TYPE datum,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i,
        lv_tabix TYPE sy-tabix.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  r_bw[] = r_gr[].
  LOOP AT r_gi INTO ls_bw.
    APPEND ls_bw TO r_bw.
  ENDLOOP.

  lv_yest = sy-datum - 1.
  IF gv_to >= lv_yest.
    lv_after = sy-datum.
  ELSE.
    lv_after = gv_to + 1.
  ENDIF.

  SELECT matnr werks labst
    FROM mard
    INTO TABLE lt_mard
    FOR ALL ENTRIES IN gt_data
    WHERE matnr = gt_data-matnr
      AND werks = gt_data-werks.

  LOOP AT lt_mard INTO ls_mard.
    READ TABLE lt_stk INTO ls_stk
      WITH KEY matnr = ls_mard-matnr
               werks = ls_mard-werks.
    IF sy-subrc = 0.
      ls_stk-labst = ls_stk-labst + ls_mard-labst.
      MODIFY lt_stk FROM ls_stk INDEX sy-tabix.
    ELSE.
      CLEAR ls_stk.
      ls_stk-matnr = ls_mard-matnr.
      ls_stk-werks = ls_mard-werks.
      ls_stk-labst = ls_mard-labst.
      INSERT ls_stk INTO TABLE lt_stk.
    ENDIF.
  ENDLOOP.

  DESCRIBE TABLE gt_data LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 399.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_pack.
    APPEND LINES OF gt_data FROM lv_from TO lv_to TO lt_pack.

    REFRESH lt_mov.
    IF gv_to >= gv_first.
      SELECT b~matnr b~werks a~budat b~bwart b~shkzg b~menge
        FROM mseg AS b
        INNER JOIN mkpf AS a
          ON a~mblnr = b~mblnr
         AND a~mjahr = b~mjahr
        INTO TABLE lt_mov
        FOR ALL ENTRIES IN lt_pack
        WHERE b~matnr = lt_pack-matnr
          AND b~werks = lt_pack-werks
          AND b~bwart IN r_bw
          AND a~budat BETWEEN gv_first AND gv_to.
    ENDIF.

    SELECT b~matnr b~werks a~budat b~bwart b~shkzg b~menge
      FROM mseg AS b
      INNER JOIN mkpf AS a
        ON a~mblnr = b~mblnr
       AND a~mjahr = b~mjahr
      APPENDING TABLE lt_mov
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks = lt_pack-werks
        AND a~budat >= lv_after.

    LOOP AT lt_mov INTO ls_mov.
      READ TABLE lt_stk INTO ls_stk
        WITH KEY matnr = ls_mov-matnr
                 werks = ls_mov-werks.
      IF sy-subrc <> 0.
        CLEAR ls_stk.
        ls_stk-matnr = ls_mov-matnr.
        ls_stk-werks = ls_mov-werks.
        INSERT ls_stk INTO TABLE lt_stk.
        READ TABLE lt_stk INTO ls_stk
          WITH KEY matnr = ls_mov-matnr
                   werks = ls_mov-werks.
      ENDIF.
      IF ls_mov-budat > gv_to.
        IF ls_mov-shkzg = 'S'.
          ls_stk-labst = ls_stk-labst - ls_mov-menge.
        ELSE.
          ls_stk-labst = ls_stk-labst + ls_mov-menge.
        ENDIF.
      ELSEIF ls_mov-bwart IN r_gr.
        IF ls_mov-shkzg = 'S'.
          ls_stk-grqty = ls_stk-grqty + ls_mov-menge.
        ELSE.
          ls_stk-grqty = ls_stk-grqty - ls_mov-menge.
        ENDIF.
      ELSEIF ls_mov-bwart IN r_gi.
        IF ls_mov-shkzg = 'H'.
          ls_stk-giqty = ls_stk-giqty + ls_mov-menge.
        ELSE.
          ls_stk-giqty = ls_stk-giqty - ls_mov-menge.
        ENDIF.
      ENDIF.
      MODIFY lt_stk FROM ls_stk INDEX sy-tabix.
    ENDLOOP.

    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    CLEAR: gs_data-gr_qty, gs_data-gi_qty, gs_data-stock_qty.
    READ TABLE lt_stk INTO ls_stk
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks.
    IF sy-subrc = 0.
      gs_data-gr_qty    = ls_stk-grqty.
      gs_data-gi_qty    = ls_stk-giqty.
      gs_data-stock_qty = ls_stk-labst.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.
ENDFORM.

FORM fill_rate.
  DATA lv_tabix TYPE sy-tabix.
  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    gs_data-ord_sum = gs_data-open_qty + gs_data-ord_qty.
    gs_data-ord_rem = gs_data-ord_sum - gs_data-gi_qty.
    PERFORM calc_rate USING gs_data-gr_qty  gs_data-ord_qty
                      CHANGING gs_data-rate_prod.
    PERFORM calc_rate USING gs_data-ord_qty gs_data-plan_qty
                      CHANGING gs_data-rate_plan_ord.
    PERFORM calc_rate USING gs_data-gi_qty  gs_data-plan_qty
                      CHANGING gs_data-rate_plan_gi.
    PERFORM calc_rate USING gs_data-gi_qty  gs_data-ord_sum
                      CHANGING gs_data-rate_ord_gi.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.
ENDFORM.

FORM calc_rate USING p_num p_den CHANGING p_rate.
  DATA: lv_num TYPE p DECIMALS 3,
        lv_den TYPE p DECIMALS 3,
        lv_rate TYPE i.
  CLEAR p_rate.
  lv_num = p_num.
  lv_den = p_den.
  IF lv_den = 0.
    p_rate = '0%'.
    RETURN.
  ENDIF.
  lv_rate = ( lv_num * 1000 / lv_den + 5 ) / 10.
  p_rate = lv_rate.
  CONDENSE p_rate.
  CONCATENATE p_rate '%' INTO p_rate.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CALL_SCREEN_0100
*& ZSDR0400 CALL_SCREEN_0100 과 동일
*&---------------------------------------------------------------------*
FORM call_screen_0100.
  PERFORM create_object_0100.
  PERFORM set_layout_grid_0100.
  PERFORM set_exclude_grid_button_0100 USING 'GT_EXCLUDE'.
  PERFORM set_fcat_grid_0100.
  PERFORM set_sort_grid_0100.
  PERFORM display_grid USING gv_grid_0100
                             gs_layout
                             gt_data
                             gt_fcat
                             gt_sort.
  PERFORM set_attribute_grid_0100.
  PERFORM refresh_grid USING gv_grid_0100
                             gs_layout.
  CALL SCREEN '0100'.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CREATE_OBJECT_0100
*&---------------------------------------------------------------------*
FORM create_object_0100.
  CREATE OBJECT gv_cntr_0100
    EXPORTING
      container_name = 'CNT_100'.
  CREATE OBJECT gv_grid_0100
    EXPORTING
      i_parent      = gv_cntr_0100
      i_appl_events = 'X'.
  gv_repid = sy-repid.
  gs_variant-report  = gv_repid.
  gs_variant-variant = p_vari.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_LAYOUT_GRID_0100
*&---------------------------------------------------------------------*
FORM set_layout_grid_0100.
  gs_layout-sel_mode   = 'A'.
  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-smalltitle = 'X'.
  gs_layout-grid_title = '판매계획 대비 수주 및 생산현황 (단위: KG)'.
  gs_layout-stylefname = 'CELLTAB'.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_EXCLUDE_GRID_BUTTON_0100
*&---------------------------------------------------------------------*
FORM set_exclude_grid_button_0100 USING p_tabname.
  DATA l_tab_name LIKE feld-name.
  FIELD-SYMBOLS <ltable> TYPE ui_functions.
  CONCATENATE p_tabname '[]' INTO l_tab_name.
  ASSIGN (l_tab_name) TO <ltable>.
  PERFORM add_exclude_toolbar_button
    TABLES <ltable>
    USING : cl_gui_alv_grid=>mc_fc_loc_undo,
            cl_gui_alv_grid=>mc_fc_help,
            cl_gui_alv_grid=>mc_fc_info,
            cl_gui_alv_grid=>mc_fc_loc_copy,
            cl_gui_alv_grid=>mc_fc_loc_copy_row,
            cl_gui_alv_grid=>mc_fc_loc_cut,
            cl_gui_alv_grid=>mc_fc_loc_delete_row,
            cl_gui_alv_grid=>mc_fc_loc_insert_row,
            cl_gui_alv_grid=>mc_fc_loc_move_row,
            cl_gui_alv_grid=>mc_fc_loc_append_row,
            cl_gui_alv_grid=>mc_fc_loc_paste,
            cl_gui_alv_grid=>mc_fc_loc_paste_new_row,
            cl_gui_alv_grid=>mc_fc_print,
            cl_gui_alv_grid=>mc_fc_refresh,
            cl_gui_alv_grid=>mc_fc_word_processor.
ENDFORM.

FORM add_exclude_toolbar_button TABLES p_table
                                 USING p_value.
  DATA l_exclude TYPE ui_func.
  l_exclude = p_value.
  APPEND l_exclude TO p_table.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_FCAT_GRID_0100
*&---------------------------------------------------------------------*
FORM set_fcat_grid_0100.

  CLEAR: gt_fcat.

  GET REFERENCE OF gt_fcat INTO g_refto.
  ASSIGN g_refto->* TO <fcat>.

  PERFORM make_fieldcat USING :

    'S' 'FIELDNAME'   'MATNR',
    ' ' 'REF_FIELD'   'MATNR',
    ' ' 'REF_TABLE'   'MARA',
    'E' 'COLTEXT'     '자재코드',

    'S' 'FIELDNAME'   'SPMON',
    ' ' 'REF_FIELD'   'SPMON',
    ' ' 'REF_TABLE'   'ZSDT0400',
    'E' 'COLTEXT'     '기준 월',

    'S' 'FIELDNAME'   'DISPO_TXT',
    'E' 'COLTEXT'     'MRP관리자',

    'S' 'FIELDNAME'   'NAME1',
    ' ' 'REF_FIELD'   'NAME1',
    ' ' 'REF_TABLE'   'KNA1',
    'E' 'COLTEXT'     '납품처',

    'S' 'FIELDNAME'   'MAKTX',
    ' ' 'REF_FIELD'   'MAKTX',
    ' ' 'REF_TABLE'   'MAKT',
    'E' 'COLTEXT'     '품목',

    'S' 'FIELDNAME'   'MEINS',
    ' ' 'NO_OUT'      'X',
    'E' 'COLTEXT'     '단위',

    'S' 'FIELDNAME'   'PLAN_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '판매계획',

    'S' 'FIELDNAME'   'OPEN_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '전월 미출하 수주량',

    'S' 'FIELDNAME'   'ORD_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '당월 수주량',

    'S' 'FIELDNAME'   'ORD_SUM',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '수주 합계',

    'S' 'FIELDNAME'   'GI_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '출하량',

    'S' 'FIELDNAME'   'ORD_REM',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '수주 잔량',

    'S' 'FIELDNAME'   'GR_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '당월 생산량',

    'S' 'FIELDNAME'   'STOCK_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '재고량',

    'S' 'FIELDNAME'   'RATE_PROD',
    'E' 'COLTEXT'     '당월 수주량 대비 생산량',

    'S' 'FIELDNAME'   'RATE_PLAN_ORD',
    'E' 'COLTEXT'     '판매계획대비 당월 수주량',

    'S' 'FIELDNAME'   'RATE_PLAN_GI',
    'E' 'COLTEXT'     '판매계획대비 출하량',

    'S' 'FIELDNAME'   'RATE_ORD_GI',
    'E' 'COLTEXT'     '수주대비 출하율'.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  MAKE_FIELDCAT
*&---------------------------------------------------------------------*
FORM make_fieldcat USING p_gub p_fname p_con.

  IF p_gub = 'S'.
    CLEAR gs_fcat.
  ENDIF.

  DATA l_col(40).
  FIELD-SYMBOLS <fs>.
  CONCATENATE 'GS_FCAT-' p_fname INTO l_col.
  ASSIGN (l_col) TO <fs>.
  MOVE p_con TO <fs>.

  IF p_gub = 'E'.
    APPEND gs_fcat TO <fcat>.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_SORT_GRID_0100
*&---------------------------------------------------------------------*
FORM set_sort_grid_0100.
  CLEAR: gs_sort, gt_sort.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_GRID
*&---------------------------------------------------------------------*
FORM display_grid USING p_grid   TYPE REF TO cl_gui_alv_grid
                        p_layout TYPE lvc_s_layo
                        p_outtab
                        p_fcat   TYPE lvc_t_fcat
                        p_sort   TYPE lvc_t_sort.
  CALL METHOD p_grid->set_table_for_first_display
    EXPORTING
      i_default                     = 'X'
      i_bypassing_buffer            = 'X'
      i_save                        = 'A'
      is_variant                    = gs_variant
      is_layout                     = p_layout
      it_toolbar_excluding          = gt_exclude
    CHANGING
      it_outtab                     = p_outtab
      it_fieldcatalog               = p_fcat
      it_sort                       = p_sort
      it_filter                     = gt_filter
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_ATTRIBUTE_GRID_0100
*&---------------------------------------------------------------------*
FORM set_attribute_grid_0100.
  CREATE OBJECT gv_event_receiver.
  SET HANDLER gv_event_receiver->handle_double_click FOR gv_grid_0100.
  CALL METHOD gv_grid_0100->set_ready_for_input
    EXPORTING
      i_ready_for_input = 0.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  REFRESH_GRID
*&---------------------------------------------------------------------*
FORM refresh_grid USING p_grid TYPE REF TO cl_gui_alv_grid
                        p_layo TYPE lvc_s_layo.
  DATA: is_scroll TYPE lvc_s_stbl,
        l_row     TYPE i,
        l_col     TYPE i.
  CHECK p_grid IS NOT INITIAL.
  CALL METHOD p_grid->set_frontend_layout
    EXPORTING
      is_layout = p_layo.
  CALL METHOD p_grid->get_current_cell
    IMPORTING
      e_row = l_row
      e_col = l_col.
  is_scroll-row = l_row.
  is_scroll-col = l_col.
  CALL METHOD p_grid->refresh_table_display
    EXPORTING
      i_soft_refresh = 'X'
      is_stable      = is_scroll.
ENDFORM.

FORM set_ok_code.
  gv_save_ok = gv_ok_code.
  CLEAR gv_ok_code.
ENDFORM.

FORM exit_process_0100 USING pv_mode.
  PERFORM object_free_0100.
  IF pv_mode = space.
    LEAVE TO SCREEN 0.
  ELSE.
    LEAVE PROGRAM.
  ENDIF.
ENDFORM.

FORM object_free_0100.
  IF gv_grid_0100 IS NOT INITIAL.
    gv_grid_0100->free( ).
  ENDIF.
  IF gv_cntr_0100 IS NOT INITIAL.
    gv_cntr_0100->free( ).
  ENDIF.
  CLEAR: gv_save_ok, gv_grid_0100, gv_cntr_0100.
ENDFORM.

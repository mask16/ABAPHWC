*&---------------------------------------------------------------------*
*& Include ZSDR5054_F01
*&---------------------------------------------------------------------*
*& 판매계획     : 사무소 + 영업사원 + 거래처 + 자재 + 플랜트. ZSDT0400-SPMNG
*& 전월 미출하  : ZSDR1100 미결수량. 일정선별 확정수량 - 품목 납품수량
*& 당월 수주량  : ZSDR1100 오더수량. 일정선별 확정수량 VBEP-BMENG
*& 수주 합계    : 미결수량 + 오더수량
*& 출하량       : ZSDR5002 출하요청수량. 플랜트는 납품, 저장위치는 오더품목
*& 수주 잔량    : 수주합계 - 출하량
*& 당월 생산량  : ZSDR0065 생산(구매)입고. 자재 + 플랜트 + 저장위치당 한 행
*& 판매계획     : 플랜트 단위. 같은 계획의 저장위치 행에는 한 번만 표시
*& 기초/기말재고: 자재 + 플랜트 + 저장위치당 한 행. 저장위치는 MARD
*& 저장위치 조건을 비우면 수량이 있는 저장위치만 남긴다
*& 같은 품목의 포항1(1010), 포항2(1020)는 별도 행
*& 기초재고     : 전월말. 행의 플랜트 + 저장위치
*& 기말재고     : 조회월 재고. 행의 플랜트 + 저장위치
*& 수주합계 대비 생산량 : 당월 생산량 / 수주 합계
*&---------------------------------------------------------------------*

FORM init_screen.
  DATA lv_lines TYPE i.
  IF p_spmon IS INITIAL.
    p_spmon = sy-datum(6).
  ENDIF.
  DESCRIBE TABLE so_werks LINES lv_lines.
  IF lv_lines = 1.
    READ TABLE so_werks INDEX 1.
    IF sy-subrc = 0
       AND so_werks-sign = 'I'
       AND so_werks-option = 'EQ'
       AND so_werks-low = '1010'
       AND so_werks-high IS INITIAL.
      so_werks-low = '1020'.
      APPEND so_werks.
    ENDIF.
  ENDIF.
ENDFORM.

FORM f4_variant.
  DATA ls_vari TYPE disvariant.
  ls_vari-report = sy-repid.
  ls_vari-handle = '01'.
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
  ls_bwart-low = '911'. APPEND ls_bwart TO r_gr.
  ls_bwart-low = '912'. APPEND ls_bwart TO r_gr.
ENDFORM.

FORM get_data.
  REFRESH gt_data.
  PERFORM set_bwart.
  PERFORM get_plan.
  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM fill_filter.
  PERFORM expand_lgort.
  PERFORM fill_order.
  PERFORM fill_stock.
  PERFORM fill_sd_stock.
  PERFORM keep_loc_once.
  PERFORM drop_empty_loc.
  PERFORM fill_rate.
  PERFORM fill_sum_rows.
ENDFORM.

*& ZSDR0410: ZSDT0401 의 조회월 최종 SPDAT.
*& 계획수량은 사무소 + 영업사원 + 거래처 + 자재 + 플랜트별 ZSDT0400-SPMNG.
FORM get_plan.
  TYPES: BEGIN OF ty_plan,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           spmng  TYPE zsdt0400-spmng,
           meins  TYPE meins,
         END OF ty_plan.
  DATA: lt_plan TYPE STANDARD TABLE OF ty_plan,
        ls_plan TYPE ty_plan,
        lv_tabix TYPE sy-tabix.

  SELECT MAX( spdat )
    FROM zsdt0401
    INTO gv_spdat
    WHERE spmon = p_spmon.
  IF gv_spdat IS INITIAL.
    RETURN.
  ENDIF.

  SELECT matnr werks vkbur person kunnr spmng meins
    FROM zsdt0400
    INTO TABLE lt_plan
    WHERE spdat = gv_spdat
      AND spmon = p_spmon
      AND matnr IN so_matnr
      AND werks IN so_werks
      AND kunnr IN so_kunnr.

  LOOP AT lt_plan INTO ls_plan.
    READ TABLE gt_data INTO gs_data
      WITH KEY matnr  = ls_plan-matnr
               werks  = ls_plan-werks
               vkbur  = ls_plan-vkbur
               person = ls_plan-person
               kunnr  = ls_plan-kunnr.
    IF sy-subrc <> 0.
      CLEAR gs_data.
      gs_data-matnr    = ls_plan-matnr.
      gs_data-werks    = ls_plan-werks.
      gs_data-spmon    = p_spmon.
      gs_data-vkbur    = ls_plan-vkbur.
      gs_data-person   = ls_plan-person.
      gs_data-kunnr    = ls_plan-kunnr.
      gs_data-meins    = ls_plan-meins.
      IF gs_data-meins IS INITIAL.
        gs_data-meins = 'KG'.
      ENDIF.
      gs_data-plan_qty = ls_plan-spmng.
      APPEND gs_data TO gt_data.
    ELSE.
      lv_tabix = sy-tabix.
      gs_data-plan_qty = gs_data-plan_qty + ls_plan-spmng.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM fill_filter.
  TYPES:          BEGIN OF ty_mara,
           matnr TYPE matnr,
           mtart TYPE mtart,
           matkl TYPE matkl,
         END OF ty_mara,
         BEGIN OF ty_makt,
           matnr TYPE matnr,
           maktx TYPE maktx,
         END OF ty_makt,
         BEGIN OF ty_kna,
           kunnr TYPE kunnr,
           name1 TYPE name1_gp,
         END OF ty_kna,
         BEGIN OF ty_vkb,
           vkbur TYPE vkbur,
           bezei TYPE tvkbt-bezei,
         END OF ty_vkb,
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
        lt_kna2 TYPE STANDARD TABLE OF ty_kna,
        lt_vkb  TYPE SORTED TABLE OF ty_vkb WITH UNIQUE KEY vkbur,
        ls_vkb  TYPE ty_vkb,
        lt_marc TYPE SORTED TABLE OF ty_marc WITH UNIQUE KEY matnr werks,
        ls_marc TYPE ty_marc,
        lt_t024 TYPE SORTED TABLE OF ty_t024 WITH UNIQUE KEY werks dispo,
        ls_t024 TYPE ty_t024,
        lv_tabix TYPE sy-tabix,
        lv_wrap  TYPE char40.

  CHECK gt_data[] IS NOT INITIAL.

  SELECT matnr mtart matkl
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

  SELECT kunnr name1
    FROM kna1
    INTO TABLE lt_kna2
    FOR ALL ENTRIES IN gt_data
    WHERE kunnr = gt_data-person.
  LOOP AT lt_kna2 INTO ls_kna.
    READ TABLE lt_kna WITH KEY kunnr = ls_kna-kunnr TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT ls_kna INTO TABLE lt_kna.
    ENDIF.
  ENDLOOP.

  SELECT vkbur bezei
    FROM tvkbt
    INTO TABLE lt_vkb
    FOR ALL ENTRIES IN gt_data
    WHERE spras = sy-langu
      AND vkbur = gt_data-vkbur.

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
    IF so_matkl[] IS NOT INITIAL.
      IF sy-subrc <> 0 OR ls_mara-matkl NOT IN so_matkl.
        CLEAR gs_data-matnr.
        MODIFY gt_data FROM gs_data INDEX lv_tabix.
        CONTINUE.
      ENDIF.
    ENDIF.
    READ TABLE lt_makt INTO ls_makt WITH KEY matnr = gs_data-matnr.
    IF sy-subrc = 0.
      gs_data-maktx = ls_makt-maktx.
    ENDIF.
    READ TABLE lt_vkb INTO ls_vkb WITH KEY vkbur = gs_data-vkbur.
    IF sy-subrc = 0.
      gs_data-vkbtx = ls_vkb-bezei.
    ENDIF.
    READ TABLE lt_kna INTO ls_kna WITH KEY kunnr = gs_data-person.
    IF sy-subrc = 0.
      gs_data-pertx = ls_kna-name1.
    ENDIF.
    READ TABLE lt_kna INTO ls_kna WITH KEY kunnr = gs_data-kunnr.
    IF sy-subrc = 0.
      gs_data-kuntx = ls_kna-name1.
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

*& 판매계획은 플랜트까지. 수주/출하/생산이 있는 저장위치마다 행을 만든다.
FORM expand_lgort.
  TYPES: BEGIN OF ty_ol,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           lgort  TYPE lgort_d,
         END OF ty_ol,
         BEGIN OF ty_pl,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_pl,
         BEGIN OF ty_lg,
           lgort TYPE lgort_d,
         END OF ty_lg,
         BEGIN OF ty_wl,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_wl,
         BEGIN OF ty_sh,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           lgort  TYPE lgort_d,
           lgso   TYPE lgort_d,
         END OF ty_sh.
  DATA: lt_base TYPE STANDARD TABLE OF ty_data,
        lt_pack TYPE STANDARD TABLE OF ty_data,
        lt_key  TYPE STANDARD TABLE OF ty_pl,
        lt_kpk  TYPE STANDARD TABLE OF ty_pl,
        ls_key  TYPE ty_pl,
        lt_ol   TYPE STANDARD TABLE OF ty_ol,
        ls_ol   TYPE ty_ol,
        lt_ordl TYPE SORTED TABLE OF ty_ol
                  WITH UNIQUE KEY matnr werks vkbur person kunnr lgort,
        lt_gil  TYPE SORTED TABLE OF ty_ol
                  WITH UNIQUE KEY matnr werks vkbur person kunnr lgort,
        lt_mv   TYPE STANDARD TABLE OF ty_pl,
        ls_mv   TYPE ty_pl,
        lt_ship TYPE STANDARD TABLE OF ty_sh,
        ls_ship TYPE ty_sh,
        lt_prl  TYPE SORTED TABLE OF ty_pl WITH UNIQUE KEY matnr werks lgort,
        lt_lg   TYPE SORTED TABLE OF ty_lg WITH UNIQUE KEY lgort,
        ls_lg   TYPE ty_lg,
        lt_wl   TYPE SORTED TABLE OF ty_wl WITH UNIQUE KEY werks lgort,
        lt_bus  TYPE SORTED TABLE OF ty_wl WITH UNIQUE KEY werks lgort,
        lt_mrd  TYPE SORTED TABLE OF ty_pl WITH UNIQUE KEY matnr werks lgort,
        ls_wl   TYPE ty_wl,
        lv_plan TYPE c,
        lv_biz  TYPE c,
        ls_row  TYPE ty_data,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  lt_base[] = gt_data[].

  DESCRIBE TABLE lt_base LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 399.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_pack.
    APPEND LINES OF lt_base FROM lv_from TO lv_to TO lt_pack.

    REFRESH lt_ol.
    SELECT b~matnr b~werks c~vkbur c~kunnr b~lgort
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS h
        ON h~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO CORRESPONDING FIELDS OF TABLE lt_ol
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks IN so_werks
        AND c~kunnr = lt_pack-kunnr
        AND b~lgort IN so_lgort
        AND c~erdat < gv_first
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND h~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.
    LOOP AT lt_ol INTO ls_ol.
      INSERT ls_ol INTO TABLE lt_ordl.
    ENDLOOP.

    REFRESH lt_ol.
    SELECT b~matnr b~werks c~vkbur c~kunnr b~lgort
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS h
        ON h~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO CORRESPONDING FIELDS OF TABLE lt_ol
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks IN so_werks
        AND c~kunnr = lt_pack-kunnr
        AND b~lgort IN so_lgort
        AND c~erdat BETWEEN gv_first AND gv_last
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND h~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.
    LOOP AT lt_ol INTO ls_ol.
      INSERT ls_ol INTO TABLE lt_ordl.
    ENDLOOP.

    REFRESH lt_ship.
    SELECT b~matnr b~werks c~vkbur d~kunnr AS person c~kunnr
           g~lgort AS lgso
      FROM lips AS b
      INNER JOIN likp AS a
        ON a~vbeln = b~vbeln
      INNER JOIN vbak AS c
        ON c~vbeln = b~vgbel
      INNER JOIN vbap AS g
        ON g~vbeln = b~vgbel
       AND g~posnr = b~vgpos
      INNER JOIN vbpa AS d
        ON d~vbeln = c~vbeln
       AND d~posnr = space
       AND d~parvw = 'S1'
      INTO CORRESPONDING FIELDS OF TABLE lt_ship
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks IN so_werks
        AND c~vkbur = lt_pack-vkbur
        AND c~kunnr = lt_pack-kunnr
        AND a~wadat BETWEEN gv_first AND gv_last.
    LOOP AT lt_ship INTO ls_ship.
      CHECK ls_ship-lgso IN so_lgort.
      CLEAR ls_ol.
      ls_ol-matnr  = ls_ship-matnr.
      ls_ol-werks  = ls_ship-werks.
      ls_ol-vkbur  = ls_ship-vkbur.
      ls_ol-person = ls_ship-person.
      ls_ol-kunnr  = ls_ship-kunnr.
      ls_ol-lgort  = ls_ship-lgso.
      INSERT ls_ol INTO TABLE lt_gil.
    ENDLOOP.

    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT lt_base INTO gs_data.
    ls_key-matnr = gs_data-matnr.
    CLEAR ls_key-werks.
    APPEND ls_key TO lt_key.
  ENDLOOP.
  SORT lt_key BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING matnr.

  IF lt_key[] IS NOT INITIAL.
    DESCRIBE TABLE lt_key LINES lv_lines.
    lv_from = 1.
    WHILE lv_from <= lv_lines.
      lv_to = lv_from + 399.
      IF lv_to > lv_lines.
        lv_to = lv_lines.
      ENDIF.
      REFRESH lt_kpk.
      APPEND LINES OF lt_key FROM lv_from TO lv_to TO lt_kpk.
      REFRESH lt_mv.
      SELECT b~matnr b~werks b~lgort
        FROM mseg AS b
        INNER JOIN mkpf AS a
          ON a~mblnr = b~mblnr
         AND a~mjahr = b~mjahr
        INTO TABLE lt_mv
        FOR ALL ENTRIES IN lt_kpk
        WHERE b~matnr = lt_kpk-matnr
          AND b~werks IN so_werks
          AND b~lgort IN so_lgort
          AND b~bwart IN r_gr
          AND a~budat BETWEEN gv_first AND gv_last.
      LOOP AT lt_mv INTO ls_mv.
        INSERT ls_mv INTO TABLE lt_prl.
      ENDLOOP.
      REFRESH lt_mv.
      SELECT a~matnr a~werks a~lgort
        FROM mard AS a
        INTO TABLE lt_mv
        FOR ALL ENTRIES IN lt_kpk
        WHERE a~matnr = lt_kpk-matnr
          AND a~werks IN so_werks
          AND a~lgort IN so_lgort
          AND a~lvorm = space.
      LOOP AT lt_mv INTO ls_mv.
        INSERT ls_mv INTO TABLE lt_mrd.
      ENDLOOP.
      lv_from = lv_to + 1.
    ENDWHILE.
  ENDIF.

  REFRESH gt_data.
  LOOP AT lt_base INTO gs_data.
    CLEAR lt_wl.
    LOOP AT lt_ordl INTO ls_ol
      WHERE matnr = gs_data-matnr
        AND kunnr = gs_data-kunnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_ol-werks.
      ls_wl-lgort = ls_ol-lgort.
      INSERT ls_wl INTO TABLE lt_wl.
    ENDLOOP.
    LOOP AT lt_gil INTO ls_ol
      WHERE matnr = gs_data-matnr
        AND vkbur = gs_data-vkbur
        AND kunnr = gs_data-kunnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_ol-werks.
      ls_wl-lgort = ls_ol-lgort.
      INSERT ls_wl INTO TABLE lt_wl.
    ENDLOOP.
    LOOP AT lt_prl INTO ls_mv
      WHERE matnr = gs_data-matnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_mv-werks.
      ls_wl-lgort = ls_mv-lgort.
      INSERT ls_wl INTO TABLE lt_wl.
    ENDLOOP.

    CLEAR lv_biz.
    LOOP AT lt_wl INTO ls_wl WHERE werks = gs_data-werks.
      lv_biz = 'X'.
      EXIT.
    ENDLOOP.
    lt_bus[] = lt_wl[].

    LOOP AT lt_mrd INTO ls_mv WHERE matnr = gs_data-matnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_mv-werks.
      ls_wl-lgort = ls_mv-lgort.
      INSERT ls_wl INTO TABLE lt_wl.
    ENDLOOP.

    IF lv_biz IS INITIAL AND so_lgort[] IS INITIAL.
      CLEAR lv_plan.
      LOOP AT lt_wl INTO ls_wl WHERE werks = gs_data-werks.
        lv_plan = 'X'.
        EXIT.
      ENDLOOP.
      IF lv_plan IS INITIAL.
        CLEAR ls_wl.
        ls_wl-werks = gs_data-werks.
        INSERT ls_wl INTO TABLE lt_wl.
        INSERT ls_wl INTO TABLE lt_bus.
      ENDIF.
    ENDIF.

    IF lt_wl[] IS INITIAL.
      CONTINUE.
    ENDIF.

    LOOP AT lt_wl INTO ls_wl.
      ls_row = gs_data.
      ls_row-werks = ls_wl-werks.
      ls_row-lgort = ls_wl-lgort.
      IF ls_wl-werks <> gs_data-werks.
        CLEAR ls_row-plan_qty.
      ELSEIF lv_biz = 'X'.
        READ TABLE lt_bus WITH KEY werks = ls_wl-werks
                                   lgort = ls_wl-lgort
          TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          CLEAR ls_row-plan_qty.
        ENDIF.
      ENDIF.
      APPEND ls_row TO gt_data.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*& 전월 미출하 = ZSDR1100 미결수량.
*& 일정선마다 확정수량에서 품목의 납품수량을 빼고, 0 미만은 0.
*& 당월 수주 = ZSDR1100 오더수량. 일정선의 확정수량 VBEP-BMENG.
FORM fill_order.
  TYPES:          BEGIN OF ty_qty,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           vbeln  TYPE vbeln_va,
           posnr  TYPE posnr_va,
           etenr  TYPE etenr,
           kwmeng TYPE kwmeng,
         END OF ty_qty,
         BEGIN OF ty_itm,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           vbeln  TYPE vbeln_va,
           posnr  TYPE posnr_va,
           etenr  TYPE etenr,
           kwmeng TYPE kwmeng,
         END OF ty_itm,
         BEGIN OF ty_dlv,
           dlv   TYPE vbeln_vl,
           dlp   TYPE posnr_vl,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           lfimg TYPE lfimg,
         END OF ty_dlv,
         BEGIN OF ty_sch,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           etenr TYPE etenr,
         END OF ty_sch,
         BEGIN OF ty_dd,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           lfimg TYPE lfimg,
         END OF ty_dd,
         BEGIN OF ty_sum,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           menge  TYPE kwmeng,
         END OF ty_sum.
  DATA: lt_pack TYPE STANDARD TABLE OF ty_data,
        lt_qty  TYPE STANDARD TABLE OF ty_qty,
        ls_qty  TYPE ty_qty,
        lt_itm  TYPE STANDARD TABLE OF ty_itm,
        ls_itm  TYPE ty_itm,
        lt_dlv  TYPE STANDARD TABLE OF ty_dlv,
        ls_dlv  TYPE ty_dlv,
        lt_dd   TYPE SORTED TABLE OF ty_dd WITH UNIQUE KEY vbeln posnr,
        ls_dd   TYPE ty_dd,
        lt_one  TYPE SORTED TABLE OF ty_itm WITH UNIQUE KEY vbeln posnr,
        ls_one  TYPE ty_itm,
        lt_open TYPE SORTED TABLE OF ty_sum
                  WITH UNIQUE KEY matnr werks lgort vkbur person kunnr,
        lt_ord  TYPE SORTED TABLE OF ty_sum
                  WITH UNIQUE KEY matnr werks lgort vkbur person kunnr,
        ls_sum  TYPE ty_sum,
        lt_seen TYPE SORTED TABLE OF ty_dd WITH UNIQUE KEY vbeln posnr,
        ls_seen TYPE ty_dd,
        lt_sch  TYPE SORTED TABLE OF ty_sch WITH UNIQUE KEY vbeln posnr etenr,
        ls_sch  TYPE ty_sch,
        lt_fin  TYPE SORTED TABLE OF ty_dd WITH UNIQUE KEY vbeln posnr,
        lv_open TYPE kwmeng,
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

    REFRESH lt_itm.
    SELECT b~matnr b~werks b~lgort c~vkbur c~kunnr
           b~vbeln b~posnr e~etenr e~bmeng AS kwmeng
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS f
        ON f~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO CORRESPONDING FIELDS OF TABLE lt_itm
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks = lt_pack-werks
        AND c~kunnr = lt_pack-kunnr
        AND b~lgort IN so_lgort
        AND c~erdat < gv_first
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND f~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.

    REFRESH lt_dd.
    IF lt_itm[] IS NOT INITIAL.
      REFRESH lt_dlv.
      SELECT a~vbeln AS dlv b~posnr AS dlp
             b~vgbel AS vbeln b~vgpos AS posnr b~lfimg
        FROM lips AS b
        INNER JOIN likp AS a
          ON a~vbeln = b~vbeln
        INTO CORRESPONDING FIELDS OF TABLE lt_dlv
        FOR ALL ENTRIES IN lt_itm
        WHERE b~vgbel = lt_itm-vbeln
          AND b~vgpos = lt_itm-posnr.
      LOOP AT lt_dlv INTO ls_dlv.
        READ TABLE lt_dd INTO ls_dd
          WITH KEY vbeln = ls_dlv-vbeln
                   posnr = ls_dlv-posnr.
        IF sy-subrc = 0.
          ls_dd-lfimg = ls_dd-lfimg + ls_dlv-lfimg.
          MODIFY lt_dd FROM ls_dd INDEX sy-tabix.
        ELSE.
          CLEAR ls_dd.
          ls_dd-vbeln = ls_dlv-vbeln.
          ls_dd-posnr = ls_dlv-posnr.
          ls_dd-lfimg = ls_dlv-lfimg.
          INSERT ls_dd INTO TABLE lt_dd.
        ENDIF.
      ENDLOOP.
    ENDIF.

    LOOP AT lt_itm INTO ls_itm.
      READ TABLE lt_sch WITH KEY vbeln = ls_itm-vbeln
                                 posnr = ls_itm-posnr
                                 etenr = ls_itm-etenr
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      CLEAR ls_sch.
      ls_sch-vbeln = ls_itm-vbeln.
      ls_sch-posnr = ls_itm-posnr.
      ls_sch-etenr = ls_itm-etenr.
      INSERT ls_sch INTO TABLE lt_sch.
      lv_open = ls_itm-kwmeng.
      READ TABLE lt_dd INTO ls_dd
        WITH KEY vbeln = ls_itm-vbeln
                 posnr = ls_itm-posnr.
      IF sy-subrc = 0.
        lv_open = lv_open - ls_dd-lfimg.
      ENDIF.
      IF lv_open < 0.
        lv_open = 0.
      ENDIF.
      IF lv_open = 0.
        CONTINUE.
      ENDIF.
      CLEAR ls_itm-person.
      READ TABLE lt_open INTO ls_sum
        WITH KEY matnr  = ls_itm-matnr
                 werks  = ls_itm-werks
                 lgort  = ls_itm-lgort
                 vkbur  = ls_itm-vkbur
                 person = ls_itm-person
                 kunnr  = ls_itm-kunnr.
      IF sy-subrc = 0.
        ls_sum-menge = ls_sum-menge + lv_open.
        MODIFY lt_open FROM ls_sum INDEX sy-tabix.
      ELSE.
        CLEAR ls_sum.
        ls_sum-matnr  = ls_itm-matnr.
        ls_sum-werks  = ls_itm-werks.
        ls_sum-lgort  = ls_itm-lgort.
        ls_sum-vkbur  = ls_itm-vkbur.
        ls_sum-kunnr  = ls_itm-kunnr.
        ls_sum-menge  = lv_open.
        INSERT ls_sum INTO TABLE lt_open.
      ENDIF.
    ENDLOOP.

    REFRESH lt_qty.
    SELECT b~matnr b~werks b~lgort c~vkbur c~kunnr
           b~vbeln b~posnr e~etenr e~bmeng AS kwmeng
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS f
        ON f~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO CORRESPONDING FIELDS OF TABLE lt_qty
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND b~werks = lt_pack-werks
        AND c~kunnr = lt_pack-kunnr
        AND b~lgort IN so_lgort
        AND c~erdat BETWEEN gv_first AND gv_last
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND f~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.
    LOOP AT lt_qty INTO ls_qty.
      READ TABLE lt_fin WITH KEY vbeln = ls_qty-vbeln
                                posnr = ls_qty-posnr
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      READ TABLE lt_ord INTO ls_sum
        WITH KEY matnr  = ls_qty-matnr
                 werks  = ls_qty-werks
                 lgort  = ls_qty-lgort
                 vkbur  = ls_qty-vkbur
                 person = ls_qty-person
                 kunnr  = ls_qty-kunnr.
      IF sy-subrc = 0.
        ls_sum-menge = ls_sum-menge + ls_qty-kwmeng.
        MODIFY lt_ord FROM ls_sum INDEX sy-tabix.
      ELSE.
        CLEAR ls_sum.
        ls_sum-matnr  = ls_qty-matnr.
        ls_sum-werks  = ls_qty-werks.
        ls_sum-lgort  = ls_qty-lgort.
        ls_sum-vkbur  = ls_qty-vkbur.
        ls_sum-person = ls_qty-person.
        ls_sum-kunnr  = ls_qty-kunnr.
        ls_sum-menge  = ls_qty-kwmeng.
        INSERT ls_sum INTO TABLE lt_ord.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_qty INTO ls_qty.
      CLEAR ls_seen.
      ls_seen-vbeln = ls_qty-vbeln.
      ls_seen-posnr = ls_qty-posnr.
      INSERT ls_seen INTO TABLE lt_fin.
    ENDLOOP.

*   재고운송오더. ZSDR1100 은 오더수량에 구매수량, 미결수량에 구매수량 - 납품수량을 넣는다.
    REFRESH lt_itm.
    SELECT b~matnr a~reswk AS werks b~reslo AS lgort d~kunnr
           b~ebeln AS vbeln b~ebelp AS posnr b~menge AS kwmeng
      FROM ekko AS a
      INNER JOIN ekpo AS b
        ON b~ebeln = a~ebeln
      INNER JOIN ekpv AS d
        ON d~ebeln = b~ebeln
       AND d~ebelp = b~ebelp
      INTO CORRESPONDING FIELDS OF TABLE lt_itm
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND a~reswk = lt_pack-werks
        AND d~kunnr = lt_pack-kunnr
        AND b~reslo IN so_lgort
        AND a~aedat < gv_first
        AND a~memorytype = space
        AND b~loekz = space
        AND b~menge <> 0.
    IF lt_itm[] IS NOT INITIAL.
      REFRESH lt_dlv.
      SELECT a~vbeln AS dlv b~posnr AS dlp
             b~vgbel AS vbeln b~vgpos AS posnr b~lfimg
        FROM lips AS b
        INNER JOIN likp AS a
          ON a~vbeln = b~vbeln
        INTO CORRESPONDING FIELDS OF TABLE lt_dlv
        FOR ALL ENTRIES IN lt_itm
        WHERE b~vgbel = lt_itm-vbeln
          AND b~vgpos = lt_itm-posnr.
      REFRESH lt_dd.
      LOOP AT lt_dlv INTO ls_dlv.
        READ TABLE lt_dd INTO ls_dd
          WITH KEY vbeln = ls_dlv-vbeln
                   posnr = ls_dlv-posnr.
        IF sy-subrc = 0.
          ls_dd-lfimg = ls_dd-lfimg + ls_dlv-lfimg.
          MODIFY lt_dd FROM ls_dd INDEX sy-tabix.
        ELSE.
          CLEAR ls_dd.
          ls_dd-vbeln = ls_dlv-vbeln.
          ls_dd-posnr = ls_dlv-posnr.
          ls_dd-lfimg = ls_dlv-lfimg.
          INSERT ls_dd INTO TABLE lt_dd.
        ENDIF.
      ENDLOOP.
      LOOP AT lt_itm INTO ls_itm.
        READ TABLE lt_sch WITH KEY vbeln = ls_itm-vbeln
                                   posnr = ls_itm-posnr
                                   etenr = space
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.
        CLEAR ls_sch.
        ls_sch-vbeln = ls_itm-vbeln.
        ls_sch-posnr = ls_itm-posnr.
        INSERT ls_sch INTO TABLE lt_sch.
        lv_open = ls_itm-kwmeng.
        READ TABLE lt_dd INTO ls_dd
          WITH KEY vbeln = ls_itm-vbeln
                   posnr = ls_itm-posnr.
        IF sy-subrc = 0.
          lv_open = lv_open - ls_dd-lfimg.
        ENDIF.
        IF lv_open < 0.
          lv_open = 0.
        ENDIF.
        IF lv_open = 0.
          CONTINUE.
        ENDIF.
        READ TABLE lt_open INTO ls_sum
          WITH KEY matnr  = ls_itm-matnr
                   werks  = ls_itm-werks
                   lgort  = ls_itm-lgort
                   vkbur  = space
                   person = space
                   kunnr  = ls_itm-kunnr.
        IF sy-subrc = 0.
          ls_sum-menge = ls_sum-menge + lv_open.
          MODIFY lt_open FROM ls_sum INDEX sy-tabix.
        ELSE.
          CLEAR ls_sum.
          ls_sum-matnr = ls_itm-matnr.
          ls_sum-werks = ls_itm-werks.
          ls_sum-lgort = ls_itm-lgort.
          ls_sum-kunnr = ls_itm-kunnr.
          ls_sum-menge = lv_open.
          INSERT ls_sum INTO TABLE lt_open.
        ENDIF.
      ENDLOOP.
    ENDIF.

    REFRESH lt_qty.
    SELECT b~matnr a~reswk AS werks b~reslo AS lgort d~kunnr
           b~ebeln AS vbeln b~ebelp AS posnr b~menge AS kwmeng
      FROM ekko AS a
      INNER JOIN ekpo AS b
        ON b~ebeln = a~ebeln
      INNER JOIN ekpv AS d
        ON d~ebeln = b~ebeln
       AND d~ebelp = b~ebelp
      INTO CORRESPONDING FIELDS OF TABLE lt_qty
      FOR ALL ENTRIES IN lt_pack
      WHERE b~matnr = lt_pack-matnr
        AND a~reswk = lt_pack-werks
        AND d~kunnr = lt_pack-kunnr
        AND b~reslo IN so_lgort
        AND a~aedat BETWEEN gv_first AND gv_last
        AND a~memorytype = space
        AND b~loekz = space
        AND b~menge <> 0.
    LOOP AT lt_qty INTO ls_qty.
      READ TABLE lt_fin WITH KEY vbeln = ls_qty-vbeln
                                posnr = ls_qty-posnr
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      CLEAR ls_seen.
      ls_seen-vbeln = ls_qty-vbeln.
      ls_seen-posnr = ls_qty-posnr.
      INSERT ls_seen INTO TABLE lt_fin.
      READ TABLE lt_ord INTO ls_sum
        WITH KEY matnr  = ls_qty-matnr
                 werks  = ls_qty-werks
                 lgort  = ls_qty-lgort
                 vkbur  = space
                 person = space
                 kunnr  = ls_qty-kunnr.
      IF sy-subrc = 0.
        ls_sum-menge = ls_sum-menge + ls_qty-kwmeng.
        MODIFY lt_ord FROM ls_sum INDEX sy-tabix.
      ELSE.
        CLEAR ls_sum.
        ls_sum-matnr = ls_qty-matnr.
        ls_sum-werks = ls_qty-werks.
        ls_sum-lgort = ls_qty-lgort.
        ls_sum-kunnr = ls_qty-kunnr.
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
      WITH KEY matnr  = gs_data-matnr
               werks  = gs_data-werks
               lgort  = gs_data-lgort
               vkbur  = gs_data-vkbur
               person = space
               kunnr  = gs_data-kunnr.
    IF sy-subrc = 0.
      gs_data-open_qty = ls_sum-menge.
      DELETE TABLE lt_open WITH TABLE KEY matnr  = gs_data-matnr
                                          werks  = gs_data-werks
                                          lgort  = gs_data-lgort
                                          vkbur  = gs_data-vkbur
                                          person = space
                                          kunnr  = gs_data-kunnr.
    ENDIF.
    READ TABLE lt_ord INTO ls_sum
      WITH KEY matnr  = gs_data-matnr
               werks  = gs_data-werks
               lgort  = gs_data-lgort
               vkbur  = gs_data-vkbur
               person = space
               kunnr  = gs_data-kunnr.
    IF sy-subrc = 0.
      gs_data-ord_qty = ls_sum-menge.
      DELETE TABLE lt_ord WITH TABLE KEY matnr  = gs_data-matnr
                                         werks  = gs_data-werks
                                         lgort  = gs_data-lgort
                                         vkbur  = gs_data-vkbur
                                         person = space
                                         kunnr  = gs_data-kunnr.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.

  LOOP AT lt_open INTO ls_sum.
    CLEAR lv_tabix.
    LOOP AT gt_data INTO gs_data
      WHERE matnr = ls_sum-matnr
        AND werks = ls_sum-werks
        AND lgort = ls_sum-lgort
        AND kunnr = ls_sum-kunnr.
      lv_tabix = sy-tabix.
      EXIT.
    ENDLOOP.
    IF lv_tabix > 0.
      gs_data-open_qty = gs_data-open_qty + ls_sum-menge.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_ord INTO ls_sum.
    CLEAR lv_tabix.
    LOOP AT gt_data INTO gs_data
      WHERE matnr = ls_sum-matnr
        AND werks = ls_sum-werks
        AND lgort = ls_sum-lgort
        AND kunnr = ls_sum-kunnr.
      lv_tabix = sy-tabix.
      EXIT.
    ENDLOOP.
    IF lv_tabix > 0.
      gs_data-ord_qty = gs_data-ord_qty + ls_sum-menge.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
  ENDLOOP.
ENDFORM.

*& 생산량은 자재+플랜트+저장위치. 출하는 납품 출하요청수량.
FORM fill_stock.
  TYPES: BEGIN OF ty_key,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_key,
         BEGIN OF ty_gr,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
           menge TYPE kwmeng,
         END OF ty_gr,
         BEGIN OF ty_gi,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           menge  TYPE kwmeng,
         END OF ty_gi,
         BEGIN OF ty_mvg,
           mblnr TYPE mblnr,
           mjahr TYPE mjahr,
           zeile TYPE mblpo,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
           bwart TYPE bwart,
           shkzg TYPE shkzg,
           menge TYPE menge_d,
         END OF ty_mvg,
         BEGIN OF ty_shp,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           lgso   TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
           lfimg  TYPE lfimg,
           auart  TYPE auart,
         END OF ty_shp,
         BEGIN OF ty_drv,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
         END OF ty_drv.
  DATA: lt_key  TYPE STANDARD TABLE OF ty_key,
        ls_key  TYPE ty_key,
        lt_kpk  TYPE STANDARD TABLE OF ty_key,
        lt_pack TYPE STANDARD TABLE OF ty_data,
        lt_mvg  TYPE STANDARD TABLE OF ty_mvg,
        ls_mvg  TYPE ty_mvg,
        lt_shp  TYPE STANDARD TABLE OF ty_shp,
        ls_shp  TYPE ty_shp,
        lt_drv  TYPE STANDARD TABLE OF ty_drv,
        ls_drv  TYPE ty_drv,
        lt_dpk  TYPE STANDARD TABLE OF ty_drv,
        lt_gr   TYPE SORTED TABLE OF ty_gr WITH UNIQUE KEY matnr werks lgort,
        ls_gr   TYPE ty_gr,
        lt_gi   TYPE SORTED TABLE OF ty_gi
                  WITH UNIQUE KEY matnr werks lgort vkbur person kunnr,
        ls_gi   TYPE ty_gi,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i,
        lv_tabix TYPE sy-tabix,
        lv_qty   TYPE kwmeng,
        lv_lgort TYPE lgort_d.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT gt_data INTO gs_data.
    ls_key-matnr = gs_data-matnr.
    ls_key-werks = gs_data-werks.
    ls_key-lgort = gs_data-lgort.
    APPEND ls_key TO lt_key.
  ENDLOOP.
  SORT lt_key BY matnr werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING matnr werks lgort.

  IF lt_key[] IS NOT INITIAL.
    DESCRIBE TABLE lt_key LINES lv_lines.
    lv_from = 1.
    WHILE lv_from <= lv_lines.
      lv_to = lv_from + 399.
      IF lv_to > lv_lines.
        lv_to = lv_lines.
      ENDIF.
      REFRESH lt_kpk.
      APPEND LINES OF lt_key FROM lv_from TO lv_to TO lt_kpk.
      REFRESH lt_mvg.
*     문서번호를 함께 읽는다. 수량이 같은 입고를 한 건으로 지우지 않기 위함.
      SELECT b~mblnr b~mjahr b~zeile
             b~matnr b~werks b~lgort b~bwart b~shkzg b~menge
        FROM mseg AS b
        INNER JOIN mkpf AS a
          ON a~mblnr = b~mblnr
         AND a~mjahr = b~mjahr
        INTO TABLE lt_mvg
        FOR ALL ENTRIES IN lt_kpk
        WHERE b~matnr = lt_kpk-matnr
          AND b~werks = lt_kpk-werks
          AND b~lgort = lt_kpk-lgort
          AND b~bwart IN r_gr
          AND a~budat BETWEEN gv_first AND gv_last.
      LOOP AT lt_mvg INTO ls_mvg.
        READ TABLE lt_gr INTO ls_gr
          WITH KEY matnr = ls_mvg-matnr
                   werks = ls_mvg-werks
                   lgort = ls_mvg-lgort.
        IF sy-subrc <> 0.
          CLEAR ls_gr.
          ls_gr-matnr = ls_mvg-matnr.
          ls_gr-werks = ls_mvg-werks.
          ls_gr-lgort = ls_mvg-lgort.
          INSERT ls_gr INTO TABLE lt_gr.
          READ TABLE lt_gr INTO ls_gr
            WITH KEY matnr = ls_mvg-matnr
                     werks = ls_mvg-werks
                     lgort = ls_mvg-lgort.
        ENDIF.
        CLEAR lv_qty.
        IF ls_mvg-bwart = '911'.
          IF ls_mvg-shkzg = 'S'.
            lv_qty = ls_mvg-menge.
          ENDIF.
        ELSEIF ls_mvg-bwart = '912'.
          IF ls_mvg-shkzg = 'H'.
            lv_qty = 0 - ls_mvg-menge.
          ENDIF.
        ELSEIF ls_mvg-shkzg = 'S'.
          lv_qty = ls_mvg-menge.
        ELSE.
          lv_qty = 0 - ls_mvg-menge.
        ENDIF.
        ls_gr-menge = ls_gr-menge + lv_qty.
        MODIFY lt_gr FROM ls_gr INDEX sy-tabix.
      ENDLOOP.
      lv_from = lv_to + 1.
    ENDWHILE.
  ENDIF.

  REFRESH lt_drv.
  LOOP AT gt_data INTO gs_data.
    ls_drv-matnr  = gs_data-matnr.
    ls_drv-werks  = gs_data-werks.
    ls_drv-vkbur  = gs_data-vkbur.
    ls_drv-kunnr  = gs_data-kunnr.
    APPEND ls_drv TO lt_drv.
  ENDLOOP.
  SORT lt_drv BY matnr werks vkbur kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_drv
    COMPARING matnr werks vkbur kunnr.

  DESCRIBE TABLE lt_drv LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 399.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_dpk.
    APPEND LINES OF lt_drv FROM lv_from TO lv_to TO lt_dpk.
    REFRESH lt_shp.
    SELECT b~matnr b~werks g~lgort AS lgso
           c~vkbur d~kunnr AS person c~kunnr b~lfimg c~auart
      FROM lips AS b
      INNER JOIN likp AS a
        ON a~vbeln = b~vbeln
      INNER JOIN vbak AS c
        ON c~vbeln = b~vgbel
      INNER JOIN vbap AS g
        ON g~vbeln = b~vgbel
       AND g~posnr = b~vgpos
      INNER JOIN vbpa AS d
        ON d~vbeln = c~vbeln
       AND d~posnr = space
       AND d~parvw = 'S1'
      INTO CORRESPONDING FIELDS OF TABLE lt_shp
      FOR ALL ENTRIES IN lt_dpk
      WHERE b~matnr = lt_dpk-matnr
        AND b~werks = lt_dpk-werks
        AND c~vkbur = lt_dpk-vkbur
        AND c~kunnr = lt_dpk-kunnr
        AND a~wadat BETWEEN gv_first AND gv_last.
    LOOP AT lt_shp INTO ls_shp.
      lv_lgort = ls_shp-lgso.
      CHECK lv_lgort IN so_lgort.
      IF ls_shp-auart = 'ZRE' OR ls_shp-auart = 'ZK2'
      OR ls_shp-auart = 'ZK4' OR ls_shp-auart = 'ZKA'
      OR ls_shp-auart = 'ZKR'.
        ls_shp-lfimg = 0 - ls_shp-lfimg.
      ENDIF.
      READ TABLE lt_gi INTO ls_gi
        WITH KEY matnr  = ls_shp-matnr
                 werks  = ls_shp-werks
                 lgort  = lv_lgort
                 vkbur  = ls_shp-vkbur
                 person = ls_shp-person
                 kunnr  = ls_shp-kunnr.
      IF sy-subrc <> 0.
        CLEAR ls_gi.
        ls_gi-matnr  = ls_shp-matnr.
        ls_gi-werks  = ls_shp-werks.
        ls_gi-lgort  = lv_lgort.
        ls_gi-vkbur  = ls_shp-vkbur.
        ls_gi-person = ls_shp-person.
        ls_gi-kunnr  = ls_shp-kunnr.
        INSERT ls_gi INTO TABLE lt_gi.
        READ TABLE lt_gi INTO ls_gi
          WITH KEY matnr  = ls_shp-matnr
                   werks  = ls_shp-werks
                   lgort  = lv_lgort
                   vkbur  = ls_shp-vkbur
                   person = ls_shp-person
                   kunnr  = ls_shp-kunnr.
      ENDIF.
      ls_gi-menge = ls_gi-menge + ls_shp-lfimg.
      MODIFY lt_gi FROM ls_gi INDEX sy-tabix.
    ENDLOOP.
    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    CLEAR: gs_data-gr_qty, gs_data-gi_qty.
    READ TABLE lt_gr INTO ls_gr
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks
               lgort = gs_data-lgort.
    IF sy-subrc = 0.
      gs_data-gr_qty = ls_gr-menge.
    ENDIF.
    READ TABLE lt_gi INTO ls_gi
      WITH KEY matnr  = gs_data-matnr
               werks  = gs_data-werks
               lgort  = gs_data-lgort
               vkbur  = gs_data-vkbur
               person = gs_data-person
               kunnr  = gs_data-kunnr.
    IF sy-subrc = 0.
      gs_data-gi_qty = ls_gi-menge.
      DELETE TABLE lt_gi WITH TABLE KEY matnr  = gs_data-matnr
                                        werks  = gs_data-werks
                                        lgort  = gs_data-lgort
                                        vkbur  = gs_data-vkbur
                                        person = gs_data-person
                                        kunnr  = gs_data-kunnr.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.

  LOOP AT lt_gi INTO ls_gi.
    CLEAR lv_tabix.
    LOOP AT gt_data INTO gs_data
      WHERE matnr = ls_gi-matnr
        AND werks = ls_gi-werks
        AND lgort = ls_gi-lgort
        AND vkbur = ls_gi-vkbur
        AND kunnr = ls_gi-kunnr.
      lv_tabix = sy-tabix.
      EXIT.
    ENDLOOP.
    IF lv_tabix > 0.
      gs_data-gi_qty = gs_data-gi_qty + ls_gi-menge.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
  ENDLOOP.
ENDFORM.

*& 기초/기말재고는 행의 플랜트와 저장위치. ZMMF01_GET_STOCK.
FORM fill_sd_stock.
  TYPES: BEGIN OF ty_key,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_key,
         BEGIN OF ty_stk,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
           openq TYPE labst,
           endq  TYPE labst,
         END OF ty_stk.
  DATA: lt_key TYPE SORTED TABLE OF ty_key WITH UNIQUE KEY matnr werks lgort,
        ls_key TYPE ty_key,
        lt_stk TYPE SORTED TABLE OF ty_stk WITH UNIQUE KEY matnr werks lgort,
        ls_stk TYPE ty_stk,
        lv_prev TYPE datum,
        lv_ym   TYPE spmon,
        lv_labst TYPE labst,
        lv_tabix TYPE sy-tabix.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  lv_prev = gv_first.
  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = -1
      olddate = lv_prev
    IMPORTING
      newdate = lv_prev.
  lv_ym = lv_prev(6).

  LOOP AT gt_data INTO gs_data.
    IF gs_data-lgort IS INITIAL.
      CONTINUE.
    ENDIF.
    ls_key-matnr = gs_data-matnr.
    ls_key-werks = gs_data-werks.
    ls_key-lgort = gs_data-lgort.
    INSERT ls_key INTO TABLE lt_key.
  ENDLOOP.

  LOOP AT lt_key INTO ls_key.
    CLEAR ls_stk.
    ls_stk-matnr = ls_key-matnr.
    ls_stk-werks = ls_key-werks.
    ls_stk-lgort = ls_key-lgort.
    CLEAR lv_labst.
    CALL FUNCTION 'ZMMF01_GET_STOCK'
      EXPORTING
        i_matnr = ls_key-matnr
        i_werks = ls_key-werks
        i_lgort = ls_key-lgort
        i_sdate = lv_ym
      IMPORTING
        o_labst = lv_labst
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc = 0.
      ls_stk-openq = lv_labst.
    ENDIF.
    CLEAR lv_labst.
    CALL FUNCTION 'ZMMF01_GET_STOCK'
      EXPORTING
        i_matnr = ls_key-matnr
        i_werks = ls_key-werks
        i_lgort = ls_key-lgort
        i_sdate = p_spmon
      IMPORTING
        o_labst = lv_labst
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc = 0.
      ls_stk-endq = lv_labst.
    ENDIF.
    INSERT ls_stk INTO TABLE lt_stk.
  ENDLOOP.

  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    CLEAR: gs_data-open_stk, gs_data-end_stk.
    READ TABLE lt_stk INTO ls_stk
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks
               lgort = gs_data-lgort.
    IF sy-subrc = 0.
      gs_data-open_stk = ls_stk-openq.
      gs_data-end_stk  = ls_stk-endq.
    ENDIF.
    MODIFY gt_data FROM gs_data INDEX lv_tabix.
  ENDLOOP.
ENDFORM.

*& 판매계획은 같은 계획키의 첫 저장위치 행만 남긴다.
*& 생산량과 기초/기말재고는 자재+플랜트+저장위치의 첫 행만 남긴다.
FORM keep_loc_once.
  DATA: lv_tabix TYPE sy-tabix,
        lv_matnr TYPE matnr,
        lv_werks TYPE werks_d,
        lv_lgort TYPE lgort_d,
        lv_vkbur TYPE vkbur,
        lv_person TYPE kunnr,
        lv_kunnr TYPE kunnr,
        lv_on TYPE c,
        lv_kept TYPE c.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  SORT gt_data BY matnr werks vkbur person kunnr lgort.
  CLEAR lv_on.
  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    IF lv_on = 'X'
       AND gs_data-matnr = lv_matnr
       AND gs_data-werks = lv_werks
       AND gs_data-vkbur = lv_vkbur
       AND gs_data-person = lv_person
       AND gs_data-kunnr = lv_kunnr.
      IF lv_kept = 'X'.
        CLEAR gs_data-plan_qty.
        MODIFY gt_data FROM gs_data INDEX lv_tabix.
      ELSEIF gs_data-plan_qty <> 0.
        lv_kept = 'X'.
      ENDIF.
    ELSE.
      IF gs_data-plan_qty <> 0.
        lv_kept = 'X'.
      ELSE.
        CLEAR lv_kept.
      ENDIF.
    ENDIF.
    lv_on = 'X'.
    lv_matnr  = gs_data-matnr.
    lv_werks  = gs_data-werks.
    lv_vkbur  = gs_data-vkbur.
    lv_person = gs_data-person.
    lv_kunnr  = gs_data-kunnr.
  ENDLOOP.

  SORT gt_data BY matnr werks lgort vkbur person kunnr.
  CLEAR lv_on.
  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    IF lv_on = 'X'
       AND gs_data-matnr = lv_matnr
       AND gs_data-werks = lv_werks
       AND gs_data-lgort = lv_lgort.
      CLEAR: gs_data-gr_qty, gs_data-open_stk, gs_data-end_stk.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDIF.
    lv_on = 'X'.
    lv_matnr = gs_data-matnr.
    lv_werks = gs_data-werks.
    lv_lgort = gs_data-lgort.
  ENDLOOP.
ENDFORM.

*& 저장위치를 비우면 수량이 있는 저장위치만 남긴다.
FORM drop_empty_loc.
  IF so_lgort[] IS NOT INITIAL.
    RETURN.
  ENDIF.
  DELETE gt_data WHERE plan_qty = 0
                   AND open_qty = 0
                   AND ord_qty  = 0
                   AND gi_qty   = 0
                   AND gr_qty   = 0
                   AND open_stk = 0
                   AND end_stk  = 0.
ENDFORM.

FORM fill_rate.
  DATA lv_tabix TYPE sy-tabix.
  LOOP AT gt_data INTO gs_data.
    lv_tabix = sy-tabix.
    gs_data-ord_sum = gs_data-open_qty + gs_data-ord_qty.
    gs_data-ord_rem = gs_data-ord_sum - gs_data-gi_qty.
    PERFORM calc_rate USING gs_data-gr_qty  gs_data-ord_sum
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

*& 사무소 소계, 전체 합계.
*& 당월 생산량, 기초재고, 기말재고는 자재+플랜트+저장위치당 한 번만 더한다.
FORM fill_sum_rows.
  TYPES: BEGIN OF ty_grk,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_grk,
         BEGIN OF ty_pln,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
         END OF ty_pln.
  DATA: lt_out TYPE STANDARD TABLE OF ty_data,
        ls_sub TYPE ty_data,
        ls_tot TYPE ty_data,
        lt_gr  TYPE SORTED TABLE OF ty_grk WITH UNIQUE KEY matnr werks lgort,
        lt_all TYPE SORTED TABLE OF ty_grk WITH UNIQUE KEY matnr werks lgort,
        ls_gr  TYPE ty_grk,
        lt_pln TYPE SORTED TABLE OF ty_pln
                 WITH UNIQUE KEY matnr werks vkbur person kunnr,
        lt_plna TYPE SORTED TABLE OF ty_pln
                  WITH UNIQUE KEY matnr werks vkbur person kunnr,
        ls_pln TYPE ty_pln,
        lv_vk  TYPE tvkbt-bezei,
        lv_on  TYPE c.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  SORT gt_data BY vkbtx pertx kuntx matnr werks lgort.

  LOOP AT gt_data INTO gs_data.
    IF lv_on = 'X' AND gs_data-vkbtx <> lv_vk.
      ls_sub-maktx = '소계'.
      ls_sub-rowcol = 'C300'.
      PERFORM calc_rate USING ls_sub-gr_qty ls_sub-ord_sum
                        CHANGING ls_sub-rate_prod.
      APPEND ls_sub TO lt_out.
      CLEAR: ls_sub, lt_gr, lt_pln.
    ENDIF.
    lv_on = 'X'.
    lv_vk = gs_data-vkbtx.
    APPEND gs_data TO lt_out.

    ls_sub-vkbtx = gs_data-vkbtx.
    ls_sub-meins = gs_data-meins.
    ls_sub-open_qty = ls_sub-open_qty + gs_data-open_qty.
    ls_sub-ord_qty  = ls_sub-ord_qty + gs_data-ord_qty.
    ls_sub-ord_sum  = ls_sub-ord_sum + gs_data-ord_sum.
    ls_sub-gi_qty   = ls_sub-gi_qty + gs_data-gi_qty.
    ls_sub-ord_rem  = ls_sub-ord_rem + gs_data-ord_rem.

    ls_tot-meins = gs_data-meins.
    ls_tot-open_qty = ls_tot-open_qty + gs_data-open_qty.
    ls_tot-ord_qty  = ls_tot-ord_qty + gs_data-ord_qty.
    ls_tot-ord_sum  = ls_tot-ord_sum + gs_data-ord_sum.
    ls_tot-gi_qty   = ls_tot-gi_qty + gs_data-gi_qty.
    ls_tot-ord_rem  = ls_tot-ord_rem + gs_data-ord_rem.

    ls_pln-matnr  = gs_data-matnr.
    ls_pln-werks  = gs_data-werks.
    ls_pln-vkbur  = gs_data-vkbur.
    ls_pln-person = gs_data-person.
    ls_pln-kunnr  = gs_data-kunnr.
    READ TABLE lt_pln WITH KEY matnr  = ls_pln-matnr
                               werks  = ls_pln-werks
                               vkbur  = ls_pln-vkbur
                               person = ls_pln-person
                               kunnr  = ls_pln-kunnr
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT ls_pln INTO TABLE lt_pln.
      ls_sub-plan_qty = ls_sub-plan_qty + gs_data-plan_qty.
    ENDIF.
    READ TABLE lt_plna WITH KEY matnr  = ls_pln-matnr
                                werks  = ls_pln-werks
                                vkbur  = ls_pln-vkbur
                                person = ls_pln-person
                                kunnr  = ls_pln-kunnr
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT ls_pln INTO TABLE lt_plna.
      ls_tot-plan_qty = ls_tot-plan_qty + gs_data-plan_qty.
    ENDIF.

    ls_gr-matnr = gs_data-matnr.
    ls_gr-werks = gs_data-werks.
    ls_gr-lgort = gs_data-lgort.
    READ TABLE lt_gr WITH KEY matnr = ls_gr-matnr
                              werks = ls_gr-werks
                              lgort = ls_gr-lgort
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT ls_gr INTO TABLE lt_gr.
      ls_sub-gr_qty   = ls_sub-gr_qty + gs_data-gr_qty.
      ls_sub-open_stk = ls_sub-open_stk + gs_data-open_stk.
      ls_sub-end_stk  = ls_sub-end_stk + gs_data-end_stk.
    ENDIF.
    READ TABLE lt_all WITH KEY matnr = ls_gr-matnr
                               werks = ls_gr-werks
                               lgort = ls_gr-lgort
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      INSERT ls_gr INTO TABLE lt_all.
      ls_tot-gr_qty   = ls_tot-gr_qty + gs_data-gr_qty.
      ls_tot-open_stk = ls_tot-open_stk + gs_data-open_stk.
      ls_tot-end_stk  = ls_tot-end_stk + gs_data-end_stk.
    ENDIF.
  ENDLOOP.

  ls_sub-maktx = '소계'.
  ls_sub-rowcol = 'C300'.
  PERFORM calc_rate USING ls_sub-gr_qty ls_sub-ord_sum
                    CHANGING ls_sub-rate_prod.
  APPEND ls_sub TO lt_out.

  ls_tot-vkbtx = '합계'.
  ls_tot-maktx = '합계'.
  ls_tot-rowcol = 'C500'.
  PERFORM calc_rate USING ls_tot-gr_qty ls_tot-ord_sum
                    CHANGING ls_tot-rate_prod.
  APPEND ls_tot TO lt_out.

  gt_data[] = lt_out[].
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
  gs_variant-handle  = '01'.
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
  gs_layout-info_fname = 'ROWCOL'.
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

    'S' 'FIELDNAME'   'VKBTX',
    'E' 'COLTEXT'     '사무소',

    'S' 'FIELDNAME'   'PERTX',
    'E' 'COLTEXT'     '영업사원명',

    'S' 'FIELDNAME'   'KUNTX',
    ' ' 'REF_FIELD'   'NAME1',
    ' ' 'REF_TABLE'   'KNA1',
    'E' 'COLTEXT'     '거래처명',

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

    'S' 'FIELDNAME'   'WERKS',
    ' ' 'REF_FIELD'   'WERKS',
    ' ' 'REF_TABLE'   'MARC',
    ' ' 'KEY'         'X',
    'E' 'COLTEXT'     '플랜트',

    'S' 'FIELDNAME'   'LGORT',
    ' ' 'REF_FIELD'   'LGORT',
    ' ' 'REF_TABLE'   'MARD',
    ' ' 'KEY'         'X',
    'E' 'COLTEXT'     '저장위치',

    'S' 'FIELDNAME'   'GR_QTY',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    'E' 'COLTEXT'     '당월 생산량',

    'S' 'FIELDNAME'   'OPEN_STK',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    ' ' 'NO_ZERO'     'X',
    'E' 'COLTEXT'     '기초재고',

    'S' 'FIELDNAME'   'END_STK',
    ' ' 'QFIELDNAME'  'MEINS',
    ' ' 'DATATYPE'    'QUAN',
    ' ' 'NO_ZERO'     'X',
    'E' 'COLTEXT'     '기말재고',

    'S' 'FIELDNAME'   'RATE_PROD',
    'E' 'COLTEXT'     '수주합계 대비 당월생산량',

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

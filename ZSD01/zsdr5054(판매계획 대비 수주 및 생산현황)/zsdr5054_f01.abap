*&---------------------------------------------------------------------*
*& Include ZSDR5054_F01
*&---------------------------------------------------------------------*
*& 판매계획     : 사무소 + 영업사원 + 거래처 + 자재 + 플랜트. ZSDT0400-SPMNG
*& 전월 미출하  : ZSDR1100 미결수량.
*&                출하지점/입고지점은 화면값. 비우면 전체.
*&                판매 VBAP-VSTEL, 재고운송 EKPO-RESLO.
*&                납품일은 전월 1일의 10년 전 ~ 전월 말일.
*&                2026.11 이면 2016.10.01 ~ 2026.10.31.
*&                2026.12 이면 2016.11.01 ~ 2026.11.30.
*&                승인완료만. ZSDT1150-STEPS = 'F'.
*&                일정선 확정수량 - 품목 납품수량. 0 이하면 더하지 않는다.
*&                납품수량은 ZSDR1100 과 같이 LIPS-LFIMG. 조건은 VGBEL + VGPOS.
*&                납품완료(VBUP-LFSTA/LFGSA C, EKPO-ELIKZ X)는 0.
*& 당월 수주량  : ZSDR1100 오더수량. 화면 참조는 VBAP-KWMENG.
*&                ZSDR1100 이 그 칸에 넣는 값은 일정선 확정수량 VBEP-BMENG.
*&                출하예정일이 조회월인 일정선만. 승인완료만. ZSDT1150-STEPS = 'F'.
*&                재고운송은 EKKO-RESWK, EKPO-RESLO, 품목수량 EKPO-MENGE 한 번.
*&                납품일이 조회월이고 승인완료면 오더수량.
*& 수주 합계    : 전월 미출하 + 당월 수주량.
*& 출하량       : ZSDR5002 [적송]출하수량. 납품요청일 LIKP-LFDAT.
*&                저장위치 LIPS-LGORT 가 9000 또는 CY00 인 LIPS-LFIMG.
*&                플랜트 LIPS-WERKS, 판매처 LIKP-KUNAG. 반품오더는 음수.
*& 수주 잔량    : 수주합계 - 출하량
*& 당월 생산량  : ZSDR0065 생산(구매)입고(MENGE_GR_NOR). 전기일 MKPF-BUDAT.
*&                101/102/131/132 는 차변 가산, 대변 차감.
*&                911 은 차변만 입고, 912 는 대변만 입고취소.
*&                자재 + 플랜트 + 저장위치당 한 행. 기타입고는 넣지 않는다.
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

*& ZSDR0065 생산(구매)입고. 정상입고 101/102/131/132, 입고 911, 입고취소 912.
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
  PERFORM fill_stock.
  PERFORM fill_sd_stock.
  PERFORM keep_loc_once.
  PERFORM fill_order.
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
         END OF ty_sh,
         BEGIN OF ty_mk,
           matnr TYPE matnr,
           kunnr TYPE kunnr,
         END OF ty_mk,
         BEGIN OF ty_sv,
           matnr TYPE matnr,
           vkbur TYPE vkbur,
           kunnr TYPE kunnr,
         END OF ty_sv,
         BEGIN OF ty_ix,
           matnr TYPE matnr,
           kunnr TYPE kunnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_ix,
         BEGIN OF ty_gx,
           matnr TYPE matnr,
           vkbur TYPE vkbur,
           kunnr TYPE kunnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
         END OF ty_gx.
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
        lt_mk   TYPE STANDARD TABLE OF ty_mk,
        ls_mk   TYPE ty_mk,
        lt_mpk  TYPE STANDARD TABLE OF ty_mk,
        lt_sv   TYPE STANDARD TABLE OF ty_sv,
        ls_sv   TYPE ty_sv,
        lt_spk  TYPE STANDARD TABLE OF ty_sv,
        lt_ix   TYPE SORTED TABLE OF ty_ix
                  WITH UNIQUE KEY matnr kunnr werks lgort,
        ls_ix   TYPE ty_ix,
        lt_gx   TYPE SORTED TABLE OF ty_gx
                  WITH UNIQUE KEY matnr vkbur kunnr werks lgort,
        ls_gx   TYPE ty_gx,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

  lt_base[] = gt_data[].

* 같은 자재·거래처는 한 번만 읽는다. 전월과 당월 일정을 한 조회로 가져온다.
  LOOP AT lt_base INTO gs_data.
    ls_mk-matnr = gs_data-matnr.
    ls_mk-kunnr = gs_data-kunnr.
    APPEND ls_mk TO lt_mk.
    ls_sv-matnr = gs_data-matnr.
    ls_sv-vkbur = gs_data-vkbur.
    ls_sv-kunnr = gs_data-kunnr.
    APPEND ls_sv TO lt_sv.
  ENDLOOP.
  SORT lt_mk BY matnr kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_mk COMPARING matnr kunnr.
  SORT lt_sv BY matnr vkbur kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_sv COMPARING matnr vkbur kunnr.

  DESCRIBE TABLE lt_mk LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 499.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_mpk.
    APPEND LINES OF lt_mk FROM lv_from TO lv_to TO lt_mpk.

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
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND b~werks IN so_werks
        AND c~kunnr = lt_mpk-kunnr
        AND b~lgort IN so_lgort
        AND e~edatu <= gv_last
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
    SELECT b~matnr a~reswk AS werks d~kunnr b~reslo AS lgort
      FROM ekko AS a
      INNER JOIN ekpo AS b
        ON b~ebeln = a~ebeln
      INNER JOIN eket AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
      INNER JOIN ekpv AS d
        ON d~ebeln = b~ebeln
       AND d~ebelp = b~ebelp
      INTO CORRESPONDING FIELDS OF TABLE lt_ol
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND a~reswk IN so_werks
        AND d~kunnr = lt_mpk-kunnr
        AND b~reslo IN so_lgort
        AND c~eindt <= gv_last
        AND a~memorytype = space
        AND b~loekz = space
        AND b~menge <> 0.
    LOOP AT lt_ol INTO ls_ol.
      INSERT ls_ol INTO TABLE lt_ordl.
    ENDLOOP.

    lv_from = lv_to + 1.
  ENDWHILE.

  DESCRIBE TABLE lt_sv LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 499.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_spk.
    APPEND LINES OF lt_sv FROM lv_from TO lv_to TO lt_spk.
    REFRESH lt_ship.
    SELECT b~matnr b~werks b~lgort b~vkbur
           d~kunnr AS person a~kunag AS kunnr
      FROM likp AS a
      INNER JOIN lips AS b
        ON b~vbeln = a~vbeln
      INNER JOIN knvv AS k
        ON k~kunnr = a~kunnr
       AND k~vkorg = a~vkorg
       AND k~vtweg = '10'
       AND k~spart = '10'
      LEFT JOIN vbpa AS d
        ON d~vbeln = a~vbeln
       AND d~posnr = space
       AND d~parvw = 'S1'
      INTO CORRESPONDING FIELDS OF TABLE lt_ship
      FOR ALL ENTRIES IN lt_spk
      WHERE b~matnr = lt_spk-matnr
        AND b~werks IN so_werks
        AND b~lgort IN so_lgort
        AND b~vkbur = lt_spk-vkbur
        AND a~kunag = lt_spk-kunnr
        AND a~lfdat BETWEEN gv_first AND gv_last.
    LOOP AT lt_ship INTO ls_ship.
      CLEAR ls_ol.
      ls_ol-matnr  = ls_ship-matnr.
      ls_ol-werks  = ls_ship-werks.
      ls_ol-vkbur  = ls_ship-vkbur.
      ls_ol-person = ls_ship-person.
      ls_ol-kunnr  = ls_ship-kunnr.
      ls_ol-lgort  = ls_ship-lgort.
      INSERT ls_ol INTO TABLE lt_gil.
    ENDLOOP.
    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT lt_ordl INTO ls_ol.
    ls_ix-matnr = ls_ol-matnr.
    ls_ix-kunnr = ls_ol-kunnr.
    ls_ix-werks = ls_ol-werks.
    ls_ix-lgort = ls_ol-lgort.
    INSERT ls_ix INTO TABLE lt_ix.
  ENDLOOP.
  LOOP AT lt_gil INTO ls_ol.
    ls_gx-matnr = ls_ol-matnr.
    ls_gx-vkbur = ls_ol-vkbur.
    ls_gx-kunnr = ls_ol-kunnr.
    ls_gx-werks = ls_ol-werks.
    ls_gx-lgort = ls_ol-lgort.
    INSERT ls_gx INTO TABLE lt_gx.
  ENDLOOP.

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
    LOOP AT lt_ix INTO ls_ix
      WHERE matnr = gs_data-matnr
        AND kunnr = gs_data-kunnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_ix-werks.
      ls_wl-lgort = ls_ix-lgort.
      INSERT ls_wl INTO TABLE lt_wl.
    ENDLOOP.
    LOOP AT lt_gx INTO ls_gx
      WHERE matnr = gs_data-matnr
        AND vkbur = gs_data-vkbur
        AND kunnr = gs_data-kunnr.
      CLEAR ls_wl.
      ls_wl-werks = ls_gx-werks.
      ls_wl-lgort = ls_gx-lgort.
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

*& 전월 미출하 = ZSDR1100 미결. 출하지점, 전월말까지 10년, 승인완료.
*& 당월 수주량 = ZSDR1100 오더수량. 조회월 일정선, 승인완료.
FORM fill_order.
  TYPES: BEGIN OF ty_mat,
           matnr TYPE matnr,
         END OF ty_mat,
         BEGIN OF ty_sal,
           vbeln  TYPE vbeln_va,
           posnr  TYPE posnr_va,
           etenr  TYPE etenr,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           edatu  TYPE edatu,
           bmeng  TYPE bmeng,
         END OF ty_sal,
         BEGIN OF ty_opn,
           vbeln  TYPE vbeln_va,
           posnr  TYPE posnr_va,
           etenr  TYPE etenr,
           matnr  TYPE matnr,
           werks  TYPE werks_d,
           lgort  TYPE lgort_d,
           vstel  TYPE vstel,
           edatu  TYPE edatu,
           bmeng  TYPE bmeng,
         END OF ty_opn,
         BEGIN OF ty_sto,
           ebeln TYPE ebeln,
           ebelp TYPE ebelp,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
           edatu TYPE eindt,
           menge TYPE bstmg,
         END OF ty_sto,
         BEGIN OF ty_one,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           matnr TYPE matnr,
           werks TYPE werks_d,
           lgort TYPE lgort_d,
           menge TYPE kwmeng,
           month TYPE c,
         END OF ty_one,
         BEGIN OF ty_item,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
         END OF ty_item,
         BEGIN OF ty_doc,
           vbeln TYPE vbeln_va,
         END OF ty_doc,
         BEGIN OF ty_dlv,
           vgbel TYPE vgbel,
           vgpos TYPE vgpos,
           lfimg TYPE lfimg,
         END OF ty_dlv,
         BEGIN OF ty_flow,
           vbelv TYPE vbfa-vbelv,
           posnv TYPE vbfa-posnv,
           rfmng TYPE vbfa-rfmng,
         END OF ty_flow,
         BEGIN OF ty_lf,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           lfimg TYPE lfimg,
         END OF ty_lf,
         BEGIN OF ty_ek,
           ebeln TYPE ebeln,
           ebelp TYPE ebelp,
           wamng TYPE bstmg,
           elikz TYPE elikz,
         END OF ty_ek,
         BEGIN OF ty_appr,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
         END OF ty_appr,
         BEGIN OF ty_stp,
           vbeln TYPE vbeln_va,
           posnr TYPE posnr_va,
           steps TYPE zsdt1150-steps,
         END OF ty_stp,
         BEGIN OF ty_sum,
           matnr    TYPE matnr,
           werks    TYPE werks_d,
           lgort    TYPE lgort_d,
           open_qty TYPE kwmeng,
           ord_qty  TYPE kwmeng,
         END OF ty_sum.
  DATA: lt_mat  TYPE STANDARD TABLE OF ty_mat,
        ls_mat  TYPE ty_mat,
        lt_mpk  TYPE STANDARD TABLE OF ty_mat,
        lt_sal  TYPE STANDARD TABLE OF ty_sal,
        lt_sale TYPE STANDARD TABLE OF ty_sal,
        lt_opn  TYPE STANDARD TABLE OF ty_opn,
        lt_open TYPE STANDARD TABLE OF ty_opn,
        ls_opn  TYPE ty_opn,
        ls_sal  TYPE ty_sal,
        ls_hold TYPE ty_sto,
        lt_sto  TYPE STANDARD TABLE OF ty_sto,
        ls_sto  TYPE ty_sto,
        lt_stoa TYPE STANDARD TABLE OF ty_sto,
        lt_stoo TYPE STANDARD TABLE OF ty_sto,
        lt_one  TYPE STANDARD TABLE OF ty_one,
        ls_one  TYPE ty_one,
        lt_item TYPE STANDARD TABLE OF ty_item,
        ls_item TYPE ty_item,
        lt_appr TYPE SORTED TABLE OF ty_appr
                  WITH UNIQUE KEY vbeln posnr,
        ls_appr TYPE ty_appr,
        lt_stp  TYPE STANDARD TABLE OF ty_stp,
        ls_stp  TYPE ty_stp,
        lt_ipk  TYPE STANDARD TABLE OF ty_item,
        lt_doc  TYPE STANDARD TABLE OF ty_doc,
        ls_doc  TYPE ty_doc,
        lt_dlv  TYPE STANDARD TABLE OF ty_dlv,
        ls_dlv  TYPE ty_dlv,
        lt_flow TYPE STANDARD TABLE OF ty_flow,
        ls_flow TYPE ty_flow,
        lt_lf   TYPE SORTED TABLE OF ty_lf WITH UNIQUE KEY vbeln posnr,
        ls_lf   TYPE ty_lf,
        lt_ship TYPE SORTED TABLE OF ty_lf WITH UNIQUE KEY vbeln posnr,
        lt_add  TYPE SORTED TABLE OF ty_lf WITH UNIQUE KEY vbeln posnr,
        lt_done TYPE SORTED TABLE OF ty_item WITH UNIQUE KEY vbeln posnr,
        lt_ek   TYPE STANDARD TABLE OF ty_ek,
        ls_ek   TYPE ty_ek,
        lv_del  TYPE kwmeng,
        lt_sum  TYPE SORTED TABLE OF ty_sum
                  WITH UNIQUE KEY matnr werks lgort,
        ls_sum  TYPE ty_sum,
        ls_src  TYPE ty_data,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i,
        lv_tabix TYPE sy-tabix,
        lv_open TYPE kwmeng,
        lv_ord  TYPE kwmeng,
        lv_open_from TYPE datum,
        lv_open_to TYPE datum,
        lv_year TYPE n LENGTH 4,
        lv_posnr TYPE posnr_va,
        lv_vstel TYPE vstel,
        lv_ebeln TYPE ebeln,
        lv_ebelp TYPE ebelp,
        lv_month TYPE c,
        lv_hit TYPE c.

  IF gt_data[] IS INITIAL.
    RETURN.
  ENDIF.

* 전월 1일의 10년 전 ~ 전월 말일.
* 2026.11 이면 2016.10.01 ~ 2026.10.31.
* 2026.12 이면 2016.11.01 ~ 2026.11.30.
  lv_open_to = gv_first - 1.
  lv_year = lv_open_to(4).
  lv_year = lv_year - 10.
  CONCATENATE lv_year lv_open_to+4(2) '01' INTO lv_open_from.

  LOOP AT gt_data INTO gs_data.
    CHECK gs_data-matnr IS NOT INITIAL.
    ls_mat-matnr = gs_data-matnr.
    APPEND ls_mat TO lt_mat.
  ENDLOOP.
  SORT lt_mat BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_mat COMPARING matnr.

  DESCRIBE TABLE lt_mat LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 399.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_mpk.
    APPEND LINES OF lt_mat FROM lv_from TO lv_to TO lt_mpk.

    REFRESH lt_sal.
    SELECT b~vbeln b~posnr e~etenr
           b~matnr b~werks b~lgort
           e~edatu e~bmeng
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS h
        ON h~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO TABLE lt_sal
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND b~werks IN so_werks
        AND b~lgort IN so_lgort
        AND c~kunnr IN so_kunnr
        AND e~edatu <> '00000000'
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND h~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.
    SORT lt_sal BY vbeln posnr etenr.
    DELETE ADJACENT DUPLICATES FROM lt_sal COMPARING vbeln posnr etenr.
    APPEND LINES OF lt_sal TO lt_sale.

*   전월 미출하. 출하지점과 납품일만. 플랜트·저장위치는 걸지 않는다.
    REFRESH lt_opn.
    SELECT b~vbeln b~posnr e~etenr
           b~matnr b~werks b~lgort b~vstel
           e~edatu e~bmeng
      FROM vbak AS c
      INNER JOIN vbap AS b
        ON b~vbeln = c~vbeln
      INNER JOIN vbuk AS h
        ON h~vbeln = c~vbeln
      INNER JOIN vbep AS e
        ON e~vbeln = b~vbeln
       AND e~posnr = b~posnr
      INTO TABLE lt_opn
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND b~vstel IN so_vstel
        AND c~kunnr IN so_kunnr
        AND e~edatu >= lv_open_from
        AND e~edatu <= lv_open_to
        AND b~abgru = space
        AND c~auart <> 'ZCR'
        AND c~auart <> 'ZDR'
        AND c~auart <> 'ZTH'
        AND c~auart <> 'ZRH'
        AND h~cmgst IN (space, 'A', 'D')
        AND e~bmeng <> 0.
    APPEND LINES OF lt_opn TO lt_open.

    REFRESH lt_sto.
    SELECT a~ebeln b~ebelp b~matnr
           a~reswk AS werks
           b~reslo AS lgort
           c~eindt AS edatu
           b~menge AS menge
      FROM ekko AS a
      INNER JOIN ekpo AS b
        ON b~ebeln = a~ebeln
      INNER JOIN eket AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
      INNER JOIN ekpv AS d
        ON d~ebeln = b~ebeln
       AND d~ebelp = b~ebelp
      INTO TABLE lt_sto
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND a~reswk IN so_werks
        AND b~reslo IN so_lgort
        AND d~kunnr IN so_kunnr
        AND c~eindt <> '00000000'
        AND a~memorytype = space
        AND b~loekz = space
        AND b~menge <> 0.
    APPEND LINES OF lt_sto TO lt_stoa.

*   전월 미출하 재고운송. 입고지점은 EKPO-RESLO.
    REFRESH lt_sto.
    SELECT a~ebeln b~ebelp b~matnr
           a~reswk AS werks
           b~reslo AS lgort
           c~eindt AS edatu
           b~menge AS menge
      FROM ekko AS a
      INNER JOIN ekpo AS b
        ON b~ebeln = a~ebeln
      INNER JOIN eket AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
      INNER JOIN ekpv AS d
        ON d~ebeln = b~ebeln
       AND d~ebelp = b~ebelp
      INTO TABLE lt_sto
      FOR ALL ENTRIES IN lt_mpk
      WHERE b~matnr = lt_mpk-matnr
        AND b~reslo IN so_vstel
        AND d~kunnr IN so_kunnr
        AND c~eindt >= lv_open_from
        AND c~eindt <= lv_open_to
        AND a~memorytype = space
        AND b~loekz = space
        AND b~menge <> 0.
    APPEND LINES OF lt_sto TO lt_stoo.

    lv_from = lv_to + 1.
  ENDWHILE.

  SORT lt_stoa BY ebeln ebelp edatu.
  CLEAR: lv_ebeln, lv_ebelp, lv_month.
  LOOP AT lt_stoa INTO ls_sto.
    IF ls_sto-ebeln <> lv_ebeln OR ls_sto-ebelp <> lv_ebelp.
      IF lv_ebeln IS NOT INITIAL AND lv_month = 'X'.
        CLEAR ls_one.
        ls_one-vbeln = lv_ebeln.
        ls_one-posnr = lv_ebelp.
        ls_one-matnr = ls_hold-matnr.
        ls_one-werks = ls_hold-werks.
        ls_one-lgort = ls_hold-lgort.
        ls_one-menge = ls_hold-menge.
        ls_one-month = lv_month.
        APPEND ls_one TO lt_one.
      ENDIF.
      lv_ebeln = ls_sto-ebeln.
      lv_ebelp = ls_sto-ebelp.
      ls_hold = ls_sto.
      CLEAR lv_month.
    ENDIF.
    IF ls_sto-edatu >= gv_first AND ls_sto-edatu <= gv_last.
      lv_month = 'X'.
    ENDIF.
  ENDLOOP.
  IF lv_ebeln IS NOT INITIAL AND lv_month = 'X'.
    CLEAR ls_one.
    ls_one-vbeln = lv_ebeln.
    ls_one-posnr = lv_ebelp.
    ls_one-matnr = ls_hold-matnr.
    ls_one-werks = ls_hold-werks.
    ls_one-lgort = ls_hold-lgort.
    ls_one-menge = ls_hold-menge.
    ls_one-month = lv_month.
    APPEND ls_one TO lt_one.
  ENDIF.

  LOOP AT lt_open INTO ls_opn.
    ls_item-vbeln = ls_opn-vbeln.
    ls_item-posnr = ls_opn-posnr.
    APPEND ls_item TO lt_item.
  ENDLOOP.
  LOOP AT lt_stoo INTO ls_sto.
    lv_posnr = ls_sto-ebelp.
    ls_item-vbeln = ls_sto-ebeln.
    ls_item-posnr = lv_posnr.
    APPEND ls_item TO lt_item.
  ENDLOOP.
  LOOP AT lt_sale INTO ls_sal.
    CHECK ls_sal-edatu >= gv_first AND ls_sal-edatu <= gv_last.
    ls_item-vbeln = ls_sal-vbeln.
    ls_item-posnr = ls_sal-posnr.
    APPEND ls_item TO lt_item.
  ENDLOOP.
  LOOP AT lt_one INTO ls_one.
    ls_item-vbeln = ls_one-vbeln.
    ls_item-posnr = ls_one-posnr.
    APPEND ls_item TO lt_item.
  ENDLOOP.
  SORT lt_item BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM lt_item COMPARING vbeln posnr.
  DELETE lt_item WHERE vbeln = space.

  IF lt_item[] IS NOT INITIAL.
    DESCRIBE TABLE lt_item LINES lv_lines.
    lv_from = 1.
    WHILE lv_from <= lv_lines.
      lv_to = lv_from + 399.
      IF lv_to > lv_lines.
        lv_to = lv_lines.
      ENDIF.
      REFRESH lt_ipk.
      APPEND LINES OF lt_item FROM lv_from TO lv_to TO lt_ipk.
      REFRESH: lt_doc, lt_dlv.
      LOOP AT lt_ipk INTO ls_item.
        ls_doc-vbeln = ls_item-vbeln.
        APPEND ls_doc TO lt_doc.
      ENDLOOP.
      SORT lt_doc BY vbeln.
      DELETE ADJACENT DUPLICATES FROM lt_doc COMPARING vbeln.
*     납품수량은 계산 때 ZSDR1100 과 같이 VGBEL + VGPOS 로 읽는다.
*     납품완료는 미결 0.
      IF lt_doc[] IS NOT INITIAL.
        REFRESH: lt_flow, lt_add.
        SELECT vbelv posnv rfmng
          FROM vbfa
          INTO TABLE lt_flow
          FOR ALL ENTRIES IN lt_doc
          WHERE vbelv = lt_doc-vbeln
            AND vbtyp_n = 'J'.
        LOOP AT lt_flow INTO ls_flow.
          CLEAR ls_lf.
          ls_lf-vbeln = ls_flow-vbelv.
          lv_posnr = ls_flow-posnv.
          ls_lf-posnr = lv_posnr.
          ls_lf-lfimg = ls_flow-rfmng.
          COLLECT ls_lf INTO lt_add.
        ENDLOOP.
        LOOP AT lt_add INTO ls_lf.
          lv_del = ls_lf-lfimg.
          lv_ebeln = ls_lf-vbeln.
          lv_posnr = ls_lf-posnr.
          READ TABLE lt_lf INTO ls_lf
            WITH TABLE KEY vbeln = lv_ebeln
                           posnr = lv_posnr.
          IF sy-subrc <> 0.
            CLEAR ls_lf.
            ls_lf-vbeln = lv_ebeln.
            ls_lf-posnr = lv_posnr.
            ls_lf-lfimg = lv_del.
            INSERT ls_lf INTO TABLE lt_lf.
          ELSEIF lv_del > ls_lf-lfimg.
            ls_lf-lfimg = lv_del.
            MODIFY lt_lf FROM ls_lf INDEX sy-tabix.
          ENDIF.
        ENDLOOP.
        REFRESH: lt_ek, lt_add.
        SELECT ebeln ebelp wamng
          FROM eket
          INTO CORRESPONDING FIELDS OF TABLE lt_ek
          FOR ALL ENTRIES IN lt_doc
          WHERE ebeln = lt_doc-vbeln.
        LOOP AT lt_ek INTO ls_ek.
          CLEAR ls_lf.
          ls_lf-vbeln = ls_ek-ebeln.
          lv_posnr = ls_ek-ebelp.
          ls_lf-posnr = lv_posnr.
          ls_lf-lfimg = ls_ek-wamng.
          COLLECT ls_lf INTO lt_add.
        ENDLOOP.
        LOOP AT lt_add INTO ls_lf.
          lv_del = ls_lf-lfimg.
          lv_ebeln = ls_lf-vbeln.
          lv_posnr = ls_lf-posnr.
          READ TABLE lt_lf INTO ls_lf
            WITH TABLE KEY vbeln = lv_ebeln
                           posnr = lv_posnr.
          IF sy-subrc <> 0.
            CLEAR ls_lf.
            ls_lf-vbeln = lv_ebeln.
            ls_lf-posnr = lv_posnr.
            ls_lf-lfimg = lv_del.
            INSERT ls_lf INTO TABLE lt_lf.
          ELSEIF lv_del > ls_lf-lfimg.
            ls_lf-lfimg = lv_del.
            MODIFY lt_lf FROM ls_lf INDEX sy-tabix.
          ENDIF.
        ENDLOOP.
        SELECT vbeln posnr lfsta
          FROM vbup
          INTO TABLE lt_stp
          FOR ALL ENTRIES IN lt_ipk
          WHERE vbeln = lt_ipk-vbeln
            AND posnr = lt_ipk-posnr
            AND ( lfsta = 'C' OR lfgsa = 'C' ).
        LOOP AT lt_stp INTO ls_stp.
          CLEAR ls_item.
          ls_item-vbeln = ls_stp-vbeln.
          ls_item-posnr = ls_stp-posnr.
          INSERT ls_item INTO TABLE lt_done.
        ENDLOOP.
        REFRESH lt_ek.
        SELECT ebeln ebelp elikz
          FROM ekpo
          INTO CORRESPONDING FIELDS OF TABLE lt_ek
          FOR ALL ENTRIES IN lt_doc
          WHERE ebeln = lt_doc-vbeln
            AND elikz = 'X'.
        LOOP AT lt_ek INTO ls_ek.
          CLEAR ls_item.
          ls_item-vbeln = ls_ek-ebeln.
          lv_posnr = ls_ek-ebelp.
          ls_item-posnr = lv_posnr.
          INSERT ls_item INTO TABLE lt_done.
        ENDLOOP.
      ENDIF.
      REFRESH lt_stp.
      SELECT vbeln posnr steps
        FROM zsdt1150
        INTO TABLE lt_stp
        FOR ALL ENTRIES IN lt_ipk
        WHERE vbeln = lt_ipk-vbeln
          AND posnr = lt_ipk-posnr.
      LOOP AT lt_stp INTO ls_stp.
        CHECK ls_stp-steps = 'F'.
        CLEAR ls_appr.
        ls_appr-vbeln = ls_stp-vbeln.
        ls_appr-posnr = ls_stp-posnr.
        INSERT ls_appr INTO TABLE lt_appr.
      ENDLOOP.
      lv_from = lv_to + 1.
    ENDWHILE.
  ENDIF.

  REFRESH lt_sum.
  LOOP AT lt_sale INTO ls_sal.
    CLEAR lv_ord.
    IF ls_sal-edatu >= gv_first AND ls_sal-edatu <= gv_last.
      READ TABLE lt_appr TRANSPORTING NO FIELDS
        WITH KEY vbeln = ls_sal-vbeln
                 posnr = ls_sal-posnr.
      IF sy-subrc = 0.
        lv_ord = ls_sal-bmeng.
      ENDIF.
    ENDIF.
    IF lv_ord = 0.
      CONTINUE.
    ENDIF.
    READ TABLE lt_sum INTO ls_sum
      WITH KEY matnr = ls_sal-matnr
               werks = ls_sal-werks
               lgort = ls_sal-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_sum.
      ls_sum-matnr = ls_sal-matnr.
      ls_sum-werks = ls_sal-werks.
      ls_sum-lgort = ls_sal-lgort.
      INSERT ls_sum INTO TABLE lt_sum.
      READ TABLE lt_sum INTO ls_sum
        WITH KEY matnr = ls_sal-matnr
                 werks = ls_sal-werks
                 lgort = ls_sal-lgort.
    ENDIF.
    ls_sum-ord_qty = ls_sum-ord_qty + lv_ord.
    MODIFY lt_sum FROM ls_sum INDEX sy-tabix.
  ENDLOOP.

  LOOP AT lt_one INTO ls_one.
    CLEAR lv_ord.
    IF ls_one-month = 'X'.
      READ TABLE lt_appr TRANSPORTING NO FIELDS
        WITH KEY vbeln = ls_one-vbeln
                 posnr = ls_one-posnr.
      IF sy-subrc = 0.
        lv_ord = ls_one-menge.
      ENDIF.
    ENDIF.
    IF lv_ord = 0.
      CONTINUE.
    ENDIF.
    READ TABLE lt_sum INTO ls_sum
      WITH KEY matnr = ls_one-matnr
               werks = ls_one-werks
               lgort = ls_one-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_sum.
      ls_sum-matnr = ls_one-matnr.
      ls_sum-werks = ls_one-werks.
      ls_sum-lgort = ls_one-lgort.
      INSERT ls_sum INTO TABLE lt_sum.
      READ TABLE lt_sum INTO ls_sum
        WITH KEY matnr = ls_one-matnr
                 werks = ls_one-werks
                 lgort = ls_one-lgort.
    ENDIF.
    ls_sum-ord_qty = ls_sum-ord_qty + lv_ord.
    MODIFY lt_sum FROM ls_sum INDEX sy-tabix.
  ENDLOOP.

  LOOP AT lt_open INTO ls_opn.
    READ TABLE lt_appr TRANSPORTING NO FIELDS
      WITH KEY vbeln = ls_opn-vbeln
               posnr = ls_opn-posnr.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF ls_opn-vstel NOT IN so_vstel.
      CONTINUE.
    ENDIF.
    READ TABLE lt_done TRANSPORTING NO FIELDS
      WITH TABLE KEY vbeln = ls_opn-vbeln
                     posnr = ls_opn-posnr.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.
    CLEAR ls_lf.
    READ TABLE lt_ship INTO ls_lf
      WITH TABLE KEY vbeln = ls_opn-vbeln
                     posnr = ls_opn-posnr.
    IF sy-subrc <> 0.
      CLEAR ls_lf.
      ls_lf-vbeln = ls_opn-vbeln.
      ls_lf-posnr = ls_opn-posnr.
      SELECT SUM( lfimg )
        FROM lips
        INTO ls_lf-lfimg
        WHERE vgbel = ls_opn-vbeln
          AND vgpos = ls_opn-posnr.
      IF sy-subrc <> 0.
        CLEAR ls_lf-lfimg.
      ENDIF.
      INSERT ls_lf INTO TABLE lt_ship.
    ENDIF.
    lv_open = ls_opn-bmeng - ls_lf-lfimg.
    IF lv_open <= 0.
      CONTINUE.
    ENDIF.
    READ TABLE lt_sum INTO ls_sum
      WITH KEY matnr = ls_opn-matnr
               werks = ls_opn-werks
               lgort = ls_opn-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_sum.
      ls_sum-matnr = ls_opn-matnr.
      ls_sum-werks = ls_opn-werks.
      ls_sum-lgort = ls_opn-lgort.
      INSERT ls_sum INTO TABLE lt_sum.
      READ TABLE lt_sum INTO ls_sum
        WITH KEY matnr = ls_opn-matnr
                 werks = ls_opn-werks
                 lgort = ls_opn-lgort.
    ENDIF.
    ls_sum-open_qty = ls_sum-open_qty + lv_open.
    MODIFY lt_sum FROM ls_sum INDEX sy-tabix.
  ENDLOOP.

  LOOP AT lt_stoo INTO ls_sto.
    CLEAR lv_open.
    lv_posnr = ls_sto-ebelp.
    READ TABLE lt_appr TRANSPORTING NO FIELDS
      WITH KEY vbeln = ls_sto-ebeln
               posnr = lv_posnr.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    lv_vstel = ls_sto-lgort.
    IF lv_vstel NOT IN so_vstel.
      CONTINUE.
    ENDIF.
    READ TABLE lt_done TRANSPORTING NO FIELDS
      WITH TABLE KEY vbeln = ls_sto-ebeln
                     posnr = lv_posnr.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.
    CLEAR ls_lf.
    READ TABLE lt_ship INTO ls_lf
      WITH TABLE KEY vbeln = ls_sto-ebeln
                     posnr = lv_posnr.
    IF sy-subrc <> 0.
      CLEAR ls_lf.
      ls_lf-vbeln = ls_sto-ebeln.
      ls_lf-posnr = lv_posnr.
      SELECT SUM( lfimg )
        FROM lips
        INTO ls_lf-lfimg
        WHERE vgbel = ls_sto-ebeln
          AND vgpos = lv_posnr.
      IF sy-subrc <> 0.
        CLEAR ls_lf-lfimg.
      ENDIF.
      INSERT ls_lf INTO TABLE lt_ship.
    ENDIF.
    lv_open = ls_sto-menge - ls_lf-lfimg.
    IF lv_open <= 0.
      CONTINUE.
    ENDIF.
    READ TABLE lt_sum INTO ls_sum
      WITH KEY matnr = ls_sto-matnr
               werks = ls_sto-werks
               lgort = ls_sto-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_sum.
      ls_sum-matnr = ls_sto-matnr.
      ls_sum-werks = ls_sto-werks.
      ls_sum-lgort = ls_sto-lgort.
      INSERT ls_sum INTO TABLE lt_sum.
      READ TABLE lt_sum INTO ls_sum
        WITH KEY matnr = ls_sto-matnr
                 werks = ls_sto-werks
                 lgort = ls_sto-lgort.
    ENDIF.
    ls_sum-open_qty = ls_sum-open_qty + lv_open.
    MODIFY lt_sum FROM ls_sum INDEX sy-tabix.
  ENDLOOP.

  LOOP AT lt_sum INTO ls_sum.
    CLEAR lv_hit.
    LOOP AT gt_data INTO gs_data
      WHERE matnr = ls_sum-matnr
        AND werks = ls_sum-werks
        AND lgort = ls_sum-lgort.
      lv_tabix = sy-tabix.
      gs_data-open_qty = ls_sum-open_qty.
      gs_data-ord_qty = ls_sum-ord_qty.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
      lv_hit = 'X'.
      EXIT.
    ENDLOOP.
    IF lv_hit = 'X'.
      CONTINUE.
    ENDIF.
    CLEAR gs_data.
    READ TABLE gt_data INTO ls_src
      WITH KEY matnr = ls_sum-matnr
               werks = ls_sum-werks.
    IF sy-subrc <> 0.
      READ TABLE gt_data INTO ls_src
        WITH KEY matnr = ls_sum-matnr.
    ENDIF.
    gs_data-matnr     = ls_sum-matnr.
    gs_data-spmon     = p_spmon.
    gs_data-werks     = ls_sum-werks.
    gs_data-lgort     = ls_sum-lgort.
    gs_data-open_qty  = ls_sum-open_qty.
    gs_data-ord_qty   = ls_sum-ord_qty.
    gs_data-maktx     = ls_src-maktx.
    gs_data-meins     = ls_src-meins.
    gs_data-dispo     = ls_src-dispo.
    gs_data-dispo_txt = ls_src-dispo_txt.
    IF gs_data-meins IS INITIAL.
      gs_data-meins = 'KG'.
    ENDIF.
    APPEND gs_data TO gt_data.
  ENDLOOP.
ENDFORM.

*& 생산량은 ZSDR0065 생산(구매)입고. 자재+플랜트+저장위치. 전기일 조회월.
*& 출하량은 ZSDR5002 [적송]출하수량. 저장위치 9000, CY00. 납품요청일 LIKP-LFDAT.
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
           vbeln  TYPE vbeln_vl,
           posnr  TYPE posnr_vl,
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
           lgort  TYPE lgort_d,
           vkbur  TYPE vkbur,
           person TYPE kunnr,
           kunnr  TYPE kunnr,
         END OF ty_drv,
         BEGIN OF ty_nm,
           kunnr TYPE kunnr,
           name1 TYPE name1_gp,
         END OF ty_nm,
         BEGIN OF ty_vk,
           vkbur TYPE vkbur,
           bezei TYPE tvkbt-bezei,
         END OF ty_vk.
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
        lt_new  TYPE STANDARD TABLE OF ty_gi,
        lt_nm   TYPE STANDARD TABLE OF ty_nm,
        ls_nm   TYPE ty_nm,
        lt_kna  TYPE SORTED TABLE OF ty_nm WITH UNIQUE KEY kunnr,
        lt_vk   TYPE SORTED TABLE OF ty_vk WITH UNIQUE KEY vkbur,
        ls_vk   TYPE ty_vk,
        ls_src  TYPE ty_data,
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

* 자재문서의 플랜트·저장위치별로 읽는다. 계획 행의 저장위치에 묶지 않는다.
  REFRESH lt_drv.
  LOOP AT gt_data INTO gs_data.
    CLEAR ls_drv.
    ls_drv-matnr = gs_data-matnr.
    APPEND ls_drv TO lt_drv.
  ENDLOOP.
  SORT lt_drv BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_drv COMPARING matnr.

  IF lt_drv[] IS NOT INITIAL.
    DESCRIBE TABLE lt_drv LINES lv_lines.
    lv_from = 1.
    WHILE lv_from <= lv_lines.
      lv_to = lv_from + 399.
      IF lv_to > lv_lines.
        lv_to = lv_lines.
      ENDIF.
      REFRESH lt_dpk.
      APPEND LINES OF lt_drv FROM lv_from TO lv_to TO lt_dpk.
      REFRESH lt_mvg.
*     문서번호를 함께 읽는다. 수량이 같은 입고를 한 건으로 지우지 않기 위함.
      SELECT b~mblnr b~mjahr b~zeile
             b~matnr b~werks b~lgort b~bwart b~shkzg b~menge
        FROM mseg AS b
        INNER JOIN mkpf AS a
          ON a~mblnr = b~mblnr
         AND a~mjahr = b~mjahr
        INTO TABLE lt_mvg
        FOR ALL ENTRIES IN lt_dpk
        WHERE b~matnr = lt_dpk-matnr
          AND b~werks IN so_werks
          AND b~lgort IN so_lgort
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
*       ZSDR0065 FORM data_modify 의 생산(구매)입고와 같은 부호.
        CLEAR lv_qty.
        IF ls_mvg-bwart = '101' OR ls_mvg-bwart = '102'
        OR ls_mvg-bwart = '131' OR ls_mvg-bwart = '132'.
          IF ls_mvg-shkzg = 'S'.
            lv_qty = ls_mvg-menge.
          ELSEIF ls_mvg-shkzg = 'H'.
            lv_qty = 0 - ls_mvg-menge.
          ENDIF.
        ELSEIF ls_mvg-bwart = '911'.
          IF ls_mvg-shkzg = 'S'.
            lv_qty = ls_mvg-menge.
          ENDIF.
        ELSEIF ls_mvg-bwart = '912'.
          IF ls_mvg-shkzg = 'H'.
            lv_qty = 0 - ls_mvg-menge.
          ENDIF.
        ENDIF.
        ls_gr-menge = ls_gr-menge + lv_qty.
        MODIFY lt_gr FROM ls_gr INDEX sy-tabix.
      ENDLOOP.
      lv_from = lv_to + 1.
    ENDWHILE.
  ENDIF.

  REFRESH lt_drv.
  LOOP AT gt_data INTO gs_data.
    CLEAR ls_drv.
    ls_drv-matnr = gs_data-matnr.
    APPEND ls_drv TO lt_drv.
  ENDLOOP.
  SORT lt_drv BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_drv COMPARING matnr.

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
*   납품번호, 품목을 같이 읽는다. FOR ALL ENTRIES 는 같은 결과 행을 한 건으로 지운다.
    SELECT b~vbeln b~posnr
           b~matnr b~werks b~lgort
           b~vkbur d~kunnr AS person a~kunag AS kunnr
           b~lfimg f~auart
      FROM likp AS a
      INNER JOIN lips AS b
        ON b~vbeln = a~vbeln
      INNER JOIN knvv AS k
        ON k~kunnr = a~kunnr
       AND k~vkorg = a~vkorg
       AND k~vtweg = '10'
       AND k~spart = '10'
      LEFT JOIN vbpa AS d
        ON d~vbeln = a~vbeln
       AND d~posnr = space
       AND d~parvw = 'S1'
      LEFT JOIN vbak AS f
        ON f~vbeln = b~vgbel
      INTO CORRESPONDING FIELDS OF TABLE lt_shp
      FOR ALL ENTRIES IN lt_dpk
      WHERE b~matnr = lt_dpk-matnr
        AND b~werks IN so_werks
        AND b~lgort IN so_lgort
        AND a~kunag IN so_kunnr
        AND a~lfdat BETWEEN gv_first AND gv_last.
    LOOP AT lt_shp INTO ls_shp.
      lv_lgort = ls_shp-lgort.
*     ZSDR5002 [적송]출하수량. 저장위치 9000, CY00 만 출하요청수량을 쓴다.
      IF lv_lgort <> '9000' AND lv_lgort <> 'CY00'.
        CONTINUE.
      ENDIF.
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
    ELSE.
      APPEND ls_gi TO lt_new.
    ENDIF.
  ENDLOOP.

* 판매계획에 없는 판매처의 출하요청수량도 행으로 남긴다.
  IF lt_new[] IS NOT INITIAL.
    LOOP AT lt_new INTO ls_gi.
      ls_nm-kunnr = ls_gi-kunnr.
      APPEND ls_nm TO lt_nm.
      ls_nm-kunnr = ls_gi-person.
      APPEND ls_nm TO lt_nm.
    ENDLOOP.
    SORT lt_nm BY kunnr.
    DELETE ADJACENT DUPLICATES FROM lt_nm COMPARING kunnr.
    DELETE lt_nm WHERE kunnr = space.
    IF lt_nm[] IS NOT INITIAL.
      SELECT kunnr name1
        FROM kna1
        INTO TABLE lt_kna
        FOR ALL ENTRIES IN lt_nm
        WHERE kunnr = lt_nm-kunnr.
    ENDIF.
    SELECT vkbur bezei
      FROM tvkbt
      INTO TABLE lt_vk
      FOR ALL ENTRIES IN lt_new
      WHERE spras = sy-langu
        AND vkbur = lt_new-vkbur.
    LOOP AT lt_new INTO ls_gi.
      CLEAR gs_data.
      READ TABLE gt_data INTO ls_src
        WITH KEY matnr = ls_gi-matnr
                 werks = ls_gi-werks.
      IF sy-subrc <> 0.
        READ TABLE gt_data INTO ls_src
          WITH KEY matnr = ls_gi-matnr.
      ENDIF.
      gs_data-matnr     = ls_gi-matnr.
      gs_data-spmon     = p_spmon.
      gs_data-werks     = ls_gi-werks.
      gs_data-lgort     = ls_gi-lgort.
      gs_data-vkbur     = ls_gi-vkbur.
      gs_data-person    = ls_gi-person.
      gs_data-kunnr     = ls_gi-kunnr.
      gs_data-gi_qty    = ls_gi-menge.
      gs_data-maktx     = ls_src-maktx.
      gs_data-meins     = ls_src-meins.
      gs_data-dispo     = ls_src-dispo.
      gs_data-dispo_txt = ls_src-dispo_txt.
      READ TABLE lt_vk INTO ls_vk
        WITH KEY vkbur = ls_gi-vkbur.
      IF sy-subrc = 0.
        gs_data-vkbtx = ls_vk-bezei.
      ENDIF.
      READ TABLE lt_kna INTO ls_nm
        WITH KEY kunnr = ls_gi-kunnr.
      IF sy-subrc = 0.
        gs_data-kuntx = ls_nm-name1.
      ENDIF.
      READ TABLE lt_kna INTO ls_nm
        WITH KEY kunnr = ls_gi-person.
      IF sy-subrc = 0.
        gs_data-pertx = ls_nm-name1.
      ENDIF.
      APPEND gs_data TO gt_data.
    ENDLOOP.
  ENDIF.

* 생산(구매)입고가 있는 플랜트·저장위치는 행마다 같은 수량을 둔다.
* 행이 없으면 그 플랜트·저장위치 행을 만든다.
  LOOP AT lt_gr INTO ls_gr.
    IF ls_gr-menge = 0.
      CONTINUE.
    ENDIF.
    CLEAR lv_tabix.
    LOOP AT gt_data INTO gs_data
      WHERE matnr = ls_gr-matnr
        AND werks = ls_gr-werks
        AND lgort = ls_gr-lgort.
      lv_tabix = sy-tabix.
      gs_data-gr_qty = ls_gr-menge.
      MODIFY gt_data FROM gs_data INDEX lv_tabix.
    ENDLOOP.
    IF lv_tabix > 0.
      CONTINUE.
    ENDIF.
    CLEAR gs_data.
    READ TABLE gt_data INTO ls_src
      WITH KEY matnr = ls_gr-matnr
               werks = ls_gr-werks.
    IF sy-subrc <> 0.
      READ TABLE gt_data INTO ls_src
        WITH KEY matnr = ls_gr-matnr.
    ENDIF.
    gs_data-matnr     = ls_gr-matnr.
    gs_data-spmon     = p_spmon.
    gs_data-werks     = ls_gr-werks.
    gs_data-lgort     = ls_gr-lgort.
    gs_data-gr_qty    = ls_gr-menge.
    gs_data-maktx     = ls_src-maktx.
    gs_data-meins     = ls_src-meins.
    gs_data-dispo     = ls_src-dispo.
    gs_data-dispo_txt = ls_src-dispo_txt.
    APPEND gs_data TO gt_data.
  ENDLOOP.
ENDFORM.

*& 기초/기말재고는 행의 플랜트와 저장위치.
*& ZMMF01_GET_STOCK 과 같은 계산을 MARD, MARDH 한 번 조회로 한다.
TYPES: BEGIN OF ty_srow,
         matnr TYPE matnr,
         werks TYPE werks_d,
         lgort TYPE lgort_d,
         lfgja TYPE lfgja,
         lfmon TYPE lfmon,
         labst TYPE labst,
         insme TYPE insme,
         speme TYPE speme,
       END OF ty_srow,
       BEGIN OF ty_sper,
         matnr TYPE matnr,
         werks TYPE werks_d,
         lgort TYPE lgort_d,
         spmon TYPE spmon,
         labst TYPE labst,
         insme TYPE insme,
         speme TYPE speme,
       END OF ty_sper,
       BEGIN OF ty_scur,
         matnr TYPE matnr,
         werks TYPE werks_d,
         lgort TYPE lgort_d,
         labst TYPE labst,
       END OF ty_scur.
DATA: gt_s_per TYPE SORTED TABLE OF ty_sper
                WITH UNIQUE KEY matnr werks lgort spmon,
      gt_s_lat TYPE SORTED TABLE OF ty_sper
                WITH UNIQUE KEY matnr werks lgort,
      gt_s_cur TYPE SORTED TABLE OF ty_scur
                WITH UNIQUE KEY matnr werks lgort.

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
        lt_bat TYPE STANDARD TABLE OF ty_key,
        lt_raw TYPE STANDARD TABLE OF ty_srow,
        ls_raw TYPE ty_srow,
        lt_stk TYPE SORTED TABLE OF ty_stk WITH UNIQUE KEY matnr werks lgort,
        ls_stk TYPE ty_stk,
        lv_prev TYPE datum,
        lv_ym   TYPE spmon,
        lv_labst TYPE labst,
        lv_tabix TYPE sy-tabix,
        lv_from TYPE i,
        lv_to   TYPE i,
        lv_lines TYPE i.

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

  REFRESH: gt_s_per, gt_s_lat, gt_s_cur.
  DESCRIBE TABLE lt_key LINES lv_lines.
  lv_from = 1.
  WHILE lv_from <= lv_lines.
    lv_to = lv_from + 499.
    IF lv_to > lv_lines.
      lv_to = lv_lines.
    ENDIF.
    REFRESH lt_bat.
    APPEND LINES OF lt_key FROM lv_from TO lv_to TO lt_bat.
    IF lt_bat[] IS INITIAL.
      lv_from = lv_to + 1.
      CONTINUE.
    ENDIF.
    SELECT matnr werks lgort lfgja lfmon labst insme speme
      FROM mard
      INTO TABLE lt_raw
      FOR ALL ENTRIES IN lt_bat
      WHERE matnr = lt_bat-matnr
        AND werks = lt_bat-werks
        AND lgort = lt_bat-lgort.
    LOOP AT lt_raw INTO ls_raw.
      PERFORM add_scur USING ls_raw-matnr ls_raw-werks ls_raw-lgort
                             ls_raw-labst.
      PERFORM add_sper USING ls_raw-matnr ls_raw-werks ls_raw-lgort
                             ls_raw-lfgja ls_raw-lfmon
                             ls_raw-labst ls_raw-insme ls_raw-speme.
    ENDLOOP.
    SELECT matnr werks lgort lfgja lfmon labst insme speme
      FROM mardh
      INTO TABLE lt_raw
      FOR ALL ENTRIES IN lt_bat
      WHERE matnr = lt_bat-matnr
        AND werks = lt_bat-werks
        AND lgort = lt_bat-lgort.
    LOOP AT lt_raw INTO ls_raw.
      PERFORM add_sper USING ls_raw-matnr ls_raw-werks ls_raw-lgort
                             ls_raw-lfgja ls_raw-lfmon
                             ls_raw-labst ls_raw-insme ls_raw-speme.
    ENDLOOP.
    lv_from = lv_to + 1.
  ENDWHILE.

  LOOP AT lt_key INTO ls_key.
    CLEAR ls_stk.
    ls_stk-matnr = ls_key-matnr.
    ls_stk-werks = ls_key-werks.
    ls_stk-lgort = ls_key-lgort.
    PERFORM stock_at USING ls_key-matnr ls_key-werks ls_key-lgort lv_ym
                     CHANGING lv_labst.
    ls_stk-openq = lv_labst.
    PERFORM stock_at USING ls_key-matnr ls_key-werks ls_key-lgort p_spmon
                     CHANGING lv_labst.
    ls_stk-endq = lv_labst.
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

FORM add_scur USING p_matnr TYPE matnr
                    p_werks TYPE werks_d
                    p_lgort TYPE lgort_d
                    p_labst TYPE labst.
  DATA ls_cur TYPE ty_scur.
  READ TABLE gt_s_cur TRANSPORTING NO FIELDS
    WITH KEY matnr = p_matnr
             werks = p_werks
             lgort = p_lgort.
  IF sy-subrc = 0.
    RETURN.
  ENDIF.
  ls_cur-matnr = p_matnr.
  ls_cur-werks = p_werks.
  ls_cur-lgort = p_lgort.
  ls_cur-labst = p_labst.
  INSERT ls_cur INTO TABLE gt_s_cur.
ENDFORM.

FORM add_sper USING p_matnr TYPE matnr
                    p_werks TYPE werks_d
                    p_lgort TYPE lgort_d
                    p_lfgja TYPE lfgja
                    p_lfmon TYPE lfmon
                    p_labst TYPE labst
                    p_insme TYPE insme
                    p_speme TYPE speme.
  DATA: ls_per TYPE ty_sper,
        ls_lat TYPE ty_sper.
  ls_per-matnr = p_matnr.
  ls_per-werks = p_werks.
  ls_per-lgort = p_lgort.
  CONCATENATE p_lfgja p_lfmon INTO ls_per-spmon.
  ls_per-labst = p_labst.
  ls_per-insme = p_insme.
  ls_per-speme = p_speme.
  READ TABLE gt_s_per TRANSPORTING NO FIELDS
    WITH KEY matnr = ls_per-matnr
             werks = ls_per-werks
             lgort = ls_per-lgort
             spmon = ls_per-spmon.
  IF sy-subrc <> 0.
    INSERT ls_per INTO TABLE gt_s_per.
  ENDIF.
  READ TABLE gt_s_lat INTO ls_lat
    WITH KEY matnr = ls_per-matnr
             werks = ls_per-werks
             lgort = ls_per-lgort.
  IF sy-subrc <> 0.
    INSERT ls_per INTO TABLE gt_s_lat.
  ELSEIF ls_per-spmon > ls_lat-spmon.
    ls_lat-spmon = ls_per-spmon.
    ls_lat-labst = ls_per-labst.
    ls_lat-insme = ls_per-insme.
    ls_lat-speme = ls_per-speme.
    MODIFY gt_s_lat FROM ls_lat INDEX sy-tabix.
  ENDIF.
ENDFORM.

*& ZMMF01_GET_STOCK 과 같은 월말재고.
FORM stock_at USING p_matnr TYPE matnr
                    p_werks TYPE werks_d
                    p_lgort TYPE lgort_d
                    p_spmon TYPE spmon
              CHANGING p_labst TYPE labst.
  DATA: ls_per TYPE ty_sper,
        ls_lat TYPE ty_sper,
        ls_cur TYPE ty_scur,
        lv_date TYPE datum.
  CLEAR p_labst.
  IF p_spmon >= sy-datum(6).
    READ TABLE gt_s_cur INTO ls_cur
      WITH KEY matnr = p_matnr
               werks = p_werks
               lgort = p_lgort.
    IF sy-subrc = 0.
      p_labst = ls_cur-labst.
    ENDIF.
    RETURN.
  ENDIF.
  READ TABLE gt_s_per INTO ls_per
    WITH KEY matnr = p_matnr
             werks = p_werks
             lgort = p_lgort
             spmon = p_spmon.
  IF sy-subrc = 0.
    p_labst = ls_per-labst + ls_per-insme + ls_per-speme.
    RETURN.
  ENDIF.
  READ TABLE gt_s_lat INTO ls_lat
    WITH KEY matnr = p_matnr
             werks = p_werks
             lgort = p_lgort.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  IF p_spmon > ls_lat-spmon.
    p_labst = ls_lat-labst + ls_lat-insme + ls_lat-speme.
    RETURN.
  ENDIF.
  lv_date = p_spmon.
  lv_date+6(2) = '01'.
  DO 12 TIMES.
    CALL FUNCTION 'MONTH_PLUS_DETERMINE'
      EXPORTING
        months  = 1
        olddate = lv_date
      IMPORTING
        newdate = lv_date.
    IF lv_date(6) = sy-datum(6).
      p_labst = ls_lat-labst + ls_lat-insme + ls_lat-speme.
      RETURN.
    ENDIF.
    READ TABLE gt_s_per INTO ls_per
      WITH KEY matnr = p_matnr
               werks = p_werks
               lgort = p_lgort
               spmon = lv_date(6).
    IF sy-subrc = 0.
      p_labst = ls_per-labst + ls_per-insme + ls_per-speme.
      RETURN.
    ENDIF.
  ENDDO.
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

* 생산, 재고는 자재+플랜트+저장위치당 한 행.
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
*& 생산량, 기초재고, 기말재고는 자재+플랜트+저장위치당 한 번만 더한다.
*& 사무소명 정렬 때문에 수량이 0인 행이 먼저 나와도 실제 수량을 더한다.
*& 같은 수량이 거래처 행마다 반복되면 다시 더하지 않는다.
FORM fill_sum_rows.
  TYPES: BEGIN OF ty_grk,
           matnr    TYPE matnr,
           werks    TYPE werks_d,
           lgort    TYPE lgort_d,
           gr_qty   TYPE kwmeng,
           open_stk TYPE labst,
           end_stk  TYPE labst,
           gr_set   TYPE c,
           op_set   TYPE c,
           en_set   TYPE c,
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
        ls_all TYPE ty_grk,
        lt_pln TYPE SORTED TABLE OF ty_pln
                 WITH UNIQUE KEY matnr werks vkbur person kunnr,
        lt_plna TYPE SORTED TABLE OF ty_pln
                  WITH UNIQUE KEY matnr werks vkbur person kunnr,
        ls_pln TYPE ty_pln,
        lv_vk  TYPE tvkbt-bezei,
        lv_on  TYPE c,
        lv_tabix TYPE sy-tabix.

  DEFINE add_kept.
    IF &1 <> 0.
      IF &2 = space OR &1 <> &3.
        &4 = &4 + &1.
        &3 = &1.
        &2 = 'X'.
      ENDIF.
    ENDIF.
  END-OF-DEFINITION.

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

    READ TABLE lt_gr INTO ls_gr
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks
               lgort = gs_data-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_gr.
      ls_gr-matnr = gs_data-matnr.
      ls_gr-werks = gs_data-werks.
      ls_gr-lgort = gs_data-lgort.
      INSERT ls_gr INTO TABLE lt_gr.
    ENDIF.
    lv_tabix = sy-tabix.
    add_kept gs_data-gr_qty   ls_gr-gr_set ls_gr-gr_qty   ls_sub-gr_qty.
    add_kept gs_data-open_stk ls_gr-op_set ls_gr-open_stk ls_sub-open_stk.
    add_kept gs_data-end_stk  ls_gr-en_set ls_gr-end_stk  ls_sub-end_stk.
    MODIFY lt_gr FROM ls_gr INDEX lv_tabix.

    READ TABLE lt_all INTO ls_all
      WITH KEY matnr = gs_data-matnr
               werks = gs_data-werks
               lgort = gs_data-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_all.
      ls_all-matnr = gs_data-matnr.
      ls_all-werks = gs_data-werks.
      ls_all-lgort = gs_data-lgort.
      INSERT ls_all INTO TABLE lt_all.
    ENDIF.
    lv_tabix = sy-tabix.
    add_kept gs_data-gr_qty   ls_all-gr_set ls_all-gr_qty   ls_tot-gr_qty.
    add_kept gs_data-open_stk ls_all-op_set ls_all-open_stk ls_tot-open_stk.
    add_kept gs_data-end_stk  ls_all-en_set ls_all-end_stk  ls_tot-end_stk.
    MODIFY lt_all FROM ls_all INDEX lv_tabix.
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
  PERFORM show_office_hide_customer USING gv_grid_0100.
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
    ' ' 'NO_OUT'      'X',
    ' ' 'TECH'        'X',
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

*& 저장된 레이아웃과 관계없이 사무소는 보이게, 거래처명은 숨긴다.
FORM show_office_hide_customer USING p_grid TYPE REF TO cl_gui_alv_grid.
  DATA: lt_fcat TYPE lvc_t_fcat,
        ls_fcat TYPE lvc_s_fcat,
        lv_pos  TYPE i,
        lv_tabix TYPE sy-tabix.

  CHECK p_grid IS NOT INITIAL.

  CALL METHOD p_grid->get_frontend_fieldcatalog
    IMPORTING
      et_fieldcatalog = lt_fcat.

  READ TABLE lt_fcat INTO ls_fcat WITH KEY fieldname = 'KUNTX'.
  IF sy-subrc = 0.
    lv_pos = ls_fcat-col_pos.
  ENDIF.

  LOOP AT lt_fcat INTO ls_fcat.
    lv_tabix = sy-tabix.
    CASE ls_fcat-fieldname.
      WHEN 'KUNTX'.
        ls_fcat-no_out = 'X'.
        ls_fcat-tech   = 'X'.
        MODIFY lt_fcat FROM ls_fcat INDEX lv_tabix.
      WHEN 'VKBTX'.
        CLEAR: ls_fcat-no_out, ls_fcat-tech.
        IF lv_pos IS NOT INITIAL.
          ls_fcat-col_pos = lv_pos.
        ENDIF.
        MODIFY lt_fcat FROM ls_fcat INDEX lv_tabix.
    ENDCASE.
  ENDLOOP.

  CALL METHOD p_grid->set_frontend_fieldcatalog
    EXPORTING
      it_fieldcatalog = lt_fcat.

  CALL METHOD p_grid->refresh_table_display.
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

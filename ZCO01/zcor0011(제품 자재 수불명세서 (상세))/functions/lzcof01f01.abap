*----------------------------------------------------------------------*
***INCLUDE LZCOF01F01 .
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  REFRESH_INTERNAL_TABLE
*&---------------------------------------------------------------------*
FORM refresh_internal_table .
  REFRESH:  gt_wzubb_pu,  gt_wzubb_po, gt_wzubb_mt, gt_wagbb_mt,
            gt_wzubb_su,  gt_wzubb_st,  gt_wzubb_et,  gt_wzubb_pr,
            gt_wzubb_th,  gt_wzubb_co,  gt_wzubb_cp,  gt_wzubb_ivp,
            gt_wzubb_ivs, gt_wzubb_sap, gt_wzubb_mlp, gt_wagbb_jr,
            gt_wagbb_mc,  gt_wagbb_ys,  gt_wagbb_st,  gt_wagbb_su,
            gt_wagbb_et,  gt_wagbb_th,  gt_wagbb_pi,  gt_wagbb_co.
  CLEAR:    gt_wzubb_pu,  gt_wzubb_po, gt_wzubb_mt, gt_wagbb_mt,
            gt_wzubb_su,  gt_wzubb_st,  gt_wzubb_et,  gt_wzubb_pr,
            gt_wzubb_th,  gt_wzubb_co,  gt_wzubb_cp,  gt_wzubb_ivp,
            gt_wzubb_ivs, gt_wzubb_sap, gt_wzubb_mlp, gt_wagbb_jr,
            gt_wagbb_mc,  gt_wagbb_ys,  gt_wagbb_st,  gt_wagbb_su,
            gt_wagbb_et,  gt_wagbb_th,  gt_wagbb_pi,  gt_wagbb_co.
  CLEAR: gr_bwart[], gr_werks[], gr_matnr[], gr_mblnr[], gr_matnr_8[].

  MOVE: 'I'             TO gs_matnr_8-sign,
        'CP'            TO gs_matnr_8-option,
        '00000000008*'  TO gs_matnr_8-low.
  APPEND gs_matnr_8 TO gr_matnr_8.
ENDFORM.                    " REFRESH_INTERNAL_TABLE

*&---------------------------------------------------------------------*
*&      Form  ADD_DATA_TO_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_BKPFS  text
*      -->P_IT_BSEGS  text
*      -->P_6868   text
*----------------------------------------------------------------------*
FORM add_data_to_table  USING    ps_bkpf TYPE bkpf
                                 ps_bseg  TYPE bseg
                                 p_tabname.
  DATA: l_tabname TYPE tabname,
        l_struct  TYPE tabname.

  "-- 2013.03.04 추가 ---------------------------
  DATA: l_error(1).
  CLEAR l_error.
  PERFORM check_bklas_by_data USING ps_bseg-matnr
                                    ps_bseg-bwtar
                                    l_error.
  CHECK l_error IS INITIAL.
  "----------------------------------------------

  FIELD-SYMBOLS: <dyn_table> TYPE STANDARD TABLE,
                 <fs> TYPE zcos0005.

  CONCATENATE: p_tabname '[]' INTO l_tabname.
  ASSIGN: (p_tabname) TO <fs>,
          (l_tabname) TO <dyn_table>.

  CLEAR <fs>.
  MOVE-CORRESPONDING ps_bseg TO <fs>.
  MOVE: g_waers       TO <fs>-waers,
        ps_bkpf-blart TO <fs>-blart,
        ps_bkpf-budat TO <fs>-budat,
        ps_bkpf-awkey TO <fs>-awkey.
  APPEND <fs> TO <dyn_table>.
ENDFORM.                    " ADD_DATA_TO_TABLE

*&---------------------------------------------------------------------*
*&      Form  ADD_DATA_TO_TABLE_BY_MSEG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG  text
*      -->P_1448   text
*----------------------------------------------------------------------*
FORM add_data_to_table_by_mseg  USING    ps_mseg LIKE it_mseg
                                         p_tabname.
  DATA: l_tabname TYPE tabname,
        l_struct  TYPE tabname.

  "-- 2013.03.04 추가 ---------------------------
  DATA: l_error(1).
  CLEAR l_error.
  PERFORM check_bklas_by_data USING ps_mseg-matnr
                                    ps_mseg-bwtar
                                    l_error.
  CHECK l_error IS INITIAL.
  "-----------------------------------------------

  FIELD-SYMBOLS: <dyn_table> TYPE STANDARD TABLE,
                 <fs> TYPE zcos0005.

  CONCATENATE: p_tabname '[]' INTO l_tabname.
  ASSIGN: (p_tabname) TO <fs>,
          (l_tabname) TO <dyn_table>.

  CLEAR <fs>.
  MOVE-CORRESPONDING ps_mseg TO <fs>.
  MOVE: ps_mseg-sakto     TO <fs>-hkont,
        ps_mseg-kdauf     TO <fs>-vbel2,
        ps_mseg-kdpos     TO <fs>-posn2,
        g_waers           TO <fs>-waers.
  CONCATENATE ps_mseg-mblnr ps_mseg-gjahr INTO <fs>-awkey.
  IF ps_mseg-belnr IS INITIAL.
    MOVE ps_mseg-mblnr TO <fs>-belnr.
  ENDIF.
  APPEND <fs> TO <dyn_table>.
ENDFORM.                    " ADD_DATA_TO_TABLE_BY_MSEG

*&---------------------------------------------------------------------*
*&      Form  ADJUST_DATA
*&---------------------------------------------------------------------*
FORM adjust_data .
  DELETE: gt_wzubb_pu   WHERE dmbtr IS INITIAL,
          gt_wzubb_po   WHERE dmbtr IS INITIAL,
          gt_wzubb_su   WHERE dmbtr IS INITIAL,
          gt_wzubb_st   WHERE dmbtr IS INITIAL,
          gt_wzubb_et   WHERE dmbtr IS INITIAL,
          gt_wzubb_pr   WHERE dmbtr IS INITIAL,
          gt_wzubb_th   WHERE dmbtr IS INITIAL,
          gt_wzubb_co   WHERE dmbtr IS INITIAL,
          gt_wzubb_cp   WHERE dmbtr IS INITIAL,
          gt_wzubb_ivp  WHERE dmbtr IS INITIAL,
          gt_wzubb_ivs  WHERE dmbtr IS INITIAL,
          gt_wzubb_sap  WHERE dmbtr IS INITIAL,
          gt_wzubb_mlp  WHERE dmbtr IS INITIAL,
          gt_wagbb_jr   WHERE dmbtr IS INITIAL,
          gt_wagbb_mc   WHERE dmbtr IS INITIAL,
          gt_wagbb_ys   WHERE dmbtr IS INITIAL,
          gt_wagbb_st   WHERE dmbtr IS INITIAL,
          gt_wagbb_su   WHERE dmbtr IS INITIAL,
          gt_wagbb_et   WHERE dmbtr IS INITIAL,
          gt_wagbb_th   WHERE dmbtr IS INITIAL,
          gt_wagbb_pi   WHERE dmbtr IS INITIAL,
          gt_wagbb_co   WHERE dmbtr IS INITIAL.

ENDFORM.                    " ADJUST_DATA

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_PU_ZCOT090
*&---------------------------------------------------------------------*
FORM mzubb_wzubb_pu_zcot090 .
  CLEAR : it_zcot090.
  READ TABLE it_zcot090 WITH KEY bwart = it_mseg-bwart
                                 zshkzg = it_mseg-shkzg.
ENDFORM.                    " MZUBB_WZUBB_PU_ZCOT090

*&---------------------------------------------------------------------*
*&      Form  READ_DATA_0003_11_1Z
*&---------------------------------------------------------------------*
FORM read_data_0003_11_1z .
*---- 이동유형 101 ~ 123 의 경우 생산/구매/공장간지원/사급 구분
  IF it_mseg-bwart BETWEEN '101' AND '123'.
    PERFORM p2022_calc_gubun_rtn.
  ENDIF.

  IF   it_mseg-pocls   EQ    space.
    CASE it_zcot090-gubun.
*- 구매입고
*- 입고-구매가격차이
      WHEN '11'.
        IF it_mseg-bwart = '411'
                OR it_mseg-bwart = '412'
  .
          PERFORM mzubb_wzubb_ppu USING it_mseg-matnr
                                        it_mseg-werks.


        ELSE.
          PERFORM mzubb_wzubb_pu USING it_mseg-matnr
                                       it_mseg-werks
                                       it_mseg-ebeln
                                       it_mseg-ebelp
                                       ct_pstyp0.
        ENDIF.

      WHEN '12'.
*- 생산입고
        PERFORM mzubb_wzubb_po USING it_mseg-aufnr.
        PERFORM r1000_mzubb_wzubb_po USING it_mseg-matnr
                                           it_mseg-werks.

      WHEN '13'.
        PERFORM p2025_add_to_13_rtn.
*- 외주가공입고(무상사급)
*- 입고-원가차이
        PERFORM mzubb_wzubb_su USING it_mseg-matnr
                                     it_mseg-werks
                                     it_mseg-ebeln
                                     it_mseg-ebelp
                                     ct_pstyp3.

      WHEN '14'.
*- 공장간이전입고
*- 입고-원가차이
        PERFORM mzubb_wzubb_st USING it_mseg-matnr
                                     it_mseg-werks.

*--입고 - 자재간이전.
      WHEN '1A'.
        PERFORM mzubb_wzubb_mt USING it_mseg-matnr
                                     it_mseg-werks.

      WHEN '15'.
*- 타계정입고
        PERFORM mzubb_wzubb_et USING it_mseg-matnr
                                     it_mseg-werks.

    ENDCASE.
  ENDIF.
ENDFORM.                    " READ_DATA_0003_11_1Z

*&---------------------------------------------------------------------*
*&      Form  P2022_CALC_GUBUN_RTN
*&---------------------------------------------------------------------*
FORM p2022_calc_gubun_rtn .
*---- 입고(무상사급)
  IF it_mseg-pstyp = '3'.
    it_zcot090-gubun = '13'.
*---- 입고(생산)
  ELSEIF it_mseg-aufnr NE ' '.
    it_zcot090-gubun = '12'.
*---- 입고(구매)
  ELSE.
    it_zcot090-gubun = '11'.
  ENDIF.
ENDFORM.                    " P2022_CALC_GUBUN_RTN

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_PPU
*&---------------------------------------------------------------------*
FORM mzubb_wzubb_ppu  USING    p_u0 p_u1.
  PERFORM move_rule_data_rtn.
  it_zcot097-mzubb_pu = it_mseg-menge.
  it_zcot097-wzubb_pu = it_mseg-dmbtr.

  """입고금액(구매).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_PU'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR(ML)
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                            CHANGING it_bsegr-dmbtr.
        it_zcot097-wzubb_pu = it_zcot097-wzubb_pu + it_bsegr-dmbtr.

        ""입고금액(구매).""////////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WZUBB_PU'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.

*- IT_BSEGS(ML 이외)
    LOOP AT it_bsegs WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = ct_gubun19
                                     hkont = it_bsegs-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                            CHANGING it_bsegs-dmbtr.
        it_zcot097-wzubb_cp = it_zcot097-wzubb_cp + it_bsegs-dmbtr.
        ""입고금액(구매가격차이).""////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CP'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.

  ENDIF.
*
*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MZUBB_WZUBB_PPU

*&---------------------------------------------------------------------*
*&      Form  MOVE_RULE_DATA_RTN
*&---------------------------------------------------------------------*
FORM move_rule_data_rtn .
  IF it_zcot090-cacul EQ '-'.
    it_mseg-menge = it_mseg-menge * -1.
    it_mseg-dmbtr = it_mseg-dmbtr * -1.
  ENDIF.

  CLEAR it_zcot097.
  it_zcot097-bukrs    = it_mseg-bukrs.    "UP01..---------------
  it_zcot097-werks    = it_mseg-werks.
  it_zcot097-spmon    = it_mseg-budat+0(6).
  it_zcot097-matnr    = it_mseg-matnr.
  it_zcot097-bwtar    = it_mseg-bwtar.
*  IT_ZCOT097-MEINS    = IT_MSEG-MEINS.
*  PERFORM select_mara_meins USING it_mseg-matnr. " Material 단위
*  IT_ZCOT097-WAERS    = IT_MSEG-WAERS.
  it_zcot097-waers    = g_waers.
ENDFORM.                    " MOVE_RULE_DATA_RTN

*&---------------------------------------------------------------------*
*&      Form  MSEG_BKPF_BSEG
*&---------------------------------------------------------------------*
FORM mseg_bkpf_bseg  USING    p_u1 p_u2 p_u3.
*- PR: 가격변경
*  RE: 송장 - 총액
*  SA: G/L 계정전표
*  ML: ML 정산
*  WE: 입고

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
  SELECT blart bukrs belnr gjahr awkey waers FROM bkpf
    APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfs
    WHERE bukrs EQ g_bukrs    "UP01.----------------------------
      AND awkey EQ p_u1
      AND blart IN ('PR', 'RE', 'SA', 'ML', 'WE', 'WL', 'WA', 'WI'
                     , 'WX')
    AND   budat BETWEEN g_from AND g_till.
*  AND   STBLG EQ SPACE.
  DESCRIBE TABLE it_bkpfs LINES max_cnt.
  IF max_cnt < 0.
  ELSE.
    LOOP AT it_bkpfs.
      IF it_bkpfs-blart = 'ML'.
        SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr matnr werks
               bwtar vbel2 posn2 ebeln ebelp prctr"pswsl AS waers
        FROM bseg
        APPENDING CORRESPONDING FIELDS OF TABLE it_bsegr
        WHERE bukrs EQ it_bkpfs-bukrs
        AND   belnr EQ it_bkpfs-belnr
        AND   gjahr EQ it_bkpfs-gjahr
        AND   matnr EQ p_u2
        AND   werks EQ p_u3.
      ENDIF.
*      ELSE.
      SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr matnr werks
             bwtar vbel2 posn2 ebeln ebelp prctr"pswsl AS waers
        FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      WHERE bukrs EQ it_bkpfs-bukrs
      AND   belnr EQ it_bkpfs-belnr
      AND   gjahr EQ it_bkpfs-gjahr
      AND   matnr EQ p_u2
      AND   werks EQ p_u3.
*      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " MSEG_BKPF_BSEG

*&---------------------------------------------------------------------*
*&      Form  SHKZG_DMBTR
*&---------------------------------------------------------------------*
FORM shkzg_dmbtr  USING    p_u1
                  CHANGING p_u2.

  IF p_u1 = 'H'.
    p_u2 = p_u2 * ( -1 ).
  ENDIF.

ENDFORM.                    " SHKZG_DMBTR

*&---------------------------------------------------------------------*
*&      Form  APPEND_IT_LEGER
*&---------------------------------------------------------------------*
FORM append_it_leger  USING    p_u1
                               p_u2
                               p_u3.
  it_leger-awkey = p_u1.
  it_leger-matnr = p_u2.
  it_leger-werks = p_u3.
  APPEND it_leger.
  CLEAR  it_leger.
ENDFORM.                    " APPEND_IT_LEGER

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_PU
*&---------------------------------------------------------------------*
FORM mzubb_wzubb_pu  USING    p_u0
                              p_u1
                              p_u2
                              p_u3
                              p_u4.
*  MSEG에서 구매오더 범주가 "0"인 경우만 해당 (EKPO-PSTYP)
*  Setting된 이동유형 및 MSEG의 수량
*  1) MSEG의 금액 포함
*  2) 해당 자재문서번호와 연결된 회계전표 중 전표유형이 ML이 있는경우에
*     BSEG-KOART가 "M"인 금액을 포함

  SELECT SINGLE * FROM ekpo
  WHERE ebeln EQ p_u2
  AND   ebelp EQ p_u3
*  AND   LOEKZ EQ SPACE
  AND   pstyp EQ p_u4.
  IF sy-subrc = 0.
    PERFORM move_rule_data_rtn.
    it_zcot097-mzubb_pu = it_mseg-menge.
    it_zcot097-wzubb_pu = it_mseg-dmbtr.
    """입고금액(구매).""////////////////////////////////////////
    PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_PU'.
    "////////////////////////////////////////////////////////////

*- 오브젝트키
    CLEAR : ed_awkey.
    CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
    READ TABLE it_leger WITH KEY awkey = ed_awkey
                                 matnr = p_u0
                                 werks = p_u1.
    IF sy-subrc = 0.
    ELSE.
      PERFORM mseg_bkpf_bseg USING ed_awkey
                                   p_u0
                                   p_u1.
*- IT_BSEGR(ML)
      LOOP AT it_bsegr WHERE matnr EQ p_u0
                       AND   werks EQ p_u1.
        READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                       hkont = it_bsegr-hkont.
        IF sy-subrc = 0.
          PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
          it_zcot097-wzubb_pu = it_zcot097-wzubb_pu + it_bsegr-dmbtr.
          ""입고금액(구매).""////////////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegr
                                          'GT_WZUBB_PU'.
          "//////////////////////////////////////////////////////////
          PERFORM append_it_leger USING ed_awkey
                                        p_u0
                                        p_u1.
        ENDIF.
      ENDLOOP.

*- IT_BSEGS(ML 이외)
      LOOP AT it_bsegs WHERE matnr EQ p_u0
                       AND   werks EQ p_u1.
        READ TABLE it_zcot091 WITH KEY gubun = ct_gubun19
                                       hkont = it_bsegs-hkont.
        IF sy-subrc = 0.
          PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                              CHANGING it_bsegs-dmbtr.
          it_zcot097-wzubb_cp = it_zcot097-wzubb_cp + it_bsegs-dmbtr.
          ""입고금액(구매가격차이).""////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegs
                                          'GT_WZUBB_CP'.
          "//////////////////////////////////////////////////////////

          PERFORM append_it_leger USING ed_awkey
                                        p_u0
                                        p_u1.
        ENDIF.
      ENDLOOP.

    ENDIF.

*    COLLECT it_zcot097.
*    CLEAR   it_zcot097.
  ENDIF.
ENDFORM.                    " MZUBB_WZUBB_PU

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_PO
*&---------------------------------------------------------------------*
FORM mzubb_wzubb_po  USING    p_u1.

*  오더 방식의 생산인 경우에 구매입고 이동유형인 101,102가
*  같이 사용되므로 MSEG-AUFNR이 1000000~1999999인 경우에는
*  생산입고에 기표 되도록 함.
*  Setting된 이동유형 및 MSEG의 수량
*  Setting된 이동유형 및 MSEG의 금액

  IF it_mseg-bwart = '101' OR it_mseg-bwart = '102'.
    IF ( p_u1 BETWEEN ct_aufnrb AND ct_aufnre ). "OR.
* HWS추가
*       ( p_u1 BETWEEN cx_aufnrb AND cx_aufnre ).

      PERFORM move_rule_data_rtn.
      it_zcot097-mzubb_po = it_mseg-menge.
      it_zcot097-wzubb_po = it_mseg-dmbtr.

      """입고금액(구매).""////////////////////////////////////////
      PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_PO'.
      "////////////////////////////////////////////////////////////
*      COLLECT it_zcot097.
*      CLEAR   it_zcot097.
    ENDIF.
  ELSE.
    PERFORM move_rule_data_rtn.
    it_zcot097-mzubb_po = it_mseg-menge.
    it_zcot097-wzubb_po = it_mseg-dmbtr.

    """입고금액(구매).""////////////////////////////////////////
    PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_PO'.
    "////////////////////////////////////////////////////////////
*    COLLECT it_zcot097.
*    CLEAR   it_zcot097.
  ENDIF.
ENDFORM.                    " MZUBB_WZUBB_PO

*&---------------------------------------------------------------------*
*&      Form  R1000_MZUBB_WZUBB_PO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*----------------------------------------------------------------------*
FORM r1000_mzubb_wzubb_po  USING    p_u0
                                    p_u1.

* 2006/07/05  Modify Start     *****************************************
*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    CLEAR it_zcot097.
    it_zcot097-bukrs    = it_mseg-bukrs.    "UP01. ---------------------
    it_zcot097-werks    = it_mseg-werks.
    it_zcot097-spmon    = it_mseg-budat+0(6).
    it_zcot097-matnr    = it_mseg-matnr.
    it_zcot097-bwtar    = it_mseg-bwtar.
*   IT_ZCOT097-MEINS    = IT_MSEG-MEINS.
*    PERFORM select_mara_meins USING it_mseg-matnr. " Material 단위
*   IT_ZCOT097-WAERS    = IT_MSEG-WAERS.
    it_zcot097-waers    = g_waers.

    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                            CHANGING it_bsegr-dmbtr.
        it_zcot097-wzubb_po = it_zcot097-wzubb_po + it_bsegr-dmbtr.
        ""입고금액(생산).""////////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WZUBB_PO'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
* 2006/07/05  Modify Start     *****************************************
ENDFORM.                    " R1000_MZUBB_WZUBB_PO

*&---------------------------------------------------------------------*
*&      Form  P2025_ADD_TO_13_RTN
*&---------------------------------------------------------------------*
FORM p2025_add_to_13_rtn .
  it_zcot097-bukrs    = it_mseg-bukrs.  "UP01.----------------
  it_zcot097-mzubb_su = it_mseg-menge.
  it_zcot097-wzubb_su = it_mseg-dmbtr.
ENDFORM.                    " P2025_ADD_TO_13_RTN
*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_SU
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*      -->P_IT_MSEG_EBELN  text
*      -->P_IT_MSEG_EBELP  text
*      -->P_CT_PSTYP3  text
*----------------------------------------------------------------------*
FORM mzubb_wzubb_su  USING    p_u0
                             p_u1
                             p_u2
                             p_u3
                             p_u4.

* MSEG에서 구매오더 범주가 "3"인 경우만 해당 (EKPO-PSTYP)
* Setting된 이동유형 및 MSEG의 수량
* 1).MSEG의 금액 포함
* 2).해당 자재문서번호와 연결된 회계전표 중 전표유형이 ML이 있는경우에
*    BSEG-KOART가 "M"인 금액을 포함

  SELECT SINGLE * FROM ekpo
  WHERE ebeln EQ p_u2
  AND   ebelp EQ p_u3
*  AND   LOEKZ EQ SPACE
  AND   pstyp EQ p_u4.

  IF sy-subrc = 0.
    PERFORM move_rule_data_rtn.
    it_zcot097-mzubb_su = it_mseg-menge.
    it_zcot097-wzubb_su = it_mseg-dmbtr.
    """입고금액(외주가공).""/////////////////////////////////////
    PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_SU'.
    "////////////////////////////////////////////////////////////

*- 오브젝트키
    CLEAR : ed_awkey.
    CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
    READ TABLE it_leger WITH KEY awkey = ed_awkey
                                 matnr = p_u0
                                 werks = p_u1.
    IF sy-subrc = 0.
    ELSE.
      PERFORM mseg_bkpf_bseg USING ed_awkey
                                   p_u0
                                   p_u1.
*- IT_BSEGR
      LOOP AT it_bsegr WHERE matnr EQ p_u0
                       AND   werks EQ p_u1.
        READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                       hkont = it_bsegr-hkont.
        IF sy-subrc = 0.
          PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
          it_zcot097-wzubb_su = it_zcot097-wzubb_su + it_bsegr-dmbtr.
          ""입고금액(외주가공).""////////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegr
                                          'GT_WZUBB_SU'.
          "//////////////////////////////////////////////////////////
          PERFORM append_it_leger USING ed_awkey
                                        p_u0
                                        p_u1.
        ENDIF.
      ENDLOOP.
*- IT_BSEGS
      LOOP AT it_bsegs WHERE matnr EQ p_u0
                       AND   werks EQ p_u1.
        READ TABLE it_zcot091 WITH KEY gubun = ct_gubun18
                                       hkont = it_bsegs-hkont.
        IF sy-subrc = 0.
          PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                              CHANGING it_bsegs-dmbtr.
          it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
          ""입고금액(원가차이).""////////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegs
                                          'GT_WZUBB_CO'.
          "//////////////////////////////////////////////////////////
          PERFORM append_it_leger USING ed_awkey
                                        p_u0
                                        p_u1.
        ENDIF.
      ENDLOOP.

    ENDIF.

*    COLLECT it_zcot097.
*    CLEAR   it_zcot097.
  ENDIF.
ENDFORM.                    " MZUBB_WZUBB_SU

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_ST
*&---------------------------------------------------------------------*
FORM mzubb_wzubb_st  USING    p_u0
                          p_u1.

* Setting된 이동유형 및 MSEG의 수량
* Setting된 이동유형 및 MSEG의 금액

  PERFORM move_rule_data_rtn.
  it_zcot097-mzubb_st = it_mseg-menge.
  it_zcot097-wzubb_st = it_mseg-dmbtr.
  """입고금액(공장이전).""/////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_ST'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun"CT_GUBUN18
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                            CHANGING it_bsegr-dmbtr.
        it_zcot097-wzubb_st = it_zcot097-wzubb_st + it_bsegr-dmbtr.
        ""입고금액(공장이전).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WZUBB_ST'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
*- IT_BSEGS
    LOOP AT it_bsegs WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = ct_gubun18
                                     hkont = it_bsegs-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                            CHANGING it_bsegs-dmbtr.
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
        it_zcot097-werks    = it_bsegs-werks.
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.

  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MZUBB_WZUBB_ST

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_ET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*----------------------------------------------------------------------*
FORM mzubb_wzubb_et  USING    p_u0
                          p_u1.

* Setting된 이동유형 및 MSEG의 수량
* 1).MSEG의 금액 포함
* 2).해당 자재문서번호와 연결된 회계전표 중 전표유형이 ML이 있는경우에
*    BSEG-KOART가 "M"인 금액을 포함

  PERFORM move_rule_data_rtn.
  it_zcot097-mzubb_et = it_mseg-menge.
  it_zcot097-wzubb_et = it_mseg-dmbtr.
  """입고금액(타계정).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_ET'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                            CHANGING it_bsegr-dmbtr.
* 이동유형이 '905', '906' 인 경우 LC 외부금액 Field 로 입력된
* 금액이 반영됨으로 인하여 제외한다.
*       IF   IT_MSEG-BWART   NE   '905'
*           AND   IT_MSEG-BWART   NE   '906'.
        it_zcot097-wzubb_et = it_zcot097-wzubb_et
                                       + it_bsegr-dmbtr.
        ""입고금액(타계정).""//////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WZUBB_ET'.
        "//////////////////////////////////////////////////////////
*       ENDIF.

        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.

  ENDIF.
*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MZUBB_WZUBB_ET

*&---------------------------------------------------------------------*
*&      Form  READ_DATA_0003_21_2Z
*&---------------------------------------------------------------------*
FORM read_data_0003_21_2z .
  CASE it_zcot090-gubun.
*- 출고(생산)
    WHEN '21'.
*      PERFORM MAGBB_WAGBB_JR.
      PERFORM magbb_wagbb_jr USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(매출)  ---
    WHEN '22'.
*      PERFORM MAGBB_WAGBB_MC.
      PERFORM magbb_wagbb_mc USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(유상매각) ---
    WHEN '23'.
*      PERFORM P2025_ADD_TO_23_RTN.
      PERFORM p2025_add_to_23_rtn USING it_mseg-matnr
                                        it_mseg-werks.

*- 출고(공장간이전) --
    WHEN '24'.
*      PERFORM MAGBB_WAGBB_ST USING IT_MSEG-MATNR.
      PERFORM magbb_wagbb_st USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(자재간이전) -- 츠가 2012.12.18.
    WHEN '2A'.
      PERFORM magbb_wagbb_mt USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(타계정) ---
    WHEN '25'.
      PERFORM magbb_wagbb_et USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(무상사급)
    WHEN '26'.
      PERFORM magbb_wagbb_su USING it_mseg-matnr
                                   it_mseg-werks.

*- 출고(실사차이)
    WHEN '2Z'.
*      PERFORM MAGBB_WAGBB_PI.
      PERFORM magbb_wagbb_pi USING it_mseg-matnr
                                   it_mseg-werks.
  ENDCASE.
ENDFORM.                    " READ_DATA_0003_21_2Z

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_JR
*&---------------------------------------------------------------------*
FORM magbb_wagbb_jr  USING    p_u0
                          p_u1.

  PERFORM move_rule_data_rtn.

*  IF   it_mseg-aufnr   >=   '000004000000'
*       AND   it_mseg-aufnr   <=   '000004999999'.
*    it_zcot097-magbb_et = it_mseg-menge.
*    it_zcot097-wagbb_et = it_mseg-dmbtr.
*  ELSE.
  it_zcot097-magbb_jr = it_mseg-menge.
  it_zcot097-wagbb_jr = it_mseg-dmbtr.
  """출고금액(재료비).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_JR'.
  "////////////////////////////////////////////////////////////
*  ENDIF.

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반   'S'일때 *-1를 한다
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
*        IF   it_mseg-aufnr   >=   '000004000000'
*            AND   it_mseg-aufnr   <=   '000004999999'.
*          it_zcot097-wagbb_et = it_zcot097-wagbb_et
*                                  + it_bsegr-dmbtr.
*        ELSE.
        it_zcot097-wagbb_jr = it_zcot097-wagbb_jr
                                + it_bsegr-dmbtr.
        ""출고금액(재료비).""//////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_JR'.
        "//////////////////////////////////////////////////////////
*        ENDIF.

        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_JR

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_MC
*&---------------------------------------------------------------------*
FORM magbb_wagbb_mc  USING    p_u0
                          p_u1.

*  PERFORM MOVE_RULE_DATA_RTN.
*  IT_ZCOT097-MAGBB_MC = IT_MSEG-MENGE.
*  IT_ZCOT097-WAGBB_MC = IT_MSEG-DMBTR.
*  COLLECT IT_ZCOT097.
*  CLEAR   IT_ZCOT097.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_mc = it_mseg-menge.
  it_zcot097-wagbb_mc = it_mseg-dmbtr.
  """출고금액(매출원가).""/////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_MC'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0   "MATNR
                                 p_u1.  "WERKS
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_mc = it_zcot097-wagbb_mc + it_bsegr-dmbtr.
        ""출고금액(매출원가).""////////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_MC'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_MC

*&---------------------------------------------------------------------*
*&      Form  P2025_ADD_TO_23_RTN
*&---------------------------------------------------------------------*
FORM p2025_add_to_23_rtn  USING    p_u0
                               p_u1.
*  PERFORM MOVE_RULE_DATA_RTN.
*  IT_ZCOT097-MAGBB_YS = IT_MSEG-MENGE.
*  IT_ZCOT097-WAGBB_YS = IT_MSEG-DMBTR.
*  COLLECT IT_ZCOT097.
*  CLEAR   IT_ZCOT097.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_ys = it_mseg-menge.
  it_zcot097-wagbb_ys = it_mseg-dmbtr.
  """출고금액(유상매각).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_YS'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_ys = it_zcot097-wagbb_ys + it_bsegr-dmbtr.
        ""출고금액(유상매각).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_YS'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " P2025_ADD_TO_23_RTN

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_ST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*----------------------------------------------------------------------*
FORM magbb_wagbb_st  USING    p_u0
                           p_u1.

*  PERFORM MOVE_RULE_DATA_RTN.
*  IT_ZCOT097-MAGBB_ST = IT_MSEG-MENGE.
*  IT_ZCOT097-WAGBB_ST = IT_MSEG-DMBTR.
*  COLLECT IT_ZCOT097.
*  CLEAR   IT_ZCOT097.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_st = it_mseg-menge.
  it_zcot097-wagbb_st = it_mseg-dmbtr.
  """출고금액(공장이전).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_ST'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_st = it_zcot097-wagbb_st + it_bsegr-dmbtr.
        ""출고금액(공장이전).""/////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_ST'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_ST

*&---------------------------------------------------------------------*
*&      Form  SHKZG_DMBTR_S
*&---------------------------------------------------------------------*
FORM shkzg_dmbtr_s  USING    p_u1
                    CHANGING p_u2.

  IF p_u1 = 'S'.
    p_u2 = p_u2 * ( -1 ).
  ENDIF.

ENDFORM.                    " SHKZG_DMBTR_S

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_ET
*&---------------------------------------------------------------------*
FORM magbb_wagbb_et  USING    p_u0
                              p_u1.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_et = it_mseg-menge.
  it_zcot097-wagbb_et = it_mseg-dmbtr.
  """출고금액(타계정).""///////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_ET'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_et = it_zcot097-wagbb_et + it_bsegr-dmbtr.
        ""출고금액(타계정)."////////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_ET'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.
*
*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_ET

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_SU
*&---------------------------------------------------------------------*
FORM magbb_wagbb_su  USING    p_u0
                          p_u1.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_su = it_mseg-menge.
  it_zcot097-wagbb_su = it_mseg-dmbtr.
  """출고금액(사급자재).""/////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_SU'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_su = it_zcot097-wagbb_su + it_bsegr-dmbtr.
        ""출고금액(사급자재).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_SU'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_SU

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_PI
*&---------------------------------------------------------------------*
FORM magbb_wagbb_pi  USING    p_u0
                          p_u1.

  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_pi = it_mseg-menge.
  it_zcot097-wagbb_pi = it_mseg-dmbtr.
  """출고금액(실사차이).""/////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_PI'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_pi = it_zcot097-wagbb_pi + it_bsegr-dmbtr.
        ""출고금액(실사차이).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_PI'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.

*  COLLECT it_zcot097.
*  CLEAR   it_zcot097.
ENDFORM.                    " MAGBB_WAGBB_PI

*&---------------------------------------------------------------------*
*&      Form  WZUBB_PR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM wzubb_pr .
  CLEAR it_zcot097.
  PERFORM bkpf_bseg_pr USING 'PR'.

*- IT_BSEGS
  LOOP AT it_bsegs.
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun16
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
*      PERFORM SHKZG_DMBTR USING    IT_BSEGS-SHKZG
*                          CHANGING IT_BSEGS-DMBTR.
      IF it_zcot091-cacul = '-'.
        it_bsegs-dmbtr = it_bsegs-dmbtr * ( -1 ).
      ENDIF.
      it_zcot097-bukrs    = it_bsegs-bukrs.  "UP01.-------------------
      it_zcot097-wzubb_pr = it_zcot097-wzubb_pr + it_bsegs-dmbtr.
      ""입고금액(가격변경).""////////////////////////////////////
      CLEAR it_bkpfs.
      READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
      PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_PR'.
      "//////////////////////////////////////////////////////////

      it_zcot097-werks    = it_bsegs-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-bwtar    = it_bsegs-bwtar.
      it_zcot097-matnr    = it_bsegs-matnr.
      it_zcot097-bwtar    = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
*      IT_ZCOT097-WAERS    = IT_BSEGS-PSWSL.
      it_zcot097-waers    = g_waers.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.

*- BLART = 'ML'
*  PERFORM BKPF_BSEG_PR_ML USING 'ML'.
  PERFORM bkpf_bseg_pr_ml_two USING 'ML'.
  REFRESH : it_bkpfml.
  CLEAR   : it_bkpfml.
*- IT_BSEGML

  LOOP AT it_bsegml.
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun16
                                   hkont = it_bsegml-hkont
                                   zshkzg = it_bsegml-shkzg.
    IF sy-subrc = 0.
      IF it_zcot091-cacul = '-'.
        it_bsegml-dmbtr = it_bsegml-dmbtr * ( -1 ).
      ENDIF.
      it_zcot097-wzubb_pr = it_zcot097-wzubb_pr + it_bsegml-dmbtr.
      ""입고금액(가격변경).""////////////////////////////////////
      CLEAR it_bkpfml.
      READ TABLE it_bkpfml WITH KEY belnr = it_bsegml-belnr.
      PERFORM add_data_to_table USING it_bkpfml
                                        it_bsegml
                                        'GT_WZUBB_PR'.
      "//////////////////////////////////////////////////////////

      it_zcot097-bukrs    = it_bsegml-bukrs.  "UP01.-------------------
      it_zcot097-werks    = it_bsegml-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegml-matnr.
      it_zcot097-bwtar    = it_bsegml-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGML-MEINS.
*      PERFORM select_mara_meins USING it_bsegml-matnr. " Material 단위
*      IT_ZCOT097-WAERS    = IT_BSEGML-PSWSL.
      it_zcot097-waers    = g_waers.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.

  REFRESH it_bkpfml.
ENDFORM.                    " WZUBB_PR

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_PR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2325   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_pr  USING    p_u1.

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
* 입고(가격변경) 금액 산정시 BKPF-AWTYP = 'AUAK'는 제외한다.
* - 2006.04.24 이정관BJ
  SELECT bukrs belnr gjahr awkey blart waers FROM bkpf
     APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfs
     WHERE bukrs EQ g_bukrs     "UP01.----------------------------
     AND   blart EQ p_u1
     AND   budat BETWEEN g_from AND g_till
     AND   awtyp <> 'AUAK'.
*  AND   STBLG EQ SPACE.
  DESCRIBE TABLE it_bkpfs LINES max_cnt.
  IF it_bkpfs[] IS NOT INITIAL.
    SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr matnr werks pswsl
           bwtar ebeln ebelp vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      FOR ALL ENTRIES IN it_bkpfs
      WHERE bukrs EQ it_bkpfs-bukrs
      AND   belnr EQ it_bkpfs-belnr
      AND   gjahr EQ it_bkpfs-gjahr
      AND   matnr IN gr_matnr[]
      AND   werks IN gr_werks[].
  ENDIF.
ENDFORM.                    " BKPF_BSEG_PR

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_PR_ML_TWO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2394   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_pr_ml_two  USING    p_u1.

  REFRESH : it_bkpfml, it_bsegml.
  CLEAR   : it_bkpfml, it_bsegml.
  DATA : l_cnt TYPE i.
  DESCRIBE TABLE it_bkpfs LINES l_cnt.
  CHECK l_cnt > 0.

*//수정전 로직
*  SELECT BUKRS BELNR GJAHR FROM BKPF
*  APPENDING CORRESPONDING FIELDS OF TABLE IT_BKPFML
*  FOR ALL ENTRIES IN IT_BKPFS
*  WHERE BLART EQ P_U1
*  AND   BUDAT BETWEEN G_FROM AND G_TILL
*  AND   AWKEY EQ IT_BKPFS-AWKEY.
**    AND   STBLG EQ SPACE.

*//수정후 로직
* 입고(가격변경) 금액 산정시 BKPF-AWTYP = 'AUAK'는 제외한다.
* - 2006.04.24 이정관BJ
  SELECT bukrs belnr gjahr blart awkey waers FROM bkpf
    INTO CORRESPONDING FIELDS OF TABLE it_bkpfml
    WHERE bukrs EQ g_bukrs    "UP01.-------------------------
    AND   awkey IN ( SELECT awkey FROM bkpf
                      WHERE bukrs EQ g_bukrs  "UP01.-----------------
                      AND   blart IN ('PR', 'ML')
                      AND   budat BETWEEN g_from AND g_till )
    AND   blart EQ p_u1
    AND   budat BETWEEN g_from AND g_till
    AND   awtyp <> 'AUAK'
    AND     awtyp <> 'MLHD'.
  IF max_cnt > 0 AND it_bkpfml[] IS NOT INITIAL.
    SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
           ebeln ebelp bwtar vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegml
      FOR ALL ENTRIES IN it_bkpfml
      WHERE bukrs EQ it_bkpfml-bukrs
      AND   belnr EQ it_bkpfml-belnr
      AND   gjahr EQ it_bkpfml-gjahr
      AND   matnr IN gr_matnr[]
      AND   werks IN gr_werks[].
  ENDIF.
*  REFRESH : it_bkpfml.
  CLEAR   : it_bkpfml.
ENDFORM.                    " BKPF_BSEG_PR_ML_TWO

*&---------------------------------------------------------------------*
*&      Form  WZUBB_PU_WZUBB_CP_RE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM wzubb_pu_wzubb_cp_re .
  CLEAR it_zcot097.
*//RE 타입과 KP 타입 모두다 읽는다.(20050621-kp 추가)
  PERFORM bkpf_bseg_re USING space.             "'RE'.

*- IT_BSEGS
  LOOP AT it_bsegs.
*& 입고금액(구매)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun11
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                          CHANGING it_bsegs-dmbtr.
*      IF IT_ZCOT091-CACUL = '-'.
*        IT_BSEGS-DMBTR = IT_BSEGS-DMBTR * ( -1 ).
*      ENDIF.
* MSEG에서 구매오더 범주가 "3"인 경우만 해당 (EKPO-PSTYP)
* Setting된 이동유형 및 MSEG의 수량
* 1).MSEG의 금액 포함
* 2).해당 자재문서번호와 연결된 회계전표 중 전표유형이 ML이 있는경우에
*    BSEG-KOART가 "M"인 금액을 포함

      CLEAR:   g_budat,   g_awkey,   g_awtyp.
      SELECT   SINGLE   awtyp   awkey
                   INTO  (g_awtyp,  g_awkey)
                  FROM   bkpf
                 WHERE   bukrs   EQ   it_bsegs-bukrs
                   AND   belnr   EQ   it_bsegs-belnr
                   AND   gjahr   EQ   it_bsegs-gjahr.
      IF   NOT   g_awkey   IS   INITIAL.
        SELECT   budat   INTO   g_budat
                   FROM   bkpf
                   UP   TO    1   ROWS
                  WHERE   bukrs   EQ g_bukrs    "UP01.-----------------
                    AND   awtyp    EQ   g_awtyp
                    AND   awkey    EQ   g_awkey
                    AND   budat    <    g_from.
        ENDSELECT.
      ENDIF.

      SELECT SINGLE * FROM ekpo
      WHERE ebeln EQ it_bsegs-ebeln
      AND   ebelp EQ it_bsegs-ebelp
      AND   pstyp EQ ct_pstyp3.
      IF sy-subrc = 0.
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
      ELSE.
        IF   g_budat   IS    INITIAL.
          it_zcot097-wzubb_pu = it_zcot097-wzubb_pu
                                    + it_bsegs-dmbtr.
          ""입고금액(구매).""//////////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegs
                                          'GT_WZUBB_PU'.
          "/////////////////////////////////////////////////////////
        ELSE.
*           IT_BSEGS-DMBTR  =   IT_BSEGS-DMBTR  *   ( -1 ).
          it_zcot097-wzubb_pr = it_zcot097-wzubb_pr
                                    + it_bsegs-dmbtr.
          ""입고금액(가격변경).""////////////////////////////////////
          CLEAR it_bkpfs.
          READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
          PERFORM add_data_to_table USING it_bkpfs
                                          it_bsegs
                                          'GT_WZUBB_PR'.
          "//////////////////////////////////////////////////////////
        ENDIF.
      ENDIF.

      it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.------------------
      it_zcot097-werks    = it_bsegs-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegs-matnr.
      it_zcot097-bwtar    = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGS-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.

*& 입고금액(구매가격차)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun19
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                          CHANGING it_bsegs-dmbtr.
*      IF IT_ZCOT091-CACUL = '-'.
*        IT_BSEGMS-DMBTR = IT_BSEGMS-DMBTR * ( -1 ).
*      ENDIF.
      SELECT SINGLE * FROM ekpo
      WHERE ebeln EQ it_bsegs-ebeln
      AND   ebelp EQ it_bsegs-ebelp
      AND   pstyp EQ ct_pstyp3.
      IF sy-subrc = 0.
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
      ELSE.
        it_zcot097-wzubb_cp = it_zcot097-wzubb_cp + it_bsegs-dmbtr.
        ""입고금액(구매가격차이).""////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CP'.
        "//////////////////////////////////////////////////////////
      ENDIF.
      it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.------------------
      it_zcot097-werks    = it_bsegs-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegs-matnr.
      it_zcot097-bwtar    = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGS-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.

*- BLART = 'ML'
  PERFORM bkpf_bseg_pr_ml USING 'ML'.

*  PERFORM BKPF_BSEG_PR_ML USING 'KP'.

  PERFORM zcot097_pr_ml.

*- BLART = 'ML'
  PERFORM bkpf_bseg_pr_ml_tow USING 'ML'.
  PERFORM bkpf_bseg_pr_kp_tow USING 'KP'.
  PERFORM zcot097_pr_ml_two.
ENDFORM.                    " WZUBB_PU_WZUBB_CP_RE

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_RE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SPACE  text
*----------------------------------------------------------------------*
FORM bkpf_bseg_re  USING    p_u1.
*  RE: 송장 - 총액
*  ML: ML 정산

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
  SELECT bukrs belnr gjahr budat awkey waers
    FROM bkpf
    APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfs
      WHERE bukrs EQ g_bukrs     "UP01.----------------------------
    AND   blart IN ('RE', 'RA', 'RX', 'KP')               " EQ P_U1
    AND   budat BETWEEN g_from AND g_till.


  IF it_bkpfs[] IS NOT INITIAL.
    SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
           ebeln ebelp bwtar vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      FOR ALL ENTRIES IN it_bkpfs
      WHERE bukrs EQ it_bkpfs-bukrs
      AND   belnr EQ it_bkpfs-belnr
      AND   gjahr EQ it_bkpfs-gjahr
      AND   matnr IN gr_matnr[]
      AND   werks IN gr_werks[].
  ENDIF.

ENDFORM.                    " BKPF_BSEG_RE

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_PR_ML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2975   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_pr_ml  USING    p_u1.

  REFRESH : it_bkpfml, it_bsegml.
  CLEAR   : it_bkpfml, it_bsegml.

  DATA : l_cnt TYPE i.
  DESCRIBE TABLE it_bkpfs LINES l_cnt.
  CHECK l_cnt > 0.

  d_from = g_from - 31.

*  LOOP AT IT_BKPFS.
*//수정전 로직
*  SELECT BUKRS BELNR GJAHR FROM BKPF
*  APPENDING CORRESPONDING FIELDS OF TABLE IT_BKPFML
*  FOR ALL ENTRIES IN IT_BKPFS
*  WHERE BLART EQ P_U1
*  AND   BUDAT BETWEEN G_FROM AND G_TILL
*  AND   AWKEY EQ IT_BKPFS-AWKEY.
**    AND   STBLG EQ SPACE.

*//수정후 로직
  SELECT bukrs belnr gjahr blart awkey waers FROM bkpf
    INTO CORRESPONDING FIELDS OF TABLE it_bkpfml
    WHERE bukrs EQ g_bukrs  "UP01.-------------------------------
      AND awkey IN ( SELECT awkey FROM bkpf
                          WHERE bukrs EQ g_bukrs  "UP01.----------------
                          AND blart IN ('RE', 'KP', 'RA', 'RX' )
*                           WHERE blart EQ 'RE'
                          AND budat BETWEEN g_from AND g_till )
      AND blart EQ p_u1
      AND budat BETWEEN g_from AND g_till.

**UP01. -- 주석 ----------------------
***// 당월 'ML' 전표를 읽어서 원 'RE' 전표가 당월 발생인지
***// 전월 발생인지 Check하여 전월발생분인 경우도 가져온다.
**  DATA: BEGIN OF lt_awkey   OCCURS      0,
**          belnr          LIKE      bkpf-belnr, " 전표번호
**          awkey          LIKE      bkpf-awkey, " 오브젝트키
**        END OF lt_awkey.
**
**  CLEAR: lt_awkey, lt_awkey[].
**  SELECT belnr awkey
**            FROM bkpf
**    INTO CORRESPONDING FIELDS OF TABLE lt_awkey
**    WHERE bukrs EQ g_bukrs_8100 "'8100'
**      AND gjahr EQ g_spmon+0(4)
**      AND awtyp EQ 'RMRP'
**      AND blart EQ 'ML'
**      AND budat BETWEEN g_from AND g_till
**      AND bldat BETWEEN g_from AND g_till.     "2006/01/09 추가
**
**  SORT lt_awkey BY belnr.

*  LOOP AT lt_awkey.
*    READ TABLE it_bkpfml WITH KEY bukrs = '8100'
*                                  gjahr = g_spmon+0(4)
*                                  belnr = lt_awkey-belnr.
*    IF sy-subrc = 0.
*      DELETE lt_awkey.
*    ELSE.
*      SELECT SINGLE * FROM bkpf WHERE bukrs = '8100'
*                                  AND gjahr EQ g_spmon+0(4)
*                                  AND belnr = lt_awkey-belnr.
*      IF sy-subrc = 0.
*        MOVE-CORRESPONDING bkpf TO it_bkpfml.
*        APPEND it_bkpfml.  CLEAR: it_bkpfml.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*//

  DESCRIBE TABLE it_bkpfml LINES max_cnt.
  IF it_bkpfml[] IS NOT INITIAL.
    SELECT bukrs belnr gjahr buzei hkont shkzg bwtar
             dmbtr werks matnr pswsl  ebeln ebelp vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegml
      FOR ALL ENTRIES IN it_bkpfml
      WHERE bukrs EQ it_bkpfml-bukrs
      AND   belnr EQ it_bkpfml-belnr
      AND   gjahr EQ it_bkpfml-gjahr
      AND   matnr IN gr_matnr[]
      AND   werks IN gr_werks[].
  ENDIF.
**    REFRESH : IT_BKPFML.
**    CLEAR   : IT_BKPFML.
*  ENDLOOP.

*// 증빙일이 전월이고 전기일이 당월인 '0011205110'-원재료 계정은 제외
*  LOOP AT IT_BSEGML.
*    READ TABLE IT_ZCOT091 WITH KEY GUBUN = CT_GUBUN11
*                                   HKONT = IT_BSEGML-HKONT
*                                   SHKZG = IT_BSEGML-SHKZG.
*    IF SY-SUBRC = 0.
**      SELECT SINGLE * FROM BKPF WHERE BUKRS = '8100'
**                                  AND GJAHR = IT_BSEGML-GJAHR
**                                  AND BELNR = IT_BSEGML-BELNR.
**      IF BKPF-BLDAT < G_FROM AND
**        ( BKPF-BUDAT BETWEEN G_FROM AND G_TILL ).
**        DELETE IT_BSEGML.
**      ENDIF.
*    ELSE.
*       DELETE IT_BSEGML.
*    ENDIF.
*  ENDLOOP.
*//
ENDFORM.                    " BKPF_BSEG_PR_ML

*&---------------------------------------------------------------------*
*&      Form  ZCOT097_PR_ML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM zcot097_pr_ml .
*- IT_BSEGML
  LOOP AT it_bsegml.
*& 입고금액(구매)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun11
                                   hkont = it_bsegml-hkont
                                   zshkzg = it_bsegml-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegml-shkzg
                          CHANGING it_bsegml-dmbtr.
*      IF IT_ZCOT091-CACUL = '-'.
*        IT_BSEGML-DMBTR = IT_BSEGML-DMBTR * ( -1 ).
*      ENDIF.
      SELECT SINGLE * FROM ekpo
      WHERE ebeln EQ it_bsegml-ebeln
      AND   ebelp EQ it_bsegml-ebelp
      AND   pstyp EQ ct_pstyp3.
      IF sy-subrc = 0.
* 입고금액(원가차이)
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegml-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfml.
        READ TABLE it_bkpfml WITH KEY belnr = it_bsegml-belnr.
        PERFORM add_data_to_table USING it_bkpfml
                                        it_bsegml
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
      ELSE.
* 입고금액(구매)
        it_zcot097-wzubb_pu = it_zcot097-wzubb_pu + it_bsegml-dmbtr.
        ""입고금액(구매).""////////////////////////////////////
        CLEAR it_bkpfml.
        READ TABLE it_bkpfml WITH KEY belnr = it_bsegml-belnr.
        PERFORM add_data_to_table USING it_bkpfml
                                        it_bsegml
                                        'GT_WZUBB_PU'.
        "//////////////////////////////////////////////////////////
      ENDIF.
      it_zcot097-bukrs    = it_bsegml-werks.  "UP01.------------------
      it_zcot097-werks    = it_bsegml-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegml-matnr.
*      it_zcot097-blart <> 'PR'
      it_zcot097-bwtar    = it_bsegml-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGML-MEINS.
*      PERFORM select_mara_meins USING it_bsegml-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGML-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.

*& 입고금액(구매가격차)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun19
                                   hkont = it_bsegml-hkont
                                   zshkzg = it_bsegml-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegml-shkzg
                          CHANGING it_bsegml-dmbtr.
*      IF IT_ZCOT091-CACUL = '-'.
*        IT_BSEGML-DMBTR = IT_BSEGML-DMBTR * ( -1 ).
*      ENDIF.
      SELECT SINGLE * FROM ekpo
      WHERE ebeln EQ it_bsegml-ebeln
      AND   ebelp EQ it_bsegml-ebelp
      AND   pstyp EQ ct_pstyp3.
      IF sy-subrc = 0.
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegml-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfml.
        READ TABLE it_bkpfml WITH KEY belnr = it_bsegml-belnr.
        PERFORM add_data_to_table USING it_bkpfml
                                        it_bsegml
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
      ELSE.
        it_zcot097-wzubb_cp = it_zcot097-wzubb_cp + it_bsegml-dmbtr.
        ""입고금액(구매가격차이).""////////////////////////////////
        CLEAR it_bkpfml.
        READ TABLE it_bkpfml WITH KEY belnr = it_bsegml-belnr.
        PERFORM add_data_to_table USING it_bkpfml
                                        it_bsegml
                                        'GT_WZUBB_CP'.
        "//////////////////////////////////////////////////////////
      ENDIF.

      it_zcot097-bukrs    = it_bsegml-bukrs.  "UP01.----------------
      it_zcot097-werks    = it_bsegml-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegml-matnr.
      it_zcot097-bwtar    = it_bsegml-bwtar.
*      it_zcot097-bwtar    = it_bsegs-bwtar.

*      PERFORM select_mara_meins USING it_bsegml-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGML-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " ZCOT097_PR_ML

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_PR_ML_TOW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2981   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_pr_ml_tow  USING    p_u1.

  REFRESH : it_bkpfml2, it_bsegml.
  CLEAR   : it_bkpfml2, it_bsegml.

  DATA : l_cnt TYPE i.
  DESCRIBE TABLE it_bkpfml LINES l_cnt.
  CHECK l_cnt > 0.

*//수정 로직 2
  DATA : BEGIN OF lt_bkpf OCCURS 0,
           belnr             LIKE bkpf-belnr,
         END OF lt_bkpf.

  CLEAR: lt_bkpf, lt_bkpf[].
  LOOP AT it_bkpfml.
    MOVE-CORRESPONDING it_bkpfml TO lt_bkpf.
    APPEND lt_bkpf.  CLEAR: lt_bkpf.
  ENDLOOP.

**UP01. 주석 ---------------------
**  SELECT bukrs belnr gjahr awkey
**  FROM bkpf
**  APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfml2
**  FOR ALL ENTRIES IN lt_bkpf
**  WHERE bukrs = g_bukrs_8100  "'8100' --> 없다...
**  AND   gjahr = g_spmon+0(4)
**  AND   belnr NE lt_bkpf-belnr
**  AND   blart EQ p_u1
**  AND   budat BETWEEN g_from AND g_till
**  AND   NOT tcode LIKE 'CKM%'.
**    AND   STBLG EQ SPACE.

*//원본
*  SELECT BUKRS BELNR GJAHR AWKEY
*  FROM BKPF
*  APPENDING CORRESPONDING FIELDS OF TABLE IT_BKPFML2
*  FOR ALL ENTRIES IN IT_BKPFML
*  WHERE BUKRS = '8100'
*  AND   GJAHR = g_spmon+0(4)
*  AND   BELNR NE IT_BKPFML-BELNR
*  AND   BLART EQ P_U1
*  AND   BUDAT BETWEEN G_FROM AND G_TILL
*  AND   NOT TCODE LIKE 'CKM%'.
**    AND   STBLG EQ SPACE.

**//수정 로직 1
*  SELECT BUKRS BELNR GJAHR AWKEY
*    FROM BKPF
*    into corresponding FIELDS OF TABLE IT_BKPFML2
*      WHERE bukrs = '8100'
*        and BELNR not in
*           ( SELECT BELNR from bkpf
*              WHERE awtyp IN R_AWTYP
*                and AWKEY in ( SELECT AWKEY FROM BKPF
*                                WHERE BLART in ('RE', 'KP')
*                                  AND BUDAT BETWEEN G_FROM AND G_TILL )
*                and BLART EQ 'ML'
*                AND BUDAT BETWEEN G_FROM AND G_TILL
*            )
*      AND   BLART EQ P_U1
*      AND   BUDAT BETWEEN G_FROM AND G_TILL
*      AND   NOT TCODE LIKE 'CKM%'.

*  DESCRIBE TABLE it_bkpfml2 LINES max_cnt.
*  IF max_cnt < 0.
*  ELSE.
*    LOOP AT it_bkpfml2.
*      SELECT SINGLE * FROM bkpf
*      WHERE awtyp IN r_awtyp
*      AND   awkey EQ it_bkpfml2-awkey
*      AND   bukrs EQ it_bkpfml2-bukrs
*      AND   gjahr EQ it_bkpfml2-gjahr
*      AND   blart EQ 'RE'.
*      IF sy-subrc = 0.
*      ELSE.
*        DELETE it_bkpfml2.
*        CLEAR  it_bkpfml2.
*      ENDIF.
*    ENDLOOP.
*    LOOP AT it_bkpfml2.
*      SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
*             bwtar ebeln ebelp
*      FROM bseg
*      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegml
*      WHERE bukrs EQ it_bkpfml2-bukrs
*      AND   belnr EQ it_bkpfml2-belnr
*      AND   gjahr EQ it_bkpfml2-gjahr.
***hjgwon
**       AND   matnr IN s_matnr
***-----------------------------------
**      AND   werks IN s_werks.  "  p_werks "UP01. -------------
*    ENDLOOP.
*  ENDIF.
*  REFRESH : it_bkpfml, it_bkpfml2.
*  CLEAR   : it_bkpfml, it_bkpfml2.
ENDFORM.                    " BKPF_BSEG_PR_ML_TOW

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_PR_KP_TOW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2985   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_pr_kp_tow  USING    p_u1.

  REFRESH : it_bkpfml2, it_bsegml.
  CLEAR   : it_bkpfml2, it_bsegml.

  DATA cnt TYPE i.
  DESCRIBE TABLE it_bkpfml LINES cnt.
  CHECK cnt > 0.

*//수정전 로직
*  SELECT BUKRS BELNR GJAHR AWKEY
*  FROM BKPF
*  APPENDING CORRESPONDING FIELDS OF TABLE IT_BKPFML2
*  FOR ALL ENTRIES IN IT_BKPFML
*  WHERE BELNR NE IT_BKPFML-BELNR
*  AND   BLART EQ P_U1
*  AND   BUDAT BETWEEN G_FROM AND G_TILL
*  AND   NOT TCODE LIKE 'CKM%'.
**    AND   STBLG EQ SPACE.

*//수정 후 로직
  SELECT bukrs belnr gjahr awkey blart waers
   FROM bkpf
   INTO CORRESPONDING FIELDS OF TABLE it_bkpfml2
   WHERE bukrs  EQ g_bukrs  "UP01.------------------------------
     AND belnr NOT IN
         ( SELECT belnr FROM bkpf
               WHERE bukrs EQ g_bukrs "UP01.-----------------------
                 AND awkey IN ( SELECT awkey FROM bkpf
                                 WHERE bukrs EQ g_bukrs "UP01.---------
                                  AND blart IN ('RE', 'KP')
                                  AND budat BETWEEN g_from AND g_till )
                 AND blart EQ 'ML'
                 AND budat BETWEEN g_from AND g_till
          )
   AND   blart EQ p_u1
   AND   budat BETWEEN g_from AND g_till
   AND   NOT tcode LIKE 'CKM%'.

  IF it_bkpfml2[] IS NOT INITIAL.
    DATA: lt_mlkey TYPE TABLE OF bkpf.
    SELECT bukrs gjahr awkey
      FROM bkpf
      INTO CORRESPONDING FIELDS OF TABLE lt_mlkey
      FOR ALL ENTRIES IN it_bkpfml2
      WHERE bukrs EQ it_bkpfml2-bukrs
      AND   gjahr EQ it_bkpfml2-gjahr
      AND   awkey EQ it_bkpfml2-awkey
      AND   blart EQ 'ML'.
    SORT lt_mlkey BY bukrs gjahr awkey.
    LOOP AT it_bkpfml2.
      READ TABLE lt_mlkey WITH KEY bukrs = it_bkpfml2-bukrs
                                   gjahr = it_bkpfml2-gjahr
                                   awkey = it_bkpfml2-awkey
                                   BINARY SEARCH
                                   TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE it_bkpfml2.
      ENDIF.
    ENDLOOP.
    IF it_bkpfml2[] IS NOT INITIAL.
      SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
             ebeln ebelp bwtar vbel2 posn2 prctr
        FROM bseg
        APPENDING CORRESPONDING FIELDS OF TABLE it_bsegml
        FOR ALL ENTRIES IN it_bkpfml2
        WHERE bukrs EQ it_bkpfml2-bukrs
        AND   belnr EQ it_bkpfml2-belnr
        AND   gjahr EQ it_bkpfml2-gjahr
        AND   matnr IN gr_matnr[]
        AND   werks IN gr_werks[].
    ENDIF.
  ENDIF.
*  REFRESH : it_bkpfml, it_bkpfml2.
  CLEAR   : it_bkpfml, it_bkpfml2.
ENDFORM.                    " BKPF_BSEG_PR_KP_TOW

*&---------------------------------------------------------------------*
*&      Form  ZCOT097_PR_ML_TWO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM zcot097_pr_ml_two .
*- IT_BSEGML
  LOOP AT it_bsegml.
*& 입고금액(구매)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun16
                                   hkont = it_bsegml-hkont
                                   zshkzg = it_bsegml-shkzg.
    IF sy-subrc = 0.
*      PERFORM SHKZG_DMBTR USING    IT_BSEGML-SHKZG
*                          CHANGING IT_BSEGML-DMBTR.
      IF it_zcot091-cacul = '-'.
        it_bsegml-dmbtr = it_bsegml-dmbtr * ( -1 ).
      ENDIF.
      it_zcot097-wzubb_pr = it_zcot097-wzubb_pr + it_bsegml-dmbtr.
      ""입고금액(가격변경).""////////////////////////////////////////
      CLEAR it_bkpfml2.
      READ TABLE it_bkpfml2 WITH KEY belnr = it_bsegml-belnr.
      PERFORM add_data_to_table USING it_bkpfml2
                                        it_bsegml
                                        'GT_WZUBB_PR'.
      "//////////////////////////////////////////////////////////

*      SELECT SINGLE * FROM EKPO
*      WHERE EBELN EQ IT_BSEGML-EBELN
*      AND   EBELP EQ IT_BSEGML-EBELP
*      AND   PSTYP EQ CT_PSTYP3.
*      IF SY-SUBRC = 0.
*        IT_ZCOT097-WZUBB_CO = IT_ZCOT097-WZUBB_CO + IT_BSEGML-DMBTR.
*      ELSE.
*        IT_ZCOT097-WZUBB_PU = IT_ZCOT097-WZUBB_PU + IT_BSEGML-DMBTR.
*      ENDIF.
      it_zcot097-bukrs    = it_bsegml-bukrs.  "UP01.--------------
      it_zcot097-werks    = it_bsegml-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegml-matnr.
      it_zcot097-bwtar    = it_bsegml-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGML-MEINS.
*      PERFORM select_mara_meins USING it_bsegml-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGML-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.

**& 입고금액(구매가격차)
*    READ TABLE IT_ZCOT091 WITH KEY GUBUN = CT_GUBUN19
*                                   HKONT = IT_BSEGML-HKONT
*                                   SHKZG = IT_BSEGML-SHKZG.
*    IF SY-SUBRC = 0.
*      PERFORM SHKZG_DMBTR USING    IT_BSEGML-SHKZG
*                          CHANGING IT_BSEGML-DMBTR.
**      IF IT_ZCOT091-CACUL = '-'.
**        IT_BSEGML-DMBTR = IT_BSEGML-DMBTR * ( -1 ).
**      ENDIF.
*      SELECT SINGLE * FROM EKPO
*      WHERE EBELN EQ IT_BSEGML-EBELN
*      AND   EBELP EQ IT_BSEGML-EBELP
*      AND   PSTYP EQ CT_PSTYP3.
*      IF SY-SUBRC = 0.
*        IT_ZCOT097-WZUBB_CO = IT_ZCOT097-WZUBB_CO + IT_BSEGML-DMBTR.
*      ELSE.
*        IT_ZCOT097-WZUBB_CP = IT_ZCOT097-WZUBB_CP + IT_BSEGML-DMBTR.
*      ENDIF.
*      IT_ZCOT097-WERKS    = IT_BSEGML-WERKS.
*      IT_ZCOT097-SPMON    = g_spmon.
*      IT_ZCOT097-MATNR    = IT_BSEGML-MATNR.
**      IT_ZCOT097-BWTAR    = IT_BSEGS-BWTAR.
**      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM SELECT_MARA_MEINS USING IT_BSEGML-MATNR. " Material 단위
*      it_zcot097-waers    = g_waers. "IT_BSEGML-PSWSL.
*      COLLECT IT_ZCOT097.
*      CLEAR   IT_ZCOT097.
*    ENDIF.
  ENDLOOP.
ENDFORM.                    " ZCOT097_PR_ML_TWO

*&---------------------------------------------------------------------*
*&      Form  WZUBB_PO_WZUBB_CO_SA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM wzubb_po_wzubb_co_sa .
  CLEAR it_zcot097.
* SA : 조정/정산 전표
  PERFORM bkpf_bseg_sa USING 'SA'.

  LOOP AT it_bsegs.
*& 입고금액(생산)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun12
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                          CHANGING it_bsegs-dmbtr.
      it_zcot097-wzubb_po = it_zcot097-wzubb_po + it_bsegs-dmbtr.
      ""입고금액(생산).""////////////////////////////////////////
      CLEAR it_bkpfs.
      READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
      PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_PO'.
      "//////////////////////////////////////////////////////////

      it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.-------------------
      it_zcot097-werks    = it_bsegs-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegs-matnr.
      it_zcot097-bwtar    = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGS-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
*& 입고금액(원가차이)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun18
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                          CHANGING it_bsegs-dmbtr.
      it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
      ""입고금액(원가차이).""////////////////////////////////////////
      CLEAR it_bkpfs.
      READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
      PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CO'.
      "//////////////////////////////////////////////////////////
      it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.-------------------
      it_zcot097-werks    = it_bsegs-werks.
      it_zcot097-spmon    = g_spmon.
      it_zcot097-matnr    = it_bsegs-matnr.
      it_zcot097-bwtar    = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
      it_zcot097-waers    = g_waers. "IT_BSEGS-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " WZUBB_PO_WZUBB_CO_SA

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_SA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_3840   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_sa  USING    p_u1.

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
  SELECT bukrs belnr gjahr blart awkey waers
          FROM bkpf
      APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfs
      WHERE   bukrs EQ g_bukrs "UP01.-----------------------
        AND   blart  EQ  p_u1
        AND   budat  BETWEEN  g_from  AND  g_till.
*  AND   STBLG EQ SPACE.
  DESCRIBE TABLE it_bkpfs LINES max_cnt.
  IF max_cnt < 0.
  ELSE.
    LOOP AT it_bkpfs.
      SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
             bwtar ebeln ebelp vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      WHERE bukrs EQ it_bkpfs-bukrs
      AND   belnr EQ it_bkpfs-belnr
      AND   gjahr EQ it_bkpfs-gjahr.
**hjgwon
*       AND   matnr IN s_matnr
**-----------------------------------
*      AND   werks IN s_werks.  "  p_werks "UP01. -------------
    ENDLOOP.
  ENDIF.
ENDFORM.                    " BKPF_BSEG_SA

*&---------------------------------------------------------------------*
*&      Form  WZUBB_MLP_ML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM wzubb_mlp_ml .
  CLEAR it_zcot097.
  PERFORM bkpf_bseg_ml USING 'ML'
                             'CKMI'
                             'CKMLCP'.
  LOOP AT it_bsegs.
*& 입고금액(ML 정산)
    READ TABLE it_zcot091 WITH KEY gubun = ct_gubun17
                                   hkont = it_bsegs-hkont
                                   zshkzg = it_bsegs-shkzg.
    IF sy-subrc = 0.
      PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                          CHANGING it_bsegs-dmbtr.
      it_zcot097-wzubb_mlp = it_zcot097-wzubb_mlp + it_bsegs-dmbtr.
      ""입고금액(ML정산).""////////////////////////////////////////
      CLEAR it_bkpfs.
      READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
      PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_MLP'.
      "//////////////////////////////////////////////////////////

      it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.-------------------
      it_zcot097-werks     = it_bsegs-werks.
      it_zcot097-spmon     = g_spmon.
      it_zcot097-matnr     = it_bsegs-matnr.
      it_zcot097-bwtar     = it_bsegs-bwtar.
*      IT_ZCOT097-MEINS     = IT_BSEGS-MEINS.
*      PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
      it_zcot097-waers     = 'KRW'. "IT_BSEGS-PSWSL.
*      COLLECT it_zcot097.
      CLEAR   it_zcot097.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " WZUBB_MLP_ML

*&---------------------------------------------------------------------*
*&      Form  BKPF_BSEG_ML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4051   text
*      -->P_4052   text
*      -->P_4053   text
*----------------------------------------------------------------------*
FORM bkpf_bseg_ml  USING    p_u1
                            p_u2
                            p_u3.

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
  SELECT bukrs belnr gjahr blart awkey waers FROM bkpf
  APPENDING CORRESPONDING FIELDS OF TABLE it_bkpfs
  WHERE bukrs EQ g_bukrs "UP01.-----------------------
  AND   awtyp IN  ('MLHD',  'AUAK')
  AND   blart EQ p_u1
  AND   budat BETWEEN g_from AND g_till
  .
*  AND ( TCODE EQ P_U2 OR TCODE EQ P_U3 ).
*  AND   STBLG EQ SPACE.

*  2006/06/28 일 추가   Start
*  SELECT BUKRS BELNR GJAHR FROM BKPF
*      APPENDING CORRESPONDING FIELDS OF TABLE IT_BKPFS
*         WHERE   AWTYP  EQ   'MKPF'
*           AND   BLART  EQ   P_U1
*           AND   GLVOR  EQ   'RMRU'
*           AND   AWKEY  NE   SPACE
*           AND   BUDAT  BETWEEN  G_FROM  AND  G_TILL.
*  2006/06/28 일 추가  End


  IF it_bkpfs[] IS NOT INITIAL.
    SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
           bwtar ebeln ebelp vbel2 posn2 prctr
      FROM bseg
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      FOR ALL ENTRIES IN it_bkpfs
      WHERE bukrs EQ it_bkpfs-bukrs
      AND   belnr EQ it_bkpfs-belnr
      AND   gjahr EQ it_bkpfs-gjahr
      AND   matnr NE space
      AND   matnr IN gr_matnr[]
      AND   werks IN gr_werks[].
  ENDIF.

ENDFORM.                    " BKPF_BSEG_ML

*&---------------------------------------------------------------------*
*&      Form  READ_DATA_0002
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM read_data_0002.
  DATA : lt_090 LIKE TABLE OF zcot0090 WITH HEADER LINE,
         l_sakto LIKE ekkn-sakto.
*  RANGES : lr_bwart FOR zcot0090-bwart.
  REFRESH : it_mseg.
  CLEAR   : it_mseg.

  SELECT a~budat      a~blart
         b~mandt     b~mblnr     b~mjahr     b~bwart     b~xauto
         b~kzvbr     b~matnr     b~werks     b~sobkz     b~kzbew
         b~lifnr     b~shkzg     b~waers     b~dmbtr     b~menge
         b~bwtar     b~meins     b~aufnr     b~ebeln     b~ebelp
         b~gjahr     b~bukrs     b~umwrk     b~ummat     b~sakto
          b~belnr     b~buzei     b~kdauf     b~kdpos     b~prctr
         c~reswk
         d~pstyp     d~knttp
    INTO CORRESPONDING FIELDS OF TABLE it_mseg
    FROM mkpf AS a INNER JOIN mseg AS b
      ON a~mblnr = b~mblnr AND
         a~mjahr = b~mjahr
    LEFT OUTER JOIN ekko AS c
      ON b~ebeln = c~ebeln
    LEFT OUTER JOIN ekpo AS d
      ON b~ebeln = d~ebeln AND
         b~ebelp = d~ebelp
    WHERE a~budat BETWEEN g_from AND g_till
      AND b~bukrs EQ g_bukrs
      AND b~bwart IN gr_bwart[]
      AND b~matnr IN gr_matnr[]
      AND b~werks IN gr_werks[]
      AND b~mblnr IN gr_mblnr[].
ENDFORM.                    " READ_DATA_0002

*&---------------------------------------------------------------------*
*&      Form  WZUBB_TH
*&---------------------------------------------------------------------*
FORM wzubb_th .

  DEFINE _set_ranges.
    &2-sign   = &3.
    &2-option = &4.
    &2-low    = &5.
    &2-high   = &6.
    append &2 to &1.
  END-OF-DEFINITION.

  CLEAR it_zcot097.

  DATA: lr_hkont  TYPE RANGE OF hkont,
        ls_hkont  LIKE LINE OF lr_hkont,
        lt_ekpo   TYPE TABLE OF ekpo,
        ls_ekpo   TYPE ekpo.
  LOOP AT it_zcot091 WHERE gubun = '29'.
    _set_ranges:  lr_hkont ls_hkont 'I' 'EQ' it_zcot091-hkont ''.
  ENDLOOP.
  SORT lr_hkont BY low.
  DELETE ADJACENT DUPLICATES FROM lr_hkont COMPARING low.

* - EKPO...
  SELECT ebeln ebelp
    INTO CORRESPONDING FIELDS OF TABLE lt_ekpo
    FROM ekpo
   WHERE bukrs EQ g_bukrs
*     AND werks IN s_werks
*     AND matnr IN s_matnr
     AND pstyp EQ '5'
     AND knttp EQ '1'.

  REFRESH : it_bkpfs, it_bsegr, it_bsegs.
  CLEAR   : it_bkpfs, it_bsegr, it_bsegs.
  SELECT bukrs belnr gjahr blart awkey waers
    INTO CORRESPONDING FIELDS OF TABLE it_bkpfs
    FROM bkpf
   WHERE bukrs EQ g_bukrs "UP01.-----------------------
     AND blart EQ  'RE'
     AND budat BETWEEN  g_from  AND  g_till.
*  AND   STBLG EQ SPACE.
*  DESCRIBE TABLE it_bkpfs LINES max_cnt.
*  IF max_cnt < 0.
*  ELSE.

  CHECK it_bkpfs[] IS NOT INITIAL.
  LOOP AT it_bkpfs.
    SELECT bukrs belnr gjahr buzei hkont shkzg dmbtr werks matnr pswsl
           bwtar menge ebeln ebelp vbel2 posn2 prctr
      APPENDING CORRESPONDING FIELDS OF TABLE it_bsegs
      FROM bseg
     WHERE bukrs EQ it_bkpfs-bukrs
       AND belnr EQ it_bkpfs-belnr
       AND gjahr EQ it_bkpfs-gjahr
       AND hkont IN lr_hkont.
*       AND matnr IN s_matnr
*       AND werks IN s_werks.  "  p_werks "UP01. -------------
  ENDLOOP.


  LOOP AT it_bsegs.
    READ TABLE lt_ekpo WITH KEY ebeln = it_bsegs-ebeln
                                ebelp = it_bsegs-ebelp
                                TRANSPORTING NO FIELDS.
    CHECK sy-subrc EQ 0.
    PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                        CHANGING: it_bsegs-dmbtr,
                                  it_bsegs-menge.

    it_zcot097-wzubb_th = it_zcot097-wzubb_th + it_bsegs-dmbtr.
    it_zcot097-wagbb_th = it_zcot097-wagbb_th + it_bsegs-dmbtr.
    ""3자거래(입,출고).""////////////////////////////////////////
    CLEAR it_bkpfs.
    READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
    PERFORM add_data_to_table USING: it_bkpfs it_bsegs 'GT_WZUBB_TH',
                                     it_bkpfs it_bsegs 'GT_WAGBB_TH'.
    "//////////////////////////////////////////////////////////

    it_zcot097-mzubb_th = it_zcot097-mzubb_th + it_bsegs-menge.
    it_zcot097-magbb_th = it_zcot097-magbb_th + it_bsegs-menge.

*    it_zcot097-bukrs    = it_bsegs-bukrs. "UP01.-------------------
*    it_zcot097-werks    = it_bsegs-werks.
*    it_zcot097-spmon    = p_spmon.
*    it_zcot097-matnr    = it_bsegs-matnr.
*    it_zcot097-bwtar    = it_bsegs-bwtar.
**      IT_ZCOT097-MEINS    = IT_BSEGS-MEINS.
*    PERFORM select_mara_meins USING it_bsegs-matnr. " Material 단위
*    it_zcot097-waers    = g_waers. "IT_BSEGS-PSWSL.
*    COLLECT it_zcot097.
    CLEAR:   it_zcot097, it_bsegs.
  ENDLOOP.
ENDFORM.                    " WZUBB_TH

*&---------------------------------------------------------------------*
*&      Form  MZUBB_WZUBB_MT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*----------------------------------------------------------------------*
FORM mzubb_wzubb_mt  USING    p_u0
                              p_u1.

  PERFORM move_rule_data_rtn.
  it_zcot097-mzubb_mt = it_mseg-menge.
  it_zcot097-wzubb_mt = it_mseg-dmbtr.
  """입고금액(공장이전).""/////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WZUBB_MT'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun"CT_GUBUN18
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegr-shkzg
                            CHANGING it_bsegr-dmbtr.
        it_zcot097-wzubb_mt = it_zcot097-wzubb_mt + it_bsegr-dmbtr.
        ""입고금액(공장이전).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WZUBB_MT'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
*- IT_BSEGS
    LOOP AT it_bsegs WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = ct_gubun18
                                     hkont = it_bsegs-hkont.
      IF sy-subrc = 0.
        PERFORM shkzg_dmbtr USING    it_bsegs-shkzg
                            CHANGING it_bsegs-dmbtr.
        it_zcot097-wzubb_co = it_zcot097-wzubb_co + it_bsegs-dmbtr.
        ""입고금액(원가차이).""////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegs-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegs
                                        'GT_WZUBB_CO'.
        "//////////////////////////////////////////////////////////
        it_zcot097-werks    = it_bsegs-werks.
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.

  ENDIF.
ENDFORM.                    " MZUBB_WZUBB_MT

*&---------------------------------------------------------------------*
*&      Form  MAGBB_WAGBB_MT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_MSEG_MATNR  text
*      -->P_IT_MSEG_WERKS  text
*----------------------------------------------------------------------*
FORM magbb_wagbb_mt  USING    p_u0
                              p_u1.
  PERFORM move_rule_data_rtn.
  it_zcot097-magbb_mt = it_mseg-menge.
  it_zcot097-wagbb_mt = it_mseg-dmbtr.
  """출고금액(공장이전).""////////////////////////////////////////
  PERFORM add_data_to_table_by_mseg USING it_mseg 'GT_WAGBB_MT'.
  "////////////////////////////////////////////////////////////

*- 오브젝트키
  CLEAR : ed_awkey.
  CONCATENATE it_mseg-mblnr it_mseg-gjahr INTO ed_awkey.
*- 중복값확인: 한번만 돌것
  READ TABLE it_leger WITH KEY awkey = ed_awkey
                               matnr = p_u0
                               werks = p_u1.
  IF sy-subrc = 0.
  ELSE.
    PERFORM mseg_bkpf_bseg USING ed_awkey
                                 p_u0
                                 p_u1.
*- IT_BSEGR
    LOOP AT it_bsegr WHERE matnr EQ p_u0
                     AND   werks EQ p_u1.
      READ TABLE it_zcot091 WITH KEY gubun = it_zcot090-gubun
                                     hkont = it_bsegr-hkont.
      IF sy-subrc = 0.
*- 입고 시에만 반영됨
*  출고는 대변에 금액이 있고, 차대변지시자 역시 'H' 이나
*  '+' 반
        PERFORM shkzg_dmbtr_s USING    it_bsegr-shkzg
                              CHANGING it_bsegr-dmbtr.
        it_zcot097-wagbb_mt = it_zcot097-wagbb_st + it_bsegr-dmbtr.
        ""출고금액(공장이전).""/////////////////////////////////////
        CLEAR it_bkpfs.
        READ TABLE it_bkpfs WITH KEY belnr = it_bsegr-belnr.
        PERFORM add_data_to_table USING it_bkpfs
                                        it_bsegr
                                        'GT_WAGBB_MT'.
        "//////////////////////////////////////////////////////////
        PERFORM append_it_leger USING ed_awkey
                                      p_u0
                                      p_u1.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " MAGBB_WAGBB_MT

*&---------------------------------------------------------------------*
*&      Form  CHECK_BKLAS_BY_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PS_BSEG_MATNR  text
*      -->P_PS_BSEG_BWTAR  text
*      -->P_L_ERROR  text
*----------------------------------------------------------------------*
FORM check_bklas_by_data  USING    p_matnr
                                   p_bwtar
                                   p_error.
  DATA: ls_mara TYPE mara,
        l_bklas TYPE bklas.

  SELECT SINGLE * INTO ls_mara FROM mara WHERE matnr EQ p_matnr.
  IF ls_mara-mtart EQ 'FERT'.
    SELECT SINGLE bklas INTO l_bklas FROM mbew
        WHERE bwtar EQ p_bwtar
          AND matnr EQ p_matnr.
  ELSE.
    SELECT SINGLE bklas INTO l_bklas FROM mbew
    WHERE matnr EQ p_matnr.
  ENDIF.

  IF l_bklas EQ space AND p_matnr IN gr_matnr_8.
    p_error = 'X'.
  ENDIF.
*  IF l_bklas EQ space. p_error = 'X'. ENDIF.
ENDFORM.                    " CHECK_BKLAS_BY_DATA

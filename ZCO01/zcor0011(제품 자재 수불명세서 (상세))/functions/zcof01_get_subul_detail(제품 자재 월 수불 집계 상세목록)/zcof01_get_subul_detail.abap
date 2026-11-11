FUNCTION zcof01_get_subul_detail.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BUKRS) TYPE  BUKRS DEFAULT '1000'
*"     VALUE(I_SPMON) TYPE  SPMON
*"     VALUE(I_EPMON) TYPE  SPMON OPTIONAL
*"  TABLES
*"      IT_WZUBB_PU STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_PO STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_SU STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_ST STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_MT STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_ET STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_PR STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_TH STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_CO STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_CP STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_IVP STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_IVS STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_SAP STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WZUBB_MLP STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_JR STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_MC STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_YS STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_ST STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_MT STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_SU STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_ET STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_TH STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_PI STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_WAGBB_CO STRUCTURE  ZCOS0005 OPTIONAL
*"      IT_BWART STRUCTURE  ZCOS_BWART OPTIONAL
*"      IT_MATNR STRUCTURE  ZCOS_MATNR OPTIONAL
*"      IT_WERKS STRUCTURE  ZCOS_WERKS OPTIONAL
*"      IT_MBLNR STRUCTURE  ZCOS_MBLNR OPTIONAL
*"----------------------------------------------------------------------

**& MSEG INTERNAL TABLE
*  DATA : BEGIN OF it_mseg OCCURS 0,
*           bwart               LIKE mseg-bwart,
*           shkzg               LIKE mseg-shkzg,
*           mblnr               LIKE mseg-mblnr,
*           mjahr               LIKE mseg-mjahr,
*           xauto               LIKE mseg-xauto,
*           kzvbr               LIKE mseg-kzvbr,
*           matnr               LIKE mseg-matnr,
*           bwtar               LIKE mseg-bwtar,
*           werks               LIKE mseg-werks,
*           lifnr               LIKE mseg-lifnr,
*           waers               LIKE mseg-waers,
*           dmbtr               LIKE mseg-dmbtr,
*           menge               LIKE mseg-menge,
*           meins               LIKE mseg-meins,
*           reswk               LIKE ekko-reswk,
*           aufnr               LIKE mseg-aufnr,
*           ebeln               LIKE mseg-ebeln,
*           ebelp               LIKE mseg-ebelp,
*           pstyp               LIKE ekpo-pstyp,
*           knttp               LIKE ekpo-knttp,
*           gjahr               LIKE mseg-gjahr,
*           umwrk               LIKE mseg-umwrk,
*           ummat               LIKE mseg-ummat,
*           bukrs               LIKE mseg-bukrs,
*           blart               LIKE mkpf-blart,
*           belnr               LIKE mseg-belnr, "추가.
*           buzei               LIKE mseg-buzei, "추가.
*           kdauf               LIKE mseg-kdauf,"추가 판매문서.
*           kdpos               LIKE mseg-kdpos,"추가 판매문서품목.
*           prctr               LIKE mseg-prctr, "추가 손익센터.
*           budat               LIKE mkpf-budat,
*           sakto               LIKE mseg-sakto,
*           pocls(01)   TYPE    c,
*           mtart               LIKE mara-mtart,  "HWS
*         END OF it_mseg.



*       Global data declarations
  MOVE: i_bukrs TO g_bukrs,
        i_spmon TO g_spmon.

  PERFORM refresh_internal_table.

  gr_bwart[] = it_bwart[].
  gr_werks[] = it_werks[].
  gr_matnr[] = it_matnr[].
  gr_mblnr[] = it_mblnr[].

  CONCATENATE i_spmon '01' INTO g_from.
  IF i_epmon IS INITIAL.
    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = g_from
      IMPORTING
        last_day_of_month = g_till.
  ELSE.
    DATA: l_datum TYPE dats.
    CONCATENATE i_epmon '01' INTO l_datum.
    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = l_datum
      IMPORTING
        last_day_of_month = g_till.
  ENDIF.

  CALL FUNCTION 'CCM_GO_BACK_MONTHS'
    EXPORTING
      currdate   = g_from
      backmonths = 1
    IMPORTING
      newdate    = g_fmon.

  MOVE    g_fmon(6)   TO    g_pspmon.

* ----------------------------------------------------------------------
* 1. FORM read_data_0001 . ---------------------------------------------
* ----------------------------------------------------------------------

*& 이동유형 반영규칙 정의
  REFRESH : it_zcot090.
  CLEAR   : it_zcot090.
  SELECT * FROM zcot0090
  APPENDING CORRESPONDING FIELDS OF TABLE it_zcot090
    WHERE bukrs = g_bukrs.

*& 계정에 대한 재고 반영규칙 정의
  REFRESH : it_zcot091.
  CLEAR   : it_zcot091.
  SELECT * FROM zcot0091
  APPENDING CORRESPONDING FIELDS OF TABLE it_zcot091
    WHERE bukrs = g_bukrs.

  REFRESH r_awtyp.

  SELECT SINGLE waers INTO g_waers
    FROM t001
   WHERE bukrs = g_bukrs.

  DATA: lv_col TYPE fieldname.
  IMPORT col = lv_col FROM MEMORY ID 'ZCOR0011_COL'.
  FREE MEMORY ID 'ZCOR0011_COL'.

  IF lv_col = 'WZUBB_PR'.
*- 입고금액(가격변경). 자재전표 전체는 읽지 않는다.
    PERFORM wzubb_pr.
    PERFORM wzubb_pu_wzubb_cp_re.
  ELSEIF lv_col = 'WZUBB_MLP'.
*- 입고금액(ML 정산).
    PERFORM wzubb_mlp_ml.
  ELSEIF lv_col = 'WAGBB_MC'.
*- 출고금액(매출원가). 매출 출고만 읽는다.
    PERFORM read_data_0002.
    SORT it_mseg BY bwart mblnr.
    REFRESH : it_zcot097,  it_leger.
    CLEAR   : it_zcot097,  it_leger.
    LOOP AT it_mseg.
      PERFORM mzubb_wzubb_pu_zcot090.
      CHECK it_zcot090-bwart NE ' '.
      CHECK it_zcot090-gubun = '22'.
      PERFORM read_data_0003_21_2z.
    ENDLOOP.
  ELSE.
  PERFORM read_data_0002.

* ///////////////////////////////////////////////////////////
  SORT it_mseg BY bwart mblnr. "SHKZG.

  REFRESH : it_zcot097,  it_leger.
  CLEAR   : it_zcot097,  it_leger.

  LOOP AT it_mseg.

*    it_zcot097-bukrs = it_mseg-bukrs.
    PERFORM mzubb_wzubb_pu_zcot090.

    CHECK it_zcot090-bwart NE ' '.
*& 구매입고
*& 생산입고
*& 외주가공입고
*& 공장간이전입고
*& 타계정입고
    IF it_zcot090-gubun BETWEEN '11' AND '1Z'.
      PERFORM read_data_0003_11_1z.
*& 출고(생산)
*& 출고(매출)
*& 출고(공장간이전)
*& 출고(타계정)
*& 출고(무상사급)
*& 출고(실사차이)
    ELSEIF it_zcot090-gubun BETWEEN '21' AND '2Z'.
      PERFORM read_data_0003_21_2z.
    ENDIF.

  ENDLOOP.

*  UP01. --------------------
*  DELETE   it_mseg   WHERE   sakto    >= '0040000000'
*                       AND   pocls    EQ   'Y'.

*- PR
*- 입고(가격변경)
  PERFORM wzubb_pr.

*- RE
*- WE
*- 입고금액(구매)
*- 입고금액(구매가격차)
  PERFORM wzubb_pu_wzubb_cp_re.
*  PERFORM WZUBB_PU_WZUBB_CP_WE.

*- SA( 조정/정산 전표)
*- 입고금액(생산)
*- 입고금액(원가차이)
  PERFORM wzubb_po_wzubb_co_sa.

*-출고(삼자거래) 추가 -- 2012.12.18.
  PERFORM wzubb_th.

*- ML
*- 입고금액(ML 정산)
  PERFORM wzubb_mlp_ml.
  ENDIF.
* ///////////////////////////////////////////////////////////



  PERFORM adjust_data.

  it_wzubb_pu[]   = gt_wzubb_pu[].
  it_wzubb_po[]	  = gt_wzubb_po[].
  it_wzubb_su[]	  = gt_wzubb_su[].
  it_wzubb_st[]	  = gt_wzubb_st[].
  it_wzubb_mt[]	  = gt_wzubb_mt[].
  it_wzubb_et[]   = gt_wzubb_et[].
  it_wzubb_pr[]   = gt_wzubb_pr[].
  it_wzubb_th[]   = gt_wzubb_th[].
  it_wzubb_co[]   = gt_wzubb_co[].
  it_wzubb_cp[]   = gt_wzubb_cp[].
  it_wzubb_ivp[]  = gt_wzubb_ivp[].
  it_wzubb_ivs[]  = gt_wzubb_ivs[].
  it_wzubb_sap[]  = gt_wzubb_sap[].
  it_wzubb_mlp[]  = gt_wzubb_mlp[].
  it_wagbb_jr[]   = gt_wagbb_jr[].
  it_wagbb_mc[]   = gt_wagbb_mc[].
  it_wagbb_ys[]   = gt_wagbb_ys[].
  it_wagbb_st[]   = gt_wagbb_st[].
  it_wagbb_mt[]   = gt_wagbb_mt[].
  it_wagbb_su[]   = gt_wagbb_su[].
  it_wagbb_et[]   = gt_wagbb_et[].
  it_wagbb_th[]   = gt_wagbb_th[].
  it_wagbb_pi[]   = gt_wagbb_pi[].
  it_wagbb_co[]   = gt_wagbb_co[].
ENDFUNCTION.

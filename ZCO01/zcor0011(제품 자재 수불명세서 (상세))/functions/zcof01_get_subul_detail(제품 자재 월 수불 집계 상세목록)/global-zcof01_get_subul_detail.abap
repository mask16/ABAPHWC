FUNCTION-POOL zcof01.                       "MESSAGE-ID ..

* INCLUDE LZCOF01D...                        " Local class definition
"INCLUDE lzcof01f01.

*&---------------------------------------------------------------------*
*   TABLES/STRUCTURES/VIEWS
*&---------------------------------------------------------------------*
TABLES: zcot0096,                  " 자재원장: 기간 총레코드 값
        zcot0097,                  " 자재원장 기간 총레코드 수량
        bkpf,
        bseg,
        rbkp,
        rseg,
        mkpf,
        mseg,
        mbew,
        mbewh,
        vbfa,
        vbrp,
        mara,
        afpo,
        bsim.

TABLES : ekpo.

*&---------------------------------------------------------------------*
* DATA DEFINITIONS
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
* CONSTANTS
*&---------------------------------------------------------------------*
DATA : ct_pstyp0             LIKE ekpo-pstyp    VALUE '0'.
DATA : ct_pstyp3             LIKE ekpo-pstyp    VALUE '3'.
DATA : ct_gubun11            LIKE zcot0090-gubun VALUE '11'.
DATA : ct_gubun12            LIKE zcot0090-gubun VALUE '12'.
DATA : ct_gubun15            LIKE zcot0090-gubun VALUE '15'.
DATA : ct_gubun16            LIKE zcot0090-gubun VALUE '16'.
DATA : ct_gubun17            LIKE zcot0090-gubun VALUE '17'.
DATA : ct_gubun18            LIKE zcot0090-gubun VALUE '18'.
DATA : ct_gubun19            LIKE zcot0090-gubun VALUE '19'.
DATA : ct_koartm             LIKE bseg-koart    VALUE 'M'.
DATA : ct_koarts             LIKE bseg-koart    VALUE 'S'.
DATA : ct_aufnrb             LIKE mseg-aufnr    VALUE '000001000000'.
DATA : ct_aufnre             LIKE mseg-aufnr    VALUE '000001999999'.
* HWS 추가
DATA : cx_aufnrb             LIKE mseg-aufnr    VALUE '9A0000000000'.
DATA : cx_aufnre             LIKE mseg-aufnr    VALUE '9AZZZZZZZZZZ'.

*&---------------------------------------------------------------------*
* INTERNAL TABLES
*&---------------------------------------------------------------------*
*& 제품/자재 월 수불 집계 INTERNAL TABLE
DATA: st_zcot097             LIKE zcot0097.
DATA: sa_zcot097             LIKE zcot0097 OCCURS 0 WITH HEADER LINE.
DATA: it_zcot097             LIKE zcot0097 OCCURS 0 WITH HEADER LINE.
DATA: it_zcot090             LIKE zcot0090 OCCURS 0 WITH HEADER LINE.
DATA: it_zcot091             LIKE zcot0091 OCCURS 0 WITH HEADER LINE.

DATA: gt_wzubb_pu   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(구매).
      gt_wzubb_po   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(생산).
      gt_wzubb_su   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(외주가공).
      gt_wzubb_st   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(공장이전).
      gt_wzubb_mt   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(자재간이전).
      gt_wzubb_et   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(타계정).
      gt_wzubb_pr   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(가격변경).
      gt_wzubb_th   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(삼자거래).
      gt_wzubb_co   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(원가차이).
      gt_wzubb_cp   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(구매가격차이).
      gt_wzubb_ivp  TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(IV구매).
      gt_wzubb_ivs  TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(IV사급).
      gt_wzubb_sap  TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(SA정산).
      gt_wzubb_mlp  TYPE TABLE OF zcos0005  WITH HEADER LINE,   "입고금액(ML정산).
      gt_wagbb_jr   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(재료비).
      gt_wagbb_mc   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(매출원가).
      gt_wagbb_ys   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(유상매각).
      gt_wagbb_st   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(공장이전).
      gt_wagbb_mt   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(자재간이전).
      gt_wagbb_su   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(사급자재).
      gt_wagbb_et   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(타계정).
      gt_wagbb_th   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(삼자거래).
      gt_wagbb_pi   TYPE TABLE OF zcos0005  WITH HEADER LINE,   "출고금액(실사차이).
      gt_wagbb_co   TYPE TABLE OF zcos0005  WITH HEADER LINE.   "출고금액(원가차이).

*& MSEG INTERNAL TABLE
DATA : BEGIN OF it_mseg OCCURS 0,
         bwart               LIKE mseg-bwart,
         shkzg               LIKE mseg-shkzg,
         mblnr               LIKE mseg-mblnr,
         mjahr               LIKE mseg-mjahr,
         xauto               LIKE mseg-xauto,
         kzvbr               LIKE mseg-kzvbr,
         matnr               LIKE mseg-matnr,
         bwtar               LIKE mseg-bwtar,
         werks               LIKE mseg-werks,
         lifnr               LIKE mseg-lifnr,
         waers               LIKE mseg-waers,
         dmbtr               LIKE mseg-dmbtr,
         menge               LIKE mseg-menge,
         meins               LIKE mseg-meins,
         reswk               LIKE ekko-reswk,
         aufnr               LIKE mseg-aufnr,
         ebeln               LIKE mseg-ebeln,
         ebelp               LIKE mseg-ebelp,
         pstyp               LIKE ekpo-pstyp,
         knttp               LIKE ekpo-knttp,
         gjahr               LIKE mseg-gjahr,
         umwrk               LIKE mseg-umwrk,
         ummat               LIKE mseg-ummat,
         bukrs               LIKE mseg-bukrs,
         blart               LIKE mkpf-blart,
         belnr               LIKE mseg-belnr, "추가.
         buzei               LIKE mseg-buzei, "추가.
         kdauf               LIKE mseg-kdauf,"추가 판매문서.
         kdpos               LIKE mseg-kdpos,"추가 판매문서품목.
         prctr               LIKE mseg-prctr, "추가 손익센터.
         budat               LIKE mkpf-budat,
         sakto               LIKE mseg-sakto,
         pocls(01)   TYPE    c,
         mtart               LIKE mara-mtart,  "HWS
       END OF it_mseg.

DATA : it_bkpfs              LIKE bkpf OCCURS 0 WITH HEADER LINE.
DATA : it_bkpfml             LIKE bkpf OCCURS 0 WITH HEADER LINE.
DATA : it_bkpfml2            LIKE bkpf OCCURS 0 WITH HEADER LINE.
DATA : it_bsegr              LIKE bseg OCCURS 0 WITH HEADER LINE.
DATA : it_bsegs              LIKE bseg OCCURS 0 WITH HEADER LINE.
DATA : it_bsegml             LIKE bseg OCCURS 0 WITH HEADER LINE.
RANGES : r_awtyp FOR bkpf-awtyp.

*---- BKPF INTERNAL TABLE
DATA : it_bkpf LIKE bkpf OCCURS 0 WITH HEADER LINE.

*---- BSEG INTERNAL TABLE
DATA : BEGIN OF te_bseg OCCURS 0,
        bukrs             TYPE bukrs, "UP01.----------------------
        gjahr             TYPE gjahr,
        belnr             TYPE belnr_d,
        buzei             TYPE buzei,
        werks             LIKE bseg-werks,
        matnr             LIKE bseg-matnr,
        bwtar             LIKE bseg-bwtar,
        shkzg             LIKE bseg-shkzg,
        dmbtr             LIKE bseg-dmbtr,
        hkont             LIKE bseg-hkont,
        aufnr             LIKE bseg-aufnr,
       END OF te_bseg.
*---- BSEG TABLE STRUCTURE
DATA: it_bseg LIKE te_bseg OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF it_leger OCCURS 0,
         awkey               LIKE bkpf-awkey,
         matnr               LIKE mara-matnr,
         werks               LIKE marc-werks,
       END OF it_leger.

DATA : ed_awkey LIKE bkpf-awkey.

DATA : tp_bdate LIKE bkpf-budat.
DATA : tp_edate LIKE bkpf-budat.

*---- 전역변수 선언
DATA: g_index   LIKE sy-tabix,
        g_pspmon  LIKE zcot0097-spmon,
      g_from    LIKE sy-datum,
      d_from    LIKE sy-datum,
        g_fmon    LIKE sy-datum,
      g_till    LIKE sy-datum,
      g_awtyp   LIKE bkpf-awtyp,
      g_awkey   LIKE bkpf-awkey,
*        g_belnr   LIKE bkpf-belnr,
      g_budat   LIKE bkpf-budat
*        g_datum   LIKE sy-datum,
*        g_dchk(01)   TYPE   c,
*        g_save_gubun LIKE zcot0090-gubun.
.
DATA : max_cnt     TYPE i.

DATA: g_bukrs TYPE bukrs,
      g_spmon TYPE spmon,
      g_waers TYPE waers.

DATA: gr_bwart TYPE RANGE OF bwart,
      gr_werks TYPE RANGE OF werks,
      gr_matnr TYPE RANGE OF matnr,
      gr_mblnr TYPE RANGE OF mblnr.

DATA: gr_matnr_8 TYPE RANGE OF matnr,
      gs_matnr_8 LIKE LINE OF gr_matnr.

*&---------------------------------------------------------------------*
*& Include ZSDR5054_E01
*&---------------------------------------------------------------------*

INITIALIZATION.
  PERFORM init_screen.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
  PERFORM f4_variant.

START-OF-SELECTION.
  PERFORM set_date_range.
  PERFORM get_data.
  IF gt_data IS INITIAL.
    MESSAGE '조회된 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  PERFORM call_screen_0100.

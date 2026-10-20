*&---------------------------------------------------------------------*
*& Include ZSDR5054_C01
*&---------------------------------------------------------------------*

CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row
                e_column
                es_row_no.
ENDCLASS.

CLASS lcl_event_receiver IMPLEMENTATION.
  METHOD handle_double_click.
    READ TABLE gt_data INTO gs_data INDEX e_row-index.
    CHECK sy-subrc = 0.
    IF e_column-fieldname = 'MATNR'.
      SET PARAMETER ID 'MAT' FIELD gs_data-matnr.
      CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

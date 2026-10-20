*&---------------------------------------------------------------------*
*& Include ZSDR5054_I01
*&---------------------------------------------------------------------*

MODULE exit_0100 INPUT.
  PERFORM exit_process_0100 USING 'X'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  PERFORM set_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      PERFORM exit_process_0100 USING space.
    WHEN 'EXIT'.
      PERFORM exit_process_0100 USING 'X'.
  ENDCASE.
ENDMODULE.

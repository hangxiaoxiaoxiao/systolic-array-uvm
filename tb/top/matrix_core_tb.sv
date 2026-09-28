module matrix_core_tb;
  timeunit 1ns;
  timeprecision 1ps;
  import uvm_pkg::*;
  import matrix_core_tests_pkg::*;
  initial run_test("matrix_core_smoke_test");
endmodule

`ifndef MATRIX_COMMON_PKG_SV
`define MATRIX_COMMON_PKG_SV

`include "uvm_macros.svh"

package matrix_common_pkg;
  import uvm_pkg::*;

  // Declare each imp suffix once, shared by every parameter specialization.
  `uvm_analysis_imp_decl(_matrix_input)
  `uvm_analysis_imp_decl(_matrix_output)

  `include "matrix_item.svh"
  `include "matrix_result.svh"
  `include "matrix_reference.svh"
  `include "matrix_prediction.svh"
  `include "matrix_scoreboard.svh"
endpackage

`endif

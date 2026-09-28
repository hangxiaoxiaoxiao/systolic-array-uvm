// Component self-tests only. These tests do not drive a DUT interface.
`include "uvm_macros.svh"
package matrix_core_tests_pkg;
  import uvm_pkg::*;
  import matrix_common_pkg::*;
  `include "matrix_core_test.svh"
endpackage

// Lesson 11: bundle the array module's signals in a SystemVerilog interface.
// This is a signal-access example, not a complete matrix input schedule.
// No DUT or UVM components are connected; DUT output signals remain undriven.
`timescale 1ns/1ps

interface systolic_array_if #(
  parameter int DIN_WIDTH = 8,
  parameter int N = 2
)(input logic clk);
  logic rst_n;
  logic signed [DIN_WIDTH-1:0] a_din[0:N-1];
  logic signed [DIN_WIDTH-1:0] b_din[0:N-1];
  logic signed [2*DIN_WIDTH-1:0] c_din[0:N-1];
  logic in_valid;

  // Preserve the output array direction given in the PDF.
  logic signed [2*DIN_WIDTH-1:0] c_dout[N-1:0];
  logic out_valid;

  // The PDF describes in_valid/out_valid as last-element indications.
  // Do not assume these are ordinary per-beat valid signals.
endinterface

module interface_demo;
  logic clk = 0;
  always #5 clk = ~clk;

  systolic_array_if #(.DIN_WIDTH(8), .N(2)) bus(clk);

  initial begin
    bus.rst_n = 0;
    bus.in_valid = 0;
    for (int lane = 0; lane < 2; lane++) begin
      bus.a_din[lane] = 0;
      bus.b_din[lane] = 0;
      bus.c_din[lane] = 0;
    end

    repeat (2) @(negedge clk);
    bus.rst_n = 1;

    // Illustrative lane values only; this does not submit a matrix operation.
    // Drive on the falling edge, so values are stable at the next rising edge.
    bus.a_din[0] =  8'sd1;
    bus.a_din[1] = -8'sd2;

    @(posedge clk);
    $display("Input element width: %0d; output element width: %0d",
             $bits(bus.a_din[0]), $bits(bus.c_dout[0]));
    $display("Interface inputs: rst_n=%0b, a_din[0]=%0d, a_din[1]=%0d",
             bus.rst_n, bus.a_din[0], bus.a_din[1]);

    @(negedge clk);
    $finish;
  end
endmodule

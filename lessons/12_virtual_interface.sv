// Lesson 12: a class accesses a real interface through a virtual interface.
// Standalone SystemVerilog example; top: virtual_interface_demo. No UVM or DUT.
// Compile this file by itself, without other lessons defining the same interface.
// This demonstrates handle binding only, not the matrix input protocol.
// Local Icarus 13.0 rejects the virtual-interface field declaration. A minimal
// unparameterized probe reproduces it; this lesson has not been simulated.
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
  logic signed [2*DIN_WIDTH-1:0] c_dout[N-1:0];
  logic out_valid;
endinterface

class interface_writer;
  // This handle must match the parameters of the actual interface instance.
  virtual systolic_array_if #(.DIN_WIDTH(8), .N(2)) vif;

  task drive_example();
    if (vif == null)
      $fatal(1, "Bind the virtual interface before driving signals");

    @(negedge vif.clk);
    vif.a_din[0] =  8'sd1;
    vif.a_din[1] = -8'sd2;
  endtask
endclass

module virtual_interface_demo;
  logic clk = 0;
  always #5 clk = ~clk;

  systolic_array_if #(.DIN_WIDTH(8), .N(2)) bus(clk);
  interface_writer writer;

  initial begin
    bus.rst_n = 0;
    bus.in_valid = 0;
    for (int lane = 0; lane < 2; lane++) begin
      bus.a_din[lane] = 0;
      bus.b_din[lane] = 0;
      bus.c_din[lane] = 0;
    end

    writer = new();       // Create the class object.
    writer.vif = bus;     // Refer to the existing interface, without copying it.

    repeat (2) @(negedge clk);
    bus.rst_n = 1;
    writer.drive_example();

    // Read through bus after the class wrote through vif.
    @(posedge clk);
    $display("Read via bus: a_din[0]=%0d, a_din[1]=%0d",
             bus.a_din[0], bus.a_din[1]);

    @(negedge clk);
    $finish;
  end
endmodule

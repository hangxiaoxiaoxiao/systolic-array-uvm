`timescale 1ns/1ps
// Lesson 53: advance to the next prepared word only after an accepted write.
// Ordinary SV; top: fifo_write_acceptance_demo. No UVM or interview DUT.
// TEACHING CONTRACT, not confirmed by the PDF:
//   a write is accepted at posedge sys_clk when pre-edge wr_fifo && !full;
//   the writer drives at negedge and deasserts wr_fifo while full;
//   a full slot cannot accept a write even if consumed on that same edge.
// A one-slot, single-clock model creates real occupancy-based backpressure.
// consume_enable is an INTERNAL teaching consumer, NOT the PDF's rd_fifo.
// There is no sr_clk, CDC, output FIFO, or matrix computation in this example.
// +INJECT_SKIP deliberately advances past one pending word while full.
module fifo_write_acceptance_demo;
  localparam int BUS_WIDTH = 32;
  localparam int WORD_COUNT = 3;

  logic sys_clk = 0;
  logic rst_n = 0;
  logic [BUS_WIDTH-1:0] din = '0;
  logic wr_fifo = 0;
  wire in_fifo_full;
  logic consume_enable = 0;
  logic occupied;
  logic [BUS_WIDTH-1:0] slot;
  wire accepted_write = wr_fifo && !in_fifo_full;
  wire consumed_word = consume_enable && occupied;

  logic [BUS_WIDTH-1:0] prepared_words[0:WORD_COUNT-1];
  int accepted_count = 0;
  int consumed_count = 0;
  int waiting_edges = 0;
  bit skip_injected = 0;

  always #5 sys_clk = ~sys_clk;
  assign in_fifo_full = occupied;

  // Synchronous reset is another local teaching choice.
  // Nonblocking assignments leave pre-edge occupancy/data visible to observers.
  always @(posedge sys_clk) begin
    if (!rst_n) begin
      occupied <= 0;
      slot <= '0;
    end else begin
      if (accepted_write) begin
        slot <= din;
        occupied <= 1;
      end else if (consumed_word) begin
        occupied <= 0;
      end
    end
  end

  // Independent literal oracle: never read the driver's prepared_words array.
  function automatic logic [BUS_WIDTH-1:0] expected_word(input int index);
    case (index)
      0: return 32'h08070401;
      1: return 32'h0AF705FE;
      2: return 32'hF40BFA03;
      default: begin
        $fatal(1, "EXTRA_WORD: index=%0d", index);
        return 'x;
      end
    endcase
  endfunction

  // Observe actual model acceptance, not the driver's progress variable.
  always @(posedge sys_clk) begin
    if (rst_n) begin
      if ((wr_fifo !== 1'b0 && wr_fifo !== 1'b1) ||
          (in_fifo_full !== 1'b0 && in_fifo_full !== 1'b1) ||
          (consume_enable !== 1'b0 && consume_enable !== 1'b1))
        $fatal(1, "UNKNOWN_CONTROL");
      if (wr_fifo && in_fifo_full)
        $fatal(1, "WRITER_CONTRACT: wr_fifo must be low while full in this lesson");
      if (accepted_write) begin
        if (din !== expected_word(accepted_count))
          $fatal(1, "ACCEPT_ORDER: index=%0d actual=%08h expected=%08h",
                 accepted_count, din, expected_word(accepted_count));
        $display("ACCEPT: t=%0t index=%0d din=%08h",
                 $time, accepted_count, din);
        accepted_count++;
      end
      if (consumed_word) begin
        if (slot !== expected_word(consumed_count))
          $fatal(1, "CONSUME_ORDER: index=%0d actual=%08h expected=%08h",
                 consumed_count, slot, expected_word(consumed_count));
        $display("CONSUME: t=%0t index=%0d data=%08h",
                 $time, consumed_count, slot);
        consumed_count++;
      end
    end
  end

  // Pause consumption long enough to force full-induced waiting.
  initial begin
    wait (rst_n === 1'b1);
    repeat (6) @(negedge sys_clk);
    consume_enable = 1;
  end

  initial begin : writer_and_completion
    int next_word;
    $timeformat(-9, 0, " ns", 0);
    // Reuse the three words prepared in lesson 52, with its assumed bit layout.
    prepared_words[0] = 32'h08070401;
    prepared_words[1] = 32'h0AF705FE;
    prepared_words[2] = 32'hF40BFA03;
    next_word = 0;

    repeat (2) @(negedge sys_clk);
    rst_n = 1;
    while (next_word < WORD_COUNT) begin
      @(negedge sys_clk);
      if (in_fifo_full !== 1'b0 && in_fifo_full !== 1'b1)
        $fatal(1, "UNKNOWN_FULL");
      din = prepared_words[next_word];
      wr_fifo = !in_fifo_full;

      @(posedge sys_clk);
      if (accepted_write) begin
        next_word++;
      end else begin
        waiting_edges++;
        $display("WAIT_FULL: t=%0t keep_index=%0d", $time, next_word);
        if ($test$plusargs("INJECT_SKIP") && !skip_injected) begin
          $display("INJECT_SKIP: abandoning pending word index=%0d", next_word);
          next_word++;
          skip_injected = 1;
        end
      end
    end

    @(negedge sys_clk);
    wr_fifo = 0;
    wait (consumed_count == WORD_COUNT);
    @(negedge sys_clk);
    if (accepted_count != WORD_COUNT || consumed_count != WORD_COUNT ||
        in_fifo_full !== 1'b0 || waiting_edges == 0)
      $fatal(1, "COMPLETION: accepted=%0d consumed=%0d full=%b waits=%0d",
             accepted_count, consumed_count, in_fifo_full, waiting_edges);
    $display("WRITE_DEMO_PASS: accepted=%0d consumed=%0d waits=%0d; teaching FIFO only.",
             accepted_count, consumed_count, waiting_edges);
    $finish;
  end

  initial begin
    #500;
    $fatal(1, "WATCHDOG: teaching example did not complete within 500 ns");
  end
endmodule

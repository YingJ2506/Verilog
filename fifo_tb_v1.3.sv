`timescale 1ns/1ps

module fifo_tb_1 ();
  logic clk;
  logic rst;
  logic wt_en;
  logic rd_en;
  logic [WIDTH-1:0]data_in;
  
  logic [WIDTH-1:0]data_out;
  logic full_s;
  logic empty_s;
  logic overflow,underflow;
  
  parameter MODE = 0; // 0: manual, 1:auto 
  parameter DEPTH = 16;
  parameter WIDTH = 8;  
  
  logic [WIDTH-1:0] overflow_c = 0;
  logic [WIDTH-1:0] underflow_c = 0;
  logic pre_overflow,pre_underflow;
  logic [WIDTH-1:0]cycle;
  logic [31:0] seed = 111; //set seed
  
  // instance module
  fifo_rtl_1 ins1 (.dout(data_out),
                   .full(full_s),
                   .empty(empty_s),
                   .clk(clk),
                   .rst(rst),
                   .wt_en(wt_en),
                   .rd_en(rd_en),
                   .din(data_in),
                   .overflow(overflow),
                   .underflow(underflow)
                  );
//   fifo_coverage ins_coverage;
  
  // tb
  initial begin  
    $dumpfile("fifo_tb_1.vcd");
    $dumpvars(0, ins1);
    
    $display("---Start FIFO Test---");
    $display(" Time  | ct | wt_p | rd_p | din | dout | full | empty");

    clk = 0;
    rst = 0;
    wt_en = 0;
    rd_en = 0;
    data_in = 1'd1;
    cycle = 0;
    // ins_coverage = new; // initial covergroup
    
    #5 rst = 1;    // test reset
    #10 rst = 0;  
    
    #1100 $display("---End FIFO Test---");
    $display("overflow_count = %0d, underflow_count = %0d",overflow_c,underflow_c);
    $finish;  
  end
  
  // manual test
  always @(posedge clk) begin
    if (!MODE) begin
      case (cycle)
      // --- test write ---
      3: wt_en = 1;
      5: wt_en = 0;

      // --- test read ---
      6: rd_en = 1;
      8: rd_en = 0;

      // --- test underflow ---
      9: rd_en = 1;
      15: rd_en = 0;

      // --- test write & read together ---
      16: wt_en = 1;
      18: rd_en = 1;

      // --- test overflow ---
      28: rd_en = 0;
      45: wt_en = 1;
      46: wt_en = 0;

      // --- test reset in process ---
      47: wt_en = 1;
      48: rd_en = 1;
      49: rst = 1;
      50: rst = 0;

      // --- test idle ---
      51: begin wt_en = 0; rd_en = 0; end
      endcase 
      cycle <= cycle + 1;
      
    end
    // random test
    else begin
      $urandom(seed); //seed
      wt_en = !full_s ? ($urandom(seed) % 2) : 0;  // 50% write
      rd_en = !empty_s ? ($urandom(seed) % 2) : 0; // 50% read
      rst = ($urandom(seed) % 1000 < 1);  // 0.1% rst
    end
  end
  
  // clock create
  always begin
    #10 clk = ~clk;
//     ins_coverage.sample();
  end
  
  // data in
  always_ff @(posedge clk) begin
    data_in <= data_in + 1;
  end
  
  // show data
  always @(posedge clk) begin
    $display("%6t | %3d | %3d | %3d | %3d | %4d | %4b | %4b",
             $time, ins1.ct, ins1.wt_p, ins1.rd_p, data_in, data_out, full_s, empty_s);
  end
  
  // count overflow/underflow  (Count only switch on)
  always_ff @(posedge clk) begin 
    if (overflow && !pre_overflow) overflow_c <= overflow_c + 1;
    if (underflow && !pre_underflow) underflow_c <= underflow_c + 1;
    pre_overflow <= overflow;
    pre_underflow <= underflow;
  end
  
  // assert
  always @(posedge clk) begin
    if (ins1.ct == DEPTH) 
      assert (full_s == 1) else $error("TB Fail: full flag error at time %t", $time);
    if (ins1.ct == 0)
      assert (empty_s == 1) else $error("TB Fail: empty flag error at time %t", $time);
  end
  
// //   coverage (lcarus verilog cannot)
//   covergroup fifo_coverage @(posedge clk);
//     c_full: coverpoint full_s;
//     c_empty: coverpoint empty_s;
//     c_count: coverpoint ins1.ct {
//       bins low = {[0:4]};
//       bins mid = {[5:10]};
//       bins high = {[11:15]};
//       bins full_val = {16};
//     }
//     cross_wt_rd: cross wt_en, rd_en;
//   endgroup
  
endmodule
  

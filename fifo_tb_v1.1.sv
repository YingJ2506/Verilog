`timescale 1ns/1ps

module fifo_tb_1 ();
  reg clk;
  reg rst;
  reg wt_en;
  reg rd_en;
  reg [7:0]data_in;
  wire [7:0]data_out;
  wire full_s;
  wire empty_s;
  
  // instance module
  fifo_rtl_1 ins1 (.dout(data_out),
                   .full(full_s),
                   .empty(empty_s),
                   .clk(clk),
                   .rst(rst),
                   .wt_en(wt_en),
                   .rd_en(rd_en),
                   .din(data_in)
                  );
  
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
    
    #5 rst = 1;    // test reset
    #10 rst = 0;  
    
    #5 wt_en = 1;  // test write
    #20 wt_en = 0;
    #5 rd_en = 1;   // test read
    #20 rd_en = 0;
    
    #5 rd_en = 1;  // test underflow
    #60 rd_en = 0;
    
    #5 wt_en = 1;  // test together
    #20 rd_en = 1;
    
    #60 rd_en = 0;  // test overflow
    #330 wt_en = 0;
    
    #5 wt_en = 1;  // test reset in process
    #15 rd_en = 1;
    #15 rst = 1;
    #10 rst = 0;
    
    #5 wt_en = 0; // test idle
    #5 rd_en = 0;
    #80 $display("---End FIFO Test---");
    $finish;  
  end
  
  // clock create
  always #10 clk = ~clk;
  
  // data in
  always @(posedge clk) begin
    data_in <= data_in + 1;
  end
  
  // show data
  always @(posedge clk) begin
    $display("%6t | %3d | %3d | %3d | %3d | %4d | %4b | %4b",
             $time, ins1.ct, ins1.wt_p, ins1.rd_p, data_in, data_out, full_s, empty_s);
  end
  
  // assert block
  always @(posedge clk) begin
    if (ins1.ct == 16) 
      assert (full_s == 1) else $error("TB Fail: full flag error at time %t", $time);
    else if (ins1.ct == 0)
      assert (empty_s == 1) else $error("TB Fail: empty flag error at time %t", $time);
  end
  
endmodule
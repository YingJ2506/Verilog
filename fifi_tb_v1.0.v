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
  
endmodule
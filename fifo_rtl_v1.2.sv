module fifo_rtl_1 (
  input clk,
  input rst,
  input wt_en,
  input rd_en,
  input [7:0]din,
  output [7:0]dout,
  output full,empty,
  output reg overflow,underflow
);

  reg [7:0]mem[15:0];   // memory: 16depth in every bit (8bits)
  reg [3:0]wt_p, rd_p;  // pointer in write and read, for memory, 16=2^4, 4bits enough to save
  reg [4:0]ct;          // Fix: from reg [3:0]ct to reg [4:0]ct for count dada in (0~16)
  reg [7:0]dout_r;      
  
  // combination logic for full & empty
  assign full = (ct == 5'd16);  // fix from (ct == 4'd16) to (ct == 5'd16)
  assign empty = (ct == 0);
  assign dout = dout_r;
  
  // sequential logic for write & read & reset
  always @(posedge clk or posedge rst) begin
    // for reset
    if (rst) begin
      wt_p <= 0;
      rd_p <= 0;
      dout_r <= 0;
      ct <= 0;
    end
    else begin  // Fix: ct logic from (if wt or rd) to (if wt or rd or wr&rd)
      if (wt_en && !full && rd_en && !empty) begin
      // write & read, ct in same
        mem[wt_p] <= din;
        wt_p <= wt_p + 1;
        dout_r <= mem[rd_p];
        rd_p <= rd_p + 1;
      end
      else if (wt_en && !full) begin
      // write
        mem[wt_p] <= din;
        wt_p <= wt_p + 1;
        ct <= ct + 1;
      end
      else if (rd_en && !empty) begin  // 沒有else?
      // read
        dout_r <= mem[rd_p];
        rd_p <= rd_p + 1;
        ct <= ct - 1;
      end
      else begin
        ct <= ct;
        wt_p <= wt_p;
        rd_p <= rd_p;
        dout_r <= dout_r;
      end
    end
  end
  
  // overflow & underflow
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      overflow <= 0;
      underflow <= 0;
    end
    else if (wt_en && full) begin
      overflow <= 1;
    end
    else if (rd_en && empty) begin
      underflow <= 1;
    end
    else begin
      overflow <= 0;
      underflow <= 0;
    end
  end
  
  //assert block
  always @(posedge clk) begin
    // check full status
    assert ((ct == 5'd16) -> full) 
      else $error("RTL Fail: full flag error at time %t", $time);
    // check empty status
    assert ((ct == 0) -> empty)
      else $error("RTL Fail: empty flag error at time %t", $time);
  end
  always @(posedge clk) begin
    // over counting is not allowed
    if (ct > 5'd16) begin
      assert (0) else $fatal(0, "ERROR: ct > 16 overflowed at time %t", $time);
    end
  end
  always @(posedge clk) begin
    // check overflow status
    assert (!overflow) 
      else $warning("RTL Fail: overflow flag error at time %t", $time);
    // check underflow status
    assert (!underflow) 
      else $warning("RTL Fail: underflow flag error at time %t", $time);
  end
  
endmodule
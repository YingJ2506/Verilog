module fifo_rtl_1 #(
  parameter DEPTH = 16,
  parameter WIDTH = 8
)(
  input logic clk,
  input logic rst,
  input logic wt_en,
  input logic rd_en,
  input logic [WIDTH-1:0]din,
  output logic [WIDTH-1:0]dout,
  output logic full,empty,
  output logic overflow,underflow
);
  localparam LOG_WIDTH = $clog2(DEPTH+1);  // as math.ceil(math.log2(depth+1))  0~16 => 16+1

  logic [WIDTH-1:0]mem[0:DEPTH-1];   // memory: 16depth in every bit (8bits)
  logic [LOG_WIDTH-1:0]wt_p, rd_p;  // pointer in write and read, for memory, 16=2^4, enough to save
  logic [LOG_WIDTH:0]ct;          // (0~16) need 17 counts, 4+1 bits
  logic [WIDTH-1:0]dout_r;        // for sequential logic output
  
  // def status for fifo case
  typedef enum logic[1:0]{
  	IDLE = 2'b00,
    READ_ONLY = 2'b01,
    WRITE_ONLY = 2'b10, 
    WRITE_READ = 2'b11
  }fifo_status;
  
  
  // combination logic for full & empty
  assign full = (ct == DEPTH);  // fix from (ct == 4'd16) to (ct == 5'd16)
  assign empty = (ct == 0);
  assign dout = dout_r;
  
  // sequential logic for write & read & reset
  always_ff @(posedge clk or posedge rst) begin
    // for reset
    if (rst) begin
      wt_p <= 0;
      rd_p <= 0;
      dout_r <= 0;
      ct <= 0;
      overflow <= 0;  // overflow & underflow logic combine
      underflow <= 0;      
    end
    else begin  
      overflow <= 0;
      underflow <= 0;
      unique case({wt_en, rd_en})  // case
//         IDLE: begin // not write & read to default
        READ_ONLY: begin // {0,1} 2'b01 read only
          if (!empty) begin
            ct <= ct - 1;
            dout_r <= mem[rd_p];
            rd_p <= (rd_p == DEPTH-1) ? 0 : (rd_p + 1);
          end else begin
            underflow <= 1;
          end
        end
        WRITE_ONLY: begin // {1,0} 2'b10 write only
          if (!full) begin
            ct <= ct + 1;
            mem[wt_p] <= din;
            wt_p <= (wt_p == DEPTH-1) ? 0 : (wt_p + 1);
          end else begin
            overflow <= 1;
          end
        end
        WRITE_READ: begin // {1,1} 2'b11 write & read
          if (!empty && !full) begin
            ct <= ct;
            mem[wt_p] <= din;
            dout_r <= mem[rd_p];
            wt_p <= (wt_p == DEPTH-1) ? 0 : (wt_p + 1);
            rd_p <= (rd_p == DEPTH-1) ? 0 : (rd_p + 1);
          end else if (full) begin
            overflow <= 1;
          end else if (empty) begin
            underflow <= 1;
          end
        end
        default: begin // {0,0} 2'b00 not write & read
          ct <= ct;
          wt_p <= wt_p;
          rd_p <= rd_p;
        end
      endcase
    end
  end
  
  
  //assert block
  always @(posedge clk) begin
    // check full status
    assert ((ct == DEPTH) -> full) 
      else $error("RTL Fail: full flag error at time %t", $time);
    // check empty status
    assert ((ct == 0) -> empty)
      else $error("RTL Fail: empty flag error at time %t", $time);
  end
  always @(posedge clk) begin
    // over counting is not allowed
    if (ct > DEPTH) begin
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:10:10 10/26/2013 
// Design Name: 
// Module Name:    WrBuf_mux 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module WrBuf_mux(d2, d1, d0, WrBuf_sel,Dout);
  input [63:0] d2,d1,d0;
  input [1:0] WrBuf_sel;
  output[63:0] Dout;
  reg [63:0]   Dout;
	
  always@(d2,d1,d0, WrBuf_sel) begin
    case(WrBuf_sel)
      2'b00: Dout=d0;
      2'b01: Dout=d1;
      2'b10: Dout=d2;
      default: Dout=Dout;

    endcase
  end	 

endmodule

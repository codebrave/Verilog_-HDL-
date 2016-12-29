`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:01:46 10/26/2013 
// Design Name: 
// Module Name:    S_mux 
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
module S_mux(d2, d1, d0, S_Sel,S_mux_out);
	input [63:0] d2,d1,d0;
	input [1:0] S_Sel;
	output[63:0] S_mux_out;
	reg [63:0] S_mux_out;
	
   always@(d2,d1,d0, S_Sel)
    casex(S_Sel)
      2'b00: S_mux_out=d0;
		2'b01: S_mux_out=d1;
		2'b10: S_mux_out=d2;
		default: S_mux_out=S_mux_out;
  
    endcase


endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:09:24 10/26/2013 
// Design Name: 
// Module Name:    MAR_mux 
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
module MAR_mux(d2, d1, d0, MAR_sel,MAR_mux_out);
	input [31:0] d2, d1, d0;
	input [3:0]  MAR_sel;
	output[31:0] MAR_mux_out;
	reg [31:0]   MAR_mux_out;	 
	 
 always@(*)//d2,d1,d0, MAR_sel) // whenever data or select change
	 case( MAR_sel)
	   4'b0000: MAR_mux_out = d0;
		4'b0001: MAR_mux_out = d1;
		4'b0010: MAR_mux_out = d2;	
		4'b0011: MAR_mux_out = 32'h3ff;
		4'b0011: MAR_mux_out = 64'h3fe;
		4'b0100: MAR_mux_out = 64'h2a1;
		4'b0101: MAR_mux_out = 64'h2a3;
		4'b0110: MAR_mux_out = 64'h2a5;
		4'b0111: MAR_mux_out = 64'h2a7;
		4'b1000: MAR_mux_out = 64'h2a9;
	   default: MAR_mux_out=MAR_mux_out; 
    endcase

endmodule

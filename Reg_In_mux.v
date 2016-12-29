`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:22:11 10/26/2013 
// Design Name: 
// Module Name:    Reg_In_mux 
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
module Reg_In_mux(d4, d3, d2, d1, d0, Reg_In_sel,Reg_mux_out);
	input [63:0] d4, d3,d2,d1,d0;
	input [2:0] Reg_In_sel;
	output[63:0] Reg_mux_out;
	reg [63:0]Reg_mux_out;
	
   always@(d4,d3,d2,d1,d0, Reg_In_sel,Reg_mux_out)
    casex(Reg_In_sel)
      3'b000: Reg_mux_out=d0;
		3'b001: Reg_mux_out=d1;
		3'b010: Reg_mux_out=d2;
		3'b011: Reg_mux_out=d3;
		3'b100: Reg_mux_out=d4;
		default: Reg_mux_out=Reg_mux_out;
  
    endcase


endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:56:39 10/26/2013 
// Design Name: 
// Module Name:    CPSR_mux 
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
module CPSR_mux(d4, d3, d2, d1, d0, CPSR_sel,CPSR_mux_out);
	input [31:0] d4, d3,d2,d1,d0;
	input [2:0] CPSR_sel;
	output[31:0] CPSR_mux_out;
	reg [31:0]CPSR_mux_out;
	
   always@(d4,d3,d2,d1,d0, CPSR_sel,CPSR_mux_out)
    case(CPSR_sel)
      3'b000: CPSR_mux_out=d0;
		3'b001: CPSR_mux_out=d1;
		3'b010: CPSR_mux_out=d2;
		3'b011: CPSR_mux_out=d3;
		3'b100: CPSR_mux_out=d4;
		default: CPSR_mux_out = CPSR_mux_out;
  
    endcase


endmodule

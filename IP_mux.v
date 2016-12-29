`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:03:49 10/26/2013 
// Design Name: 
// Module Name:    IP_mux 
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
module IP_mux(d4, d3, d2, d1, d0, IP_sel,IP_mux_out);
	input [31:0] d4, d3,d2,d1,d0;
	input [2:0] IP_sel;
	output[31:0] IP_mux_out;
	reg [31:0]IP_mux_out;
	
   always@(d4,d3,d2,d1,d0, IP_sel)
    case(IP_sel)
      3'b000: IP_mux_out=d0;
		3'b001: IP_mux_out=d1;
		3'b010: IP_mux_out=d2;
		3'b011: IP_mux_out=d3;
		3'b100: IP_mux_out=d4;
		default: IP_mux_out = IP_mux_out;
  
    endcase


endmodule


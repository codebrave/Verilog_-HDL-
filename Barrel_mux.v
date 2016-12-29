`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:17:26 10/25/2013 
// Design Name: 
// Module Name:    Barrel_mux 
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
module Barrel_mux(d9,d8, d7, d6, d5,d4, d3, d2, d1,d0, select, data_out);
	input [63:0] d9, d8,d7,d6,d5,d4,d3,d2,d1,d0;
	input [3:0] select;
	output[63:0] data_out;
	reg [63:0]data_out;
	
	always@(*) begin // whenever data or select change
	
	  case(select) 
       4'b0000: data_out = d0;
       4'b0001: data_out = d1;
       4'b0010: data_out = d2;
       4'b0011: data_out = d3;
       4'b0100: data_out = d4;	
       4'b0101: data_out = d5;
       4'b0110: data_out = d6;
       4'b0111: data_out = d7;
       4'b1000: data_out = d8;
       4'b1001: data_out = d9;		
		
      default: data_out = data_out; 
    endcase
	 
  end

endmodule

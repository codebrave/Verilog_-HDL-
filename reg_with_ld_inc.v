`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:11:34 10/26/2013 
// Design Name: 
// Module Name:    IP_reg 
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
module reg_with_ld_inc(clk, reset, ld, inc, Din, Dout);
	input clk, reset; 
	input  ld, inc;
	input [31:0] Din;
	output reg [31:0] Dout;
	
	//behavioral section for writing to the register
	always @(posedge clk)
	
		if (reset)//check for reset
		
			Dout<=32'b0;
			
		else begin
		
			if (ld)
			
				Dout <= Din;
			else if (inc)

          Dout <= Dout+1;
         else Dout<= Dout;		

       end			

endmodule

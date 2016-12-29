`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:11:42 10/27/2013 
// Design Name: 
// Module Name:    reg_with_ld 
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
module reg_with_ld(clk, reset, ld, Din, Dout);
	input clk, reset; 
	input  ld;
	input [31:0] Din;
	output reg [31:0] Dout;
	
	//behavioral section for writing to the register
	always @(posedge clk) begin
	
		if (reset)//check for reset
		
			Dout<=32'b0;
			
		else begin
		
			if (ld)
			
				Dout <= Din;

         else 
			Dout<= Dout;		

       end	

  end		 

endmodule


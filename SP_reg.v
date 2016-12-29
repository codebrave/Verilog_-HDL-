`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:13:51 10/26/2013 
// Design Name: 
// Module Name:    SP_reg 
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
module SP_reg(clk, reset, Din, ld, inc, dec, Dout);
	input clk, reset; 
	input ld, inc, dec;
	input [31:0] Din;
	output reg [31:0] Dout;
	
	//behavioral section for writing to the register
	always @(posedge clk) begin
	
		if (reset)//check for reset
		
			Dout <= 32'h3fe;
			
		else
		
        if(ld)

         Dout <= Din;

        else if (inc)
			
          Dout <= Dout+1;
						
        else if (dec)

          Dout <= Dout-1;			
			  
        else 
          Dout <= Dout;

  end
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    05:18:23 11/05/2013 
// Design Name: 
// Module Name:    CPSR 
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

module CPSR(clk, reset, ld, Din, Dout);
	input clk, reset; 
	input [2:0] ld;
	input [31:0] Din;
	output reg [31:0] Dout;
	
	//behavioral section for writing to the register
	always @(posedge reset, posedge clk) begin
	
     if (reset)//check for reset
		
       Dout <=32'b0;
			
     else begin
		
      case(ld)
		  3'b001:  Dout <= {Dout[31:10], Din[9:6],  Dout[5:0]};
        3'b010:  Dout <= {Dout[31:10], Dout[9:6], Din[5:0]};
        3'b100:  Dout <= {Din[31:10],  Dout[9:6], Dout[5:0]};     
        3'b111:  Dout <= Din;		  
        default: Dout  <= Dout;
      endcase
    end
  end	 
endmodule


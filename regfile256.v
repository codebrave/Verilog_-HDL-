`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:41:54 10/26/2013 
// Design Name: 
// Module Name:    regfile256 
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
module regfile256(clk, W_En, W_Addr, S_Addr, R_Addr, R, S, WR);

  input W_En, clk; 
  input [4:0] W_Addr, R_Addr, S_Addr;
  input [255:0] WR;
  output reg [255:0] R, S;
  
  //Array of 32 Registers of 256 bits
  reg[255:0] reg_files[0:31];
  
  always @(R_Addr or reg_files[R_Addr])
    R= reg_files[R_Addr];
	 
  always @(S_Addr or reg_files[S_Addr])
    S= reg_files[S_Addr];
	 
  always @(posedge clk)
    if(W_En==1'b1)
	   reg_files[W_Addr] <= WR;
		
endmodule

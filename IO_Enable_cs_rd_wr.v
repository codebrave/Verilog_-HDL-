`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:26:03 10/27/2013 
// Design Name: 
// Module Name:    IO_Enable_cs_rd_wr 
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
module IO_Enable_cs_rd_wr(Enable, CS_In, RD_In, WR_In, CS_Out, RD_Out, WR_Out);

  input CS_In, RD_In, WR_In, Enable;
  output wire CS_Out, RD_Out, WR_Out;
  
  assign CS_Out = Enable ? (CS_In): CS_Out;
  assign RD_Out = Enable ? (RD_In): RD_Out;
  assign CS_Out = Enable ? (WR_In): WR_Out;  


endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:06:12 10/26/2013 
// Design Name: 
// Module Name:    FloatDP 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  The FloatDP module is a structural implementation that 
//               interconnects the regfile64 and the FloatALU modules together. 
//               In addition, it instantiates a 2-1 multiplexer that allow data 
//               to come from the Float_In input for memory, input, output, or 
//               other applicable instruction register fields. The FloatALU 
//               module will perform arithmeic and logical operations and it is 
//               in a double precision format that consists of a an exponent 
//              (bits 62-53) and a fraction (bits 52-0). 
//
//////////////////////////////////////////////////////////////////////////////////
module FloatDP (FP_Op, W_Clk, FW_En, FW_Addr,FR_Addr, FS_Addr, Float_In, F_Sel,
                FP_Status, Float_Out, FS_Sel);
					
  input         F_Sel,FS_Sel, W_Clk, FW_En;
  input  [4:0]  FR_Addr, FW_Addr, FS_Addr;
  input  [4:0]  FP_Op;
  input  [63:0] Float_In;
  
  output [5:0]  FP_Status;
  output [63:0] Float_Out;
  wire   [5:0]  FP_Status;
  wire   [63:0] Float_Out,Fl_ALU_Out, R_Out, S_Out, F_mux_out, FS_mux_out;
  
                // Y,          R,     S,          Op,    Status
  FloatALU  falu  (Fl_ALU_Out, R_Out, FS_mux_out, FP_Op, FP_Status);  
  
                // clk,   W_En,  W_Addr,  S_Addr,  R_Addr,  R,     S,     			
  regfile64 freg64(W_Clk, FW_En, FW_Addr, FS_Addr, FR_Addr, R_Out, S_Out,

                // WR
                   F_mux_out);
  
  assign Float_Out = Fl_ALU_Out;
  
      // If F_Sel equals to 1, then F_mux_out gets Float_In. Otherwise, 
      // F_mux_out gets Fl_ALU_Out.	
  assign F_mux_out = F_Sel? Float_In : Fl_ALU_Out;
  assign FS_mux_out = FS_Sel? Float_In: S_Out; 
  
endmodule

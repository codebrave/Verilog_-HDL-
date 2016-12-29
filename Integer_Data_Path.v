`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:02:52 10/26/2013 
// Design Name: 
// Module Name:    Integer_Data_Path 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  The Integer Data Path module is a structural implementation 
//               that interconnects the regfile64 module and the ALU6_64_bit 
//               module together.In addition, it instantiates two of 2-1 
//               multiplexers that allow the data to come from the DS and DY 
//               inputs for memory, input, output, or other applicable 
//               instruction register fields. The ALU will be used to perform 
//               arithmetic and logical operations while the registers are being 
//               accessed in the register file in this Integer Data Path module.      
//                
//////////////////////////////////////////////////////////////////////////////////

module Integer_Data_Path(W_Clk, W_En, S_Sel, Y_Sel, R_Addr, S_Addr, W_Addr, 
                         ALU_Op, DS, DY, C, N, Z, V, REG_OUT, ALU_OUT, B_Sel,
                         samt );
								 
  input         W_Clk, W_En, Y_Sel;
  input  [1:0]  S_Sel;
  input  [3:0]  B_Sel;
  input  [4:0]  W_Addr, R_Addr, S_Addr, ALU_Op;
  input  [4:0]  samt;
  input  [63:0] DS, DY;
  
  output        C, N, Z, V;
  output [63:0] REG_OUT, ALU_OUT;
  wire          C, N, Z, V;
  wire   [63:0] REG_OUT, ALU_OUT, S_Out, Y_Out, R, S_mux_out, barrel_mux_out;
  
             // clk,   W_En, W_Addr, S_Addr, R_Addr, R, S,     WR      
  regfile64 rg0(W_Clk, W_En, W_Addr, S_Addr, R_Addr, R, S_Out, ALU_OUT);
  
          // d2, d1, d0,    S_Sel, S_mux_out  
  S_mux smux(DY, DS, S_Out, S_Sel, S_mux_out);

                  // S_mux_out, samt, B_Sel, barrel_mux_out
  barrel_shifter bsh(S_mux_out, samt, B_Sel, barrel_mux_out); 
  
              // R, S,              Alu_Op, Y,     C, N, Z, V
  ALU_64_bit alu(R, barrel_mux_out, ALU_Op, Y_Out, C, N, Z, V);


 
  assign REG_OUT = R;
  
  // If S_Sel equals to 1, the output of the S_mux will get DS. Otherwise
  // it will get S_Out. 
 // assign S_mux_to_ALU_s = S_Sel? DS: S_Out;
  
  // If Y_Sel equals to 1, the output of the Y_mux will get DY. Otherwise
  // it will get Y_Out.  
  assign ALU_OUT = Y_Sel ? DY: Y_Out; 
endmodule

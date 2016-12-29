`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:36:19 10/26/2013 
// Design Name: 
// Module Name:    Vector_Integer_Data_Path 
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
module Vector_Integer_Data_Path(Vector_in, Vector_sel, W_Clk, V_W_En,
                                V_Y_Sel, V_W_Addr,V_R_Addr, V_S_Addr,
										  V_ALU_Op, V_REG_OUT,
										  V_ALU_OUT);

    	 
  input [255:0] Vector_in;	 
  //output reg [255:0] Vector_out;
  input Vector_sel;
  
  input       W_Clk, V_W_En, V_Y_Sel;
  input [4:0] V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op;
  //input [255:0] DS, DY;
  
  wire C,N,Z,V;
  //wire [15:0] V_int_Status;  //C, N, Z, V;
  output wire [255:0] V_REG_OUT, V_ALU_OUT;
  wire [255:0] S_Out, Y_Out, S_mux_to_ALU_s;//Y_32b_Out;


               // clk,    W_En,   W_Addr, S_Addr, R_Addr,       R,         S,     WR
  regfile256 rg256(W_Clk, V_W_En, V_W_Addr, V_S_Addr, V_R_Addr, V_REG_OUT, S_Out, V_ALU_OUT);
 
               // R,                S,               Alu_Op,   Y,    
  V_ALU_64_bit alu3(V_REG_OUT[255:192], S_Out[255:192],  V_ALU_Op, Y_Out[255:192], 
  
                // C, N, Z, V 
                   C, N, Z, V),
						
                // R,                S,               Alu_Op,   Y,   						
              alu2(V_REG_OUT[191:128], S_Out[191:128],  V_ALU_Op, Y_Out[191:128], 
				 
                // C, N, Z, V 
                   C, N, Z, V),

                // R,                S,               Alu_Op,   Y,   						
              alu1(V_REG_OUT[127:64], S_Out[127:64],    V_ALU_Op, Y_Out[127:64], 
				 
                // C, N, Z, V 
                   C, N, Z, V),
                // R,                S,           Alu_Op,   Y,	
              alu0(V_REG_OUT[63:0], S_Out[63:0],    V_ALU_Op, Y_Out[63:0], 
				 
                // C, N, Z, V 
                   C, N, Z, V);				

				 
  //assign S_mux_to_ALU_s = V_S_Sel ? DS: S_Out;
  assign V_ALU_OUT = V_Y_Sel ? Vector_in: Y_Out;
  
  assign {C,N,Z,V} = 4'b0;

endmodule

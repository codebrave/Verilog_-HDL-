`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:19:41 10/25/2013 
// Design Name: 
// Module Name:    barrel_shift_right_1 
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
module barrel_shift_right_1(D_in, samt, D_out);
    
input [63:0] D_in;
input [4:0] samt;
wire [63:0] b_stage_3, b_stage_2, b_stage_1, b_stage_0;
output wire [63:0] D_out;


assign b_stage_3 = samt[4] ? {16'hffff,      D_in[63:16]}  : D_in;
assign b_stage_2 = samt[3] ? {8'hff,         b_stage_3[63:8]}   : b_stage_3;
assign b_stage_1 = samt[2] ? {4'hf,          b_stage_2[63:4]}   : b_stage_2;
assign b_stage_0 = samt[1] ? {2'b11,         b_stage_1[63:2]}   : b_stage_1;
assign D_out     = samt[0] ? {1'b1,          b_stage_0[63:1]}   : b_stage_0; 

endmodule


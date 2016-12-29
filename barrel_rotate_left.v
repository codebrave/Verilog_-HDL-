`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:47:25 10/25/2013 
// Design Name: 
// Module Name:    barrel_rotate_left 
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
module barrel_rotate_left(D_in, samt, D_out);
    
input [63:0] D_in;
input [4:0] samt;
wire [63:0] b_stage_3, b_stage_2, b_stage_1, b_stage_0;
output wire [63:0] D_out;

assign b_stage_3 = samt[4] ? {D_in[47:0], D_in[63:48]} : D_in;
assign b_stage_2 = samt[3] ? {b_stage_3[55:0], b_stage_3[63:56]} : b_stage_3;
assign b_stage_1 = samt[2] ? {b_stage_2[59:0], b_stage_2[63:60]} : b_stage_2;
assign b_stage_0 = samt[1] ? {b_stage_1[61:0], b_stage_1[63:62]} : b_stage_1;
assign D_out     = samt[0] ? {b_stage_0[62:0], b_stage_0[63]   } : b_stage_0; 

endmodule

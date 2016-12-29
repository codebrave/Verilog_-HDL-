`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:03:39 10/25/2013 
// Design Name: 
// Module Name:    barrel_shifter 
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
module barrel_shifter(S_mux_out, samt, B_Sel, barrel_mux_out);
input [3:0] B_Sel;
input [4:0] samt;
input [63:0] S_mux_out;
output [63:0] barrel_mux_out;
wire  [63:0] shift_left_out, shift_right_out, shift_left_1_out, shift_right_1_out; 
wire [63:0] Barrel_mux_out, arithmetic_shift_left_out, arithmetic_shift_left_1_out;
wire [63:0] arithmetic_shift_right_out, rotate_left_out, rotate_right_out;

                    // D_in,      samt, D_out
  barrel_shift_left bshl(S_mux_out, samt, shift_left_out);

                       // D_in,      samt, D_out
  barrel_shift_left_1 bshl1(S_mux_out, samt, shift_left_1_out);

                     // D_in,      samt, D_out
  barrel_shift_right bshr(S_mux_out, samt, shift_right_out);

                        // D_in,      samt, D_out
  barrel_shift_right_1 bshr1(S_mux_out, samt, shift_right_1_out);

                                // D_in, samt,      D_out
  barrel_arithmetic_shift_left bashl(S_mux_out, samt, arithmetic_shift_left_out);

                                   // D_in,      samt, D_out
  barrel_arithmetic_shift_left_1 bashl1(S_mux_out, samt, arithmetic_shift_left_1_out);

                                 // D_in,      samt, D_out
  barrel_arithmetic_shift_right bashr(S_mux_out, samt, arithmetic_shift_right_out);

                     // D_in,      samt, D_out
  barrel_rotate_left brol(S_mux_out, samt, rotate_left_out);

                      // D_in,      samt, D_out
  barrel_rotate_right bror(S_mux_out, samt, rotate_right_out);

               // d9,                          d8,                d7,
  Barrel_mux bmux(arithmetic_shift_left_1_out, shift_right_1_out, shift_left_1_out,
                   
              // d6,               d5,              d4, 
                 rotate_right_out, rotate_left_out, arithmetic_shift_right_out, 
           
              // d3,                        d2,              d1,     
                 arithmetic_shift_left_out, shift_right_out, shift_left_out, 

              // d0,        select, data_out					
                 S_mux_out, B_Sel,  barrel_mux_out);

endmodule

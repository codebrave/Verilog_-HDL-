`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:06:59 10/26/2013 
// Design Name: 
// Module Name:    FloatALU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This 64-bit ALU will be used in the 440 project to perform various
//
// manipulations on the 64-bit floating point numbers.
// 
// The 6-bit status register will always return the relationship between the R and
// S operands as 6 boolean values, as defined below:
//
// 	Status [5 | 4 | 3 | 2 | 1 | 0] == [GT | GE | LT | LE | EQ | NE]
//
// Note that more than one flag can be set at a time. For example a value of
// 110001 means operand[R] was both GT, GE, and NE to operand[S].
//////////////////////////////////////////////////////////////////////////////////
module FloatALU(Y, R, S, Op, Status);

	output [63:0] Y; reg [63:0] Y; // 64-bit output
	output [5:0] Status; reg [5:0] Status; // 6-bit output
	input [63:0] R, S; // 64-bit inputs
	input [4:0] Op; // 5-bit opcode
	real 	fp_Y, fp_R, fp_S;

	

	always @(R or S or Op)begin

		fp_R = $bitstoreal(R);

		fp_S = $bitstoreal(S);

		case (Op)

			0: fp_Y = fp_R; // pass R

			1: fp_Y = fp_S; // pass S

			2: fp_Y = fp_R + fp_S; // Addition

			3: fp_Y = fp_R - fp_S; // Subtraction R - S

			4: fp_Y = fp_S - fp_R; // Subtraction S - R

			5: fp_Y = fp_R * fp_S; // Multiplication

			6: fp_Y = fp_R / fp_S; // Division R/S

			7: fp_Y = fp_S / fp_R; // Division S/R

			8: fp_Y = 0.0;			  // zeros 

			9: fp_Y = 1.0;			  // 1.0

		  10: fp_Y = fp_R + 1;    // Inc R

		  11: fp_Y = fp_S + 1;	  // Inc S

		  12: fp_Y = fp_R - 1;	  // Dec R

		  13: fp_Y = fp_S - 1;    // Dec S
		  
		  14: fp_Y = R|S;    // OR

		  default: fp_Y = 64'hx;

		endcase

			// Status [5 | 4 | 3 | 2 | 1 | 0] == [GT | GE | LT | LE | EQ | NE]

			Status[5] = fp_R > fp_S;

			Status[4] = fp_R >= fp_S;

			Status[3] = fp_R < fp_S;

			Status[2] = fp_R <= fp_S;

			Status[1] = fp_R == fp_S;

			Status[0] = fp_R != fp_S;
         if(Op >13)
         Y = fp_Y;
			else
			Y = $realtobits(fp_Y);

		end	

endmodule




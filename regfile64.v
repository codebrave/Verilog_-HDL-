`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:55:34 10/25/2013 
// Design Name: 
// Module Name:    regfile64 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  The regfile64 module is a behavioural module that changes the R
//               or the S data outputs whenever the user tries to read 
//               from the reg_file[R_Addr], reg_file[S_Addr], or changes the R or 
//               S addresses. The two always blocks will be used for reading the 
//               R and S outputs and the other always block will be used for 
//               WR input. The R_Addr and the S_Addr are used for reading the 
//               contents from each address while the W_Addr is use for writing to
//               a specific address in the register file. The WR input will write 
//               one of the registers if the W_En input is high active 
//               (logical one) at the rising edge of the clock. This will depend 
//               what the W_Addr is specified to what register number.  
//               
//               
//////////////////////////////////////////////////////////////////////////////////

module regfile64(clk, W_En, W_Addr, S_Addr, R_Addr, R, S, WR);
  input         W_En, clk;
  input  [4:0]  W_Addr, R_Addr, S_Addr;
  input  [63:0] WR;
  output [63:0] R, S;
  wire    [63:0] R, S;
  
  reg [63:0] reg_files [0:31]; // Create an array of 32 registers (64-bits)
  
  // This asynchronous always block will read the output R of the register file.  
 // always @ (R_Addr, reg_files[R_Addr])
  assign  R = reg_files[R_Addr];
	 
  // This asynchronous always block will read the output S of the register file. 	 
//  always @ (S_Addr, reg_files[S_Addr])

 assign  S = reg_files[S_Addr];  
  
  // This synchronous block will always read at the rising edge of the clock
  // and determine if one of the registers will be written. One of the registers
  // get written by the WR input if the W_En input is asserted. 
  always @(posedge clk)
    if (W_En == 1'b1)
	   reg_files[W_Addr] <= WR;

endmodule

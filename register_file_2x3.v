`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:25:18 10/26/2013 
// Design Name: 
// Module Name:    register_file_2x3 
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
module register_file_2x3(clk, reset, d0, d1, d2);
  input       clk, reset;
  output      d0, d1, d2;
  reg   [1:0] data[0:2];
  wire  [1:0] d0, d1, d2;
  
  always @ (posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
	   data[0] <= 2'b0; data[1] <= 2'b01; data[2] <= 2'b10;
	 
	 end

  end

  assign d0 = data[0];
  assign d1 = data[1];
  assign d2 = data[2];

endmodule

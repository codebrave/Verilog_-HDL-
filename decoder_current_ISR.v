`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  16:30:30 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  decoder_current_ISR.v 
// Project Name: Senior Project
// Description:  The decoder_current_ISR module is a behavorial implementation
//               that takes in the D_in input and outputs according to which IO
//               module is currently servicing its interrupt. 
//////////////////////////////////////////////////////////////////////////////////
module decoder_current_ISR(D_in, D_out);
  input  [2:0] D_in;
  output [2:0] D_out;
  reg    [2:0] D_out;
   
  // If the binary equivalent of D_in is decimal 1-3, then that indicates that 
  // the a normal interrupt is currently being serviced. Decimal 4-6 signify 
  // that a fast interrupt is being serviced. If one of the case statements 
  // do not match, then Dout gets by itself. D_out[2] is for IO2 module, 
  // Dout[1] is for IO1 module, and Dout[0] is for enabling IO0 module. 
  always @ (D_in) begin
    case (D_in)
      3'b001: D_out = 3'b100;
      3'b010: D_out = 3'b010;      
      3'b011: D_out = 3'b001;
      3'b100: D_out = 3'b100;
      3'b101: D_out = 3'b010;
      3'b110: D_out = 3'b001;      
      default: D_out = D_out;      
    endcase
  end
  


endmodule

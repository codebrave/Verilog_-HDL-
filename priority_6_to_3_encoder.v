`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  09:39:51 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  priority_6_to_3_encoder.v 
// Project Name: Senior Project
// Description:  The priority_6_to_3_encoder is a behaviorial module that handles 
//               which of the interupt requests have priority. From the most 
//               significant bit to the least signifcant bit of the D_in input, 
//               the interrupt priority goes from a higher priority to a lower 
//               lower priority. Whatever bit is set from the D_in input will 
//               take priority over the interrupt requests.
//////////////////////////////////////////////////////////////////////////////////
module priority_6_to_3_encoder(D_in, D_out);
    
  input [5:0]D_in;
  output reg [2:0] D_out;

  // Whenever D_in changes, D_in will select that input and output to to a 
  // binary format that is equavalent to a decimal such as 3'b001 is decimal 
  // 1 and 3'b110 is decimal 6 since the input of D_in on bit 5 is set. 
  // Basically, the input is converting from 2^n inputs into n decimal outputs 
  // that is equivalent to a binary base number.  
  always @ (D_in) begin
    casex (D_in)
      6'b000001: D_out = 3'b001;
      6'b00001x: D_out = 3'b010;
      6'b0001xx: D_out = 3'b011;
      6'b001xxx: D_out = 3'b100;
      6'b01xxxx: D_out = 3'b101;
      6'b1xxxxx: D_out = 3'b110;   
      default:   D_out = D_out;    
    endcase
  end
   
endmodule

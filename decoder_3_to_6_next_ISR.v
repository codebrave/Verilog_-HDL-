`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  10:44:44 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  decoder_3_to_6_next_ISR.v 
// Project Name: Senior Project
// Description:  The decoder_3_to_6_next_ISR module is a behavorial 
//               implementation that converts each decimal and binary equivalent
//               base values to a 2^n value as each output value is shifting to 
//               to the left. Dout will be a logical 1 value when one of the 
//               ISR_In bits is not set. 
//////////////////////////////////////////////////////////////////////////////////
module decoder_3_to_6_next_ISR(D_in, D_out, ISR_In);

  input  [2:0] D_in;
  input  [5:0] ISR_In;
  output [5:0] D_out;
  reg    [5:0] D_out;
   
  // If one of the ISR_In bits is set, then Dout will get a logical 0 value 
  // until an interrupt has completed its service that corresponds to the ISR_In 
  // bit number. Once one of the ISR_In bits is cleared, then Dout will get the 
  // value that signifies the interrupt request bit number. This will allow an 
  // IO module to interrupt request its own device after the module completes  
  // its interrupt service routine. 
  
  // Whenver Din or ISR_In changes.
  always @ (D_in,ISR_In) begin
  
    case (D_in)
    
      3'b001: D_out = (ISR_In[5]) ? 6'b0: 6'b000001;
      3'b010: D_out = (ISR_In[4]) ? 6'b0: 6'b000010;      
      3'b011: D_out = (ISR_In[3]) ? 6'b0: 6'b000100;
      3'b100: D_out = (ISR_In[2]) ? 6'b0: 6'b001000;
      3'b101: D_out = (ISR_In[1]) ? 6'b0: 6'b010000;
      3'b110: D_out = (ISR_In[0]) ? 6'b0: 6'b100000;   
      default D_out =  6'b0;   
      
    endcase
    
  end // end of always block

endmodule

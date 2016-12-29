`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  09:49:37 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  decoder_3_to_6.v 
// Project Name: Senior Project
// Description:  The decoder_3_to_6 module is a behavorial implementation that 
//               converts each D_in input from a decimal and binary equivalent
//               base to a 2^n value as each output value is shifting to the 
//               left. The ISR_In input is used to check if one of the ISR bits
//               is high active for servicing interrupts. 
//////////////////////////////////////////////////////////////////////////////////
module decoder_3_to_6(D_in, D_out,intr, ISR_In);

  input  [2:0] D_in;
  input  [5:0] ISR_In;
  output [5:0] D_out, intr;
  reg    [5:0] D_out, intr;
   
  // Always go to this asynchronous block if D_in or ISR_in changes. 
  // If one of the ISR_In bits is set, then D_out will get the logical 1 value
  // while intr will get the logical 0 value. Otherwise, intr will get the 
  // logical 1 value whereas D_out will get the logical 0 value. Basically, 
  // one of the ISR_In bits that is set will let D_out save the interrupt bit
  // value that is currently being serviced and let the interrupt controller 
  // interrupt the CPU after the bit ISR_In number is cleared.   
  always @ (D_in, ISR_In) begin
  
    case (D_in)
      3'b001:  {D_out, intr} = (ISR_In[5]) ? {6'b000001,  6'b0} :
                               {6'b0, 6'b000001};                                         
      3'b010:  {D_out, intr} = (ISR_In[4]) ? {6'b000010,  6'b0} :
                               {6'b0, 6'b000010};
      3'b011:  {D_out, intr} = (ISR_In[3]) ? {6'b000100,  6'b0} :
                               {6'b0, 6'b000100};
      3'b100:  {D_out, intr} = (ISR_In[2]) ? {6'b001000,  6'b0} : 
                               {6'b0, 6'b001000};
      3'b101:  {D_out, intr} = (ISR_In[1]) ? {6'b010000,  6'b0} : 
                               {6'b0, 6'b010000};
      3'b110:  {D_out, intr} = (ISR_In[0]) ? {6'b100000,  6'b0} :
                               {6'b0, 6'b100000};
      default: {D_out, intr} = {12'b0};     
      
    endcase
    
  end // end of always block
  
endmodule

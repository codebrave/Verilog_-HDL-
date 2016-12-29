`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  10:12:46 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  Next_ISR_reg.v 
// Project Name: Senior Project
// Description:  The Next_ISR_reg module is a behavorial implementation that 
//               loads in from the Din input. This module basically saves the 
//               ISR bit number and outputs Dout after the matched ISR bit 
//               number is cleared which indicates that the interrupt service
//               routine bit number has completed. The Dout output will activate  
//               the next interrupt request bit number after an IO module has 
//               completed its interrupt service routine.   
//////////////////////////////////////////////////////////////////////////////////
module Next_ISR_reg(clk, reset, ld,clr, Din,Dout);

  input        clk, reset;
  input  [5:0] ld, clr, Din;
  output [5:0] Dout;
  reg    [5:0] Dout;
   
  // Whenever at the active edge signals of clk or rest. 
  always @ (posedge clk, posedge reset) begin
    
    // Reintialize Dout to 0 if reset is high active.
    if (reset)
    Dout <= 6'b0;
    
    // If ld is high active, then Dout gets Din. 
    else if (ld)
    Dout <= Din;

    // If one of the clr bits is set, then one of the
    // Dout bits will be cleared corresponding to the
    // clr value. 
    if (clr) begin
      case (clr)
        6'b000001: Dout[0] <=1'b0;
        6'b000010: Dout[1] <=1'b0;
        6'b000100: Dout[2] <=1'b0;
        6'b001000: Dout[3] <=1'b0;
        6'b010000: Dout[4] <=1'b0;
        6'b100000: Dout[5] <=1'b0;
        default:   Dout    <= Dout;
      endcase      

    end // end of if
    
    // If none of the conditions are true, then
    // Dout gets by itself. 
    else 
      Dout <= Dout;
  
  end // end of synchronous block
  

endmodule

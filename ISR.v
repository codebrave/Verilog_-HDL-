`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  16:02:18 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  ISR.v 
// Project Name: Senior Project
// Description:  The ISR module is a behavorial module that will load from the 
//               Din input if th ld or clr are high active. This register will 
//               indicate which interrupt is being serviced. Dout[2:0] is for the 
//               fast interrupts while Dout[3:5] is for the normal interrupts. 
//               There are 3 normal and fast interrupts which is up to a total of 
//               interrupts that can be serviced, but 3 interrupts can only be 
//               serviced since there are 3 IO modules that can only service one 
//               interrupt request at a time. 
//
//////////////////////////////////////////////////////////////////////////////////
module ISR(clk, reset, ld, clr, Din, Dout);

  input        clk, ld, clr, clr,reset;
  input  [5:0] Din;
  output [5:0] Dout;
  reg    [5:0] Dout;
   
  // Whenever clk, or reset is at their high active edge signals. 
  always @ (posedge clk, posedge reset) begin
    
    // Reinitialize Dout to 0 if reset is high active.
    if (reset)
    
      Dout <= 6'b0;
      
    // If ld is high active, then Dout gets logical OR results
    // with the output and the Din input in order to maintain the the interrupt
    // bits that are being serviced.     
    else if (ld)
    
      Dout <= (Dout|Din);
   
    // If clr is high active, and one of the Dout[2:0] bits is high active, 
    // then the fast interrupt bit that has completed its service routine 
    // will be cleared. Otherwise, the normal interrupt bit that has completed
    // its service routine will be cleared. If cisr.n from the 
    // current_ISR register is not a 0, then Dout will clear whatever 
    // current value has been stored previously inside the current_ISR register.  
    // Otherwise, Dout gets by itself. 
    else if (clr) begin

      
      if (Dout[2:0]) begin


        if (intc.cisr.n!=0)
        Dout <= (Dout ^ {3'b0, intc.cisr.store_current_isr[intc.cisr.n-1]}); 
        
        else 
        Dout <= Dout;
        
      end // end of if
        
      else begin
      
        if(intc.cisr.n!=0)
         
        Dout <= (Dout ^ {intc.cisr.store_current_isr[intc.cisr.n-1], 3'b0}); 
 
        else
        Dout <= Dout;
        
      end // end of else
      
    end // end of else if
      
    // If neither of the conditions are true, then Dout gets by itself. 		
    else 
    Dout <= Dout;
  
  end // end of always block
  

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  16:23:54 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  current_ISR.v 
// Project Name: Senior Project
// Description:  The current_ISR module is a behavorial implementation that 
//               loads in inputs from a decoder. This module will store in 
//               values that correspond to the IO module that is currently 
//               servicing its own interrupt. The Dout output will enable one of 
//               the 3 IO modules to access their memory locations. 
//               
//////////////////////////////////////////////////////////////////////////////////
module current_ISR(clk, reset, ld, Din,Dout);

  input        clk, reset, ld;
  input  [2:0] Din;
  output [2:0] Dout;
  reg    [2:0] Dout;
  reg    [2:0] store_current_isr[0:7];
  reg    [3:0] n;
   
  
  // Whenever clk, or reset is at their high active edge signals. 
  always @ (posedge clk, posedge reset) begin
    
    // If reset is high active, then Dout  and n will be reinitialized
    // to 0. 
    if (reset) begin
    
      Dout <= 3'b0;
      n <=0;
      
    end // end of if
    
    // If ld is high active, then Dout gets Din and the Din value 
    // will be stored in the store_current_isr memory in order to 
    // keep in track which IO module is being serviced. 
    else if (ld) begin
      Dout <= Din;
      store_current_isr[n] <= Din;
      
      // If n is not equal to 6, then n increments, otherwise 
      // n gets by itself. 
      if (n!=6)
      n <= n + 1;
      else 
      n <= n;
    end // end of else if
    
    // If clr is high active coming from the ISR register and n is a nonzero, 
    // then Dout will get the value that was previously stored in the
    // store_current_isr memory. Otherwise, Dout gets by itself. 
    else if (intc.isr.clr) begin
      if (n!=0)
      Dout <= store_current_isr[n-1]; 
      else 
      Dout <= Dout; 
      
      // If n is a nonzero, then n will decrement. Otherwise n gets by 
      // itself. 
      if (n!=0)
      n <= n - 1;
      else 
      n <= n;
      
    end // end of else if
    
    else 
      Dout <= Dout;
  
  end // end of always synchronous block
  

endmodule
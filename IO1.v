`timescale 1ps / 100fs
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  23:02:09 10/26/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  IO1.v 
// Project Name: Senior_Project
//////////////////////////////////////////////////////////////////////////////////
module IO1(Addr, Data, CS_, RD_, WR_, Clk, fintr_check, intr_check, 
           Enable, int_ack );
   
   
//*******************************************************************************
// Description: 
// 
// A 1024 x 32 IO0 with bi-directional data lines.
//
// Reading is done asynchronously, without regard to Clk,
// and is modeled with a conditional continuous assignment
// to implement the bi-directional outputs with (HI_Z).
//
// Writing is done is done synchronously, only on the positive edge
// of Clk (iff CS_ and WR_ are asserted) and is modeled
// using a procedural block. The Enable input is used for activating the IO1 
// module while the fast and normal interrupts are being serviced in their
// interrupt service routines. 
//
// NOTE: CS_, RD_, and WR_ are all active low.
// 
/////////////////////////////////////////////////////////////////////

   input[9:0] Addr;

   input int_ack;
   input CS_, RD_, WR_, Clk, Enable;
   inout [31:0] Data;
   
   reg fintr, intr;
   output reg fintr_check, intr_check;
   reg [31:0] memarray[0:1023];

   wire[31:0] Data;

   initial begin
	
/********************************************************************************

         TESTING FOR ENHANCED MULTIPLE INTERRUPTS ONLY 

/********************************************************************************/

    // Initialize both the normal and fast interrupt requests to 0. 
    fintr_check = 1'b0;      
    intr_check  = 1'b0;        

    @(posedge int_ack)      // wait for the IO0 module to be acknowledged.
  
    @(posedge int_ack)      // wait for the IO0 module to be acknowledged.

    @(posedge int_ack)      // wait for the IO0 module to be acknowledged.
	 
    @(posedge int_ack)      // wait for the IO0 module to be acknowledged.
	 
      fintr_check = 1'b1;   // activate the fast interrupt request on IO1.   
  
    @(posedge int_ack)      // wait for IO1 module to be acknowledged. 
      fintr_check = 1'b0;   // clear the fast interrupt request on IO1.   
      fintr_check  = 1'b1;   // activate the fast interrupt request on IO1.
		
    @(posedge int_ack)      // wait for IO1 module to be acknowledged. 
      fintr_check = 1'b0;   // clear the fast interrupt request on IO1.   
      intr_check  = 1'b1;   // activate the normal interrupt request on IO1.
       
    @(posedge int_ack)      // wait for IO1 module to be acknowledged. 
      intr_check  = 1'b0;   // clear the normal interrupt request on IO1.
      intr_check  = 1'b1;   // activate the normal interrupt request on IO1.
		
    @(posedge int_ack)      // wait for IO1 module to be acknowledged. 
      intr_check = 1'b0;   // clear the fast interrupt request on IO1.        
 
   end
   
   //***************************************************
   // Conditional continuous assignment to implement
   
   // if the Enable input is active high while
   
   // (both CS_ and RD_) are asserted,
   
   // then Data = memarray[Addr]
   
   // else Data = HI-Z
   //****************************************************

   assign Data = (Enable)?((!CS_ & !RD_) ? memarray[Addr] : 32'bz): 32'bz;



   //****************************************************

   // Procedural assignment to implement

   // if the Enable input is active high 
   
   // while(both CS_ and WR_ are asserted) on posedge Clk

   // then memarray[Addr] = Data

   //****************************************************

   always @(posedge Clk)

      if (Enable) begin
        if(!CS_ & !WR_)

           memarray[Addr] = Data;
      end

endmodule

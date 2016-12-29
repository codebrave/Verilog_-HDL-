`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:27:31 10/17/2013 
// Design Name: 
// Module Name:    mem 
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
module mem(Addr, Data, CS_, RD_, WR_, Clk );

// Description: 

// 

// A 1024 x 32 memory with bi-directional data lines.

//

// Reading is done asynchronously, without regard to Clk,

// and is modeled with a conditional continuous assignment

// to implement the bi-directional outputs with (HI_Z).

//

// Writing is done is done synchronously, only on the positive edge

// of Clk (iff CS_ and WR_ are asserted) and is modeled

// using a procedural block.

//

// NOTE: CS_, RD_, and WR_ are all active low.

// 

// The memory is to be initialized from within the testbench

// that instantiates it, using the $readmem function.



// NOTE: When instantiating this module, only use the least

// 10-significant address lines, e.g. addr[9:0] 

/////////////////////////////////////////////////////////////////////

   input[9:0] Addr;

   input CS_, RD_, WR_, Clk;

   inout [31:0] Data;



   reg [31:0] memarray[0:1023];

   wire[31:0] Data;



   //***************************************************

   // Conditional continuous assignment to implement

   // if(both CS_ and RD_) are asserted

   //    then Data = memarray[Addr]

   // else Data = HI-Z

   //****************************************************

   assign Data = (!CS_ & !RD_) ? memarray[Addr]  : 32'bz;



   //****************************************************

   // Procedural assignment to implement

   // if(both CS_ and WR_ are asserted) on posedge Clk

   //    then memarray[Addr] = Data

   //****************************************************

   always @(posedge Clk)

      if(!CS_ & !WR_)

         memarray[Addr] = Data;

endmodule



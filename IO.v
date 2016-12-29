`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:02:09 10/26/2013 
// Design Name: 
// Module Name:    IO 
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
module IO(Addr, Data, CS_, RD_, WR_, Clk, intr_num, fintr_check, intr_check, 
          Enable, int_ack );

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

   input int_ack;
   input CS_, RD_, WR_, Clk, Enable;
   input [1:0] intr_num;
   inout [31:0] Data;
   
   reg fintr, intr;
   output reg fintr_check, intr_check;
   reg [31:0] memarray[0:1023];

   wire[31:0] Data;

/*   always @(posedge cpu.int_ack) begin
	  if (cpu.int_ack&&cpu.intr==1'b0)
	  case ({fintr_check,intr_check})
	  
       2'b01:   {fintr_check, intr_check} = 2'b0;
       2'b10:   {fintr_check, intr_check} = 2'b0;
       2'b00:   {fintr_check, intr_check} = 2'b0;
	    default: {fintr_check, intr_check} = 2'b0;
	  endcase
	end*/
	
	initial begin
	  
     intr_check= 1'b1;	   
     fintr_check=1'b0;
	    @(posedge int_ack)
	  	  intr_check = 1'b0;
	       
	    fintr_check= 1'b1;	
	    @(posedge int_ack)
	  	  fintr_check = 1'b0;	

		  intr_check = 1'b1;	  
	    @(posedge int_ack)
	  	  intr_check = 1'b0;	
		  
	    fintr_check= 1'b1;	
	    @(posedge int_ack)
	  	  fintr_check = 1'b0;	

	    intr_check= 1'b1;	
	    @(posedge int_ack)
	  	  intr_check = 1'b0;	

		  fintr_check = 1'b1;	  
	    @(posedge int_ack)
	  	  fintr_check = 1'b0;	
		  
		  
	 
	end
	
  /* always @ (posedge cpu.F[intr_num]) begin

     fintr_check = 1'b1;
	

   end
	
   always @ (posedge cpu.I[intr_num]) begin
	
     intr_check=1'b1;
	  
	end */



   //***************************************************

   // Conditional continuous assignment to implement

   // if(both CS_ and RD_) are asserted

   //    then Data = memarray[Addr]

   // else Data = HI-Z

   //****************************************************

   assign Data = (Enable)?((!CS_ & !RD_) ? memarray[Addr] : 32'bz): 32'bz;



   //****************************************************

   // Procedural assignment to implement

   // if(both CS_ and WR_ are asserted) on posedge Clk

   //    then memarray[Addr] = Data

   //****************************************************

   always @(posedge Clk)

      if (Enable) begin
        if(!CS_ & !WR_)

           memarray[Addr] = Data;
		end

endmodule

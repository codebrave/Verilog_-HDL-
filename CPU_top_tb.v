`timescale 1ps / 100fs
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:41:59 10/26/2013 
// Design Name: 
// Module Name:    CPU_top_tb 
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
module CPU_top_tb();
   // Inputs
  reg         sys_clk, reset;
  wire        Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr, IO_cs, int_ack; 
  wire        current_ISR_num_ld, ISR_ld, ISR_clr;
  wire  [1:0] FIQ_W_En, fb_inc, fb_dec;
  wire  [2:0] fintr_check, intr_check, IO_Enable, cs_out, rd_out, wr_out;
  wire  [4:0] FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr;
  wire  [5:0] intr;
  wire [31:0] Data, Addr, FIQ_R, FIQ_S, Link_fiq_out, SPSR_fiq_out;


               
        // sys_clk, reset, intr, Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr, IO_cs,           
  CPU cpu (sys_clk, reset, intr, Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr, IO_cs, 
  
        // int_ack, Data, Addr, FIQ_S, FIQ_R, Link_fiq_out, SPSR_fiq_out, 
           int_ack, Data, Addr, FIQ_S, FIQ_R, Link_fiq_out, SPSR_fiq_out, 

        // FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, 
           FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, 

        // ISR_ld, ISR_clr,IO_rd, IO_wr, IO_cs, fb_inc, fb_dec           
           ISR_ld, ISR_clr,IO_rd, IO_wr, IO_cs, fb_inc, fb_dec);    

        // Addr,      Data, CS_,    RD_,    WR_,    Clk      
   mem mry(Addr[9:0], Data, Mem_cs, Mem_rd, Mem_wr, sys_clk);
   
        // Addr,      Data, CS_,   RD_,   WR_,    Clk,   
   IO0 io0(Addr[9:0], Data, IO_cs, IO_rd, IO_wr,   sys_clk,      

      // fintr_check,    intr_check,    Enable,       int_ack    
         fintr_check[0], intr_check[0], IO_Enable[0], int_ack);

       //  Addr,      Data, CS_,   RD_,   WR_,   Clk,   
   IO1 io1(Addr[9:0], Data, IO_cs, IO_rd, IO_wr,  sys_clk, 

        //  fintr_check,    intr_check,   Enable,       int_ack
           fintr_check[1], intr_check[1], IO_Enable[1], int_ack);

       //  Addr,      Data, CS_,   RD_,   WR_,       Clk,   
   IO2 io2(Addr[9:0], Data, IO_cs, IO_rd, IO_wr,  sys_clk,  

        // fintr_check,    intr_check,    Enable,       int_ack
           fintr_check[2], intr_check[2], IO_Enable[2], int_ack);

                          // clk, reset,fintr_check, intr_check, ISR_ld,
   Interrupt_Controller intc(sys_clk, reset,fintr_check, intr_check, ISR_ld,

                          // ISR_clr, intr_Out, IO_Enable, current_ISR_num_ld                       
                             ISR_clr, intr,     IO_Enable, current_ISR_num_ld);

                          // clk, FIQ_W_En, FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr
   FIQ_Bank_of_Registers fbk(sys_clk, FIQ_W_En, FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, 

                        //  Link_fiq_In,  SPSR_fiq_In,  FIQ_R, FIQ_S, fb_inc, fb_dec
                            Link_fiq_out, SPSR_fiq_out, FIQ_R, FIQ_S, fb_inc, fb_dec);
                             
   always  // Create a 10 ps period.

      #5 sys_clk= ~sys_clk; 
      
   initial begin
   //   $readmemh("mem01_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem02_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem03_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem04_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem05_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem06_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem07_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem08_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem09_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem10_64_Fa13.dat", mry.memarray);
   //   $readmemh("mem11_64_Fa13.dat", mry.memarray);
   //   $readmemh("TestIDPLogicalEnhancements.dat", mry.memarray);
   //   $readmemh("TestFDPEnhancements.dat", mry.memarray);
   //   $readmemh("BarrelShifter.dat", mry.memarray);
   //   $readmemh("BarrelShiftInstructions.dat", mry.memarray);
   //   $readmemh("TestVectorEnhancements.dat", mry.memarray);
   //   $readmemh("TestVectorEnhancements2.dat", mry.memarray);
   //   $readmemh("mem14_64_Fa13_Verify_Interrupts_and_IO.dat", mry.memarray);
   //   $readmemh("test_multiple_interrupts.dat", mry.memarray);
   //   $readmemh("Link_Register.dat", mry.memarray);
      $readmemh("FP_Jumps.dat", mry.memarray);
   //   $readmemh("mem13_64_Fa13.dat", mry.memarray);
   //   $readmemh("divide_integer_zero.dat", mry.memarray);
      $timeformat(-12, 1, " ps", 9);    //Display time in picoseconds
      
      #1 $display("");   
         $display("***************************************");   
         $display("CECS 440 Senior Project Results        ");   
         $display("***************************************");
         $display("");   
         $display("***************************************");   
         $display("Interrupting                           ");   
         $display("***************************************");
         $display("");   
         
      sys_clk = 0;
      reset = 0;

      @(negedge sys_clk)      
         reset = 1'b1;      
   
      
      @(negedge sys_clk)
         reset = 1'b0;

   end

endmodule

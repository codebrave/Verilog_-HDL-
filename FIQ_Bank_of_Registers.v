`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  14:59:09 10/27/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  FIQ_Bank_of_Registers.v 
// Project Name: Senior Project
// Description:  The FIQ_Bank_of_Registers module is a behavorial implementation
//               that stores in Link_fiq register values and SPSR_fiq register
//               values that will save the status flags and the IP return 
//               address only if there are 2 or more fast interrupt requests 
//               being serviced. If a Call Link Register instruction is being 
//               executed by the CPU while a fast interrupt is being serviced,  
//               then the IP return address will be stored in the Data memory 
//               that has an array of 32 register with 32 bits. The FIQ_R
//               output is used to access the IP return address while the FIQ_S 
//               output is used for accessing the saved status of the flags.  
//               The n register is used for pointing to register locations.   
//////////////////////////////////////////////////////////////////////////////////
module FIQ_Bank_of_Registers(clk, FIQ_W_En, FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, 
                             Link_fiq_In, SPSR_fiq_In, FIQ_R, FIQ_S, fb_inc, 
                             fb_dec);
   
  input         clk;
  input   [1:0] FIQ_W_En, fb_inc, fb_dec;
  input   [4:0] FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr;
  input  [31:0] Link_fiq_In, SPSR_fiq_In;
  output [31:0] FIQ_R, FIQ_S; 
  wire   [31:0] FIQ_R, FIQ_S;
  reg     [4:0] n = 0;       // Initialize n to 0. 
  reg    [31:0] Data[0:31];
  
  assign FIQ_R = Data[FIQ_R_Addr];
  
  assign FIQ_S = Data[FIQ_S_Addr];
  
  always @ (posedge clk) begin

    // If FIQ_W_En[1] is high active, then the Link_fiq register value will be
    // stored in. Otherwise, Data[n] will get by itself. 
    if (FIQ_W_En[1]==1'b1) 
      Data[FIQ_W_Addr] <= Link_fiq_In;
    
    else 
      Data[FIQ_W_Addr] <= Data[FIQ_W_Addr];

    // if FIQ_W_En[0] is high active, then the SPSR_fiq register value will be 
    // stored into the Data register file. Otherwise, Data[n] gets by itself. 
    if (FIQ_W_En[0] == 1'b1) 
      Data[FIQ_W_Addr+1] <= SPSR_fiq_In;   

    else 
      Data[FIQ_W_Addr+1] <= Data[FIQ_W_Addr+1];
      
    // These combination inputs of fb_inc and fb_dec will decrement
    // n by 1 or 2 depending on what kind of link register is being 
    // executed. If a Call Link Register instruction is executed, then n will 
    // increment by 1 while the fast interrupt that is being requested will
    // incement n by 2. If a Return Link register is executed then n will
    // decrement by 1 whereas a Return From Interrupt with Link Register will
    // decrement n by 2.     
    case ({fb_inc,fb_dec})
    
      4'b0001: n <= n - 1;
      4'b0010: n <= n - 2;    
      4'b0100: n <= n + 1;
      4'b1000: n <= n + 2;
      default: n <= n;
      
    endcase;
          
  end // end of always synchronous block
  
endmodule

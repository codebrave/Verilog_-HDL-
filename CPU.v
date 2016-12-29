`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  21:05:11 10/26/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  CPU.v 
// Project Name: Senior Project
// Description:  The CPU (Central Processing Unit) is a structural implementation
//               that interconnects the cu_64 and th CPU_EU modules. This module
//               connects all of the control words and signals coming from the 
//               cu_64 (control unit) module to the CPU_EU (Central Processing 
//               Unit Execution Unit) that will execute the instructions that are 
//               fetched, decoded and executed. The CPU wll read the contents of 
//               the memory and execute the instructions that are decoded from the
//               IR (Instruction Register). 
//
//////////////////////////////////////////////////////////////////////////////////
module CPU(sys_clk, reset, intr, Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr, IO_cs, 
           int_ack, Data, Addr, FIQ_S,FIQ_R,       Link_fiq_out, SPSR_fiq_out, 
           FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, 
           ISR_ld, ISR_clr,IO_rd, IO_wr, IO_cs, fb_inc, fb_dec);
    
  input          sys_clk, reset; 
  input  [5:0]  intr;
  input  [31:0] FIQ_S, FIQ_R;
  inout  [31:0] Data;
  output        Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr, IO_cs, int_ack;
  output        current_ISR_num_ld, ISR_ld, ISR_clr;
  output  [1:0] FIQ_W_En, fb_inc, fb_dec;
  output  [4:0] FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr;
  output [31:0] Addr, Link_fiq_out, SPSR_fiq_out;
  wire          W_En, FW_En, IR_ld, IP_ld, IP_inc, SP_inc, SP_dec, C, N, Z, V;
  wire          F_Sel, Y_Sel, IR_SignExt_sel, Link_ld;   
  wire          Link_fiq_sel, Link_fiq_ld, Mem_rd, Mem_wr, Mem_cs, IO_rd, IO_wr;  
  wire          IO_cs, int_ack, SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld, MAR_ld;
  wire          MAR_inc,current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel;
  wire    [1:0] RdBuf_ld, WrBuf_ld, WrBuf_sel, WrBuf_oe;
  wire    [1:0] S_Sel, FPBuf_ld, FPBuf_oe, FIQ_W_En;
  wire    [2:0] F, I, CPSR_sel, IP_sel, Reg_In_sel, CPSR_ld;
  wire    [3:0] MAR_sel, B_Sel;
  wire    [4:0] FW_Addr, FS_Addr, FR_Addr, W_Addr, R_Addr, S_Addr, ALU_Op;   
  wire    [4:0] FP_Op, V_ALU_Op, V_W_Addr, V_R_Addr, V_S_Addr;// 
  wire    [4:0] samt, FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr;
  wire    [5:0] FP_Status; 
  wire    [7:0] V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld;
  wire   [31:0] Addr, Data, change_flags, CPSR_out, Link_fiq_out, SPSR_fiq_out; 

           // sys_clk, reset, intr, C, N, Z, V, int_ack, R_Addr, 
   cu_64  cu (sys_clk, reset, intr, C, N, Z, V, int_ack, R_Addr, 
   
           // S_Addr, W_Addr,W_En, ALU_Op, S_Sel, Y_Sel, IR_ld, MAR_ld, MAR_inc,    
              S_Addr, W_Addr,W_En, ALU_Op, S_Sel, Y_Sel, IR_ld, MAR_ld, MAR_inc, 
              
           // MAR_sel, RdBuf_ld, RdBuf1_sel, RdBuf0_sel, WrBuf_ld, WrBuf_oe,               
              MAR_sel, RdBuf_ld, RdBuf1_sel, RdBuf0_sel, WrBuf_ld, WrBuf_oe, 
              
           // WrBuf_sel, Mem_rd, Mem_wr, Mem_cs,FW_En, FW_Addr,  FS_Addr,                     
              WrBuf_sel, Mem_rd, Mem_wr, Mem_cs,FW_En, FW_Addr,  FS_Addr,    
              
           // FR_Addr, FP_Op, FP_Status, F_Sel, FPBuf_ld, FPBuf_oe, SP_ld, 
              FR_Addr, FP_Op, FP_Status, F_Sel, FPBuf_ld, FPBuf_oe, SP_ld, 
              
           // SP_inc, SP_dec, IP_ld, IP_inc, IP_sel  B_Sel, samt, V_Y_Sel,           
              SP_inc, SP_dec, IP_ld, IP_inc, IP_sel, B_Sel, samt, V_Y_Sel, 

           // V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op, V_WrBuf_ld,
              V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op, V_WrBuf_ld, 

           // V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, Link_ld, Link_fiq_ld,
              V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, Link_ld, Link_fiq_ld,

           // Link_fiq_sel, SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld, CPSR_sel,              
              Link_fiq_sel, SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld, CPSR_sel,

           // CPSR_ld, F, I, change_flags, FIQ_W_Addr, FIQ_R_Addr,               
              CPSR_ld, F, I, change_flags, FIQ_W_Addr, FIQ_R_Addr,

           // FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, ISR_ld, ISR_clr, IO_rd,              
              FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, ISR_ld, ISR_clr, IO_rd,        

           // IO_wr, IO_cs, IR_SignExt_sel, CPSR_in,  FS_Sel, fb_inc, fb_dec              
              IO_wr, IO_cs, IR_SignExt_sel, CPSR_out, FS_Sel, fb_inc, fb_dec);
              
          // W_Clk,   reset, IW_En, FW_En, FW_Addr,  FS_Addr, FR_Addr, W_Addr, 
   CPU_EU EU(sys_clk, reset, W_En,  FW_En, FW_Addr,  FS_Addr, FR_Addr, W_Addr,  
   
          // R_Addr, S_Addr, FP_Op, FP_Status, S_Sel, F_Sel, Y_Sel, ALU_Op, C,
             R_Addr, S_Addr, FP_Op, FP_Status, S_Sel, F_Sel, Y_Sel, ALU_Op, C,

         //  N, Z, V, FPBuf_ld, FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel,
             N, Z, V, FPBuf_ld, FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel,
             
         //  WrBuf_ld, WrBuf_oe, WrBuf_sel, MAR_ld, MAR_inc, MAR_sel, IR_ld,
             WrBuf_ld, WrBuf_oe, WrBuf_sel, MAR_ld, MAR_inc, MAR_sel, IR_ld,

         //  Addr, Data, SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, IP_sel, B_Sel,
             Addr, Data, SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, IP_sel, B_Sel, 

          // samt, V_Y_Sel, V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op,
             samt, V_Y_Sel, V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op,
             
          // V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, FIQ_R, FIQ_S,
             V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, FIQ_R, FIQ_S, 
             
          // Link_ld, Link_fiq_ld, Link_fiq_sel, Link_fiq_out, SPSR_fiq_sel,              
             Link_ld, Link_fiq_ld, Link_fiq_sel, Link_fiq_out, SPSR_fiq_sel, 

          // SPSR_ld, SPSR_fiq_ld, SPSR_fiq_out, CPSR_sel, CPSR_ld, F,I,              
             SPSR_ld, SPSR_fiq_ld, SPSR_fiq_out, CPSR_sel, CPSR_ld, F,I,   
             
          // change_flags, IR_SignExt_sel, CPSR_out, FS_Sel
             change_flags, IR_SignExt_sel, CPSR_out, FS_Sel);           
endmodule

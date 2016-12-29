`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  08:08:39 10/16/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  CPU_EU.v 
// Project Name: Senior Project
// Description:  The CPU_EU module is a structural implementation that
//               interconnects the FloatDP, Integer_Data_Path, BIU, CPSR_mux,
//               CPSR, reg_with_ld, and Vector_Integer_Data_Path modules. 
//               This module manipulates values stored in 32-bit registers 
//               and the control signals inside the BIU (Bus Interface Unit) 
//               module. The integer, floating point, or vector operations will 
//               be performed based on the control signals from the Integer, 
//               Floating Point, or Vector Datapaths. The CPSR (Current Program 
//               Status Register) will be used for handling the current state of 
//               the status flags. The SPSR (Saved Program Status Register) will  
//               be used for saving the current state of the flags when the CPU     
//               gets interrupted. The SPSR_fiq is used for saving the current
//               state of the flags while being interrupted by a fast interrupt
//               request.             
//
//////////////////////////////////////////////////////////////////////////////////

module CPU_EU(W_Clk, reset, IW_En, FW_En, FW_Addr,  FS_Addr, FR_Addr, W_Addr,  
              R_Addr, S_Addr, FP_Op, FP_Status, S_Sel, F_Sel, Y_Sel, ALU_Op, C,
              N, Z, V, FPBuf_ld, FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel,
              WrBuf_ld, WrBuf_oe, WrBuf_sel, MAR_ld, MAR_inc, MAR_sel, IR_ld,
              Addr, Data, SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, IP_sel, B_Sel, 
              samt, V_Y_Sel, V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op, 
              V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, FIQ_R, FIQ_S,  
              Link_ld, Link_fiq_ld, Link_fiq_sel, Link_fiq_out, SPSR_fiq_sel,   
              SPSR_ld, SPSR_fiq_ld, SPSR_fiq_out, CPSR_sel, CPSR_ld, F,I, 
              change_flags, IR_SignExt_sel, CPSR_out, FS_Sel);      
              
  input          W_Clk, reset, IW_En, FW_En, IR_ld, F_Sel, Y_Sel,V_W_En; 
  input          MAR_ld, MAR_inc, SP_ld, SP_inc, SP_dec, RdBuf1_sel, RdBuf0_sel;
  input          IP_ld, IP_inc,  V_Y_Sel, Link_ld, Link_fiq_ld, IR_SignExt_sel;
  input          SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld, Link_fiq_sel;
  input          FS_Sel;
  input    [1:0] FPBuf_ld, FPBuf_oe, RdBuf_ld,WrBuf_sel, WrBuf_ld, WrBuf_oe; 
  input    [1:0] S_Sel; 
  input    [2:0] IP_sel, Reg_In_sel, CPSR_sel, F,I,CPSR_ld;
  input    [3:0] MAR_sel,  B_Sel;
  input    [4:0] FW_Addr, FR_Addr, FS_Addr, W_Addr, R_Addr, S_Addr, ALU_Op; 
  input    [4:0] samt, FP_Op, V_ALU_Op, V_W_Addr, V_R_Addr, V_S_Addr;
  input    [7:0] V_RdBuf_ld, V_WrBuf_ld, V_WrBuf_oe;
  input   [31:0] FIQ_R, FIQ_S, change_flags;
  
  inout   [31:0] Data;

  output         C, N, Z, V;
  output   [5:0] FP_Status;  
  output  [31:0] Addr, Link_fiq_out, SPSR_fiq_out, CPSR_out;


  wire           C, N, Z, V;
  wire     [5:0] FP_Status;
  wire    [31:0] CPSR_mux_out, SPSR_out, SPSR_fiq_out, SPSR_fiq_mux_out, Addr, Data;   
  wire    [31:0] CPSR_out, Flags_In, Link_fiq_out;
  wire    [63:0] IR_SignExt, RdBuf_64, FP_Out, ALU_Out, Reg_Out;
  wire   [255:0] V_ALU_Out, V_Reg_Out, Vector_RdBuf_Out;
     
                     // FP_Op, W_Clk, FW_En, FW_Addr,FR_Addr, FS_Addr, Float_In,       
  FloatDP           fdp(FP_Op, W_Clk, FW_En, FW_Addr,FR_Addr, FS_Addr, RdBuf_64,
        
                     // F_Sel, FP_Status, Float_Out, FS_Sel
                        F_Sel,FP_Status,  FP_Out,    FS_Sel); 
           
                     // W_Clk, W_En,  S_Sel, Y_Sel, R_Addr, S_Addr, W_Addr, 
  Integer_Data_Path idp(W_Clk, IW_En, S_Sel, Y_Sel, R_Addr, S_Addr, W_Addr, 

                     // ALU_Op, DS,         DY,       C, N, Z, V, REG_OUT, 
                        ALU_Op, IR_SignExt, RdBuf_64, C, N, Z, V, Reg_Out, 

                     // ALU_OUT, B_Sel, samt
                        ALU_Out, B_Sel, samt);    
               
                            //  Vector_in,        Vector_sel, W_Clk, V_W_En,                           
  Vector_Integer_Data_Path vidp(Vector_RdBuf_Out, V_Y_Sel, W_Clk, V_W_En,
 
                             // V_Y_Sel, V_W_Addr,V_R_Addr, V_S_Addr,
                                V_Y_Sel, V_W_Addr,V_R_Addr, V_S_Addr,
                               
                           //   V_ALU_Op, V_REG_OUT, V_ALU_OUT                               
                                V_ALU_Op, V_Reg_Out, V_ALU_Out);
   
                     // clk,   reset, FP_In,  Reg_In,  ALU_In,  Addr, Data, IR_ld,                            
  BIU               biu(W_Clk, reset, FP_Out, Reg_Out, ALU_Out, Addr, Data, IR_ld,
   
                     // FPBuf_ld, FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel,  
                        FPBuf_ld, FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel, 
             
                     // MAR_inc, MAR_ld, MAR_sel, WrBuf_ld, WrBuf_oe, WrBuf_sel,     
                        MAR_inc, MAR_ld, MAR_sel, WrBuf_ld, WrBuf_oe, WrBuf_sel,   

                     // RdBuf_Out, IR_SignExt, SP_ld, SP_inc, SP_dec, IP_ld, IP_inc,                                   
                        RdBuf_64,  IR_SignExt, SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, 

                     // IP_sel, CPSR_In, V_Reg_In,  Reg_In_sel, V_WrBuf_ld,                            
                        IP_sel, CPSR_out, V_Reg_Out, Reg_In_sel, V_WrBuf_ld,
                        
                     // V_WrBuf_oe, V_RdBuf_ld, Vector_In, Vector_RdBuf_Out, Link_ld,
                        V_WrBuf_oe, V_RdBuf_ld, V_ALU_Out, Vector_RdBuf_Out, Link_ld, 
                        
                     // Link_fiq_ld, Link_fiq_sel, Link_fiq_out, FIQ_R, IR_SignExt_sel   
                        Link_fiq_ld, Link_fiq_sel, Link_fiq_out, FIQ_R, IR_SignExt_sel);
                        
                // d4,           d3,           d2,       d1,             d0,       
  CPSR_mux  cpsrmx(change_flags, SPSR_fiq_out, SPSR_out, RdBuf_64[31:0], Flags_In, 

                // CPSR_sel, CPSR_mux_out
                   CPSR_sel, CPSR_mux_out);      
  
                // clk, reset, ld,      Din,            Dout 
  CPSR        cpsr(W_Clk, reset, CPSR_ld, CPSR_mux_out, CPSR_out );

                // clk, reset,   ld,      Din,      Dout 
  reg_with_ld SPSR(W_Clk, reset, SPSR_ld, CPSR_out, SPSR_out),

                // clk,   reset, ld,          Din,              Dout 
         SPSR_fiq (W_Clk, reset, SPSR_fiq_ld, SPSR_fiq_mux_out, SPSR_fiq_out);  
  
         // If SPSR_fiq_sel is a 1, SPRS_fiq_mux_out gets FIQ_S. Otherwise, 
         // the SPSR_fiq_mux_out gets CPSR_out.         
  assign SPSR_fiq_mux_out = SPSR_fiq_sel ? FIQ_S : CPSR_out; 
  
         // The Flags_In wire is used for connecting all of the flags from 
         // the control unit, integer and floating point datapaths. When 
         // operations are being performed in the datapaths, the flags will
         // be updated and be loaded to the CPSR. 
  assign Flags_In={{16{F[2]}}, {F,I,N,C,Z,V },FP_Status};
  
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  00:08:17 10/26/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  BIU.v 
// Project Name: Senior Project
// Description:  The BIU (Bus Interface Unit) module manages the data and the 
//               addresses that go from and to the Integer and Floating Point 
//               Datapaths, memory, and I/O (Input/Output) modules. The I/O Data
//               is being placed in a buffer so that it can be stored in each 
//               registers one word (32-bits) at a time. The oe (output enable)
//               signals allow one of the WrBuf, V_WrBuf, or FPBuf registers to 
//               output their data while others are in high impedance mode. 
//               The Addr (Address) output and the bidirectional Data go to the 
//               memory and I/O modules. The SP (Stack Pointer) register will be 
//               used for pointing to memory locations while Data is being 
//               stored into the memory. The IP (Instruction Pointer) register 
//               is used for pointing to the contents of each memory locations 
//               that has binary data containing instructions for implementing
//               operations. The Link registers are used for storing the IP's 
//               return address and loading the contents back to the IP. The IP
//               will also read memory from the RdBuf register in order to fetch,
//               decode, and execute instructions. The IR register contains the 
//               the instructions that will implement operations.   
//               
//////////////////////////////////////////////////////////////////////////////////

module BIU(clk, reset, FP_In, Reg_In, ALU_In, Addr, Data, IR_ld, FPBuf_ld,  
           FPBuf_oe, RdBuf_ld, RdBuf1_sel, RdBuf0_sel, MAR_inc, MAR_ld, MAR_sel,
           WrBuf_ld, WrBuf_oe, WrBuf_sel, RdBuf_Out, IR_SignExt, SP_ld, SP_inc,
           SP_dec, IP_ld, IP_inc, IP_sel, CPSR_In, V_Reg_In, Reg_In_sel, 
           V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld, Vector_In, Vector_RdBuf_Out, Link_ld,
           Link_fiq_ld, Link_fiq_sel, Link_fiq_out, FIQ_R, IR_SignExt_sel);

  input          clk, reset, IR_ld, MAR_ld, MAR_inc,  RdBuf1_sel, RdBuf0_sel; 
  input          SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, Link_ld, Link_fiq_ld;
  input          Link_fiq_sel, IR_SignExt_sel;
  input    [1:0] WrBuf_ld, FPBuf_ld, RdBuf_ld, FPBuf_oe, WrBuf_oe, WrBuf_sel; 
  input    [2:0] Reg_In_sel, IP_sel;
  input    [3:0] MAR_sel;
  input    [7:0] V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld;
  input   [31:0] CPSR_In, FIQ_R;
  input   [63:0] FP_In, Reg_In, ALU_In;
  input  [255:0] V_Reg_In, Vector_In;
  
  output  [31:0] Link_fiq_out, Addr;
  output  [63:0] RdBuf_Out, IR_SignExt; 
  output [255:0] Vector_RdBuf_Out;
  inout   [31:0] Data;
  
  reg     [31:0] IR, FPBuf_1, FPBuf_0, WrBuf_1, WrBuf_0, RdBuf_1, RdBuf_0;
  reg     [31:0] V_WrBuf[0:7], V_RdBuf[7:0];
  wire    [31:0] SP_out,IP_out, MAR_out, Link_fiq_out, Link_out, Link_fiq_mux_out;
  
  wire    [31:0] Addr, RdBuf1_mux_out, RdBuf0_mux_out,IP_mux_out, MAR_mux_out;
  wire    [63:0] IR_SignExt, RdBuf_Out,WrBuf_mux_out, Reg_mux_out; 
  wire   [255:0] Vector_RdBuf_Out;
  integer n;
               // d4,                d3,                d2,                             
  Reg_In_mux rgmx(V_Reg_In[255:192], V_Reg_In[191:128], V_Reg_In[127:64], 

               // d1,             d0,     Reg_In_sel, Reg_mux_out
                  V_Reg_In[63:0], Reg_In, Reg_In_sel, Reg_mux_out);
                
               // d2,     d1,     d0,           MAR_sel, MAR_mux_out
  MAR_mux   marmx(SP_out, IP_out, Reg_In[31:0], MAR_sel, MAR_mux_out);

               // d2,              d1,             d0,     WrBuf_sel, 
  WrBuf_mux wrmx({32'b0,CPSR_In}, {32'b0, IP_out}, ALU_In, WrBuf_sel, 
 
               // Dout
                  WrBuf_mux_out); 

               // d4,           d3,       d2,               
  IP_mux     ipmx(Link_fiq_out, Link_out, RdBuf_Out[31:0], 
  
               // d1,                       d0,           IP_sel, IP_mux_out);  
                 {IP_out+IR_SignExt[31:0]}, ALU_In[31:0], IP_sel, IP_mux_out);
  
                    // clk, reset, ld,    inc,    Din,        Dout
  reg_with_ld_inc   IP(clk, reset, IP_ld, IP_inc, IP_mux_out, IP_out);

                    // clk, reset,  Din,                    ld,    inc,    
  SP_reg            SP(clk, reset, {8'b0,IR_SignExt[23:0]}, SP_ld, SP_inc,
  
                    // dec,    Dout
                       SP_dec, SP_out);
  
                    // clk, reset, ld,     inc,     Din,         Dout  
  reg_with_ld_inc  MAR(clk, reset, MAR_ld, MAR_inc, MAR_mux_out, MAR_out);
 
                    // clk, reset, ld,      Din,    Dout 
  reg_with_ld     Link(clk, reset, Link_ld, IP_out, Link_out);

                    // clk, reset, ld,          Din,              Dout   
  reg_with_ld Link_fiq(clk, reset, Link_fiq_ld, Link_fiq_mux_out, Link_fiq_out);
  
  always @(posedge clk, posedge reset) begin
  
    // Reset state reintializes the register values. 
    if (reset) begin
      {FPBuf_1, FPBuf_0}       <=  64'b0;
      {RdBuf_1, RdBuf_0}       <=  64'b0;
      {WrBuf_1, WrBuf_0}       <=  64'b0;
      {IR,   V_RdBuf[0]}       <=  64'b0;
      {V_RdBuf[1], V_RdBuf[2]} <=  64'b0;
      {V_RdBuf[3], V_RdBuf[4]} <=  64'b0;
      {V_RdBuf[5], V_RdBuf[6]} <=  64'b0;
      {V_RdBuf[7], V_WrBuf[0]} <=  64'b0;
      {V_WrBuf[1], V_WrBuf[2]} <=  64'b0;
      {V_WrBuf[3], V_WrBuf[4]} <=  64'b0;
      {V_WrBuf[5], V_WrBuf[6]} <=  64'b0;
       V_WrBuf[7]              <=  32'b0;
         
    end // end of if
    
    else begin
      
      // If IR_ld has 1'b1, then IR gets Data. Otherwise IR gets by itself.
      if (IR_ld == 1'b1) begin
  
        IR <= Data[31:0];
    
      end // end of if
  
      else begin
    
        IR <= IR;
      
      end // end of else
  
      // If WrBuf_ld[0] has 1'b1, then WrBuf_0 gets ALU_In[31:0]. 
      // Otherwise, WrBuf_0 gets by itself.
      if (WrBuf_ld[0] == 1'b1) begin
  
        WrBuf_0 <= WrBuf_mux_out[31:0];
    
      end // end of if
  
      else begin
    
        WrBuf_0 <= WrBuf_0;
      
      end // end of else  
  
      // If WrBuf_ld[1] has 1'b1, then WrBuf_1 gets ALU_In[63:32]. 
      // Otherwise, WrBuf_1 gets by itself.
      if (WrBuf_ld[1] == 1'b1) begin
  
        WrBuf_1 <= WrBuf_mux_out[63:32];
    
      end // end of if
  
      else begin 
  
        WrBuf_1 <= WrBuf_1;
    
      end // end of else
  
      // If FPBuf_ld[0] has 1'b1, then FPBuf_0 gets FP_In[31:0]. 
      // Otherwise, FPBuf_0 gets by itself.
      if (FPBuf_ld[0] == 1'b1) begin
  
        FPBuf_0 <= FP_In[31:0];
    
      end // end of if
  
      else begin
  
        FPBuf_0 <= FPBuf_0;
    
      end // end of else
 
      // If FPBuf_ld[1] has 1'b1, then FPBuf_1 gets FP_In[63:32]. 
      // Otherwise, FPuf_1 gets by itself. 
      if (FPBuf_ld[1] == 1'b1) begin
  
        FPBuf_1 <= FP_In[63:32];
    
      end // end of if
  
      else begin
  
        FPBuf_1 <= FPBuf_1;
    
      end // end of else
  
      // If RdBuf_ld[0] has 1'b1, then RdBuf_0 gets Data. 
      // Otherwise, RdBuf_0 gets by itself.
      if (RdBuf_ld[0] == 1'b1) begin
  
        RdBuf_0 <= RdBuf0_mux_out;
    
      end // end of if
  
      else begin
  
        RdBuf_0 <= RdBuf_0;
    
      end // end of else
   
      // If RdBuf_ld[1] has 1'b1, then RdBuf_1 gets Data. 
      // Otherwise, RdBuf_1 gets by itself.   
      if (RdBuf_ld[1] == 1'b1) begin
  
        RdBuf_1 <= RdBuf1_mux_out;
    
      end // end of if
  
      else begin
  
        RdBuf_1 <= RdBuf_1;
       
      end // end of else

      // If one ofthe V_RdBuf_ld bits is enabled, then the 
      // correspoding V_RdBuf registers will be loaded from
      // Data. 
      for (n=0; n<8; n=n+1) begin
    
       if(V_RdBuf_ld[n]==1'b1)
      
         V_RdBuf[n]<=Data;
       
       else
         V_RdBuf[n]<=V_RdBuf[n];
    
      end // end of for loop  

/***************************************************
* If one of the V_WrBuf_ld bits is high active, 
* then, the V_WrBuf register will be loaded from 
* Vector_In. 
****************************************************/    
      if(V_WrBuf_ld[7]==1'b1)
      V_WrBuf[7] <= Vector_In[255:224];
     
      else
      V_WrBuf[7] <= V_WrBuf[7];   
   
      if(V_WrBuf_ld[6]==1'b1)
      V_WrBuf[6] <= Vector_In[223:192];
     
      else
      V_WrBuf[6] <= V_WrBuf[6];
      
      if(V_WrBuf_ld[5]==1'b1)
      V_WrBuf[5] <= Vector_In[191:160];
     
      else
      V_WrBuf[5] <= V_WrBuf[5];
      
      if(V_WrBuf_ld[4]==1'b1)
   
      V_WrBuf[4] <= Vector_In[159:128];
   
      else
    
      V_WrBuf[4] <= V_WrBuf[4];
      
      if(V_WrBuf_ld[3]==1'b1)
      
      V_WrBuf[3] <= Vector_In[127:96];
    
      else
      V_WrBuf[3] <= V_WrBuf[3];

      if(V_WrBuf_ld[2]==1'b1)
      V_WrBuf[2] <= Vector_In[95:64];
      
      else
      V_WrBuf[2] <= V_WrBuf[2];
      
      if(V_WrBuf_ld[1]==1'b1)
      
      V_WrBuf[1] <= Vector_In[63:32];

      else
      V_WrBuf[1] <= V_WrBuf[1];
      
      if(V_WrBuf_ld[0]==1'b1)
      V_WrBuf[0] <= Vector_In[31:0];
      
      else
      V_WrBuf[0] <= V_WrBuf[0];
      
    end // end of else block
    
  end // end of always block

  // If IR_SignExt_sel, is high active, then IR_SignExt gets
  // Signed Extention IR[15:8]. Otherwise, IR_SignExt gets 
  // Signed Extension IR[23:0].
  assign IR_SignExt = IR_SignExt_sel?{{56{IR[15]}}, IR[15:8]}:
                                     {{40{IR[23]}}, IR[23:0]};
  
  // RdBuf_Out gets RdBuf_1 and RdBuf_0 concatenated with
  // the high and low word RdBuf registers. 
  assign RdBuf_Out = {RdBuf_1, RdBuf_0};
  
  // If FPBuf_oe[1] has 1'b1, then Data gets FPBuf_1.
  // Otherwise, Data is in high impedance.
  assign Data = FPBuf_oe[1] ? FPBuf_1: 32'bz;
  
  // If FPBuf_oe[0] has 1'b1, then Data gets FPBuf_0.
  // Otherwise, Data is in high impedance.
  assign Data = FPBuf_oe[0] ? FPBuf_0: 32'bz;

  // If WrBuf_oe[1] has 1'b1, then Data gets WrBuf_1.
  // Otherwise, Data is in high impedance.  
  assign Data = WrBuf_oe[1] ? WrBuf_1: 32'bz;
  
  // If WrBuf_oe[0] has 1'b1, then Data gets WrBuf_0.
  // Otherwise, Data is in high impedance.
  assign Data = WrBuf_oe[0] ? WrBuf_0: 32'bz;
  
  // Addr gets MAR.
  assign Addr = MAR_out;  
  
  // If RdBuf1_sel or RdBuf0_sel has 1'b1, the output gets 0. 
  // Otherwise, the output gets Data. 
  assign RdBuf1_mux_out = RdBuf1_sel ? 32'b0 : Data;
  assign RdBuf0_mux_out = RdBuf0_sel ? 32'b0 : Data;

  // If one of the V_WrBuf_oe bits is set, then one of the V_WrBuf
  // registers will output to the Data. Otherwise Data gets hi 
  // impedance mode. 
  assign Data = V_WrBuf_oe[7] ? V_WrBuf[7]: 32'bz;
  assign Data = V_WrBuf_oe[6] ? V_WrBuf[6]: 32'bz; 
  assign Data = V_WrBuf_oe[5] ? V_WrBuf[5]: 32'bz;
  assign Data = V_WrBuf_oe[4] ? V_WrBuf[4]: 32'bz; 
  assign Data = V_WrBuf_oe[3] ? V_WrBuf[3]: 32'bz;
  assign Data = V_WrBuf_oe[2] ? V_WrBuf[2]: 32'bz; 
  assign Data = V_WrBuf_oe[1] ? V_WrBuf[1]: 32'bz;
  assign Data = V_WrBuf_oe[0] ? V_WrBuf[0]: 32'bz; 
  
  // If Link_fiq_sel is high active, then Link_fiq_mux_out gets FIQ_R.
  // Otherwise, Link_fiq_mux_out gets IP_Out. 
  assign Link_fiq_mux_out = Link_fiq_sel ? FIQ_R : IP_out;
  
  // Let Vector_Rd_Buf_Out get the contents of each V_RdBuf registers. The
  // V_RdBuf registers are used for reading data from the memory and storing 
  // the contents back to the Vector Datapath. 
  assign Vector_RdBuf_Out = {V_RdBuf[7],V_RdBuf[6],  V_RdBuf[5], V_RdBuf[4], 
                             V_RdBuf[3], V_RdBuf[2], V_RdBuf[1], V_RdBuf[0]};
   
endmodule

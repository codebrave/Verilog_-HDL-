`timescale 1ps / 100fs
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  08:24:02 10/16/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  cu_64.v 
// Project Name: Senior_Project
// Description:  The control unit (CU) is a finite state machine that takes 
//               32-bit data coming from the IR (Instruction Register), 
//               deciphers the IR, and outputs the control word for an execution 
//               unit. The control unit has status flags from the integer 
//               datapath (C,N,Z, and V), floating point datpath (FP_Op) and 
//               the interrupt system (F), and(I). The Finite State Machine 
//               cycles through 4 main states: interrupt check, fetch, decode, 
//               and of the possible execute stages unless the IP (Intsruction
//               Pointer) enters the HALT or ILLEGAL_OP states, in which the control 
//               unit will stay until reset is asserted. The reset state resets 
//               all of the control words to their default values and sets the
//               next state to interrupt check. 
//
//*******************************************************************************
//                           CU Control Words
//*******************************************************************************
//        {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
//        {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
//        {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
//        {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
//        {W_Addr, R_Addr, S_Addr} =                     15'b0;
//        {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
//        {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
//        {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
//        {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
//        {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
//        {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
//        {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
//        {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
//        {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
//        {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
//        {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
//        {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
//        {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
//        {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
//        {F, I, change_flags} =                         38'b0; 
//////////////////////////////////////////////////////////////////////////////////

module cu_64 (sys_clk, reset, intr, // system inputs
              C, N, Z, V,           // Status Inputs
              int_ack,              // output of the I/O subsystem
   
             // Rest of the control word fields below
              R_Addr, S_Addr, W_Addr,W_En, ALU_Op, S_Sel, Y_Sel, IR_ld, MAR_ld, 
              MAR_inc, MAR_sel, RdBuf_ld, RdBuf1_sel, RdBuf0_sel, WrBuf_ld, 
              WrBuf_oe, WrBuf_sel, Mem_rd, Mem_wr, Mem_cs, FW_En, FW_Addr,                
              FS_Addr, FR_Addr, FP_Op, FP_Status, F_Sel, FPBuf_ld, FPBuf_oe,  
              SP_ld, SP_inc, SP_dec, IP_ld, IP_inc, IP_sel, B_Sel, samt, V_Y_Sel, 
              V_W_En, V_W_Addr, V_R_Addr, V_S_Addr, V_ALU_Op, V_WrBuf_ld, 
              V_WrBuf_oe, V_RdBuf_ld, Reg_In_sel, Link_ld, 
              Link_fiq_ld, Link_fiq_sel, SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld,  
              CPSR_sel, CPSR_ld, F, I, change_flags, FIQ_W_Addr, FIQ_R_Addr, 
              FIQ_S_Addr, FIQ_W_En, current_ISR_num_ld, ISR_ld, ISR_clr,
              IO_rd, IO_wr, IO_cs, IR_SignExt_sel, CPSR_in, FS_Sel, fb_inc, fb_dec);


  input            sys_clk, reset ; // system clock, reset, and interrupt
  input            C, N, Z, V ;          // Integer ALU status inputs
  input [5:0]      intr,FP_Status;            // Floating Point ALU status inputs
  input [31:0]     CPSR_in;
  output reg       int_ack;              // interrupt acknowledge
  
  // All of the other control word fields below.  
  output reg        F_Sel, Y_Sel, IR_ld, W_En, FW_En, Mem_rd, Mem_wr, MAR_ld;
  output reg        Mem_cs, SP_ld, SP_inc, SP_dec,  RdBuf1_sel;
  output reg        RdBuf0_sel, MAR_inc, IP_inc, IP_ld, current_ISR_num_ld;
  output reg        ISR_ld, ISR_clr, V_Y_Sel, V_W_En, Link_ld, Link_fiq_ld; 
  output reg        Link_fiq_sel, SPSR_fiq_sel, SPSR_ld, SPSR_fiq_ld; 
  output reg        IO_rd, IO_wr, IO_cs, IR_SignExt_sel, FS_Sel;
  output reg  [1:0] RdBuf_ld, WrBuf_sel, WrBuf_ld, WrBuf_oe, FPBuf_ld, FPBuf_oe;
  output reg  [1:0] FIQ_W_En, S_Sel, fb_inc, fb_dec;
  output reg  [2:0] CPSR_ld, IP_sel, Reg_In_sel, CPSR_sel, F,I;  
  output reg  [3:0] MAR_sel, B_Sel;
  output reg  [4:0] R_Addr, S_Addr, W_Addr, ALU_Op,FW_Addr, FS_Addr, FR_Addr; 
  output reg  [4:0] FP_Op, FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr, V_ALU_Op; 
  output reg  [4:0] V_W_Addr, V_R_Addr, V_S_Addr, samt;
  output reg  [7:0] V_RdBuf_ld, V_WrBuf_ld, V_WrBuf_oe;
  output reg [31:0] change_flags;

  integer n;
  real temp;
  //*************************
  // internal data structures
  //**************************
  
  parameter
  
/******************************************
*  Baseline Instruction states
******************************************/
    INTR_CHK   =   0, INTR_1     =   1, INTR_2     =   2, INTR_3     =   3,
    INTR_4     =   4, INTR_5     =   5, INTR_6     =   6, FETCH      =   7,  
    DECODE     =   8, ADD        =   9, SUB        =  10, MUL_1      =  11,  
    MUL_2      =  12, DIV_1      =  13, DIV_2      =  14, AND        =  15,  
    OR         =  16, XOR        =  17, LDI_1      =  18, LDI_2      =  19,  
    LDI_3      =  20, LOAD_1     =  21, LOAD_2     =  22, LOAD_3     =  23,
    LOAD_4     =  24, STORE_1    =  25, STORE_2    =  26, STORE_3    =  27,  
    COPY       =  28, EXCHANGE_1 =  29, EXCHANGE_2 =  30, EXCHANGE_3 =  31,  
    INPUT_1    =  32, INPUT_2    =  33, INPUT_3    =  34, INPUT_4    =  35, 
    OUTPUT_1   =  36, OUTPUT_2   =  37, OUTPUT_3   =  38, COMPARE    =  39, 
    TEST       =  40, ORHI_1     =  41, ORHI_2     =  42, ORHI_3     =  43, 
    PUSH_1     =  44, PUSH_2     =  45, PUSH_3     =  46, PUSH_4     =  47, 
    POP_1      =  48, POP_2      =  49, POP_3      =  50, POP_4      =  51, 
    NEG        =  52, NOT        =  53, INC        =  54, DEC        =  55, 
    LSHR       =  56, LSHL       =  57, ASHR       =  58, ASHL       =  59, 
    ROR        =  60, ROL        =  61, JC         =  62, JNC        =  63, 
    JZ         =  64, JNZ        =  65, JN         =  66, JP         =  67, 
    JO         =  68, JNO        =  69, JL         =  70, JGE        =  71, 
    JG         =  72, JLE        =  73, JB         =  74, JAE        =  75, 
    JA         =  76, JBE        =  77, JMP_REL    =  78, JREG       =  79, 
    CALL_REL_1 =  80, CALL_REL_4 =  81, CALL_REL_2 =  82, CALL_REL_3 =  83, 
    CALL_REG_1 =  84, CALL_REG_2 =  85, CALL_REG_4 =  86, CALL_REG_3 =  87, 
    RET_1      =  88, RET_2      =  89, RET_3      =  90, RET_4      =  91,
    RETI_1     =  92, RETI_2     =  93, RETI_3     =  94, RETI_4     =  95,  
    CLR_CARRY  =  96, SET_CARRY  =  97, CPL_CARRY  =  98, CLR_IE     =  99, 
    SET_IE     = 100, NOP        = 101, LD_SP      = 102, ADDI       = 103, 
    SUBI       = 104, MULI_1     = 105, MULI_2     = 106, DIVI_1     = 107, 
    DIVI_2     = 108, ANDI       = 109, ORI        = 110, XORI       = 111, 
    CMPI       = 112, TESTI      = 113, F_ADD      = 114, F_SUB      = 115, 
    F_MUL      = 116, F_DIV      = 117, F_INC      = 118, F_DEC      = 119, 
    F_ZERO     = 120, F_ONE      = 121, F_LDI_1    = 122, F_LDI_2    = 123, 
    F_LDI_3    = 124, F_LOAD_1   = 125, F_LOAD_2   = 126, F_LOAD_3   = 127, 
    F_LOAD_4   = 128, F_STORE_1  = 129, F_STORE_2  = 130, F_STORE_3  = 131, 
    F_ORHI_1   = 132, F_ORHI_2   = 133, F_ORHI_3   = 134,
    HALT       = 510, ILLEGAL_OP = 511,
    
/******************************************
*  Enhanced Instruction states
******************************************/    
    NAND           = 135, NOR           = 136, XNOR           = 137, 
    BARREL_SHIFT   = 138, NANDI         = 139, NORI           = 140, 
    XNORI          = 141, V_INC_DWORD   = 142, V_DEC_DWORD    = 143, 
    V_MUL_DWORD_1  = 144, V_DIV_DWORD_1 = 145, V_DIV_DWORD_2  = 146,  
    V_ADD_DWORD    = 147, V_SUB_DWORD   = 148, V_MUL_DWORD_2  = 149, 
    V_AND_DWORD    = 150, V_OR_DWORD    = 151, V_XOR_DWORD    = 152, 
    V_NOT_DWORD    = 153, V_NEG_DWORD   = 154, V_LSHL_DWORD   = 155, 
    V_LSHR_DWORD   = 156, V_ASHL_DWORD  = 157, V_ASHR_DWORD   = 158, 
    V_ZERO_DWORD   = 159, V_ONES_DWORD  = 160, V_PASS_R_DWORD = 161, 
    V_PASS_S_DWORD = 162, V_NAND_DWORD  = 163, V_NOR_DWORD    = 164, 
    V_XNOR_DWORD   = 165, V_ROR_DWORD   = 166, V_BROL_DWORD   = 167, 
    B_INC          = 168, B_DEC         = 169, B_MUL_1        = 170, 
    B_MUL_2        = 171, B_DIV_1       = 172, B_DIV_2        = 173, 
    B_ADD          = 174, B_SUB         = 175, B_AND          = 176, 
    B_OR           = 177, B_XOR         = 178, B_NAND         = 179, 
    B_NOR          = 180, B_XNOR        = 181, B_NOT          = 182, 
    B_NEG          = 183, SET_IE1       = 184, SET_IE2        = 185, 
    SET_FIE        = 186, SET_FIE1      = 187, SET_FIE2       = 188, 
    FINTR_1        = 189, FINTR_2       = 190, FINTR_3        = 191, 
    V_LOAD_1       = 192, V_LOAD_2      = 193, V_LOAD_3       = 194, 
    V_LOAD_4       = 195, V_LOAD_5      = 196, V_LOAD_6       = 197, 
    V_LOAD_7       = 198, V_LOAD_8      = 199, V_LOAD_9       = 200, 
    V_LOAD_10      = 201, V_STORE_1     = 202, V_STORE_2      = 203, 
    V_STORE_3      = 204, V_STORE_4     = 205, V_STORE_5      = 206, 
    V_STORE_6      = 207, V_STORE_7     = 208, V_STORE_8      = 209, 
    V_STORE_9      = 210, FJGT          = 211, FJGE           = 212, 
    FJLT           = 213, FJLE          = 214, FJEQ           = 215, 
    FJNE           = 216, CALL_REL_W_LR = 217, CALL_REG_W_LR  = 218, 
    RET_W_LR       = 219, RETI_W_LR     = 220;
    
  reg [8:0] state; // present state register (up to 512 states)
    
  always @(posedge sys_clk, posedge reset)
  
    if (reset) begin
/*******************************************/
// Reset state,everything is in default.  
/*******************************************/    
      @(negedge sys_clk)

        {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
        {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
        {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
        {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
        {W_Addr, R_Addr, S_Addr} =                     15'b0;
        {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
        {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
        {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
        {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
        {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
        {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
        {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
        {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
        {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
        {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
        {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
        {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
        {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
        {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
        {F, I, change_flags} =                         38'b0;
        
        state = INTR_CHK;
    end // end of state
 
    else
      case (state)
     
/*************************************************
*  Interrupt Check State 
**************************************************/      
        INTR_CHK: begin
/**************************************************
* Deassert all control signals and others to
* their default values and go to INTR_1 state
**************************************************/        
          if (int_ack==0 && ((intr[5:0])&{I,F})) begin
            @(negedge sys_clk)
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};
       
               state = INTR_1;
          end // end of if
        
/********************************************************
*    Let MAR get from IP and go to Fetch state
********************************************************/          
          else begin // MAR <- IP
            @(negedge sys_clk)          
              if(int_ack==1 & intr==0) int_ack=0;

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0001_0_0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};
              
               state = FETCH;

          end // end of else
          
        end // end of state
        
/********************************************************
*    Interrupt state 1: 1 of 6 Clock Cycles
********************************************************/   
        INTR_1: begin // SP <- SP - 1, WrBuf0 <-IP, I <- 3'b0 
          if(intr[2:0])
            state = FINTR_1;
          else begin
            @(negedge sys_clk)
          
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_01_00;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_01;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b1_1_0_0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {6'b000_000, 32'b0};                         
                  
               state = INTR_2;
               
          end // end of else  
          
        end // end of state
        
/********************************************************
*    Interrupt state 2: 2 of 6 Clock Cycles
********************************************************/           
        INTR_2: begin // MAR <-SP, SP <- SP - 1,
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_3;
             
        end
/********************************************************
*    Interrupt state 3: 3 of 6 Clock Cycles
********************************************************/   
        INTR_3: begin// M[MAR] <- WrBuf0, MAR <- SP, WrBuf0 <- CPSR_in
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_01_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_0_10;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_4;
             
        end

/********************************************************
*    Interrupt state 4: 4 of 6 Clock Cycles
********************************************************/           
        INTR_4: begin // M[MAR] <- WrBuf0, MAR <- 32'h3ff
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            
            if (intc.ISR_out[5]==1'b1) // MAR <- 32'h2a9
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b1000_0_0;
            
            else if (intc.ISR_out[4]==1'b1) // MAR <- 32'h2a7
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0111_0_0;
            
            else
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0011_0_0;
            
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_5;
             
        end      

/********************************************************
*    Interrupt state 5: 5 of 6 Clock Cycles
********************************************************/           
        INTR_5: begin // RdBuf0 <- M[MAR]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};      
            
             state = INTR_6;
        end // end of state
        
/********************************************************
*    Interrupt state 6: 6 of 6 Clock Cycles
********************************************************/        
        INTR_6: begin // IP <- RdBuf0, int_ack <- 1'b1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_1_010;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        end // end of stae      
        
/********************************************************
*    Fast Interrupt state 1: 1 of 3 Clock Cycles
********************************************************/        
        FINTR_1: begin // Link_fiq <- IP, CPSR <- {21'b0, CPSR_in[10:0]}
          @(negedge sys_clk)
          
            if(intc.ISR_out[2:0]) begin // FIQ[Rd] <- Link_fiq_out
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_10_0_000;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         {fbk.n, 10'b0}; 
            end
            
            else begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;
            end
            
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_1_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            
            if(intr[0]==1'b1) // MAR <- 32'h2a1
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0100_0_0;
            
            else if (intr[1] == 1'b1) // MAR <- 32'h2a3
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0101_0_0;

            else // MAR <- 32'h2a5
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0110_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0_0_0_0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,   
                                                            {21'b0,     
                                                            CPSR_in[10:0]}};
             state = FINTR_2;          
        end // end of state     

/********************************************************
*    Fast Interrupt state 2: 2 of 3 Clock Cycles
********************************************************/        
        FINTR_2: begin // RdBuf0 <- M[MAR], F <- 3'b0;
                      
          @(negedge sys_clk)
            if(intc.ISR_out[2:0]) begin // FIQ[Rd] <- Link_fiq_out
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_01_0_000;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         {fbk.n, 10'b0}; 
            end
            
            else begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;
            end
                     
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            
            if(intc.ISR_out[2:0]) // fbk.n <- fbk.n - 2
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_00_10_00;
            
            else // fbk.n <- fbk.n
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b1_1_0_0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b000_000, 32'b0};   
            
             state = FINTR_3;          
        end // end of state  
        
/********************************************************
*    Fast Interrupt state 3: 3 of 3 Clock Cycles
********************************************************/        
        FINTR_3: begin // IP <- RdBuf0, ISR <-(ISR|intr), int_ack <- 1'b1
                       // SPSR_fiq <- CPSR_out
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_1_010;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_1;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        end // end of state 
        
/********************************************************
*    Fetch state: Let IR get from the M[IP]
********************************************************/        
        FETCH: begin
        // IR <- M[IP], IP <- IP + 1;
          @(negedge sys_clk)
          
             $display("FETCH with IP=%h - goto DECODE - %t",cpu.EU.biu.IP_out,$time);

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;      
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b1_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b1_0_0_0_0_0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};      
            
             state =  DECODE;   
            
        end // end of state
        
/********************************************************
*    Decode state: Deassert all control signals and map 
     towards from IR[31:24]. 
********************************************************/           
        DECODE: begin
          @(negedge sys_clk)
          
             $display("DECODE with IR=%h - %t",cpu.EU.biu.IR,$time);
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                  
          case (cpu.EU.biu.IR[31:24])
            // Enhanced Instructions
            8'h00:   state = NAND;
            8'h01:   state = NOR;
            8'h02:   state = XNOR;
            8'h03:   state = BARREL_SHIFT;
            8'h04:   state = NANDI;
            8'h05:   state = NORI;
            8'h06:   state = XNORI;
            8'h07:   state = V_INC_DWORD;
            8'h08:   state = V_DEC_DWORD;
            8'h09:   state = V_MUL_DWORD_1;
            8'h0A:   state = V_DIV_DWORD_1;
            8'h0B:   state = V_ADD_DWORD;
            8'h0C:   state = V_SUB_DWORD;
            8'h0D:   state = V_AND_DWORD;
            8'h0E:   state = V_OR_DWORD;
            8'h0F:   state = V_XOR_DWORD;
            8'h10:   state = V_NOT_DWORD;
            8'h11:   state = V_NEG_DWORD;
            8'h12:   state = V_LSHL_DWORD;
            8'h13:   state = V_LSHR_DWORD;
            8'h14:   state = V_ASHL_DWORD;
            8'h15:   state = V_ASHR_DWORD;
            8'h16:   state = V_ZERO_DWORD;
            8'h17:   state = V_PASS_R_DWORD;
            8'h18:   state = V_PASS_S_DWORD;
            8'h19:   state = V_NAND_DWORD;
            8'h1A:   state = V_NOR_DWORD;
            8'h1B:   state = V_XNOR_DWORD;
            8'h1C:   state = V_ROR_DWORD;
            8'h1D:   state = V_BROL_DWORD;
            8'h1E:   state = B_INC;
            8'h1F:   state = B_DEC;
            8'h20:   state = B_MUL_1;   
            8'h21:   state = B_DIV_1;
            8'h22:   state = B_ADD;
            8'h23:   state = B_SUB;
            8'h24:   state = B_AND;
            8'h25:   state = B_OR;
            8'h26:   state = B_XOR;
            8'h27:   state = B_NAND;
            8'h28:   state = B_NOR;
            8'h29:   state = B_XNOR;
            8'h2A:   state = B_NEG;
            8'h2B:   state = B_NOT;
            8'h2C:   state = SET_IE1;
            8'h2D:   state = SET_IE2;
            8'h2E:   state = SET_FIE;
            8'h2F:   state = SET_FIE1;
            8'h30:   state = SET_FIE2;
            8'h31:   state = V_LOAD_1;
            8'h32:   state = V_STORE_1;
            8'h33:   state = V_ONES_DWORD;
            8'h34:   state = FJGT;
            8'h35:   state = FJGE;
            8'h36:   state = FJLT;
            8'h37:   state = FJLE;
            8'h38:   state = FJEQ;
            8'h39:   state = FJNE;
            8'h3a:   state = CALL_REL_W_LR;
            8'h3b:   state = CALL_REG_W_LR;
            8'h3c:   state = RET_W_LR;
            8'h3d:   state = RETI_W_LR;
            
            //Baseline Instructions
            8'h80:   state = ADD;
            8'h81:   state = SUB;
            8'h82:   state = MUL_1;
            8'h83:   state = DIV_1;
            8'h84:   state = AND;
            8'h85:   state = OR;
            8'h86:   state = XOR;
            8'h87:   state = LDI_1;
            8'h88:   state = LOAD_1;
            8'h89:   state = STORE_1;
            8'h8A:   state = COPY;
            8'h8B:   state = EXCHANGE_1;
            8'h8C:   state = INPUT_1; 
            8'h8D:   state = OUTPUT_1;            
            8'h8E:   state = COMPARE;
            8'h8F:   state = TEST;
            
            8'h9F:   state = ORHI_1;            
            8'h90:   state = PUSH_1;
            8'h91:   state = POP_1;
            8'h92:   state = NEG;
            8'h93:   state = NOT;
            8'h94:   state = INC;
            8'h95:   state = DEC;
            8'h98:   state = LSHR;
            8'h99:   state = LSHL;
            8'h9A:   state = ASHR;
            8'h9B:   state = ASHL;
            8'h9C:   state = ROR;
            8'h9D:   state = ROL;
            
            8'hA0:   state = JC; 
            8'hA1:   state = JNC;
            8'hA2:   state = JZ;
            8'hA3:   state = JNZ;
            8'hA4:   state = JN;
            8'hA5:   state = JP;
            8'hA6:   state = JO;
            8'hA7:   state = JNO;
            8'hA8:   state = JL;
            8'hA9:   state = JGE;
            8'hAA:   state = JG;
            8'hAB:   state = JLE;
            8'hAC:   state = JB;
            8'hAD:   state = JAE;
            8'hAE:   state = JA;
            8'hAF:   state = JBE;
            8'hB0:   state = JMP_REL;
            8'hB1:   state = JREG;
            8'hB2:   state = CALL_REL_1;
            8'hB3:   state = CALL_REG_1;
            8'hB4:   state = RET_1;
            8'hB5:   state = RETI_1;
            
            8'hC0:   state = CLR_CARRY;
            8'hC1:   state = SET_CARRY;
            8'hC2:   state = CPL_CARRY;
            8'hC3:   state = CLR_IE;
            8'hC4:   state = SET_IE;   
            8'hC6:   state = NOP;
            8'hC7:   state = LD_SP;   
            
            8'hD0:   state = ADDI;
            8'hD1:   state = SUBI;
            8'hD2:   state = MULI_1;
            8'hD3:   state = DIVI_1;
            
            8'hD8:   state = ANDI;
            8'hD9:   state = ORI;
            8'hDA:   state = XORI;
            8'hDB:   state = CMPI;
            8'hDC:   state = TESTI;
            
            8'hE0:   state = F_ADD;
            8'hE1:   state = F_SUB;
            8'hE2:   state = F_MUL;
            8'hE3:   state = F_DIV;
            8'hE4:   state = F_INC;
            8'hE5:   state = F_DEC;
            8'hE6:   state = F_ZERO;
            8'hE7:   state = F_ONE;
            8'hE8:   state = F_LDI_1;
            8'hE9:   state = F_LOAD_1;
            8'hEA:   state = F_STORE_1;
            
            8'hEF:   state = F_ORHI_1;
            8'hC5:   state = HALT;
            default: state = ILLEGAL_OP;
          
          endcase
               
        end // end of state
        
//INSTRUCTION 00h
/********************************************************
*   NAND state: 1 of 1 Clock Cycles
********************************************************/   
        NAND: begin // ALU_Op <- NAND
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                    {cpu.EU.biu.IR[4:0], 
                                                           cpu.EU.biu.IR[20:16],
                                                           cpu.EU.biu.IR[12:8]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


//INSTRUCTION 01H
/********************************************************
*   NOR state: 1 of 1 Clock Cycles
********************************************************/   
        NOR: begin // ALU_Op <- NOR, R[d] <- ~(R[s1]|R[s2])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};                                                
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

//INSTRUCTION 02H
/********************************************************
*   XNOR state: 1 of 1 Clock Cycles
********************************************************/   
        XNOR: begin // ALU_Op <- XNOR, R[d] <- ~(R[s1] ^ R[s2])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

//INSTRUCTION 03H
/********************************************************
*   Barrel Shift state: 1 of 1 Clock Cycles
********************************************************/   
        BARREL_SHIFT: begin // ALU_Op <- Pass S, samt <- IR[23:18], 
                            // B_Sel <- IR[8:5] 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[13:9]};                                          
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state   


/********************************************************
*   NANDI state: 1 of 1 Clock Cycles
********************************************************/   
        NANDI: begin // ALU_Op <- NAND,  S_Sel <- 2'b01, 
                     // R[d] <- ~(R[s1] & SignExt(IR[15:8]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};     
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state



/********************************************************
/********************************************************
*   NORI state: 1 of 1 Clock Cycles
********************************************************/   
        NORI: begin // ALU_Op <- NOR, S_Sel <- 2'b01
                    // R[d] <- ~(R[s1] | SignExt(IR[15:8]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1; 
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   XNORI state: 1 of 4 Clock Cycles
********************************************************/   
        XNORI: begin // ALU_Op <- XNOR, S_Sel <- 2'b01
                     // R[d] <- ~(R[s1] ^ SignExt(IR[15:8]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;  
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*    V_INC state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_INC_DWORD: begin // VALU_Op <- INC, R[d] <- R[s1] + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
         
        end // end of state


/********************************************************
*    V_DEC state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_DEC_DWORD: begin // VALU_Op <- DEC, R[d] <- R[s1] - 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00001;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
          
        end // end of state


/********************************************************
*    V_MUL state 1: 1 of 2 Clock Cycles
********************************************************/   
        V_MUL_DWORD_1: begin // VALU_Op <- MUL, R[d] <- R[s1] * R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00010;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = V_MUL_DWORD_2;

        end // end of state


/********************************************************
*    V_MUL_2 state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_MUL_DWORD_2: begin // VALU_Op <- MUL_MSW, R[d] <- product_reg[127:64] 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0] + 1,
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00011;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state


/********************************************************
*    V_DIV state 1: 1 of 2 Clock Cycles
********************************************************/   
        V_DIV_DWORD_1: begin // VALU_Op <- DIV, R[d] <- R[s1]/R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00100;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = V_DIV_DWORD_2;

        end // end of state
   

/********************************************************
*    V_DIV state 2: 2 of 2 Clock Cycles
********************************************************/   
        V_DIV_DWORD_2: begin // VALU_Op <- REM, R[d] <- remainder_rg[127:64]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0] + 1,
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00101;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
             
        end // end of state
   

/********************************************************
*    V_ADD state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ADD_DWORD: begin // VALU_Op <- ADD, R[d] <- R[s1] + R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00110;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
             
        end // end of state
   

/********************************************************
*    V_SUB state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_SUB_DWORD: begin // VALU_Op <- SUB, R[d] <- R[s1] - R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_00111;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
      

/********************************************************
*    V_AND state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_AND_DWORD: begin // VALU_Op <- AND, R[d] <- R[s1] & R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
   

/********************************************************
*    V_OR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_OR_DWORD: begin // VALU_Op <- OR, R[d] <- R[s1] | R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01001;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
   

/********************************************************
*    V_XOR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_XOR_DWORD: begin // VALU_Op <- XOR, R[d] <- R[s1] ^ R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01010;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state


/********************************************************
*    V_NOT state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_NOT_DWORD: begin // VALU_Op <- NOT, R[d] <- ~R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01011; 
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state


/********************************************************
*    V_NEG state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_NEG_DWORD: begin // VALU_Op <- NEG, R[d] <- ~R[s1] + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01100;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state


/********************************************************
*    V_LSHL state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_LSHL_DWORD: begin // VALU_Op <- LSHL, R[d] <- R[s1] << 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01101;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
      

/********************************************************
*    V_LSHR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_LSHR_DWORD: begin // VALU_Op <- LSHR, R[d] <- R[s1] >> 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01110;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state   


/********************************************************
*    V_ASHL state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ASHL_DWORD: begin // VALU_Op <- ASHL, R[d]<- R[s1] <<< 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_01111;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state    
    
/********************************************************
*    V_ASHR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ASHR_DWORD: begin // VALU_Op <- ASHR, R[d] <- R[s1] >>> 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    V_ZERO state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ZERO_DWORD: begin // VALU_Op <- ZERO, R[d] <- 64'b0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            5'b0};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10001;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    V_ONES state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ONES_DWORD: begin // VALU_Op <- ONES, 
                            // R[d] <- 64'hFFFF_FFFF_FFFF_FFFF_FFFF
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            5'b0};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10010;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    V_PASSR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_PASS_R_DWORD: begin // VALU_Op <- PASS R, R[d] <- R[s1] 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10011;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    V_PASS_S state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_PASS_S_DWORD: begin // VALU_Op <- PASS_S, R[d] <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10100;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    V_NAND state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_NAND_DWORD: begin // VALU_Op <- NAND, R[d] <- ~(R[s1] & R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10101;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end     
        
/********************************************************
*    V_NOR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_NOR_DWORD: begin // VALU_Op <- NOR, R[d] <- ~(R[s1] | R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10110;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end     

/********************************************************
*    V_XNOR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_XNOR_DWORD: begin // VALU_Op <- XNOR, R[d] <- ~(R[s1] ^ R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10111;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end     

/********************************************************
*    V_ROR state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_ROR_DWORD: begin // VALU_Op <- ROR, R[d] <- ROR (R[s1])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_11000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
    
/********************************************************
*    V_BROL state 1: 1 of 1 Clock Cycles
********************************************************/   
        V_BROL_DWORD: begin // VALU_Op <- ROL, R[d] <- ROL(R[s1])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_0_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_11001;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end
        
/********************************************************
*    V_Load state 1: 1 of 10 Clock Cycles
********************************************************/
        V_LOAD_1: begin // MAR <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_2;          
        
        end // end of state
        
/********************************************************
*    V_Load state 2: 2 of 10 Clock Cycles
********************************************************/
        V_LOAD_2: begin // VRdBuf0 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b0000_0001};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_3;          
        
        end // end of state


/********************************************************
*    V_Load state 3: 3 of 10 Clock Cycles
********************************************************/
        V_LOAD_3: begin // VRdBuf1 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b00000010};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_4;          
        
        end // end of state

/********************************************************
*    V_Load state 4: 4 of 10 Clock Cycles
********************************************************/
        V_LOAD_4: begin // VRdBuf2 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b00000100};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_5;          
        
        end // end of state

/********************************************************
*    V_Load state 5: 5 of 10 Clock Cycles
********************************************************/
        V_LOAD_5: begin // VRdBuf3 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b00001000};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_6;          
        
        end // end of state


/********************************************************
*    V_Load state 6: 6 of 10 Clock Cycles
********************************************************/
        V_LOAD_6: begin // VRdBuf4 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b00010000};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_7;          
        
        end // end of state
        
        
/********************************************************
*    V_Load state 7: 7 of 10 Clock Cycles
********************************************************/
        V_LOAD_7: begin // VRdBuf5 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b00100000};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_8;          
  end

/********************************************************
*    V_Load state 8: 8 of 10 Clock Cycles
********************************************************/
        V_LOAD_8: begin // VRdBuf6 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0, 8'b01000000};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_9;   
        end // end of state
        
        

/********************************************************
*    V_Load state 9: 9 of 10 Clock Cycles
********************************************************/
        V_LOAD_9: begin // VRdBuf7 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {16'b0,8'b10000000};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = V_LOAD_10;   
        end // end of state


/********************************************************
*    V_Load state 10: 10 of 10 Clock Cycles
********************************************************/
        V_LOAD_10: begin // R[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0_0_1_1;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {cpu.EU.biu.IR[4:0], 10'b0};
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state
        




/********************************************************
*    V_Store state 1: 1 of 9 Clock Cycles
********************************************************/
        V_STORE_1: begin // MAR <- R[d], VWrBuf <- R[s1]
                         // load all 8 VWrBufs
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[4:0],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               {10'b0, 
                                                            cpu.EU.biu.IR[20:16]};
                                                           
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00000_10100;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b11111111, 16'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = V_STORE_2;   
             
        end // end of state
        
/********************************************************
*    V_Store state 2: 2 of 9 Clock Cycles
********************************************************/
        V_STORE_2: begin // M[MAR] <- VWrBuf0, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00000001, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_3;        
        
        end // end of state


/********************************************************
*    V_Store state 3: 9 of 9 Clock Cycles
********************************************************/
        V_STORE_3: begin // M[MAR] <- VWrBuf1, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00000010, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_4;        
        end

/********************************************************
*    V_Store state 4: 4 of 9 Clock Cycles
********************************************************/
        V_STORE_4: begin // M[MAR] <- VWrBuf2, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;  
            {W_Addr, R_Addr, S_Addr} =                     15'b0;               
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00000100, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_5;
        end // end of state
        
/********************************************************
*    V_Store state 5: 5 of 9 Clock Cycles
********************************************************/
        V_STORE_5: begin // M[MAR] <- VWrBuf3, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0; 
            {W_Addr, R_Addr, S_Addr} =                     15'b0;           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00001000, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_6;
      end       
             
/********************************************************
*    V_Store state 6: 6 of 9 Clock Cycles
********************************************************/
        V_STORE_6: begin // M[MAR] <- VWrBuf4, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00010000, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_7;
      end
      

/********************************************************
*    V_Store state 7: 7 of 7 Clock Cycles
********************************************************/
        V_STORE_7: begin // M[MAR] <- VWrBuf5, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                 
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b00100000, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_8;
      end

/********************************************************
*    V_Store state 8: 8 of 9 Clock Cycles
********************************************************/
        V_STORE_8: begin // M[MAR] <- VWrBuf6, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b01000000, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = V_STORE_9;
      end
      
/********************************************************
*    V_Store state 9: 9 of 9 Clock Cycles
********************************************************/
        V_STORE_9: begin // M[MAR] <- VWrBuf7
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         {8'b0, 8'b10000000, 
                                                            8'b0};
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = INTR_CHK;
      end


/********************************ARITHMETIC SHIFT INSTRUCTIONS BEGIN


/********************************************************
*   B_INC state: 1 of 1 Clock Cycles
********************************************************/   
        B_INC: begin // ALU_Op <- INC, R[d] <- Barrel_Shift(R[s1]) + 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   B_DEC state: 1 of 1 Clock Cycles
********************************************************/   
        B_DEC: begin // ALU_Op <- DEC, R[d] <- Barrel_Shift(R[s1]) - 1 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

/********************************************************
*    B_MUL state: 1 of 2 Clock Cycles
********************************************************/
        B_MUL_1: begin // ALU_Op <- MUL, R[d] <- R[s2] * Barrel_Shift(R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14], 
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = B_MUL_2;
        end // end of state
 

/********************************************************
*    B_MUL state: 2 of 2 Clock Cycles
********************************************************/
        B_MUL_2: begin // ALU_Op <- MSW, R[d] <- product_rg[127:64] 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0] + 1, 
                                                            5'b0,
                                                            5'b0}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                                                       
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    

/********************************************************
*    B_DIV state: 1 of 2 Clock Cycles
********************************************************/
        B_DIV_1: begin // ALU_Op <- DIV, R[d] <- R[s1] / Barrel_Shift(R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = B_DIV_2;

        end // end of state
 

/********************************************************
*    B_DIV state: 2 of 2 Clock Cycles
********************************************************/
        B_DIV_2: begin // ALU_Op <- REM, R[d] <- remainder_rg[127:64]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0] + 1, 
                                                            5'b0, 
                                                            5'b0}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                 
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
   
/********************************************************
*    B_ADD state: 1 of 1 Clock Cycles
********************************************************/   
        B_ADD: begin // Rd[d] <- R[s1] + Barrel_Shift(R[s2])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};    
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*    B_SUB state: 1 of 1 Clock Cycles
********************************************************/   
        B_SUB: begin // ALU_Op <- Subtract, R[d] <-- R[s1] - Barrel_Shift(R[s2])
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[18:14], 
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};   
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
        end // end of state


   
/********************************************************
*    B_AND state 1: 1 of 1 Clock Cycles
********************************************************/   
        B_AND: begin // ALU_Op <- AND, R[d] <- R[s1] & Barrel_Shift(R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state



/********************************************************
*   B_OR state 1: 1 of 1 Clock Cycles
********************************************************/   
        B_OR: begin // ALU_Op <- OR, R[d] <- R[s1] | Barrel_Shift(R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state


/********************************************************
*   B_XOR state 1: 1 of 1 Clock Cycles
********************************************************/   
        B_XOR: begin // ALU_Op <- XOR, R[d] <- R[s1] ^ Barrel_Shift(R[s2])
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14], 
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state    
    
/********************************************************
*   B_NAND state: 1 of 1 Clock Cycles
********************************************************/   
        B_NAND: begin // ALU_Op = NAND, R[d] <- ~(R[s1] & Barrel_Shift(R[s2]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

/********************************************************
*   B_NOR state: 1 of 1 Clock Cycles
********************************************************/   
        B_NOR: begin // ALU_Op <- NOR, R[d] <- ~(R[s1] | Barrel_Shift(R[s2]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};  
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   B_XNOR state: 1 of 1 Clock Cycles
********************************************************/   
        B_XNOR: begin // ALU_Op <- XNOR, R[d] <- ~(R[s1] ^ Barrel_Shift(R[s2]))
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[18:14],
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};  
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
        
/********************************************************
*   B_NEG state: 1 of 1 Clock Cycles
********************************************************/   
        B_NEG: begin // ALU_Op <- NEG, R[d] <- ~Barrel_Shift(R[s1]) + 1 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]}; 
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state= INTR_CHK;      
       
        end // end of state
        
/********************************************************
*   B_NOT state: 1 of 1 Clock Cycles
********************************************************/   
        B_NOT: begin // ALU_Op <- NOT, R[d] <- ~Barrel_Shift(R[s1])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[13:9]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          {6'b000_000, 
                                                            cpu.EU.biu.IR[8:5], 
                                                            cpu.EU.biu.IR[23:19]};   
                                                            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state= INTR_CHK;      
       
        end // end of state


/*********************************ARITHMETIC SHIFT INSTUCTIONS END 
   
/********************************************************
*   SET_IE1 state: 1 of 1 Clock Cycles
********************************************************/   
         SET_IE1: begin // I[1] <- 1'b1
          @(negedge sys_clk)
          if (intc.ISR_out[2:0]==0) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b000_010, 
                                                           {CPSR_in[31:12], 1'b1,     
                                                            CPSR_in[10:0]}};   
             end                                                            
             state = INTR_CHK;                               
        
        end
        
/********************************************************
*   SET_IE2 state: 1 of 1 Clock Cycles
********************************************************/  
         SET_IE2: begin // I[2] <- 1'b1
          @(negedge sys_clk)
          if (intc.ISR_out[2:0]==0) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b000_100, 
                                                           {CPSR_in[31:13], 1'b1,     
                                                            CPSR_in[11:0]}};
          end                                               
             state = INTR_CHK;        
        
        end

/********************************************************
*   SET_FIE state: 1 of 1 Clock Cycles
********************************************************/  
         SET_FIE: begin // F[0] <- 1'b1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b001_000, 
                                                           {CPSR_in[31:14], 1'b1,   
                                                            CPSR_in[12:0]}};                                                          
             state = INTR_CHK;        
        
        end

/********************************************************
*   SET_FIE1 state: 1 of 1 Clock Cycles
********************************************************/  
         SET_FIE1: begin // F[1] <- 1'b1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b010_000, 
                                                           {CPSR_in[31:15], 1'b1,     
                                                            CPSR_in[13:0]}};                                                        
             state = INTR_CHK;        
        
        end

/********************************************************
*   SET_FIE2 state: 1 of 1 Clock Cycles
********************************************************/  
         SET_FIE2: begin // F[2] <- 1'b1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b100_000, 
                                                           {CPSR_in[31:16], 1'b1,     
                                                            CPSR_in[14:0]}};                                                           
             state = INTR_CHK;        
        
        end

/*****************************************************************
*   Floating Point Jump if Greater Than state: 1 of 1 Clock Cycles
******************************************************************/  
        FJGT: begin // If(GT == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[5]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
        
          end    
          state = INTR_CHK;
          
        end 

/*********************************************************************
*   Floating Point Jump if Greater or Equal state: 1 of 1 Clock Cycles
**********************************************************************/          
        FJGE: begin // If(GE == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[4]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
            
          end    
          state = INTR_CHK;
          
        end 

/*********************************************************************
*   Floating Point Jump if Less Than state: 1 of 1 Clock Cycles
**********************************************************************/ 
        FJLT: begin // If(LT == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[3]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
          
          end    
          state = INTR_CHK;
          
        end 

/*********************************************************************
*   Floating Point Jump if Less or Equal state: 1 of 1 Clock Cycles
**********************************************************************/ 
        FJLE: begin // If(LE == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[2]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   

                     
          end    
          state = INTR_CHK;
          
        end 

/*********************************************************************
*   Floating Point Jump if Equal state: 1 of 1 Clock Cycles
**********************************************************************/ 
        FJEQ: begin // If(EQ == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[1]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   

                     
          end    
          state = INTR_CHK;
          
        end 

/*********************************************************************
*   Floating Point Jump if Not Equal state: 1 of 1 Clock Cycles
**********************************************************************/         
        FJNE: begin // If(NE == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if(CPSR_in[0]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   

                     
          end    
          state = INTR_CHK;
          
        end 
        
/*********************************************************************
*   Call Relative with Link Register state: 1 of 1 Clock Cycles
**********************************************************************/         
        CALL_REL_W_LR: begin // Link_out <- IP, IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
          
            if (intc.ISR_out[2:0])   // FIQ[Rd] <- Link_fiq_out
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_10_0_001;
            
            else
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
            
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            
            if (intc.ISR_out[2:0])   // FIQ[Rd] <- Link_fiq_out
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         {fbk.n, 10'b0};
            
            else            
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0; 
            
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            
            if (intc.ISR_out[2:0]) begin // Link_fiq_out <- IP 
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_1_000_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_00_01_00;
            
            end
            
            else begin
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b1_0_000_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            end
            
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
        
/*********************************************************************
*   Call Register with Link Register state: 1 of 1 Clock Cycles
**********************************************************************/         
        CALL_REG_W_LR: begin // Link_out <- IP, IP <- R[s1]
          @(negedge sys_clk)
          
            if (intc.ISR_out[2:0]) // FIQ[Rd] <- Link_fiq_out
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_10_0_000;
      
            else 
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            
            if (intc.ISR_out[2:0]) // FIQ[Rd] <- Link_fiq_out       
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         {fbk.n, 10'b0};
            
            else                
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;
        
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            
            if (intc.ISR_out[2:0]) begin // Link_fiq_out <= IP
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_1_000_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_00_01_00;   
            end   
                   
            else begin
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b1_0_000_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            end
            
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state

/********************************************************
*    Return With Link Register state: 1 of 1 Clock Cycles
********************************************************/   
        RET_W_LR: begin // IP <- Link_out
          @(negedge sys_clk)

            if (intc.ISR_out[2:0]) begin // Link_fiq_out <- FIQ_R  
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_100;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b1_0_0_0;    
            end   
            
            else begin            
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_011;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            
            end
            
            if (intc.ISR_out[2:0]) // Link_fiq_out <- FIQ_R 
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         {5'b0,
                                                            fbk.n-1, 
                                                            5'b0}; 
            else
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            
            if (intc.ISR_out[2:0]) begin // Link_fiq_out <- FIQ_R
            
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_1_000_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_00_00_01;
            
            end
            
            else begin      
            
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            
            end
            
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
        
/*******************************************************************
*    Return Interrupt With Link Register state: 1 of 1 Clock Cycles
********************************************************************/   
        RETI_W_LR: begin // IP <- Link_out, CPSR <- SPSR_out
          @(negedge sys_clk)

            if (intc.ISR_out[2:0]) begin // IP <- Link_fiq_out, CPSR <- SPSR_fiq 
            
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_100;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b1_1_0_0;
              
              if(fbk.n!=0) begin
              {FIQ_W_Addr, FIQ_R_Addr} =                     {5'b0, fbk.n-2};   
              {FIQ_S_Addr} =                                  fbk.n-1;
              end
              
              else      
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;   
              
            end
            
            else begin          
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_011;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;   
            end
                     
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   

            if (intc.ISR_out[2:0]) begin // Link_fiq_out <- FIQ_R, SPSR_fiq <- FIQ_S
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_1;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_1_111_0;
              
              if (fbk.n == 0||fbk.n==1)
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              else
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_00_00_10;
            
            end
            
            else begin      
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;         
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_111_0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            
            end
            
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0_0_1_0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
        
/*******************************************************
*    END OF ENHANCED INSTRUCTIONS
********************************************************/        
        
/*START OF BASELINE INSTRUCTIONS*/        
/********************************************************
*    ADD state: 1 of 1 Clock Cycles
********************************************************/   
        ADD: begin // ALU_Op <- ADD, R[d] <- R[s1] + R[s2]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;//{3'b0,3'b100,9'b0};//15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
				//@(posedge sys_clk)
            {F, I, change_flags} =                        {F,I,32'b0}; //{F,I,{{16{F[2]}}, {F,I,N,C,Z,V },FP_Status}};//{F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

/********************************************************
*    SUB state: 1 of 1 Clock Cycles
********************************************************/   
        SUB: begin // ALU_Op <- SUB, R[d] <-- R[s1] - R[s2]
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          4'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
        end // end of state



/********************************************************
*    MUL state: 1 of 2 Clock Cycles
********************************************************/
        MUL_1: begin // ALU_Op <- MUL, R[d] <- R[s1] * R[s2]
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = MUL_2;
          end             
        end // end of state
 

/********************************************************
*    MUL state: 2 of 2 Clock Cycles
********************************************************/
        MUL_2: begin // ALU_Op <- MSW, R[d] <- product_rg[127:64]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0] + 1, 
                                                            5'b0, 
                                                            5'b0};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
        end // end of state
    

/********************************************************
*    DIV state: 1 of 2 Clock Cycles
********************************************************/
        DIV_1: begin // ALU_Op <- DIV, R[d] <- R[s1]/R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = DIV_2;
        end // end of state
 

/********************************************************
*    DIV state: 2 of 2 Clock Cycles
********************************************************/
        DIV_2: begin // ALU_Op <- REM, R[d] <- remainder_rg[127:64]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0] + 1, 
                                                            5'b0, 
                                                            5'b0}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_00101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;

        end // end of state
    
/********************************************************
*    AND state 1: 1 of 1 Clock Cycles
********************************************************/   
        AND: begin // ALU_Op <- AND, R[d] <- R[s1] & R[s2] 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
        end // end of state



/********************************************************
*   OR state 1: 1 of 1 Clock Cycles
********************************************************/   
        OR: begin // ALU_Op <- OR, R[d] <- R[s1] | R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
             
        end // end of state


/********************************************************
*   XOR state 1: 1 of 1 Clock Cycles
********************************************************/   
        XOR: begin // ALU_Op <- XOR, R[d] <- R[s1] ^ R[s2]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
        
             state = INTR_CHK;
        end // end of state    

/********************************************************
*    Load Immediate state 1: 1 of 3 Clock Cycles
********************************************************/           
        LDI_1: begin // MAR <- IP
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0001_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = LDI_2;
             
        end // end of state
        
/********************************************************
*    Load Immediate state 2: 2 of 3 Clock Cycles
********************************************************/   
        LDI_2: begin // RdBuf0 <- M[MAR], RdBuf1<- 32'h0, IP <- IP + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b11_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_1_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b1_0_0_0_0_0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = LDI_3;
        
        end // end of state
        
/********************************************************
*    Load Immediate state 3: 3 of 3 Clock Cycles
********************************************************/
        LDI_3: begin // R[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_1_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state

/********************************************************
*    Load state 1: 1 of 4 Clock Cycles
********************************************************/
        LOAD_1: begin // MAR <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = LOAD_2;          
        
        end // end of state
        
/********************************************************
*    Load state 2: 2 of 4 Clock Cycles
********************************************************/
        LOAD_2: begin // RdBuf0 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = LOAD_3;          
        
        end // end of state

/********************************************************
*    Load state 3: 3 of 4 Clock Cycles
********************************************************/
        LOAD_3: begin // RdBuf1 <- M[MAR]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b10_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = LOAD_4;          
        
        end // end of state

/********************************************************
*    Load state 4: 4 of 4 Clock Cycles
********************************************************/
        LOAD_4: begin // R[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_1_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state
        
/********************************************************
*    Store state 1: 1 of 3 Clock Cycles
********************************************************/
        STORE_1: begin // MAR <- R[d], WrBuf1:WrBuf0 <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16]};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_11_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = STORE_2;   
             
        end // end of state
        
/********************************************************
*    Store state 2: 2 of 3 Clock Cycles
********************************************************/
        STORE_2: begin // M[MAR] <- WrBuf0, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = STORE_3;        
        
        end // end of state

/********************************************************
*    Store state 3: 3 of 3 Clock Cycles
********************************************************/        
        STORE_3: begin // M[MAR] <- WrBuf1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_10;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = INTR_CHK;   
        
        end // end of state
        
/********************************************************
*   COPY state: 1 of 1 Clock Cycles
********************************************************/   
        COPY: begin // R[d] <- R[s1]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

/********************************************************
*   EXCHANGE state: 1 of 3 Clock Cycles
********************************************************/   
        EXCHANGE_1: begin // R[s1] <- R[s1] ^ R[s2]  
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = EXCHANGE_2;      
       
        end // end of state
/********************************************************
*   EXCHANGE state: 2 of 3 Clock Cycles
********************************************************/   
        EXCHANGE_2: begin // R[s2] <- R[s1] ^ R[s2]  
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[12:8],  
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};    
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = EXCHANGE_3;      
       
        end // end of state

/********************************************************
*   EXCHANGE state: 2 of 3 Clock Cycles
********************************************************/   
        EXCHANGE_3: begin // R[s1] <- R[s1] ^ R[s2]  
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[20:16],  
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
/********************************************************
*    Input state 1: 1 of 4 Clock Cycles
********************************************************/
        INPUT_1: begin // MAR <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INPUT_2;          
        
        end // end of state
        
/********************************************************
*    Input state 2: 2 of 4 Clock Cycles
********************************************************/
        INPUT_2: begin // RdBuf0 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b0_1_0;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INPUT_3;          
        
        end // end of state

/********************************************************
*    Input state 3: 3 of 4 Clock Cycles
********************************************************/
        INPUT_3: begin // RdBuf1 <- M[MAR]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b10_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b0_1_0;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INPUT_4;          
        
        end // end of state

/********************************************************
*    Input state 4: 4 of 4 Clock Cycles
********************************************************/
        INPUT_4: begin // R[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_1_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state
        
/********************************************************
*    Output state 1: 1 of 3 Clock Cycles
********************************************************/
        OUTPUT_1: begin // MAR <- R[d], WrBuf1:WrBuf0 <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16]};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_11_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = OUTPUT_2;   
             
        end // end of state
        
/********************************************************
*    Output state 2: 2 of 3 Clock Cycles
********************************************************/
        OUTPUT_2: begin // M[MAR] <- WrBuf0, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_0_0;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = OUTPUT_3;        
        
        end // end of state

/********************************************************
*    Output state 3: 3 of 3 Clock Cycles
********************************************************/        
        OUTPUT_3: begin // M[MAR] <- WrBuf1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_10;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_0_0;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = INTR_CHK;   
        
        end // end of state
        
/********************************************************
*   COMPARE state: 1 of 1 Clock 
********************************************************/   
        COMPARE: begin // R[s1] - R[s2]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};  

             state = INTR_CHK;      
       
        end // end of state



/********************************************************
*   TEST state: 1 of 1 Clock Cycles
********************************************************/   
        TEST: begin  // ALU_Op <- AND, R[s1] & R[s2]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;  
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
        
/********************************************************
*    Or Hi state 1: 1 of 3 Clock Cycles
********************************************************/
        ORHI_1: begin // MAR <- IP
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                                   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b00_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0001_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};           

             state = ORHI_2;  
             
        end // end of state
        
/********************************************************
*    Or Hi state 2: 2 of 3 Clock Cycles
********************************************************/
        ORHI_2: begin // RdBuf1 <- M[MAR], RdBuf0<- 32'h0, IP <- IP + 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                                   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b11_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_0_1;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b1_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = ORHI_3;
        
        end // end of state
        
/********************************************************
*    Or Hi state 3: 3 of 3 Clock Cycles
********************************************************/
        ORHI_3: begin // R[d] <- R[d] | RdBuf1:RdBuf0
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            
            {W_Addr, R_Addr, S_Addr} =                    {cpu.EU.biu.IR[4:0], 
                                                           cpu.EU.biu.IR[4:0],
                                                           5'b0};         
                                                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b10_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
          state = INTR_CHK;          
        
        end // end of state
        
/********************************************************
*    PUSH state 1: 1 of 4 Clock Cycles  
********************************************************/           
        PUSH_1: begin // SP <- SP - 1, WrBuf <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                    {10'b00000_00000, 
                                                            cpu.EU.biu.IR[20:16]};
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_11_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = PUSH_2;
             
        end // end of state
        

/********************************************************
*    PUSH state 2: 2 of 4 Clock Cycles  
********************************************************/           
        PUSH_2: begin // MAR <- SP, SP <- SP - 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = PUSH_3;
             
        end // end of state
        
        
        
/********************************************************
*    PUSH state 3: 3 of 4 Clock Cycles  
********************************************************/           
        PUSH_3: begin // MAR <- SP, M[MAR] <- WrBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;  
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = PUSH_4;
             
        end // end of state
        
        
        
/********************************************************
*    PUSH state 4: 4 of 4 Clock Cycles 
********************************************************/           
        PUSH_4: begin // M[MAR] <-- WrBuf1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_10;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;  
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = INTR_CHK;
             
        end // end of state



/********************************************************
*    POP state 1: 1 of 4 Clock Cycles  
********************************************************/           
        POP_1: begin // MAR <- SP
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = POP_2;
             
        end // end of state   


/********************************************************
*    POP state 2: 1 of 4 Clock Cycles  
********************************************************/           
        POP_2: begin // RdBuf1 <- M[MAR], MAR <- MAR + 1, SP  <--SP + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b10_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;  
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = POP_3;
              
        end // end of state


/********************************************************
*    POP state 3: 3 of 4 Clock Cycles  
********************************************************/           
        POP_3: begin // Rbuf0 <- M[MAR]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0; 
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = POP_4;
             
        end // end of state


/********************************************************
*    POP state 4: 4 of 4 Clock Cycles  
********************************************************/           
        POP_4: begin // R[d] <-- RdBuf, SP <-- SP + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                           10'b00000_00000};
                                                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_1_0; 
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = INTR_CHK;
             
        end // end of state                   
/********************************************************
*   NEG state: 1 of 1 Clock Cycles
********************************************************/   
        NEG: begin // ALU_Op <- NEG, R[d] <- ~R[s1] + 1 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   NOT state: 1 of 1 Clock Cycles
********************************************************/   
        NOT: begin // ALU_Op <- NOT, R[d] <- ~R[s1]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   INC state: 1 of 1 Clock Cycles
********************************************************/   
        INC: begin // ALU_Op <- INC, R[d] <- R[s1] + 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   DEC state: 1 of 1 Clock Cycles
********************************************************/   
        DEC: begin // ALU_Op <- DEC, R[d] <- R[s1] - 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   LSHR state: 1 of 1 Clock Cycles
********************************************************/   
        LSHR: begin // ALU_Op <- LSHR, R[d] <- R[s1] >> 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;            
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

   

/********************************************************
*   LSHL state: 1 of 1 Clock Cycles
********************************************************/   
        LSHL: begin // ALU_Op <- LSHL, R[d] <- R[s1] << 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;              
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state   
        
   

/********************************************************
*   ASHR state: 1 of 1 Clock Cycles
********************************************************/   
        ASHR: begin // ALU_Op <- ASHR, R[d] <- R[s1] >>> 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state   
           
         
/********************************************************
*   ASHL state: 1 of 1 Clock Cycles
********************************************************/   
        ASHL: begin // ALU_Op <- ASHL, R[d] <- R[s1] <<< 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};  
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;              
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state   
        
/********************************************************
*   ROR state: 1 of 1 Clock Cycles
********************************************************/   
        ROR: begin // ALU_Op <- ROR, R[d] <- ROR(R[s1])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};  
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_11000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

/********************************************************
*   ROL state: 1 of 1 Clock Cycles
********************************************************/   
        ROL: begin // ALU_Op <- ROL, R[d] <- ROL(R[s1])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_11001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;              
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state      

/********************************************************
*   Jump If Carry state: 1 of 1 Clock Cycles
********************************************************/          
        JC: begin // If(C==1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
            if(CPSR_in[8]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   

                     
          end    
          state = INTR_CHK;
          
        end     
        
/********************************************************
*   Jump If Not Carry state: 1 of 1 Clock Cycles
********************************************************/         
        JNC: begin // If(C==0) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[8]==1'b0) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
            
            end         
          
            state = INTR_CHK;        
        
        end     
        
/********************************************************
*   Jump If Zero state: 1 of 1 Clock Cycles
********************************************************/          
        JZ: begin // If(Z==1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[7]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   

            end         
            state = INTR_CHK;   
          
        end    
        
/********************************************************
*   Jump If Not Zero state: 1 of 1 Clock Cycles
********************************************************/  
        JNZ: begin // If(Z==0) IP<-IP+IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[7]==1'b0) begin
          
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
            
            end         
          
            state = INTR_CHK;        
        
        end  

/********************************************************
*   Jump If Negative state: 1 of 1 Clock Cycles
********************************************************/  
        JN: begin // If(N==1) IP<-IP+IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[9]==1'b1) begin
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
                       
            end         
          
            state = INTR_CHK;        
        
        end  

/********************************************************
*   Jump If Plus state: 1 of 1 Clock Cycles
********************************************************/  
        JP: begin // If(N==0) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[9]==1'b0) begin
            
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};             

            end         
          
            state = INTR_CHK;        
        
        end 
        
/********************************************************
*   Jump If Overflow state: 1 of 1 Clock Cycles
********************************************************/  
        JO: begin // If(V==1) IP<-IP+IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[6]==1'b1) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};               
            
          end         
          
          state = INTR_CHK;        

        end          

/********************************************************
*   Jump If Not Overflow state: 1 of 1 Clock Cycles
********************************************************/  
        JNO: begin // If(V==0) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[6]==1'b0) begin
            
              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
              
            end         
          
            state = INTR_CHK;      
          
        end    

/********************************************************
*   Jump If Less Than state: 1 of 1 Clock Cycles
********************************************************/  
        JL: begin // If(V^N==1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[6] ^ CPSR_in[9] == 1'b1) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};         
            
            end         
          
            state = INTR_CHK;        
        
        end     

/********************************************************
*   Jump If Greater or Equal state: 1 of 1 Clock Cycles
********************************************************/  
        JGE: begin // If((V^N)==0) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[6] ^ CPSR_in[9] == 1'b0) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
              
            end         
          
            state = INTR_CHK;   
          
        end

/********************************************************
*   Jump If Greater Than state: 1 of 1 Clock Cycles
********************************************************/  
        JG: begin // If(Z|(V^N)==0) IP<- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[7] | (CPSR_in[6] ^ CPSR_in[9]) == 1'b0) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
                                
            end         
          
            state = INTR_CHK;        
                             
        end             

/********************************************************
*   Jump if Less or Equal state: 1 of 1 Clock Cycles
********************************************************/  
        JLE: begin // If(Z|(V^N)==1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if (CPSR_in[7] | (CPSR_in[6] ^ CPSR_in[9]) == 1'b1) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
                                       
            end         
          
            state = INTR_CHK;        
        
        end      
        
/********************************************************
*   Jump If Below state: 1 of 1 Clock Cycles
********************************************************/  
        JB: begin // If(C==1) IP<- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[8] == 1'b1) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
                                          
          end         
          
          state = INTR_CHK;        
        
        end
        
/********************************************************
*   Jump If Above or Equal state: 1 of 1 Clock Cycles
********************************************************/  
        JAE: begin // If(C|Z==0) IP<- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[8] | CPSR_in[7] ==1'b0) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
              
            end         
            state = INTR_CHK;        
        
        end              

/********************************************************
*   Jump If Above state: 1 of 1 Clock Cycles
********************************************************/  
        JA: begin // If(C==0) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[8] == 1'b0) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};   
                          
            end         
            state = INTR_CHK;        
        
        end           

/********************************************************
*   Jump if Below or Equal state: 1 of 1 Clock Cycles
********************************************************/  
        JBE: begin // If(C|Z == 1) IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
        
            if(CPSR_in[8] | CPSR_in[7] == 1'b1) begin

              {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
              {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
              {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
              {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
              {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
              {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
              {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
              {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
              {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
              {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
              {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
              {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
              {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
              {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
              {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
              {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
              {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
              {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
              {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
              {F, I, change_flags} =                         {F,I,32'b0};      
            
            end         
          
            state = INTR_CHK;        
        
        end  

/********************************************************
*   Jump Relative state: 1 of 1 Clock Cycles
********************************************************/         
        JMP_REL: begin // IP <- IP + IR_SignExt[23:0]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};             

             state = INTR_CHK;        
        
        end
        
/********************************************************
*   Jump Register state: 1 of 1 Clock Cycles
********************************************************/  
        JREG: begin // IP <- R[s1]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};      
                   
          state = INTR_CHK;        
        
        end 
        
/********************************************************
*   Call Relative state: 1 of 4 Clock Cycles
********************************************************/         
        CALL_REL_1: begin // SP <- SP - 1, WrBuf0 <-IP 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_01_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_01;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = CALL_REL_2;        
        
        end  

/********************************************************
*   Call Relative state: 2 of 4 Clock Cycles
********************************************************/  
        CALL_REL_2: begin // MAR <-SP, ,SP <- SP-1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = CALL_REL_3;        
        
        end    
 
/********************************************************
*   Call Relative state: 3 of 4 Clock Cycles
********************************************************/   
        CALL_REL_3: begin // M[MAR] <- WrBuf0, MAR <- SP
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = CALL_REL_4;        
        
        end 

/********************************************************
*   Call Relative state: 4 of 4 Clock Cycles
********************************************************/          
        CALL_REL_4: begin // M[MAR] <- WrBuf1, IP <- IP + IR_SignExt[23:0] 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_001;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_10;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = INTR_CHK;        
        
        end          

/********************************************************
*   Call Register state: 1 of 4 Clock Cycles
********************************************************/  
        CALL_REG_1: begin // SP <- SP - 1, WrBuf0 <- IP 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_01_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_01;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};      
            
             state = CALL_REG_2;        
        
        end  
        
/********************************************************
*   Call Register state: 2 of 4 Clock Cycles
********************************************************/  
        CALL_REG_2: begin // MAR <-SP, SP <- SP -1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_0_1_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = CALL_REG_3;        
        
        end    

/********************************************************
*   Call Register state: 3 of 4 Clock Cycles
********************************************************/        
        CALL_REG_3: begin // M[MAR] <- WrBuf0, MAR <- SP
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_01;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = CALL_REG_4;        
        
        end       

/********************************************************
*   Call Register state: 4 of 4 Clock Cycles
********************************************************/  
        CALL_REG_4: begin // M[MAR] <- WrBuf1, MAR <- SP IP <- R[s1] 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0,
                                                            5'b0,
                                                            cpu.EU.biu.IR[20:16]};
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_10100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b00_00_10;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                         
                  
             state = INTR_CHK;        
        
        end       
/********************************************************
*   Return state: 1 of 4 Clock Cycles
********************************************************/         
        RET_1: begin // MAR <- SP
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = RET_2;        
        
        end 

/********************************************************
*   Return state: 2 of 4 Clock Cycles
********************************************************/  
        RET_2: begin // Rdbuf1 <- M[MAR],  SP <- SP +1, MAR <-MAR +1 ,
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b10_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

                  
          state = RET_3;        
        
        end 

/********************************************************
*   Return state: 3 of 4 Clock Cycles
********************************************************/  
        RET_3: begin // IP <- Rdbuf0, SP <- SP +1 
          @(negedge sys_clk)
        
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
                  
             state = RET_4;        
        
        end

/********************************************************
*   Return state: 4 of 4 Clock Cycles
********************************************************/  
        RET_4: begin // IP <- RdBuf0
          @(negedge sys_clk)
        
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_010;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
                  
             state = INTR_CHK;        
        
        end
 
/********************************************************
*   Return From Interrupt state: 1 of 4 Clock Cycles
********************************************************/   
        RETI_1: begin // MAR <- SP
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0010_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = RETI_2;        
        
        end 

/********************************************************
*   Return From Interrupt state: 2 of 4 Clock Cycles
********************************************************/        
        RETI_2: begin // Rdbuf0 <- M[MAR], MAR <- MAR +1, SP <- SP +1 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

                  
             state = RETI_3;        
        
        end 

/********************************************************
*   Return From Interrupt state: 3 of 4 Clock Cycles
********************************************************/ 
        RETI_3: begin // CPSR <- Rdbuf0, RdBuf0 <- M[MAR], SP <- SP + 1 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_0_1_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          16'b000_001_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

                  
             state = RETI_4;        
        
        end
 
/********************************************************
*   Return From Interrupt state: 4 of 4 Clock Cycles
********************************************************/  
        RETI_4: begin // IP <- RdBuf0 
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_010;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_1_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0_0_1_0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

                  
             state = INTR_CHK;        
        
        end
        
/********************************************************
*   Clear Carry state: 1 of 1 Clock Cycles
********************************************************/        
        CLR_CARRY: begin // C <- 1'b0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         { 6'b000_000, 
                                                          {CPSR_in[31:9], 1'b0, 
                                                           CPSR_in[7:0]}};
                                                                     
             state = INTR_CHK;        
        
        end
  
/********************************************************
*   Set Carry state: 1 of 1 Clock Cycles
********************************************************/   
        SET_CARRY: begin // C <- 1'b1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                        { 6'b000_000, 
                                                          {CPSR_in[31:9], 1'b1, 
                                                            CPSR_in[7:0]}};
                                                                     
             state = INTR_CHK;        
        
        end
        
/********************************************************
*   Complement Carry state: 1 of 1 Clock Cycles
********************************************************/ 
        CPL_CARRY: begin // C <- ~C
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                        { 6'b000_000, 
                                                          {CPSR_in[31:9], ~CPSR_in[8], 
                                                           CPSR_in[7:0]}};
                                                                     
             state = INTR_CHK;        
        
        end

/********************************************************
*   Clear Interrupt Enable state: 1 of 1 Clock Cycles
********************************************************/ 
        CLR_IE: begin // I[0] <- 1'b0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b000_000, 
                                                           {{16{F[2]}},{F,I[2:1],1'b0,N,C,Z,V},      
                                                            FP_Status}};                                                            
             state = INTR_CHK;        
        
        end

/********************************************************
*   Set Interrupt Enable state: 1 of 1 Clock Cycles
********************************************************/ 
        SET_IE: begin // I[0] <- 1'b1
          @(negedge sys_clk)
          if (intc.ISR_out[2:0]==0) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_100_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b000_100_0000_00000;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {6'b000_001, 
                                                           {CPSR_in[31:11], 1'b1,     
                                                            CPSR_in[9:0]}};   
            end                                                            
            state = INTR_CHK;        
        
        end

/********************************************************
*   No Operation state: 1 of 1 Clock Cycles
********************************************************/       
        NOP: begin // No operation
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                                                            
             state = INTR_CHK;        
        
        end    
        
/********************************************************
*   LD_SP state: 1 of 1 Clock Cycles
********************************************************/
        LD_SP: begin // SP <- IR[23:0]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0_1_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};                                                            
             state = INTR_CHK;        
        
        end   
        
/********************************************************
*   ADDI state: 1 of 1 Clock Cycles
********************************************************/   
        ADDI: begin // ALU_Op <- ADD, R[d] <- R[s1] + SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00110_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1; 
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   SUBI state: 1 of 1 Clock Cycles
********************************************************/   
        SUBI: begin // ALU_Op <- SUB, R[d] <- R[s1] - SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;  
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   MULII state: 1 of 2 Clock Cycles
********************************************************/   
        MULI_1: begin // ALU_Op <- MUL, R[d] <- R[s1] * SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};           
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state =  MULI_2;      
       
        end // end of state


/********************************************************
*   MULI state: 2 of 2 Clock Cycles
********************************************************/   
        MULI_2: begin // ALU_Op <- MSW, R[d] <- product_rg[127:64]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0]+1,
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00011_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state

   
/********************************************************
*   DIVI state: 1 of 2 Clock Cycles
********************************************************/   
        DIVI_1: begin // ALU_Op <- DIV, R[d] <- R[s1] / SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};  
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00100_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state =  DIVI_2;      
       
        end // end of state

/********************************************************
*   DIVI state: 2 of 2 Clock Cycles
********************************************************/   
        DIVI_2: begin // ALU_Op <- REM, R[d] <- remainder_rg[127:64]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0]+1, 
                                                            5'b0, 
                                                            5'b0};  
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00101_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;  
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   ANDI state: 1 of 1 Clock Cycles
********************************************************/   
        ANDI: begin // ALU_Op <- AND, R[d] <- R[s1] & SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   ORI state: 1 of 1 Clock Cycles
********************************************************/   
        ORI: begin // ALU_Op <- OR, R[d] <- R[s1] | SignExt([15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};  
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01001_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1; 
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   XORI state: 1 of 1 Clock Cycles
********************************************************/   
        XORI: begin // ALU_Op <- XOR, R[d] <- R[s1] ^ SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b1_0_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01010_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
/********************************************************
*   CMPI state: 1 of 1 Clock Cycles
********************************************************/   
        CMPI: begin // ALU_Op <- SUB, R[s1] - SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};    
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_00111_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;  
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*   TESTI state: 1 of 1 Clock Cycles
********************************************************/   
        TESTI: begin // ALU_Op <- AND, R[s1] & SignExt(IR[15:8])
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_0_00_0_0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0};                             
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00000_01000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b01_0_0_1;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_001_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;               
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state =  INTR_CHK;      
       
        end // end of state
        
/********************************************************
*  F_ADD state: 1 of 1 Clock Cycles
********************************************************/   
        F_ADD: begin // FP_Op <- F_ADD, R[d] <- R[s1] + R[s2] 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;      
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00010_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*  F_SUB state: 1 of 1 Clock Cycles
********************************************************/   
        F_SUB: begin // FP_Op <- F_SUB, R[d] <- R[s1] - R[s2]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;    
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00011_00000_00000;//
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state



/********************************************************
*  F_MUL state: 1 of 1 Clock Cycles
********************************************************/   
        F_MUL: begin // FP_Op <- F_MUL, R[d] <- R[s1] * R[s2]
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;    
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00101_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*  F_DIV state: 1 of 1 Clock Cycles
********************************************************/   
        F_DIV: begin // FP_Op <- F_DIV, R[d] <- R[s1] / R[s2] 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0],
                                                            cpu.EU.biu.IR[20:16],
                                                            cpu.EU.biu.IR[12:8]};
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b00110_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state


/********************************************************
*  F_INC state: 1 of 1 Clock Cycles
********************************************************/   
        F_INC: begin // FP_Op <- F_INC R, R[d] <- R[s1] + 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;     
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0}; 
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b01010_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state   

/********************************************************
*  F_DEC state: 1 of 1 Clock Cycles
********************************************************/   
        F_DEC: begin // FP_Op <- F_DEC R, R[d] <- R[s1] - 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            5'b0}; 
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b01100_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b00_0_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state        
/********************************************************
*  F_ZERO state: 1 of 1 Clock Cycles
********************************************************/   
        F_ZERO: begin // FP_Op <- F_ZERO, R[d] <- 0.0 
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;     
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0],
                                                            10'b00000_00000};
                                                            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b01000_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state
        
/********************************************************
*  F_ONE state: 1 of 1 Clock Cycles
********************************************************/   
        F_ONE: begin // FP_Op <- F_ONE, R[d] <- 1.0  
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            cpu.EU.biu.IR[20:16], 
                                                            cpu.EU.biu.IR[12:8]}; 
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                           
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b01001_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = INTR_CHK;      
       
        end // end of state        
/********************************************************
*    Float Load Immediate state 1: 1 of 3 Clock Cycles
********************************************************/           
        F_LDI_1: begin // MAR <- IP
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0001_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
                    
             state = F_LDI_2;
             
        end // end of state
        
/********************************************************
*    Float Load Immediate state 2: 2 of 3 Clock Cycles
********************************************************/   
        F_LDI_2: begin // RdBuf0 <- M[MAR], RdBuf1<- 32'h0, IP <- IP + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b11_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_1_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b1_0_0_0_0_0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = F_LDI_3;
        
        end // end of state
        
/********************************************************
*    Float Load Immediate state 3: 3 of 3 Clock Cycles
********************************************************/
        F_LDI_3: begin // FR[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;      
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0],
                                                            5'b0,
                                                            5'b0};
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                                             
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_1_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state

/********************************************************
*    Float Load state 1: 1 of 4 Clock Cycles
********************************************************/
        F_LOAD_1: begin // MAR <- R[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = F_LOAD_2;          
        
        end // end of state
        
/********************************************************
*    Float Load state 2: 2 of 4 Clock Cycles
********************************************************/
        F_LOAD_2: begin // RdBuf0 <- M[MAR], MAR <- MAR + 1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b01_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = F_LOAD_3;          
        
        end // end of state

/********************************************************
*    Float Load state 3: 3 of 4 Clock Cycles
********************************************************/
        F_LOAD_3: begin // RdBuf1 <- M[MAR]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b10_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = F_LOAD_4;          
        
        end // end of state

/********************************************************
*    Float Load state 4: 4 of 4 Clock Cycles
********************************************************/
        F_LOAD_4: begin // R[d] <- RdBuf1:RdBuf0
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;
            
            {FW_Addr, FR_Addr, FS_Addr} =                  {cpu.EU.biu.IR[4:0], 
                                                            5'b0,
                                                            5'b0};
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =        5'b00_1_0_0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
             state = INTR_CHK;          
        
        end // end of state
        
/********************************************************
*    Store state 1: 1 of 3 Clock Cycles
********************************************************/
        F_STORE_1: begin // MAR <- R[d], FPBuf1:FPBuf0 <- FR[s1]
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  {5'b0,
                                                            cpu.EU.biu.IR[20:16],
                                                            5'b0};
            
            {W_Addr, R_Addr, S_Addr} =                     {5'b0, 
                                                            cpu.EU.biu.IR[4:0],
                                                            5'b0};   
                                                            
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_1_0_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b11_00_00_00;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = F_STORE_2;   
             
        end // end of state
        
/********************************************************
*    Float Store state 2: 2 of 3 Clock Cycles
********************************************************/
        F_STORE_2: begin // M[MAR] <- FPBuf0, MAR <- MAR+1
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0_0_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_01_00_00;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};

             state = F_STORE_3;        
        
        end // end of state

/********************************************************
*    Float Store state 3: 3 of 3 Clock Cycles
********************************************************/        
        F_STORE_3: begin // M[MAR] <- FPBuf1
          @(negedge sys_clk)
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
                                       
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b00_10_00_00;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_0_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
            
             state = INTR_CHK;   
        
        end // end of state

/********************************************************
*    Float Or Hi state 1: 1 of 3 Clock Cycles
********************************************************/
        F_ORHI_1: begin // MAR <- IP
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                                   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b00_1_0_0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0001_0_0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};           

             state = F_ORHI_2;  
             
        end // end of state
        
/********************************************************
*    Float Or Hi state 2: 2 of 3 Clock Cycles
********************************************************/
        F_ORHI_2: begin // RdBuf1 <- M[MAR], RdBuf0<- 32'h0, IP <- IP + 1
          @(negedge sys_clk)
          
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;   
            {W_Addr, R_Addr, S_Addr} =                     15'b0;                                                   
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b11_00_00;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0000_0_1;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b1_0_0_0_00;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b0_1_0;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   

             state = F_ORHI_3;
        
        end // end of state
        
/********************************************************
*    Float Or Hi state 3: 3 of 3 Clock Cycles
********************************************************/
        F_ORHI_3: begin // R[d] <- R[d] | RdBuf1:RdBuf0
          @(negedge sys_clk)

            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      8'b0_1_00_0_000;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;      
            
            {FW_Addr, FR_Addr, FS_Addr} =                 {cpu.EU.biu.IR[4:0], 
                                                           cpu.EU.biu.IR[4:0],
                                                           5'b0};
            
            {W_Addr, R_Addr, S_Addr} =                     15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op, V_ALU_Op} =                    15'b01110_00000_00000;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0_0_010_0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0_0_0_1;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};   
            
          state = INTR_CHK;          
        
        end // end of state
                
/********************************************************
*    Halt state: 1 of 1 Clock Cycles. Deassert all 
     control signals. Display memory location 0x300 and 
     the register contents from R0 to R15.
********************************************************/
        HALT: begin
          @(negedge sys_clk)
          
            {W_En, FW_En, int_ack, IP_sel} =      4'b0;
            {FW_Addr, FR_Addr, FS_Addr} =        15'b0;  
            {W_Addr, R_Addr, S_Addr} =           15'b0;                                             
            {FP_Op, ALU_Op} =                    10'b0;
            {S_Sel, F_Sel, Y_Sel} =               4'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld} =     4'b0;
            {FPBuf_ld, FPBuf_oe} =                4'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =      6'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =   4'b0;
            {IP_inc, SP_inc, SP_dec, WrBuf_sel} = 4'b0;
            {Mem_rd, Mem_wr, Mem_cs} =            3'b1_1_1;   
             $display("");
             $display("*****************************************");
             $display("Final Content of Memory Location 0x300");
             $display("*****************************************");
             $display("");          
             $display("Mem[0e2h]=%h",mry.memarray[10'h3fd]);
             $display("");
             $display("*****************************************");
             $display("Final Contents of the Registers");
             $display("*****************************************");
             $display("");
             Dump_Registers;
             $display(" ");
             $display(" ");
             Dump_FP_Registers;
             $display(" ");
             $display(" ");
             Dump_V_Registers;
             $display(" ");
             $display(" ");
             $display("***************************************** ");
             $display("Dumping Memory");
             $display("***************************************** ");
             Dump_Memory;
             $display(" ");
             $display(" ");
             $display("***************************************** ");
             $display("Dumping IO0 Memory");
             $display("***************************************** ");
             IO0_Memory;
             $display(" ");
             $display(" ");
             $display("***************************************** ");
             $display("Dumping IO1 Memory");
             $display("***************************************** ");
             IO1_Memory;
             $display(" ");
             $display(" ");
             $display("***************************************** ");
             $display("Dumping IO2 Memory");
             $display("***************************************** ");
             IO2_Memory;
             $display(" ");
             $display(" ");
             $finish;
        end
   
/********************************************************
*    Illegal opcode state: 1 of 1 Clock Cycles. Deassert  
     all control signals. Display the the register 
     contents of the register, memory, and io locations. 
********************************************************/        
        ILLEGAL_OP: begin
          @(negedge sys_clk)
          
            {W_En, FW_En, int_ack, IP_sel} =      4'b0;
            {FW_Addr, FR_Addr, FS_Addr} =        15'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =        15'b0;            
            {W_Addr, R_Addr, S_Addr} =           15'b0;                                             
            {FP_Op, ALU_Op} =                    10'b0;
            {S_Sel, F_Sel, Y_Sel} =               4'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld} =     4'b0;
            {FPBuf_ld, FPBuf_oe} =                4'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =      6'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =   4'b0;
            {IP_inc, SP_inc, SP_dec, WrBuf_sel} = 4'b0;
            {Mem_rd, Mem_wr, Mem_cs} =            3'b1_1_1;   
            
            $display("ILLEGAL OPCODE FETCHED %t",$time);
             $display("Mem[0e2h]=%h",mry.memarray[10'h3fe]);
            Dump_Registers;
            Dump_FP_Registers;
            Dump_V_Registers;
            Dump_Memory;
            $display("Dumping IO");
            IO0_Memory;
            IO1_Memory;
            IO2_Memory;
            $finish;
        end
           
          
      endcase    

   // This function will access from the register file and display the 
   // contents of each register from R0 to R15.    
   task Dump_Registers;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr} =                             {5'b0, n};
             S_Addr = n+16;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
   
            #1 $display("Time=%t R%h =%h        ||        R%h =%h", 
                        $time,   R_Addr, cpu.EU.idp.R, S_Addr, cpu.EU.idp.S_Out);            
         end
      end

   endtask      
          
   
   // This function will display the contents of the Floating Point Registers
   task Dump_FP_Registers;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  {5'b0, n, 5'b0};
            {W_Addr, R_Addr} =                             15'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
            #1 $display("Time=%t FP%h =%h  //  (%f)", 
                        $time,   FR_Addr, cpu.EU.fdp.R_Out, $bitstoreal(cpu.EU.fdp.Float_Out));            
         end
      end

   endtask      
          
   // This funciton will display the contents of the Vector Registers      
   task Dump_V_Registers;
      for (n=0; n<32; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr} =                             15'b0;
            {V_W_Addr, V_R_Addr} =                        {5'b0, n};
            V_S_Addr    =     5'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
            #1 $display("Time=%t VR%h = %h   ", 
                        $time,   V_R_Addr, cpu.EU.vidp.V_REG_OUT);            
         end
      end

   endtask  

   // This funciton will display the contents of Memory locations 
   // 0xE0 to 0xFF
   task Dump_Memory;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr} =                             {10'b0};
             S_Addr = 5'b0;
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
   
            #1 $display("Time=%t M[%h] = %h        ||        M[%h] =%h", 
                        $time,   8'hE0+n, mry.memarray[8'hE0+n],
                        8'hF0+n, mry.memarray[8'hF0+n]);            
         end
      end

    endtask

    // This function will the display the contents of IO0 location 
    // 3E0 to 3FF.
    task IO0_Memory;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;    
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
   
            #1 $display("Time=%t M[%h] = %h        ||        M[%h] =%h", 
                        $time,   10'h3E0+n, io0.memarray[10'h3E0+n],
                        10'h3F0+n, io0.memarray[10'h3F0+n]);            
         end
      end

    endtask

    // This function will the display the contents of IO1 location 
    // 3E0 to 3FF.
    task IO1_Memory;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;    
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
   
            #1 $display("Time=%t M[%h] = %h        ||        M[%h] =%h", 
                        $time,   10'h3E0+n, io1.memarray[10'h3E0+n],
                        10'h3F0+n, io1.memarray[10'h3F0+n]);            
         end
      end

    endtask         

    // This function will the display the contents of IO2 location 
    // 3E0 to 3FF.
    task IO2_Memory;
      for (n=0; n<16; n=n+1) begin
      
          @(negedge sys_clk) begin
            {W_En, FW_En, FIQ_W_En, int_ack, IP_sel} =      6'b0;
            {Link_fiq_sel, SPSR_fiq_sel, V_Y_Sel, V_W_En} = 4'b0;
            {FIQ_W_Addr, FIQ_R_Addr, FIQ_S_Addr} =         15'b0;          
            {FW_Addr, FR_Addr, FS_Addr} =                  15'b0;
            {W_Addr, R_Addr, S_Addr} =                     15'b0;    
            {V_W_Addr, V_R_Addr, V_S_Addr} =               15'b0;
            {FP_Op, ALU_Op,V_ALU_Op} =                     15'b0;
            {S_Sel, F_Sel, Y_Sel, IR_SignExt_sel} =         5'b0;   
            {IR_ld, MAR_ld, MAR_inc, IP_ld, SPSR_fiq_ld} =  5'b0;
            {Link_ld, Link_fiq_ld, CPSR_ld, SPSR_ld} =      6'b0;
            {FPBuf_ld, FPBuf_oe, fb_inc, fb_dec} =          8'b0;
            {RdBuf_ld, WrBuf_ld, WrBuf_oe} =                6'b0;
            {V_WrBuf_ld, V_WrBuf_oe, V_RdBuf_ld} =         24'b0;
            {MAR_sel, RdBuf1_sel, RdBuf0_sel} =             6'b0;
            {IP_inc, SP_ld, SP_inc, SP_dec, WrBuf_sel} =    6'b0;
            {current_ISR_num_ld, ISR_ld, ISR_clr, FS_Sel} = 4'b0;
            {Reg_In_sel, CPSR_sel, B_Sel, samt} =          15'b0;                
            {Mem_rd, Mem_wr, Mem_cs} =                      3'b1_1_1;   
            {IO_rd, IO_wr, IO_cs} =                         3'b1_1_1;
            {F, I, change_flags} =                         {F,I,32'b0};
         
          @(posedge sys_clk)
   
            #1 $display("Time=%t M[%h] = %h        ||        M[%h] =%h", 
                        $time,   10'h3E0+n, io2.memarray[10'h3E0+n],
                        10'h3F0+n, io2.memarray[10'h3F0+n]);            
         end
      end

    endtask         
   
endmodule
   

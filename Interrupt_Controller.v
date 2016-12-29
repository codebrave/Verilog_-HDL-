`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:     Computer Engineering
// Author:       Jonalbert Encina & Stephen McCallum
// Create Date:  09:29:36 10/22/2013 
// Email:        kaboomultimate@yahoo.com
// Module Name:  Interrupt_Controller.v 
// Project Name: Senior Project
// Description:  The Inteterrupt Controller is a structural implementation that 
//               instantiates the ISR, current_ISR, priority_6_to_3_encoder, 
//               decoder_current_ISR, and other modules that interconnect with 
//               it. The Interrupt Controller controls all of the inputs from
//               the IO (Input/Output) modules that send out a fast or normal 
//               interrupt request. Each encoder and decoder control the 
//               interrupt requests from a high to a low priority. The ISR 
//              (Interrupt Service Routine) regsiter is used to determine which
//               interrupt request being serviced while the current_ISR register
//               tells which IO module is being serviced. If an IO is servicing 
//               its normal interrupt request, it cannot request its own fast 
//               interupt request since it is servicing the normal interrupt 
//               request. If the IO services its fast interrupt request, then 
//               the IO cannot interrupt its own device with a normal interrupt
//               request while the fast interrupt is in its service routine. 
//               Once an IO services its own normal interrupt or fast interrupt
//               request, then the IO can interrupt the CPU once it completes
//               its interrupt service routine. The Next_ISR_reg module holds
//               one of the interrupt requests and lets that interrupt go next
//               after that interrupt completes its service routine.  
//
//           
//////////////////////////////////////////////////////////////////////////////////
module Interrupt_Controller(clk, reset,fintr_check, intr_check, ISR_ld, ISR_clr,
                            intr_Out, IO_Enable, current_ISR_num_ld);
                               
  input        clk, reset, ISR_ld, ISR_clr, current_ISR_num_ld;
  input  [2:0] fintr_check, intr_check;
  output [2:0] IO_Enable;  
  output [5:0] intr_Out;    
  wire   [2:0] encoder_data_out, encoder_next_ISR_Out, decoder_current_ISR_out;
  wire   [2:0] current_ISR_out, IO_Enable;
  wire   [5:0] intr_pend, intr_still_pend, next_ISR_In, next_ISR_Out;
  wire   [5:0] intr_Out, next_ISR_decoder_Out, ISR_out;
   
  wire [5:0] intr;
  

                           // clk, reset, ld,     clr,     Din,      Dout
  ISR                     isr(clk, reset, ISR_ld, ISR_clr, intr_Out, ISR_out);
  
                           // clk, reset, ld,                                     
  current_ISR            cisr(clk, reset, current_ISR_num_ld, 

                           // Din,                     Dout
                              decoder_current_ISR_out, current_ISR_out);

                           // Din,       D_out
  priority_6_to_3_encoder pen(intr_pend, encoder_data_out); 
  
                           // D_in,             D_out  
  decoder_current_ISR   dcisr(encoder_data_out, decoder_current_ISR_out);  
  
                           // D_in,             D_out,            
  decoder_3_to_6          d36(encoder_data_out, intr_still_pend, 
  
                           // intr[5],intr[4], intr[3],intr[2], intr[1],
                             {intr[0],intr[1], intr[2],intr[3], intr[4],

                           // intr[0],  ISR_In
                              intr[5]}, ISR_out);                  
   
                   // clk, reset,  ld,          clr,                           
  Next_ISR_reg  nxisr(clk, reset,  next_ISR_In, next_ISR_decoder_Out,  

                   // Din,         Dout
                      next_ISR_In, next_ISR_Out);
  
                             // D_in[5],         D_in[4],         
  priority_6_to_3_encoder penx({next_ISR_Out[0], next_ISR_Out[1], 

                             // D_in[3],         D_in[2],
                                next_ISR_Out[2], next_ISR_Out[3],
  
                             // D_in[1],         D_in[0],            
                                next_ISR_Out[4], next_ISR_Out[5]}, 
                           
                             // D_out     
                                encoder_next_ISR_Out); 

                             // D_in,                  D_out[5],                  
  decoder_3_to_6_next_ISR decnx(encoder_next_ISR_Out, {next_ISR_decoder_Out[0], 
  
                             // D_out[4],
                                next_ISR_decoder_Out[1],   
  
                             // D_out[3],                D_out[2],
                                next_ISR_decoder_Out[2], next_ISR_decoder_Out[3],

                             // D_out[1],                D_out[0],                 
                                next_ISR_decoder_Out[4], next_ISR_decoder_Out[5]}, 
                                
                             // ISR_In  
                                ISR_out); 

  // These check if the one of the interrupts on the IO modules use one 
  // interrupt request. If one of the IO modules is servicing one interrupt
  // request, then that IO cannot make another second interrupt request that 
  // could be a normal or fast interrupt. The ISR register's output controls
  // and lets the IO modules only service one interrupt request at a time, but 
  // not two. ISR_out[5:3] indicates that one of the normal interrupts is being 
  // serviced whereas ISR_out[2:0] signifies that one of the fast interrupt 
  // requests is being serviced. Each IO module have their own normal and fast 
  // interrupt request.
  assign intr_pend[5] = (fintr_check[0]) ? (ISR_out[3] ? 1'b0 : 1'b1):1'b0; 
  assign intr_pend[4] = (fintr_check[1]) ? (ISR_out[4] ? 1'b0 : 1'b1):1'b0; 
  assign intr_pend[3] = (fintr_check[2]) ? (ISR_out[5] ? 1'b0 : 1'b1):1'b0;  
  assign intr_pend[2] = (intr_check[0])  ? (ISR_out[0] ? 1'b0 : 1'b1):1'b0;
  assign intr_pend[1] = (intr_check[1])  ? (ISR_out[1] ? 1'b0 : 1'b1):1'b0;  
  assign intr_pend[0] = (intr_check[2])  ? (ISR_out[2] ? 1'b0 : 1'b1):1'b0;  
 
  // If one of the IO modules send out an interrupt request while their 
  // interrupt is in service and their interrupt request matches to the 
  // one that is being serviced, then that interrupt that is currently being 
  // serviced will interrupt the CPU after the interrupt has completed its
  // service routine and the CPU has executed its next instruction. 
  assign {next_ISR_In[0]}=(intr_still_pend[5])?1'b1:1'b0; 
  assign {next_ISR_In[1]}=(intr_still_pend[4])?1'b1:1'b0; 
  assign {next_ISR_In[2]}=(intr_still_pend[3])?1'b1:1'b0; 
  assign {next_ISR_In[3]}=(intr_still_pend[2])?1'b1:1'b0;
  assign {next_ISR_In[4]}=(intr_still_pend[1])?1'b1:1'b0; 
  assign {next_ISR_In[5]}=(intr_still_pend[0])?1'b1:1'b0;
  
  
  // intr_Out will get logical OR result of intr and next_ISR_decoder_Out which
  // will interrupt request the CPU. 
  assign intr_Out = ((intr | next_ISR_decoder_Out));

  // Let IO_Enable get current_ISR_out to enable one of the IO modules. 
  assign IO_Enable = current_ISR_out;

endmodule

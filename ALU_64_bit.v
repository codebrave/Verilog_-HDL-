`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:04:38 10/26/2013 
// Design Name: 
// Module Name:    ALU_64_bit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  This behavorial 64-bit ALU (Arithmetic Logical Unit) takes two 
//               64-bit inputs, R and S, and the outputs of the 64-bit result of 
//               one of the operations performed or both of these inputs. The 
//               operation that is being performed depends on the value of a 
//               5-bit selector, Alu_Op. If the Alu_Op value has a value greater 
//               than 5'b10100, the S input is passed to the Y output. The 
//               module also outputs three status flags: the C flag signifies          
//               that the Y output has a carry or a borrow associated with it;
//               the N flag shows that the Y result is a negative number
//               (meaning its most  significant bit is 1); and the the Z flag is 
//               asserted when the Y value is zero. The status flags that are not
//               affecting each operation will be low active (logical 0).  
//
//////////////////////////////////////////////////////////////////////////////////

module ALU_64_bit(R, S, Alu_Op, Y, C , N, Z, V);

  input  [63:0] R, S;
  input  [4:0]  Alu_Op;
  output        C, N, Z, V;  // Status Flags.
  output [63:0] Y;
  reg           C, N, Z, V;  // Status Flags.
  
  reg           divide_by_zero_flag; // This is a flag to indicate if the divsor
                                     // value is equal to 0.
  reg [1:0]mul_flag =0;
  reg    [63:0] Y;
  
              // Temporary registers to execute the MUL, MSW, DIV,
              // and REM operations. 
  reg    [127:0] variables, product_rg, remainder_rg; 
  integer n;
  
  always @(*)begin//(R,S,Alu_Op) begin
    case (Alu_Op)
	 
//************************************	
//      Arithmetic Operations
//************************************		 
		
             // INC (Increment) (Y = S + 1)
      5'b00000: begin
                  {C, Y} = S + 1; 
                  {N, V} = {Y[63], (S[63] ? 1'b0 :(Y[63] ? 1'b1 : 1'b0))};
                end 
					 
             // DEC (Decrement) (Y = S - 1)
      5'b00001: begin
                  {C, Y} = S - 1; 
                  {N, V} = {Y[63], (S[63] ? (Y[63] ? 1'b0 : 1'b1) : 1'b0)}; 
                end
					 
      5'b00010: begin //MUL (Multiply) (Y = R * S) 
		         
               // R is the multiplicand and S is the multiplier.     
               // Since the both the R and S inputs are 64-bits, the multiplied result
               // will be 128-bits.  					
						
               // Preprocess to determine if the R or S have a negative signed result 
               // and negate those results. Otherwise, they will not be negated.			
					if (mul_flag==0)begin//&&R==cpu.EU.idp.rg0.R&&(S==cpu.EU.idp.rg0.S))begin
                  case ({R[63], S[63]})  
                    2'b00:   {variables[127:64], variables[63:0]} = {R,   S};
                    2'b01:   {variables[127:64], variables[63:0]} = {R,   0-S};
                    2'b10:   {variables[127:64], variables[63:0]} = {0-R, S};
                    2'b11:   {variables[127:64], variables[63:0]} = {0-R, 0-S};			
                    default: {variables[127:64], variables[63:0]} = {R,   S};						  
                  endcase
						
               // Initialize the product register. 
                  product_rg = {64'b0, variables[63:0]};
                
               // Doing this loop 64 times will stop the process. 
                  for (n=0; n < 64; n = n+1) begin
					  
                  // If the least significant bit of the product 
                  // register is high active, the multiplicand adds
                  // to the left half of the product register and 
                  // the result is placed into the left half
                  // of the product register. Otherwise, shift the
                  // product register to the right once.
						
                    if(product_rg[0] == 1'b1) begin
						 
                    product_rg[127:64] = product_rg[127:64] + variables[127:64]; 
							
                    end // end of if
						 
                    // Shift product register to the right once. 
                    product_rg = product_rg >> 1;
						                   				 
                  end // end of for loop
					  
                  // If both of the R and S signed bits are different, the 
                  // product result becomes negated (2's complement). 
                  if (R[63] ^ S[63] == 1'b1) begin
						
                    product_rg = ~product_rg +1;
						  
                  end // end of if 
					//	 product_rg = R*S;
               // Since the product register is a 128-bit result, the negative 
               // flag will get its signed bit and the zero flag will assert 
               // if the whole 128-bit result is 0.  					
                  {C, Y, N} = {1'b0, product_rg[63:0], product_rg[127]};
                   Z = (product_rg == 128'b0) ? 1'b1:1'b0;
						 mul_flag = 1;
					 end
					else if (mul_flag==1&&S==cpu.EU.biu.IR_SignExt)begin//&&R==cpu.EU.idp.rg0.R)begin
                  case ({R[63], S[63]})  
                    2'b00:   {variables[127:64], variables[63:0]} = {R,   S};
                    2'b01:   {variables[127:64], variables[63:0]} = {R,   0-S};
                    2'b10:   {variables[127:64], variables[63:0]} = {0-R, S};
                    2'b11:   {variables[127:64], variables[63:0]} = {0-R, 0-S};			
                    default: {variables[127:64], variables[63:0]} = {R,   S};						  
                  endcase
						
               // Initialize the product register. 
                  product_rg = {64'b0, variables[63:0]};
                
               // Doing this loop 64 times will stop the process. 
                  for (n=0; n < 64; n = n+1) begin
					  
                  // If the least significant bit of the product 
                  // register is high active, the multiplicand adds
                  // to the left half of the product register and 
                  // the result is placed into the left half
                  // of the product register. Otherwise, shift the
                  // product register to the right once.
						
                    if(product_rg[0] == 1'b1) begin
						 
                    product_rg[127:64] = product_rg[127:64] + variables[127:64]; 
							
                    end // end of if
						 
                    // Shift product register to the right once. 
                    product_rg = product_rg >> 1;
						                   				 
                  end // end of for loop
					  
                  // If both of the R and S signed bits are different, the 
                  // product result becomes negated (2's complement). 
                  if (R[63] ^ S[63] == 1'b1) begin
						
                    product_rg = ~product_rg +1;
						  
                  end // end of if 
					//	 product_rg = R*S;
               // Since the product register is a 128-bit result, the negative 
               // flag will get its signed bit and the zero flag will assert 
               // if the whole 128-bit result is 0.  					
                  {C, Y, N, V} = {1'b0, product_rg[63:0], product_rg[127], 1'b0};
                   Z = (product_rg == 128'b0) ? 1'b1:1'b0;
						 mul_flag = 2;
					 end				 
					 else begin 
					   {C, Y, N, V, Z} = {C, Y, N, V, Z};
					    product_rg = product_rg;
					 end 

                end	 
					 
                // MSW ( Y = Most Significant Word of the multiplied result.)
      5'b00011: begin
		            if (mul_flag==1||mul_flag==2) begin
                  {C, Y, N, V} = {1'b0, product_rg[127:64], product_rg[127], 1'b0};
                   Z = (product_rg == 128'b0) ? 1'b1:1'b0;
                  mul_flag = 0;						 
						end 
						
                end		 
					 
		          // DIV (Divide) ( Y = R / S) Return the quotient.
      5'b00100: begin  
		
               // R is the dividend and S is the divisor. 
		     
               // If the divisor value is not equal to 0, then the division 
               // process will execute. Otherwise, the division process will 
               // be skipped and output a high z state.  
                  if (S != 63'b0) begin
						
                 // Clear the divide_by_zero_flag to 0;
                    divide_by_zero_flag = 0;
						  
               // Preprocess to determine if the R or S have a negative signed result 
               // and negate those results. Otherwise, they will not be 
               // negated.						
						
                    case ({R[63], S[63]})  
                      2'b00:   {variables[127:64], variables[63:0]} = {R,   S};
						    2'b01:   {variables[127:64], variables[63:0]} = {R,   0-S};
                      2'b10:   {variables[127:64], variables[63:0]} = {0-R, S};
                      2'b11:   {variables[127:64], variables[63:0]} = {0-R, 0-S};			
                      default: {variables[127:64], variables[63:0]} = {R,   S};						  
                    endcase
							
                 // The Dividend is placed into the lower half of the remainder
                 // register while the higher half is filled with 64-bits of 
                 // 0's.					  
                    remainder_rg = {64'b0, variables[127:64]};
						  
                 // Shift the remainder register to the left once.   
                    remainder_rg = remainder_rg << 1;
						  
                 // Doing this for loop 64 times will stop the process. 
                    for (n = 0; n < 64; n = n + 1) begin
						
                   // The left half of the remainder register is subtracted with the
                   // Divisor and the result is placed back into the left half of the
                   // remainder register. 
                      remainder_rg[127:64] = remainder_rg[127:64] - variables[63:0]; 
							 
						
                      if (remainder_rg[127] == 1'b1) begin
						  
                     // Restore the original value by adding left half of the remainder
                     // register with the divisor and place the result back to the 
                     // left half of the remainder register. 
                        remainder_rg[127:64] = remainder_rg[127:64] + variables[63:0]; 
							 
                     // Shift the remainder register to the left once
                     // and make its least significant bit low active.
						   
                        remainder_rg = remainder_rg << 1;
                        remainder_rg[0] = 1'b0;
							 
                      end // end of if						  
						
                      else begin
						  
                   // Shift the remainder register to left once and
                   // and make its least significant bit high active.
                      remainder_rg = remainder_rg << 1;
                      remainder_rg[0] = 1'b1;
						  
                      end // end of else
						  
						
                    end // end of for loop
						
						
                    // Shift the left half  of the remainder register 
                    // to the right once. 						  
                    remainder_rg[127:64] = remainder_rg[127:64] >> 1;
						
                    // If both of the R and S signed bits are different, the 
                    // lower half of the remainder register becomes 
                    // negated (2's complement).
						
                    if (R[63] ^ S[63] == 1'b1) begin
						
                      remainder_rg[63:0] = ~remainder_rg[63:0] + 1;
						  
                    end // end of if  
						
                    // The negative flag will get the signed bit result from
                    // the quotient and the zero flag will set to 1 if the 
                    // whole remainder register is a 0. 
                      {C, Y, N, V} = {1'b0, remainder_rg[63:0], remainder_rg[63],1'b0};
                       Z = (remainder_rg == 128'b0) ? 1'b1 : 1'b0;
							 
                  end // end of if (S != 63'b0)
						
                  else begin
						
                     remainder_rg = 128'bz;
                    {C, Y, N, V, Z} = {1'b0, remainder_rg[63:0], 1'b0, 1'b1, 1'b0};
						  
                  // Set the divide_by_zero_flag to 1 since the divisor value
                  // is equal to 0. 
                     divide_by_zero_flag = 1'b1; 
							
                  end // end of else
						
                end
					 
      5'b00101: begin // REM (Y = Remainder of the division result.)
		
                   // If the divide_by_zero_flag is high active, the output
                   // will display a high z state. Otherwise the flag will 
                   // display a the left half result of the remainder register
                   // since the dividend was not divided by zero.  
						 
                   if (divide_by_zero_flag == 1'b1 ) begin
						 
                     {C, Y, N, V, Z} = {1'b0, remainder_rg[127:64], 1'b0, 1'b1, 1'b0};
							
                   end // end of if
						 
                   else begin

                     {C, Y, N, V} = {1'b0, remainder_rg[127:64], remainder_rg[63], 1'b0};
                      Z = (remainder_rg == 128'b0) ? 1'b1 : 1'b0;						
						 
                   end // end of else
						 
                end		
		
      5'b00110: begin // ADD (Add) Y = R + S
		
                   {C, Y} = R + S;
                   {N, V} = {Y[63], (~R[63] & S[63]& Y[63]| R[63]& ~S[63] & ~Y[63])};

                 end		
					  
      5'b00111: begin // SUB (Subtract) Y = R - S
		
                   {C, Y} = R - S;
                   {N, V} = {Y[63],(~R[63] & S[63]& Y[63]| R[63]& ~S[63] & ~Y[63])};

                 end		
	
//************************************	
//      Logical Operations
//************************************	
	
      // AND    (Logical And)   (Y = R & S)
      5'b01000: begin 
                  {C, Y} = {1'b0, R & S};
                  {N, V} = {Y[63], 1'b0};
                end
      // OR     (Logical Or)    (Y = R | S)
      5'b01001: begin
                  {C, Y} = {1'b0, R | S};
                  {N, V} = {Y[63], 1'b0};		
                end
      // XOR    (Logical Xor)   (Y = R ^ S)
      5'b01010: begin 
                  {C, Y} = {1'b0, R ^ S};
                  {N, V} = {Y[63], 1'b0};		
                end
      // NOT    (1's Complement)(Y = ~S)
      5'b01011: begin 
                 {C, Y} = {1'b0, ~S};
                 {N, V} = {Y[63], 1'b0};
                end						
		
      // NEGATE (2's Complement)(Y = ~S + 1)
      5'b01100: begin
		
                  {C, Y} = {1'b0, ~S+1};
                  {N, V} = {Y[63],(S[63]& Y[63]| ~S[63] & ~Y[63])};
						
                end           

//************************************	
//      Other Operations
//************************************			

      5'b01101: begin // LSHL (Logical Shift Left) 
		
      // Logical Shift Left shifts the binary values to the
      // left while the most significant bit gets moved to
      // the carry bit. 		
                 {C, Y}= {S[63], S << 1};	
                 {N, V} = {Y[63], 1'b0};
						  
                end		
					 
      5'b01110: begin // LSHR (Logical Shift Right)

      // Logical Shift Right shifts the binary values to the
      // right while the least significant bit gets moved to
      // the carry bit. 	
		
                 {C, Y} = {S[0], S >> 1};
                 {N, V} = {Y[63], 1'b0};
						  
                end		

      5'b01111: begin // ASHL (Artihmetic Shift Left)

      // Arithmetic Shift Left shifts the binary values to the
      // left while the 2nd most significant bit gets moved to
      // the carry bit. The signed bit (most significant bit)
      // will stay the same. 		
                 {C, Y, N} = {S[63], {S[63], S[61:0], 1'b0}, S[63]};
                  V = {S[63] ^ S[62]};
					  
                end		

      5'b10000: begin // ASHR (Artihmetic Shift Right)
		
      // Arithmetic Shift Right shifts the binary values to the
      // left while the least significant bit gets moved to
      // the carry bit. The signed bit (most significant bit)
      // will stay the same. 		
		            
                 {C, Y, N, V} = {S[0], S[63], S[63:1], S[63], 1'b0}; 
                    
					  
                end		
					
      // ZEROS  (Y = 0x0000_0000_0000_0000)	
      5'b10001: begin
                  {C, Y} = {1'b0, 64'b0};
                  {N, V} = {Y[63], 1'b0};
                end
					 
      // ONES   (Y = 0xFFFF_FFFF_FFFF_FFFF)
      5'b10010: begin
                  {C, Y} = {1'b0, 64'hffff_ffff_ffff_ffff};
                  {N, V} = {Y[63], 1'b0};		
		          end
					 
		// PASS R (Y = R)
		5'b10011: begin
                  {C, Y, N, V} = {1'b0, R, R[63], 1'b0};
                   
                end	
					 
      // PASS S (Y = S)
      5'b10100: begin 
                  {C, Y, N, V} = {1'b0, S, S[63],1'b0};
                   
                   end  
//ENHANCED INSTRUCTIONS		
      // NAND Y = ~(R & S)
      5'b10101: begin 
                  {C, Y} = {1'b0, ~(R & S)};
                  {N, V} = {Y[63], 1'b0};
                end
		// NOR  Y = ~(R|S)
      5'b10110: begin 
                  {C, Y} = {1'b0, ~(R|S)};
                  {N, V} = {Y[63], 1'b0};
                end
      // XNOR Y = ~(R^S)
      5'b10111: begin 
		            {C, Y} = {1'b0, ~(R ^ S)};
		            {N, V} = {Y[63], 1'b0};
                end
					 
		// ROR
      5'b11000: begin 
                  {C, Y} = {S[0], S[0], S[63:1]};
						{N, V} = {Y[63], 1'b0};
                end
      // ROL
      5'b11001: begin
                  {C, Y} = {S[63], S[62:0], S[63]};
                  {N, V} = {Y[63], 1'b0};
                end
					
      default: {C, Y, N, V} = {1'b0, S, S[63], 1'b0};
		         
    endcase // end of case (Alu_Op)
	 
	 // Handle the last status flag (Zero flag).
	 
	 // This will execute if the ALU Opcode is not equal
	 // to the value of the MUL, MSW, DIV, and REM operations.
    if (Alu_Op != 5'b00010 && Alu_Op!=5'b00011 && 
        Alu_Op!=5'b00100 && Alu_Op!=5'b00101) begin
	      
     Z= (Y == 64'b0) ? 1'b1 : 1'b0;
	  
    end // end of if	  
	 
  end // end of always @(R,S,Alu_Op)
  
endmodule




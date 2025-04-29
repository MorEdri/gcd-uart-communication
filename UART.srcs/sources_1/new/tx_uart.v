`timescale 1ns / 1ps

module tx_uart(
   input clk,
   input Tx_Data_Valid, //ask request to transmit 
   input [7:0] Tx_Byte, //Byte to trasmit
   output Tx_Active, //trasmitter is busy 
   output reg Tx_Serial, //Serial Line
   output Tx_Done //Tx_done will be driven high for one clock cycle when transmit is complete.
    );
  parameter CLKS_PER_BIT = 87;
  
  parameter IDLE = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT = 3'b011;
  parameter CLEAN = 3'b100;
  
  reg [2:0] current_state = 0;
  reg [7:0] Clock_Count = 0;
  reg [2:0] Bit_Position = 0;
  reg [7:0] Tx_Data = 0;
  reg r_Tx_Done = 0;
  reg r_Tx_Active = 0;
  
  always @(posedge clk) begin
    case(current_state) 
        IDLE : begin 
            Tx_Serial <= 1'b1;
            r_Tx_Done <= 1'b0;
            Clock_Count <= 0;
            Bit_Position <= 0;
         
             
            if (Tx_Data_Valid == 1'b1) begin
                r_Tx_Active <= 1'b1;
                Tx_Data <= Tx_Byte;
                current_state <= TX_START_BIT;
            end else //if Tx_Data_Valid == 0
                current_state <= IDLE;
        end
        
        // Send out Start Bit. Start bit = 0
        TX_START_BIT : begin
            Tx_Serial <= 1'b0;
            
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (Clock_Count < CLKS_PER_BIT-1) begin
                Clock_Count <= Clock_Count + 1;
                current_state <= TX_START_BIT;
            end else begin // if Clock_Count == CLKS_PER_BIT-1
                Clock_Count <= 0;
                current_state <= TX_DATA_BITS;
            end
        end
        
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish 
        TX_DATA_BITS : begin 
            Tx_Serial <= Tx_Data[Bit_Position];
            
            if (Clock_Count < CLKS_PER_BIT-1) begin
                Clock_Count <= Clock_Count + 1;
                current_state <= TX_DATA_BITS;
            end else begin //if (Clock_Count == CLKS_PER_BIT-1)
                Clock_Count <= 0;
                
                // Check if we have sent out all bits
                if (Bit_Position < 7) begin
                    Bit_Position <= Bit_Position +1;
                    current_state <= TX_DATA_BITS;
                end else begin //if Bit_Position == 7
                    Bit_Position <= 0;
                    current_state <= TX_STOP_BIT;
                end
            end
           end
           
           TX_STOP_BIT : begin
             // Send out Stop bit.  Stop bit = 1
            Tx_Serial <= 1'b1;
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (Clock_Count < CLKS_PER_BIT-1) begin
                Clock_Count <= Clock_Count + 1;
                current_state <= TX_STOP_BIT;
            end else begin
                r_Tx_Done <= 1;
                Clock_Count <= 0;
                current_state <= CLEAN;
                r_Tx_Active <= 1'b0;
            end
           end
           
           CLEAN : begin 
            r_Tx_Done <= 1'b1;
            current_state <= IDLE;
           end
           
           default : current_state <= IDLE;
    
    endcase
  end
  
  assign Tx_Done = r_Tx_Done;
  assign  Tx_Active = r_Tx_Active;
  
endmodule

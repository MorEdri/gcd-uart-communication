`timescale 1ns / 1ps

module rx_uart
    (input clk,
     input Rx_Serial,
     output Rx_Data_Valid, //we get fixed word of 8 bits
     output [7:0] Rx_Byte
    );
    
  parameter CLKS_PER_BIT = 87; // how much it takes to read one bit 
  
  parameter IDLE = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEAN = 3'b100;
  
  reg first_Rx_Data = 1'b1;
  reg final_Rx_Data = 1'b1;
  
  reg [7:0] Clock_Count = 0;
  reg [2:0] Bit_Position = 0; //8 bits total
  reg [7:0] r_Rx_Byte = 0;
  reg r_Rx_Data_Valid = 0;
  reg [2:0] current_state = 0;
  
  //removes problems caused by metastability
  always @(posedge clk) begin 
      first_Rx_Data <= Rx_Serial;
      final_Rx_Data <= first_Rx_Data;
  end
  
  always @(posedge clk) begin 
    case(current_state)
    
        IDLE: begin
            Clock_Count <= 0;
            r_Rx_Data_Valid <= 0;
            Bit_Position <= 0;
            
            if (final_Rx_Data == 1'b0) //start bit detected
                current_state <= RX_START_BIT;
            else 
                current_state <= IDLE;
        end
        
        RX_START_BIT : begin
            if (Clock_Count == (CLKS_PER_BIT-1)/2) begin
                if (final_Rx_Data == 1'b0) begin
                    Clock_Count <= 0;
                    current_state <= RX_DATA_BITS;
                end else //start bit still not detected
                    current_state <= IDLE;
            end else begin // Clock_Count != (CLKS_PER_BIT-1)/2
                Clock_Count <= Clock_Count + 1;
                current_state <= RX_START_BIT;
            end
        end
    
        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        RX_DATA_BITS : begin
            if (Clock_Count < CLKS_PER_BIT - 1) begin
                Clock_Count <= Clock_Count + 1;
                current_state <= RX_DATA_BITS;
            end else begin //if Clock_Count == CLKS_PER_BIT - 1
                Clock_Count <= 0;
                r_Rx_Byte[Bit_Position] <= final_Rx_Data;
            
            
            if (Bit_Position < 7) begin
                Bit_Position <= Bit_Position + 1;
                current_state <= RX_DATA_BITS;
            end else begin //if Bit_Position == 7
                Bit_Position <= 0;
                current_state <= RX_STOP_BIT;
                end
            end
        end
        
        //receive Stop bit
        RX_STOP_BIT : begin
            //wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (Clock_Count < CLKS_PER_BIT - 1) begin
                Clock_Count <= Clock_Count + 1;
                current_state <= RX_STOP_BIT;
            end else begin // if Clock_Count == CLKS_PER_BIT - 1
                r_Rx_Data_Valid <= 1;
                Clock_Count <= 0;
                current_state <= CLEAN;
            end
        end
            
       CLEAN : begin
           current_state <= IDLE;
           r_Rx_Data_Valid <= 0;
       end 
        
       default : current_state <= IDLE;
    
    endcase
  end
  
  assign Rx_Data_Valid = r_Rx_Data_Valid;
  assign Rx_Byte = r_Rx_Byte;

endmodule

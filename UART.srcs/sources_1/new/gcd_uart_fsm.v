`timescale 1ns / 1ps

module gcd_uart_fsm(
    input clk,
    input reset,
    input Rx_Data_Valid,
    input [7:0] Rx_Byte,
    output reg [7:0] Tx_Byte,
    output reg Tx_Data_Valid,
    input Tx_Done,
    output reg [7:0] a,
    output reg [7:0] b,
    output reg start_gcd,
    input done_gcd,
    input [7:0] gcd_result
    );
    
   reg [2:0] state;
   parameter IDLE = 3'b000;
   parameter GOT_A = 3'b001;
   parameter GOT_B = 3'b010;
   parameter START_GCD = 3'b011;
   parameter WAIT_GCD = 3'b100;
   parameter SEND_GCD = 3'b101;
   
   reg rx_data_valid_prev;
  
   
   // Detect rising edge of Rx_Data_Valid
   wire rx_data_valid_rise = Rx_Data_Valid && !rx_data_valid_prev;

   always @(posedge clk or posedge reset) begin 
    if (reset) begin
        state <= IDLE;
        a <= 0;
        b <= 0;
        Tx_Data_Valid <= 0;
        Tx_Byte <= 0;
        start_gcd <= 0;
        rx_data_valid_prev <= 0;
    end else begin
        Tx_Data_Valid <= 0;
        start_gcd <= 0;
        rx_data_valid_prev <= Rx_Data_Valid;
        
   // rx_data_valid_prev <= Rx_Data_Valid;
        
    case(state)
        IDLE: begin
            if (rx_data_valid_rise) begin
                a <= Rx_Byte;
                state <= GOT_A;
            end
        end
        GOT_A: begin
            if (rx_data_valid_rise) begin
                b <= Rx_Byte;
                state <= GOT_B;
                  end
        end
        
        GOT_B: begin
                 state <= START_GCD;
          end
          
        START_GCD: begin
                    start_gcd <= 1;
                    state <= WAIT_GCD;
                end
                
         WAIT_GCD: begin
                    if (done_gcd) begin
                        state <= SEND_GCD;
                    end
                  end
        SEND_GCD: begin
            if (!Tx_Data_Valid && !Tx_Done) begin
                        Tx_Byte <= gcd_result;
                        Tx_Data_Valid <= 1;
                    end else if (Tx_Done) begin
                        Tx_Data_Valid <= 0;
                        state <= IDLE;
                    end
                end
    endcase
   end
  end

initial begin
     $display("FSM Initialized: Waiting for first byte...");
   end
  
endmodule

`timescale 1ns / 1ps

module uart_tb();

  parameter CLOCK_PERIOD_NS = 100;
  parameter CLKS_PER_BIT = 87;
  parameter BIT_PERIOD = 8600;
   
  reg clk = 0;
  reg Tx_Data_Valid = 0;
  wire Tx_Done;
  reg [7:0] Tx_Byte = 0;
  wire Rx_Serial;
  
  wire [7:0] Rx_Byte;
   
  wire Tx_Serial;
  wire Rx_Data_Valid;
   
  rx_uart RX_UART_INST
    (.clk(clk),
     .Rx_Serial(Rx_Serial),
     .Rx_Data_Valid(Rx_Data_Valid),
     .Rx_Byte(Rx_Byte)
     );
   
  tx_uart TX_UART_INST
    (.clk(clk),
     .Tx_Data_Valid(Tx_Data_Valid),
     .Tx_Byte(Tx_Byte),
     .Tx_Active(),
     .Tx_Serial(Tx_Serial),
     .Tx_Done(Tx_Done)
     );
  /*
  always @(posedge clk) begin
    Rx_Serial <= Tx_Serial;
  end
   */
   assign Rx_Serial = Tx_Serial;
   
  always
    #(CLOCK_PERIOD_NS/2) clk <= !clk;

  always @(posedge clk) begin
    $display("Time: %0t | Tx_Done: %b | Tx_Serial: %b | Tx_Active: %b | Rx_Serial: %b, Rx_Byte : %b", $time, Tx_Done, Tx_Serial, TX_UART_INST.Tx_Active,Rx_Serial,Rx_Byte);
  end
  // Main Testing:
  initial begin

       
      // Tell UART to send a command (exercise Tx)
      // waiting for stabiltity
      @(posedge clk);
      @(posedge clk);
      
      Tx_Byte <= 8'h3F;
      Tx_Data_Valid <= 1'b1; // start transmit
      @(posedge clk);
      Tx_Data_Valid <= 1'b0;
      // waiting for termination of trasmit
      wait(Tx_Done); 
      wait(Rx_Data_Valid); 
     
      // Check that the correct command was received
      if (Rx_Byte == 8'h3F)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
    
    #1000000;
    $finish;   
    end
     
endmodule

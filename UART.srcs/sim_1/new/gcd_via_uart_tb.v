`timescale 1ns / 1ps
module gcd_via_uart_tb();
  parameter CLOCK_PERIOD_NS = 100;
  parameter CLKS_PER_BIT = 87;
  parameter BIT_PERIOD = 8700;
   
  reg clk = 0;
  reg Tx_Data_Valid = 0;
  wire Tx_Done;
  reg [7:0] Tx_Byte = 0;
  reg Rx_Serial = 1;
  
  wire [7:0] Rx_Byte;
  wire Tx_Serial;
  wire Rx_Data_Valid;
  
  reg [7:0] a = 0;
  reg [7:0] b = 0;
  reg reset = 1;
  wire [7:0] gcd_result;
  
  // Debug signals
  reg received_first_byte = 0;
  reg received_second_byte = 0;
  reg [7:0] debug_rx_byte = 0;
  reg debug_rx_valid = 0;
   
  rx_uart RX_INST
    (.clk(clk),
     .Rx_Serial(Rx_Serial),
     .Rx_Data_Valid(Rx_Data_Valid),
     .Rx_Byte(Rx_Byte)
     );
   
  gcd GCD_INST
    (.a(a),
     .b(b),
     .clk(clk),
     .reset(reset),
     .gcd_result(gcd_result)
     );
     
  tx_uart TX_INST
    (.clk(clk),
     .Tx_Data_Valid(Tx_Data_Valid),
     .Tx_Byte(Tx_Byte),
     .Tx_Active(),
     .Tx_Serial(Tx_Serial),
     .Tx_Done(Tx_Done)
     );
 
  // Clock generator
  always
    #(CLOCK_PERIOD_NS/2) clk <= ~clk;

  // Monitor rx_data_valid for debug
  always @(posedge clk) begin
    debug_rx_valid <= Rx_Data_Valid;
    debug_rx_byte <= Rx_Byte;
    
    // Debug output for important signals
    if (Rx_Data_Valid)
      $display("Time: %0t, Rx_Data_Valid = 1, Rx_Byte = %d", $time, Rx_Byte);
      
    if (a != 0 || b != 0)
      $display("Time: %0t, a = %d, b = %d, gcd_result = %d", $time, a, b, gcd_result);
  end

  // Monitor receiver state when data valid
  always @(posedge Rx_Data_Valid) begin
    $display("Rx_Data_Valid asserted at time %0t, Rx_Byte = %d", $time, Rx_Byte);
  end

  // Capturing received data for a and b
  always @(posedge clk) begin
    if (Rx_Data_Valid && !received_first_byte) begin
      a <= Rx_Byte;
      received_first_byte <= 1;
      $display("CAPTURED a = %d at time %0t", Rx_Byte, $time);
    end
    else if (Rx_Data_Valid && received_first_byte && !received_second_byte) begin
      b <= Rx_Byte;
      received_second_byte <= 1;
      $display("CAPTURED b = %d at time %0t", Rx_Byte, $time);
    end
  end

  // Func to send bytes
  task send_byte;
    input [7:0] data;
    integer i;
    begin
      $display("Sending byte %d at time %0t", data, $time);
      // Start bit
      Rx_Serial <= 0;
      #(BIT_PERIOD);
      
      // Send 8 bits, LSB first
      for (i = 0; i < 8; i = i + 1) begin
        Rx_Serial <= data[i];
        $display("Sending bit %0d: %b", i, data[i]);
        #(BIT_PERIOD);
      end
      // Stop bit
      Rx_Serial <= 1;
      #(BIT_PERIOD);
      
      // Add extra delay to ensure the receiver has processed the byte
      #(BIT_PERIOD);
    end
  endtask

  // Main Testing:
  initial begin
    $display("Starting Simulation at time %0t", $time);
    Rx_Serial = 1;
    reset = 1;
    #(CLOCK_PERIOD_NS * 10);
    reset = 0; 
    #(BIT_PERIOD * 2);
    
    // First byte - for 'a'
    $display("Sending a = 4...");
    send_byte(8'd4);
    
    // Add delay between bytes
    #(BIT_PERIOD * 3);
    
    // Make sure we have time to receive the first byte
    if (!received_first_byte) begin
      $display("WARNING: First byte not received yet. Waiting...");
      wait(received_first_byte);
    end
    
    // Second byte - for 'b'
    $display("Sending b = 8...");
    send_byte(8'd8);
    
    // Wait for second byte to be received
    wait(received_second_byte);
    $display("Both bytes received, a = %d, b = %d", a, b);
    
    // Apply reset after both values are received to restart GCD calculation
    $display("Applying reset to restart GCD calculation");
    reset = 1;
    repeat (5) @(posedge clk);
    reset = 0;
    
    // Allow time for GCD calculation
    $display("Waiting for GCD calculation...");
    repeat (200) @(posedge clk);
    $display("GCD result = %d", gcd_result);
    
    // Send result back via UART
    Tx_Byte = gcd_result;
    Tx_Data_Valid = 1;
    @(posedge clk);
    Tx_Data_Valid = 0;
    
    // Wait for transmission to complete
    wait(Tx_Done);
    $display("Transmission complete at time %0t", $time);
    
    // Additional time to observe waveforms
    #(BIT_PERIOD * 10);
    $finish;
  end
endmodule

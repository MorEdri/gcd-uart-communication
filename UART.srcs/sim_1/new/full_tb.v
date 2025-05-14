`timescale 1ns / 1ps

module full_tb();

  // Clock and UART parameters
  parameter CLOCK_PERIOD_NS = 100;     // 10 MHz
  parameter CLKS_PER_BIT    = 87;      // 10 MHz / 115200
  parameter BIT_PERIOD      = 8600;

  reg clk = 0;
  reg reset = 1;

  // UART TX to FSM
  wire Tx_Data_Valid_to_fsm;
  wire [7:0] Tx_Byte_to_fsm;
  wire Tx_Serial;
  wire Tx_Done_tb;
  wire Tx_Done_fsm;

  // FSM to UART RX
  wire Rx_Data_Valid;
  wire [7:0] Rx_Byte;
  wire Rx_Serial;

  // FSM <-> GCD
  wire [7:0] a, b;
  wire start_gcd;
  wire done_gcd;
  wire [7:0] gcd_result;

  // FSM to TX_UART (output)
  wire [7:0] Tx_Byte_from_fsm;
  wire Tx_Data_Valid_from_fsm;
  
  reg [7:0] Tx_Byte_reg = 0;
  reg Tx_Data_Valid_reg = 0;
  assign Tx_Byte_to_fsm = Tx_Byte_reg;
  assign Tx_Data_Valid_to_fsm = Tx_Data_Valid_reg;
  
  // UART Rx manual monitor for debug
  reg [7:0] rx_byte_monitor = 0;
  reg rx_data_valid_monitor = 0;
  always @(posedge clk) begin
    rx_byte_monitor <= Rx_Byte;
    rx_data_valid_monitor <= Rx_Data_Valid;
  end
  
    
  // UART Transmitter (simulates input bytes)
  tx_uart TX_UART (
    .clk(clk),
    .Tx_Data_Valid(Tx_Data_Valid_to_fsm),
    .Tx_Byte(Tx_Byte_to_fsm),
    .Tx_Active(),
    .Tx_Serial(Tx_Serial),
    .Tx_Done(Tx_Done_tb)
  );

  // UART Receiver (connected to FSM input)
  rx_uart RX_UART (
    .clk(clk),
    .Rx_Serial(Tx_Serial),   // TX output → RX input
    .Rx_Data_Valid(Rx_Data_Valid),
    .Rx_Byte(Rx_Byte)
  );

  // FSM
  gcd_uart_fsm FSM (
    .clk(clk),
    .reset(reset),
    .Rx_Data_Valid(Rx_Data_Valid),
    .Rx_Byte(Rx_Byte),
    .Tx_Byte(Tx_Byte_from_fsm),
    .Tx_Data_Valid(Tx_Data_Valid_from_fsm),
    .Tx_Done(Tx_Done_fsm),
    .a(a),
    .b(b),
    .start_gcd(start_gcd),
    .done_gcd(done_gcd),
    .gcd_result(gcd_result)
  );

  // GCD Unit
  gcd GCD_INST (
    .a(a),
    .b(b),
    .start_gcd(start_gcd),
    .clk(clk),
    .reset(reset),
    .gcd_result(gcd_result),
    .done_gcd(done_gcd)
  );

  // Output UART transmitter (FSM result → UART serial out)
  tx_uart TX_UART_OUT (
    .clk(clk),
    .Tx_Data_Valid(Tx_Data_Valid_from_fsm),
    .Tx_Byte(Tx_Byte_from_fsm),
    .Tx_Active(),
    .Tx_Serial(Rx_Serial),   // Simulated UART output
    .Tx_Done(Tx_Done_fsm)
  );

  // Clock generation
  always #(CLOCK_PERIOD_NS/2) clk = ~clk;
  
  // Detailed debug monitoring
  integer byte_count = 0;
  always @(posedge clk) begin
   
    if (Rx_Data_Valid) begin
      byte_count = byte_count + 1;
      $display("\n*** UART RX #%0d: Time=%0t, Rx_Byte=0x%h (%0d) ***\n", 
               byte_count, $time, Rx_Byte, Rx_Byte);
    end

   
    $display("FSM State: Time=%0t, a=%0d, b=%0d, start_gcd=%0d, done_gcd=%0d, gcd_result=%0d", 
             $time, a, b, start_gcd, done_gcd, gcd_result);

    
    if (Tx_Data_Valid_from_fsm)
      $display("*** FSM TX: Time=%0t, Tx_Byte_from_fsm=0x%h (%0d) ***", 
               $time, Tx_Byte_from_fsm, Tx_Byte_from_fsm);
    
    // Enhanced monitoring for critical signals
    if (Rx_Data_Valid) 
      $display("*** DEBUG: Time=%0t, Rx_Data_Valid HIGH, Rx_Byte=0x%h ***", $time, Rx_Byte);
    
    if (start_gcd)
      $display("*** DEBUG: Time=%0t, GCD Calculation STARTED, a=%0d, b=%0d ***", $time, a, b);
      
    if (done_gcd)
      $display("*** DEBUG: Time=%0t, GCD Calculation COMPLETED, result=%0d ***", $time, gcd_result);
  end

  // UART Byte Sender Task
  task automatic send_uart_byte(input [7:0] byte);
    begin
      @(posedge clk);
      Tx_Byte_reg <= byte;
      Tx_Data_Valid_reg <= 1'b1;
      @(posedge clk);
      Tx_Data_Valid_reg <= 1'b0;
      wait (Tx_Done_tb == 1'b1);
      #BIT_PERIOD;
    end
  endtask

  // Main Test Sequence
  initial begin
    // Reset
    reset <= 1;
    #(CLOCK_PERIOD_NS * 50);
    reset <= 0;
    #(CLOCK_PERIOD_NS * 50);
    
    $display("\n=== TEST STARTING: Sending first byte (a=12) ===\n");
    
    // Send inputs to FSM via UART
    send_uart_byte(8'h0C); // a = 12
    #(BIT_PERIOD * 20);
    $display("\n=== First byte (a=12) processed, sending second byte ===\n");
    send_uart_byte(8'h06); // b = 6
    #(BIT_PERIOD * 20);
    $display("\n=== Both bytes sent, waiting for GCD calculation and result ===\n");
    // Wait for FSM to compute and send result
    #(BIT_PERIOD * 20);
    $display("\n=== CHECKING FSM STATE: a=%0d, b=%0d ===\n", a, b);
    
    #2000000;
    $display("\n=== TEST COMPLETED: Final a=%0d, b=%0d, gcd_result=%0d ===\n", 
             a, b, gcd_result);
             
    $finish;
  end
  

endmodule


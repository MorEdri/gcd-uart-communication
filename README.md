GCD over UART Communication 

This project implements a UART-based communication system to compute the Greatest Common Divisor (GCD) of two 8-bit numbers using Verilog.

System Block Diagram
![image](https://github.com/user-attachments/assets/de895c9f-202d-486b-99bb-094d9577a591)

Modules Overview:
UART Receiver (RX): Receives two bytes representing the input numbers.

FSM Controller: Controls the data flow between RX, GCD computation, and TX. It waits for both numbers, triggers the computation, and signals when the result is ready.

GCD Module: Implements the binary GCD algorithm.

UART Transmitter (TX): Sends the GCD result back over UART.

Tools:
Designed and simulated using Vivado.


![image](https://github.com/user-attachments/assets/0f14bc72-4372-4d2b-87c4-38d84269ce4f)

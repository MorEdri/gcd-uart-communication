`timescale 1ns / 1ps
// Implement GCD algorithem in Verilog

module gcd(
    input [7:0] a,
    input [7:0] b,
    input clk,
    input reset,
    output reg [7:0] gcd_result
    );
    reg [7:0] tmp; 
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg step_flag;
    
    always @(posedge clk) begin
        if (reset) begin
            reg_a <= a;
            reg_b <= b;
            step_flag <= 0;
            if (a == 8'b0 || b == 8'b0) begin
                gcd_result <= 1;
            end else begin
                gcd_result <= 0;
            end
         end else if (a == 8'b0 || b == 8'b0) begin
                gcd_result <= 1;
            //$display("Reset: reg_a = %d, reg_b = %d, gcd_result = %d", reg_a, reg_b, gcd_result);
        end else if (reg_b != 8'b0) begin
            if (step_flag == 0) begin
                tmp <= reg_a % reg_b;
                reg_a <= reg_b;
                step_flag <= 1;
                //$display("Step 1: reg_a = %d, reg_b = %d, tmp = %d", reg_a, reg_b, tmp);
            end else begin //  if step_flag == 1
                reg_b <= tmp;
                step_flag <= 0;
               // $display("Step 2: reg_a = %d, reg_b = %d", reg_a, reg_b);
            end
          end
     else begin // if (reg_b == 8'b0)
            gcd_result <= reg_a;  
            //$display("GCD found: %d", gcd_result);
        end
    end
    
endmodule


`timescale 1ns / 1ps
// Implement GCD algorithem in Verilog

module gcd(
    input [7:0] a,
    input [7:0] b,
    input start_gcd,
    input clk,
    input reset,
    output reg [7:0] gcd_result,
    output reg done_gcd
    );
    reg [7:0] tmp; 
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg step_flag;
    reg running;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_a <= 0;
            reg_b <= 0;
            step_flag <= 0;
            tmp <= 0;
            gcd_result <= 0;
            done_gcd <= 0;
            running <= 0;
            
        end else begin 
            if (start_gcd && !running) begin
                // Start GCD computation
                reg_a <= a;
                reg_b <= b;
                step_flag <= 0;
                done_gcd <= 0;
                running <= 1;
                
                if (a == 8'b0) begin
                    gcd_result <= b;
                    done_gcd <= 1;
                    running <= 0;
                end else if (b == 8'b0) begin
                    gcd_result <= a;
                    done_gcd <= 1;
                    running <= 0;
                end
            
            end else if (running) begin
            //$display("Reset: reg_a = %d, reg_b = %d, gcd_result = %d", reg_a, reg_b, gcd_result);
               if (reg_b != 8'b0) begin
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
            end else begin // if (reg_b == 8'b0)
            gcd_result <= reg_a;  
            done_gcd <= 1;
            running <= 0;
            //$display("GCD found: %d", gcd_result);
        end
    end
   end
  end
    
endmodule


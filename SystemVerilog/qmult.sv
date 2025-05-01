`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/19/2025 01:15:01 PM
// Design Name: Capstone
// Module Name: qmult
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module qmult#(parameter Q = 11, parameter N = 20)(
    input logic signed [N-1:0]	a,
    input logic signed [N-1:0]	b,
    output logic signed [N-1:0] q_result  // Lose precision to maintain size
);
    // Choose to use the full precision result. Multiply two
    // values that are N-wide and get a 2*N result. 
    logic signed [2*N-1:0] full_result;
    
    assign full_result = a*b;
    
    // https://tinyurl.com/multOver    
    logic overflow_pos, overflow_neg;
    
    // Check if the bits above where we want to extract from our result.
    // For positive numbers, the bits should be zero
    // For negative numbers, the bits should be all 1's
    assign overflow_pos = (full_result[2*N-1] == 0) && (full_result[2*N-2:N+Q] != 0);
    assign overflow_neg = (full_result[2*N-1] == 1) && (full_result[2*N-2:N+Q] != {(N-Q-1){1'b1}});

    // Apply saturation if overflow occurs
    always_comb begin
        if (overflow_pos)
            q_result = {1'b0, {(N-1){1'b1}}}; // Max positive value
        else if (overflow_neg)
            q_result = {1'b1, {(N-1){1'b0}}}; // Min negative value
        else
            q_result = full_result[Q + N - 1 : Q]; // Normal case
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/19/2025 01:59:53 PM
// Design Name: Capstone
// Module Name: intToQ
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
// Description: Takes an 8 bit integer value and represents it as a 20 bit
// fixed point fractional value, the radix point at position Q.
//
//////////////////////////////////////////////////////////////////////////////////


module intToQ #(parameter N = 20, parameter Q = 11)(
    input [7:0] a,
    output [N-1:0] b
);
    // 1 2's comp sign bit + the given 8 bit int + Q bit fractional bits
    assign b = { 1'b0, a, {Q{1'b0}} };
endmodule

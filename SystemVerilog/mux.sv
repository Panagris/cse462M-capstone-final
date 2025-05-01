`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/02/2025 02:52:39 PM
// Design Name: Capstone
// Module Name: mux
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
// Additional Comments: NOTE: This mux is a modified 3-to-1 mux, with one input hardwired
// to 0.
//
//////////////////////////////////////////////////////////////////////////////////


module mux #(parameter N = 16)(
    input [N-1:0] a,
    input [N-1:0] b,
    input [1:0] sel,
    output [N-1:0] out
);
    
    assign out = (sel == 2'b01) ? a : ((sel == 2'b00) ? b: 0);
endmodule
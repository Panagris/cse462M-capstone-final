`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/02/2025 02:36:49 PM
// Design Name: Capstone
// Module Name: comparator
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module comparator #(parameter WIDTH = 16)(
    input ce,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] out
);

    logic [WIDTH-1:0] a_complement, b_complement;  // Two's complemented versions of the inputs.
    logic [WIDTH-1:0] temp;

    assign a_complement = {~a[WIDTH-1], ~a[WIDTH-2:0] + 1'b1};
    assign b_complement = {~b[WIDTH-1], ~b[WIDTH-2:0] + 1'b1};

    always_comb begin
        temp = 0;
        
        // If both are positive...
        if ( (a[WIDTH-1] == 0) && (b[WIDTH-1] == 0) ) begin
            temp = (a > b) ? a : b;
        // If both are negative...
        end else if ( (a[WIDTH-1] == 1) && (b[WIDTH-1] == 1) ) begin
            // Higher the magnitude, lower its value
            temp = (a_complement > b_complement) ? b : a;
        // Mixed case is easy: pick the positive value. 
        end else if ((a[WIDTH-1] == 1) && (b[WIDTH-1] == 0)) begin
            temp = b;
        end else if ((a[WIDTH-1] == 0) && (b[WIDTH-1] == 1)) begin
            temp = a;
        end
    end
    
    assign out = ce ? temp : 'd0;
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/19/2025
// Design Name: Capstone
// Module Name: qadd
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module qadd #(parameter N = 20, parameter Q = 11)(
    input  logic signed [N-1:0] a,
    input  logic signed [N-1:0] b,
    output logic signed [N-1:0] c
);
    // 1 bit wider internal signal to catch potential overflow.
    logic signed [N:0] sum_ext;
    assign sum_ext = a + b;

    // Saturation bounds
    // localparam signed [N-1:0] MAX_VAL = (1 <<< (N-1)) - 1;  // Max value
    // localparam signed [N-1:0] MIN_VAL = -(1 <<< (N-1));     // Min value

    always_comb begin
        c = sum_ext[N-1:0];
        // Overflow check
        if ((a[N-1] == b[N-1]) && (sum_ext[N] != a[N-1])) begin
            // If originally negative, output most negative value
            if (a[N-1])
                c = {1'b1, {N-1{1'b0}}};
            // If originally positive, output most positive value
            else
                c = {1'b0, {N-1{1'b1}}};
        end
    end
endmodule
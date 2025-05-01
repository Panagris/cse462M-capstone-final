`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/17/2025 05:12:11 PM
// Design Name: Capstone
// Module Name: relu
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module relu #(parameter WIDTH = 20)(
    input logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] d_out
);
    
    always_comb begin
        if(d_in[WIDTH-1] == 1) begin
            d_out = 0;
        end else begin
            d_out = d_in;
        end
    end 
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/02/2025
// Design Name: Capstone
// Module Name: register
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module register #(parameter WIDTH = 16)(
    input clk,
    input ce,
    input [WIDTH-1:0] d_in,
    input reg_reset,
    input external_reset,
    output logic [WIDTH-1:0] q_out
);

    always @(posedge clk) begin
        if (external_reset) begin
            q_out <= 0;
        end else begin
            if (ce) begin
                if (reg_reset)  q_out <= 0;
                else            q_out <= d_in;
            end
        end
    end

endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 02/18/2025
// Design Name: Capstone
// Module Name: shift_register
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module shift_register #(parameter WIDTH = 8, parameter SIZE = 3) (
    input clk,
    input ce,
    input reset,
    input [WIDTH-1:0] d,
    output [WIDTH-1:0] q
);
    // A SIZE-long series of registers that contain WIDTH-many bits. 
    logic [WIDTH-1:0] sr [SIZE-1:0];
    
    generate
        genvar i;
        for(i = 0; i < SIZE; i = i + 1) begin
            always@(posedge clk or posedge reset) begin
                if(reset)           sr[i] <= 'd0;
                else if(ce) begin
                    if(i == 'd0)   sr[i] <= d; // if the first reg, get the value d
                    else                sr[i] <= sr[i-1]; // else, get the value from the prev reg
                 end 
            end
        end
        
        assign q = sr[SIZE-1]; // the output
    
    endgenerate
endmodule

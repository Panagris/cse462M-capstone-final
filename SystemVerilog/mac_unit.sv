`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 02/23/2025
// Design Name: Capstone
// Module Name: mac_unit
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module mac_unit #(parameter N = 20, parameter Q = 11)(
    input logic clk, reset, ce,
    input logic [N-1:0] a,
    input logic signed [N-1:0] b,
    input logic signed [N-1:0] c,
    output logic signed [N-1:0] p
);
    logic [N-1:0] product, sum, product_reg, c_reg;
        
    qmult #(.N(N), .Q(Q)) multiplier (
        .a(a),
        .b(b),
        .q_result(product)
    );
    
    // After multiplication, will have 2*N full precision 
    // values
    qadd #(.N(N), .Q(Q)) adder (
        .a(product_reg),
        .b(c_reg),
        .c(sum)
    );

    always @(posedge clk) begin
        if(reset) begin 
            product_reg <= 0;
            c_reg <= 0;
        end else if(ce) begin
            product_reg <= product;
            c_reg <= c;
        end
    end 
    
    assign p = sum;
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/05/2025 10:09:27 AM
// Design Name: Capstone
// Module Name: CNN
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module CNN #(
    parameter s = 1,    // stride
    parameter OUTPUT_WIDTH = 'd20, // internal data width
    parameter n = 'd480, // initial activation map dimension
    parameter K = 'd3, // kernel dimension
    parameter logic [179:0] kernel_weights,
    parameter p = 'd2,  // pooling window dimension
    parameter P = 'd1,   // zero padding depth
    parameter INPUT_WIDTH = 'd8,  // Either an 8-bit RGB or 20-bit fixed point
    parameter NEEDS_CONVERSION = 'b1 
)(
    input logic clk,
    input logic ce,
    input logic reset,
    input logic [INPUT_WIDTH-1:0] activation,
    output logic valid_out,
    output logic [OUTPUT_WIDTH-1:0] pooler_output,
    output logic end_sig
);
    logic conv_enable, delayed_conv_enable, valid_conv, pooler_enable, end_conv;
    logic signed [OUTPUT_WIDTH-1:0] conv_output, activation_output;
    
    logic [INPUT_WIDTH-1:0] conv_input, delayed_conv_input;
    
    zero_padder #(
        .n(n),
        .DATA_WIDTH(INPUT_WIDTH),
        .P(P)
    ) padder_0 (
        .clk(clk),
        .reset(reset),
        .valid_in(ce),
        .data_in(activation),
        .valid_out(conv_enable),
        .data_out(conv_input)
    );
    
    always_ff @(posedge clk) begin
        delayed_conv_enable <= conv_enable;
        delayed_conv_input <= conv_input;
    end
    
    // A 480x480 activation map with a 3x3 kernel
    // Padding was added, so the input to the convolver has dimensions
    // n' = n + 2 * P
    // Output is n' - K + 1: 480x480 output
    localparam n_prime = n + 2 * P; 
    convolver #(
        .n(n_prime),  // n + 2 * P = 480 + 2 * 1 = 482  
        .k(K),
        .INPUT_WIDTH(INPUT_WIDTH),
        .NEEDS_CONVERSION(NEEDS_CONVERSION),
        .kernel_input(kernel_weights)
    ) convolver (
        .clk(clk),
        .ce(delayed_conv_enable),
        .reset(reset),
        .activation(delayed_conv_input),
        .conv_op(conv_output),
        .end_conv(end_conv),
        .valid_conv(valid_conv)
    );
    
    relu #(.WIDTH(OUTPUT_WIDTH)) activation_unit (conv_output, activation_output);

    assign pooler_enable = delayed_conv_enable && valid_conv;
    
    // M is the dimension of the convolver output
    localparam M = n_prime - K + 1;
    
    pooler #(.M(M), .p(p), .WIDTH(OUTPUT_WIDTH)) pooler (
        .clk(clk),
        .ce(pooler_enable),
        .external_reset(reset),
        .data_in(activation_output),
        .data_out(pooler_output),
        .valid_output(valid_out),
        .end_op(end_sig)
    );
endmodule

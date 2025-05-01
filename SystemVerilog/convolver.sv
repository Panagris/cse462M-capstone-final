`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 02/17/2025 01:55:34 PM
// Design Name: Capstone
// Module Name: convolver
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module convolver #(
    parameter n = 'd480,        // Activation map dimension
    parameter k = 9'h003,      // Kernel dimension
    parameter s = 1,          // Stride
    parameter INPUT_WIDTH = 8, // Set to 8 or 20    
    parameter NEEDS_CONVERSION = 1,  // Set to 0 when input is already fixed-point
    // 1 sign + 8 integer bits for RGB + 11 fractional bits
    // The entire number is still 2's complement, with the MSB
    // being -2^8.
    parameter OUTPUT_WIDTH = 20,         // Total bit width of internal values, in fixed point
    parameter Q = 11,        // Number of fractional bits
    parameter logic [179:0] kernel_input
)(
    input logic clk,
    input logic ce,
    input logic reset,
    input logic [INPUT_WIDTH-1:0] activation,
    output logic signed [OUTPUT_WIDTH-1:0] conv_op, // Fixed point value
    output logic valid_conv,
    output logic end_conv
);
    // Consider overflow, use saturation rather than rollover
    logic [31:0] cycle_count; // Total clock cycles since convolution started. 
    logic [31:0] valid_output_row_count; // Valid convolution outputs in the current row.
    logic [31:0] row_wrap_count; // Cycles spent when the kernel wraps to a new row, causing invalid outputs.
    logic [31:0] output_row_index;
    logic pipeline_filled, process_row, valid_output;
    
    // Holds the result of the MAC unit (the partial result of the convolution)
    // at each stage of the pipeline, passing it into the next MAC unit. 
    logic signed [OUTPUT_WIDTH-1:0] tmp [k*k+1:0];
    
    // The weights of the kernel, which are fixed.
    logic signed [OUTPUT_WIDTH-1:0] weight [0:k*k-1];
    
    logic signed [OUTPUT_WIDTH-1:0] activation_Q;
    
    // If the input is an 8-bit RGB, we must convert to the 20-bit fixed
    // point representation.
    generate
        if (NEEDS_CONVERSION) begin
            intToQ #(.N(OUTPUT_WIDTH), .Q(Q)) converter(activation, activation_Q);
        end else begin
            assign activation_Q = activation; // If the value is already 20-bit fixed point
        end
    endgenerate
    
    // Breaking the weights into separate variables.
    generate
        genvar j;
        for (j = 0; j < k*k; j = j+1) begin: kernel_weight_loop
            assign weight[j] = kernel_input[OUTPUT_WIDTH*j +: OUTPUT_WIDTH];
        end 
    endgenerate
    
    // Let the first MAC units constant (c) be 0.
    assign tmp[0] = 'd0;
    
    // Generate loop to instantiate MAC units dynamically
    generate
        genvar i;
        for (i = 0; i < k*k; i = i+1) begin : mac_loop
            if ((i+1) % k == 0) begin // End of the row
                if (i == k*k-1) begin // End of convolver
                    (* use_dsp = "yes" *)
                    mac_unit mac (
                        .clk(clk),
                        .ce(ce),
                        .reset(reset),
                        .a(activation_Q),
                        .b(weight[i]),
                        .c(tmp[i]),
                        .p(conv_op)
                    );
                end else begin  // If the end of a row but not the convolver.
                    logic [OUTPUT_WIDTH-1:0] tmp2;
                    (* use_dsp = "yes" *)
                    mac_unit mac (
                        .clk(clk),
                        .ce(ce),
                        .reset(reset),
                        .a(activation_Q),
                        .b(weight[i]),
                        .c(tmp[i]),
                        .p(tmp2)
                    );
                    
                    // Preserve the pipeline value in a SIZE-cycle_count sequence of registers.
                    // A 16-bit width because 8-bit * 8-bit = 16 bits.
                    shift_register #(.WIDTH(OUTPUT_WIDTH), .SIZE(n-k)) SR (
                        .d(tmp2),
                        .clk(clk),
                        .ce(ce),
                        .reset(reset),
                        // Only the value of the last register gets put into tmp[], 
                        // which will supply the MAC unit of the next row.
                        .q(tmp[i+1]) 
                    );
                end
            end else begin
            // If none of the other cases, simply compute the MAC and place it in the next tmp slot
            // for the next MAC unit to use.
                (* use_dsp = "yes" *)
                mac_unit mac2 (
                    .clk(clk),
                    .ce(ce),
                    .reset(reset),
                    .a(activation_Q),
                    .b(weight[i]),
                    .c(tmp[i]),
                    .p(tmp[i+1])
                );
            end
        end
    endgenerate
    
    // Logic to generate 'valid_conv' and 'end_conv' output signals
    always @(posedge clk) begin
        if (reset) begin
            cycle_count <= 0;
            valid_output_row_count <= 0;
            row_wrap_count <= 0;
            output_row_index <= 0;
            pipeline_filled <= 0;
            process_row <= 1;
            valid_output <= 0;
        end else if (ce) begin // If not ce, then cycle_count retains its state.
            if (cycle_count == (k-1)*n + k-1) begin // Time for pipeline to fill up
                pipeline_filled <= 1'b1;
                cycle_count <= cycle_count + 1'b1;
            
            end else    cycle_count <= cycle_count + 1'b1;
        end
        
        if (pipeline_filled && process_row) begin
            if (valid_output_row_count == n-k) begin
                valid_output_row_count <= 0;
                process_row <= 0;
                output_row_index <= output_row_index + 1'b1;
            
            end else    valid_output_row_count <= valid_output_row_count + 1'b1;
        end
        
        if (~process_row) begin
            if (row_wrap_count == k-2) begin
                row_wrap_count <= 0;
                process_row <= 1'b1;
            end else begin
                row_wrap_count <= row_wrap_count + 1'b1;
            end
        end
        
        // Validate convolution output
        if ((((valid_output_row_count + 1) % s == 0) && (output_row_index % s == 0)) || (row_wrap_count == k-2 && output_row_index % s == 0) || (cycle_count == (k-1)*n + k-1)) begin
            valid_output <= 1;
        end else begin
            valid_output <= 0;
        end
    end

    
    assign end_conv = (cycle_count >= n*n + 2) ? 1'b1 : 1'b0;
    assign valid_conv = (pipeline_filled && process_row && valid_output);
    
endmodule

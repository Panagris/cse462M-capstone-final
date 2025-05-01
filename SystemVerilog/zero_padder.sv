`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/22/2025 03:47:08 PM
// Design Name: Capstone
// Module Name: zero_padder
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module zero_padder #(
    parameter n = 4,      // Feature matrix size (NxN)
    parameter P = 1,      // Padding size
    parameter DATA_WIDTH = 8  // Bit-width of each element
)(
    input logic clk,
    input logic reset,
    input logic valid_in,             // Signals when input data is valid
    input logic [DATA_WIDTH-1:0] data_in, // Feature values streamed in row-wise
    output logic valid_out,           // Signals when output data is valid
    output logic [DATA_WIDTH-1:0] data_out  // Padded output matrix
);

    // Output row width
    localparam OUT_WIDTH = n + 2 * P;
    
    // FIFO buffer to store one padded row
    logic [DATA_WIDTH-1:0] row_fifo [0:OUT_WIDTH-1];
    logic [$clog2(OUT_WIDTH)-1:0] write_ptr, read_ptr;
    
    // State tracking
    logic [$clog2(n + 2*P)-1:0] row_count;
    logic [$clog2(OUT_WIDTH)-1:0] col_count;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            row_count <= 0;
            col_count <= 0;
            write_ptr <= 0;
            read_ptr <= 0;
            valid_out <= 0;
        end else if(valid_in) begin
            // Store new feature values into FIFO
            row_fifo[write_ptr] <= data_in;
            write_ptr <= write_ptr + 1;
            
            // Assert valid_out because an output will either be
            // 0 or a stored value.
            valid_out <= 1;
            
            // Padding around the edges.
            if (row_count < P || row_count >= (n + P) || col_count < P || col_count >= (n + P)) begin
                data_out <= 0;
            end else begin
                // Output from FIFO (feature data)
                data_out <= row_fifo[read_ptr];
                read_ptr <= read_ptr + 1;
            end

            // Advance column counter
            if (col_count == OUT_WIDTH - 1) begin
                col_count <= 0;
                row_count <= row_count + 1;
                read_ptr <= 0;
            end else begin
                col_count <= col_count + 1;
            end
        end else begin
            valid_out <= 0;
        end
    end
    
endmodule


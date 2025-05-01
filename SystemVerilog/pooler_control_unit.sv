`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/02/2025 12:47:55 PM
// Design Name: Capstone
// Module Name: pooler_control_unit
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module pooler_control_unit #(
    parameter M = 9'h01a,   // Dimension of input feature map after convolution. M = N - K + 1.
    parameter p = 9'h002   // Side dimension of the pooling window p x p.)
)(
    input clk,
    input external_reset,
    input ce,
    
    output logic [1:0] sel,
    output logic max_reg_reset,
    output logic valid_pool_output,
    output logic load_shift_reg,
    output logic pooler_reset,
    output logic end_op
);
    
    integer row_count = 0;
    integer col_count = 0;
    integer count = 0;  // track the number of completed pooling windows in a row.
    integer num_pooled_rows;

    always @(posedge clk) begin 
        if (external_reset) begin
            sel <= 0;
            load_shift_reg <= 0;
            max_reg_reset <= 0;
            valid_pool_output <= 0;
            pooler_reset <= 0;
            end_op <= 0;
        
        end else begin
            // If in the pooling windows bottom row and just before the last column, the next
            // input will be the final value to compute the max for the window, so assert
            // valid_pool_output at the next clock tick, which will be right when the 
            // comparator outputs the maximum. 
            if (((col_count + 1) % p != 0) && (row_count == p - 1) && (col_count == p * count + (p - 2)) && ce) begin
                valid_pool_output <= 1;
            end else begin
                valid_pool_output <= 0;
            end
            
            if (ce) begin
                if (num_pooled_rows == M / p) begin
                    end_op <= 1;
                end else begin
                    end_op <= 0;
                end
                
                // When reaching the end of a row in the input map, reset the column, row,
                // and count signals, incrementing the number of pooled rows. 
                if (((col_count + 1) % p != 0) && (col_count == M - 2) && (row_count == p - 1)) begin
                    pooler_reset <= 1;
                end else begin
                    pooler_reset <= 0;
                end  
                
                // When a pooling window is complete but there are still more pooling operations
                // to perform in a row of the input, reset the max register; the current window
                // is complete and moving on.  
                if ((((col_count + 1) % p == 0) && (count != M / p - 1) && (row_count != p - 1)) ||
                    ((col_count == M - 1) && (row_count == p - 1))) begin
                    max_reg_reset <= 1;
                end else begin
                    max_reg_reset <= 0;
                end   
                
                // Control whether the value to be compared to agains the input comes from the
                // shift register (when the pooling window wraps around to the next feature map
                // row), the max register (when the input is a member of a window that was just 
                // processed), or 0 (when the input is the first in its window). 
                if (((col_count + 1) % p != 0) && (col_count == M - 2) && (row_count == p - 1)) begin
                    sel <= 2'b10;
                end else if ((col_count % p == 0) && 
                    ((count == M / p - 1 && row_count != p - 1) || (count != M / p - 1 && row_count == p - 1))) begin
                    sel <= 2'b01;
                end else begin
                    sel <= 2'b00;
                end

                // If the end of the pooling window, store the value into the shift register.
                if ((col_count + 1) % p == 0) begin
                    load_shift_reg <= 1;
                end else begin
                    load_shift_reg <= 0;
                end
            end
        end 
    end 

    always @(posedge clk) begin
        if (external_reset) begin
            row_count <= 0;
            col_count <= 32'hFFFFFFFF;
            count <= 32'hFFFFFFFF;
            num_pooled_rows <= 0;
        end else if (ce) begin
            if (pooler_reset) begin
                row_count <= 0;
                col_count <= 0;
                count <= 0;
                num_pooled_rows <= num_pooled_rows + 1;
            end else begin
                if (((col_count + 1) % p == 0) && (count == M / p - 1) && (row_count != p - 1)) begin
                    col_count <= 0;
                    row_count <= row_count + 1;
                    count <= 0;
                end else begin
                    col_count <= col_count + 1;
                    // This logic implies that the stride is equal to p, because the count
                    // variable tracks the total number of windows oompleted in a row.
                    if (((col_count + 1) % p == 0) && (count != M / p - 1)) begin
                        count <= count + 1;
                    end 
                end
            end
        end  
    end 
endmodule

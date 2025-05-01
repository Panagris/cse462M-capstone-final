`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
// Original Source: Dr. Michael Hall, Professor CSE 462M
//
// Create Date: 02/03/2025 11:28:30 AM
// Design Name:
// Module Name: computation_sv
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module computation_sv(
    // FIFO input interface (from Accelerator Adapter S2F)
    input  logic [31:0] ap_fifo_iarg_0_dout,
    input  logic        ap_fifo_iarg_0_empty_n,
    output logic        ap_fifo_iarg_0_read,

    // FIFO output interface (to Accelerator Adapter F2S)
    output logic [31:0] ap_fifo_oarg_0_din,
    input  logic        ap_fifo_oarg_0_full_n,
    output logic        ap_fifo_oarg_0_write,

    // Scalar inputs
    input  logic [31:0] ap_iscalar_0_dout,

    // Control interface (from/to Accelerator Adapter)
    input  logic ap_start,
    input  logic ap_continue,
    output logic ap_idle,
    output logic ap_ready,
    output logic ap_done,

    // Clock and reset
    input  logic aclk,
    input  logic aresetn
);

    // State signals
    typedef enum logic [1:0] {accReady, accRunning, accDone} AccStateType;
    typedef enum logic {dataReadLength, dataCompute} DataStateType;

    AccStateType acc_state, n_acc_state;
    DataStateType data_state, n_data_state;

    // Internal signals
    logic [31:0] data_in_reg, n_data_in_reg;
    logic        data_in_valid_reg, n_data_in_valid_reg;
    logic        data_in_read;
    logic        data_out_valid_reg, n_data_out_valid_reg;
    logic [31:0] data_out_reg, n_data_out_reg;

    logic signed [19:0] n_CNN_data_out_reg;
    
    logic [31:0] total_bytes, n_total_bytes;
    logic [31:0] byte_cnt, n_byte_cnt;
    logic        acc_running;
    logic        en;
    logic        comp_done, n_comp_done;

    logic       CNN_ce, valid_CNN_out, end_CNN;
    
    multilayer_cnn #(
        .NUM_LAYERS(3),
        .s(1),
        .DATA_WIDTH(20),
        .n(480),
        .K(3),
        .p(2),
        .P(1)
    ) cnn (
        .clk(aclk),
        .ce(CNN_ce),
        .reset(~aresetn),
        .input_8bit(data_in_reg[7:0]),
        .final_output(n_CNN_data_out_reg),
        .final_valid(valid_CNN_out),
        .final_done(end_CNN)
    );
    
    // Accelerator Handshake Interface
    //   Sequential logic
    always_ff @(posedge aclk) begin
        acc_state <= n_acc_state;
    end

    //   Combinational logic
    always_comb begin
        n_acc_state = acc_state;
    
        if (~aresetn) begin
            n_acc_state = accReady;
        end
        else begin
            case (acc_state)
                accReady: begin
                    if (ap_start || ap_continue) begin
                        n_acc_state = accRunning;
                    end
                end
                accRunning: begin
                    if (comp_done) begin
                        n_acc_state = accDone;
                    end
                end
                accDone: begin
                    n_acc_state = accReady;
                end
                default: begin
                    n_acc_state = accReady;
                end
            endcase
        end
    end

    //   Output logic
    assign ap_ready = (acc_state == accReady);
    assign ap_idle = ap_ready;
    assign ap_done = (acc_state == accDone);
    assign acc_running = (acc_state == accRunning);

    // Input FIFO handshake
    assign en = acc_running && ap_fifo_oarg_0_full_n;

    always_ff @(posedge aclk) begin
        data_in_reg <= n_data_in_reg;
        data_in_valid_reg <= n_data_in_valid_reg;
    end

    always_comb begin
        n_data_in_reg = data_in_reg;
        n_data_in_valid_reg = data_in_valid_reg;
        ap_fifo_iarg_0_read = 0;
        
        if (~aresetn) begin
            n_data_in_reg = 0;
            n_data_in_valid_reg = 0;
        end
        else begin
            if (en) begin
                if (ap_fifo_iarg_0_empty_n) begin
                    if (!data_in_valid_reg || data_in_read) begin
                        ap_fifo_iarg_0_read = 1;
                        n_data_in_reg = ap_fifo_iarg_0_dout;
                        n_data_in_valid_reg = 1;
                    end
                end
                else begin
                    n_data_in_valid_reg = 0;
                end
            end
        end
    end
    
    assign CNN_ce = ap_fifo_oarg_0_full_n && (data_state == dataCompute);

    // Process data and perform computation logic (xi * scalar).
    always_ff @(posedge aclk) begin
        data_state <= n_data_state;
        data_out_reg <= n_data_out_reg;
        data_out_valid_reg <= n_data_out_valid_reg;
        byte_cnt <= n_byte_cnt;
        total_bytes <= n_total_bytes;
        comp_done <= n_comp_done;
    end

    always_comb begin
        n_data_state = data_state;
        n_data_out_reg = data_out_reg;
        n_data_out_valid_reg = data_out_valid_reg;
        n_byte_cnt = byte_cnt;
        n_total_bytes = total_bytes;
        n_comp_done = comp_done;

        data_in_read = 0;

        if (ap_fifo_oarg_0_full_n) begin
            n_data_out_valid_reg = 0;
        end

        if (~aresetn) begin
            n_data_state = dataReadLength;
            n_data_out_reg = 0;
            n_data_out_valid_reg = 0;
            n_byte_cnt = 0;
            n_total_bytes = 0;
            n_comp_done = 0;
        end
        else begin
            if (ap_ready) begin
                n_data_state = dataReadLength;
                n_byte_cnt = 0;
                n_total_bytes = 0;
                n_comp_done = 0;
            end
            else if (en) begin
                n_data_out_valid_reg = 0;
                case (data_state)
                    dataReadLength: begin
                        if (data_in_valid_reg) begin
                            data_in_read = 1;
                            n_total_bytes = data_in_reg;
                            n_data_state = dataCompute;
                        end
                    end
                    dataCompute: begin
                    // Swap the order, check if its done before doing stuff.
                        if (end_CNN) begin
                            n_comp_done = 1;
                        end else if (byte_cnt < total_bytes) begin
                            if (data_in_valid_reg) begin
                                data_in_read = 1;
                                n_data_out_reg = { {12{n_CNN_data_out_reg[19]}}, n_CNN_data_out_reg };
                                n_data_out_valid_reg = valid_CNN_out;
                                if (valid_CNN_out) begin
                                    n_byte_cnt = byte_cnt + 4;
                                end
                            end
                        end
                    end
                    default: begin
                        n_data_state = dataReadLength;
                    end
                endcase
            end
        end
    end

    // Output FIFO handshake
    assign ap_fifo_oarg_0_din   = data_out_reg;
    assign ap_fifo_oarg_0_write = data_out_valid_reg;
endmodule

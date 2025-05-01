`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 04/11/2025 03:09:04 PM
// Module Name: multilayer_CNN
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////


module multilayer_cnn #(
    parameter NUM_LAYERS = 3,
    parameter s = 1,
    parameter DATA_WIDTH = 20,
    parameter n = 480,
    parameter K = 3,
    parameter p = 2,
    parameter P = 1,
    // K^2 kernel elements * 20-bit values * NUM_LAYERS
    parameter logic [NUM_LAYERS*DATA_WIDTH*K*K-1:0] kernel_input =
    {
    180'hFFFAF_FFF12_FFDFE_00136_00097_FFFDA_00294_0019A_000BE,
    180'hFFFAF_FFEF2_FFD99_0011F_00070_FFF43_0027B_0017B_0002E,
    180'hFFFE5_FFF50_FFE41_00117_00090_FFFB3_00250_00170_0007B
    }

)(
    input  logic clk,
    input  logic ce,
    input  logic reset,
    input  logic [7:0] input_8bit, // only the first layer uses this
    output logic [DATA_WIDTH-1:0] final_output,
    output logic final_valid,
    output logic final_done
);

    // Intermediate signals between layers
    logic [DATA_WIDTH-1:0] activation [0:NUM_LAYERS];   // output of each layer
    logic valid [0:NUM_LAYERS];
    logic done [0:NUM_LAYERS];

    // Connect the 8-bit input to the activation[0]
    // The value needs to be extended to 20 bits to fit inside the
    // array of values.
    assign activation[0] = {12'd0, input_8bit};
    assign valid[0] = ce;
    assign done[0]  = 1'b0;

    genvar i;
    generate
        for (i = 0; i < NUM_LAYERS; i = i + 1) begin : cnn_layers
            localparam input_dimension = get_layer_input_size(i, n, P, K, p);
            CNN #(
                .s(s),
                .OUTPUT_WIDTH(DATA_WIDTH),
                .n(input_dimension), // dimension of input depends on placement
                .K(K),
                .kernel_weights(kernel_input[DATA_WIDTH*K*K*i +: DATA_WIDTH*K*K]),
                .p(p),
                .P(P),
                .INPUT_WIDTH(i == 0 ? 8  : DATA_WIDTH),
                .NEEDS_CONVERSION(i == 0 ? 1 : 0)
            ) layer_i (
                .clk(clk),
                .ce(valid[i]),
                .reset(reset),
                .activation(i == 0 ? input_8bit : activation[i]),
                .valid_out(valid[i+1]),
                .pooler_output(activation[i+1]),
                .end_sig(done[i+1])
            );
        end
    endgenerate

    assign final_output = activation[NUM_LAYERS];
    assign final_valid  = valid[NUM_LAYERS];
    assign final_done   = done[NUM_LAYERS];

    function int get_layer_input_size
    (
        input int layer_index,
        input int n_in,
        input int P,
        input int K,
        input int p
    );
        int result;
        int i;
        result = n_in;
        for (i = 0; i < layer_index; i++) begin
            result = (result + 2*P - K + 1) / p;
        end
        return result;
    endfunction

endmodule


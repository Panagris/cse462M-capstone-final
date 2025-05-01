`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: WashU in St. Louis
// Engineer: Dr. Michael Hall, Professor CSE 462M
//
// Create Date: 02/03/2025 08:55:53 AM
// Design Name:
// Module Name: computation
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module computation (
    // FIFO input interface (from Accelerator Adapter S2F)
    input  [31:0] ap_fifo_iarg_0_dout,
    input         ap_fifo_iarg_0_empty_n,
    output        ap_fifo_iarg_0_read,

    // FIFO output interface (to Accelerator Adapter F2S)
    output [31:0] ap_fifo_oarg_0_din,
    input         ap_fifo_oarg_0_full_n,
    output        ap_fifo_oarg_0_write,
    
    // Scalar inputs
    input [31:0] ap_iscalar_0_dout,

    // Control interface (from/to Accelerator Adapter)
    input  ap_start,
    input  ap_continue,
    output ap_idle,
    output ap_ready,
    output ap_done,

    // Clock and reset
    input aclk,
    input aresetn
);
    computation_sv u1(
        .ap_fifo_iarg_0_dout(ap_fifo_iarg_0_dout),
        .ap_fifo_iarg_0_empty_n(ap_fifo_iarg_0_empty_n),
        .ap_fifo_iarg_0_read(ap_fifo_iarg_0_read),
        .ap_fifo_oarg_0_din(ap_fifo_oarg_0_din),
        .ap_fifo_oarg_0_full_n(ap_fifo_oarg_0_full_n),
        .ap_fifo_oarg_0_write(ap_fifo_oarg_0_write),
        .ap_iscalar_0_dout(ap_iscalar_0_dout),
        .ap_start(ap_start),
        .ap_continue(ap_continue),
        .ap_idle(ap_idle),
        .ap_ready(ap_ready),
        .ap_done(ap_done),
        .aclk(aclk),
        .aresetn(aresetn)
    );
endmodule

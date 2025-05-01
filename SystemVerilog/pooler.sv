`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Original Source: "Batman" at TheDataBus
//
// Company: WashU in St. Louis
// Engineer: C. Okoye
//
// Create Date: 03/02/2025 12:47:55 PM
// Design Name: Capstone
// Module Name: pooler
// Target Devices: PYNQ-Z2
// Tool Versions: Vivado 2024.2
//
//////////////////////////////////////////////////////////////////////////////////

module pooler #(
    parameter M = 9'h00c,
    parameter p = 9'h003,
    parameter WIDTH = 16
)(
    input clk,
    input ce,
    input external_reset,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output valid_output,               //output signal to indicate the valid output
    output end_op                  //output signal to indicate when all the valid outputs have been  
                                   //produced for that particular input matrix
);
   
    logic reset_max_reg, load_shift_reg, pooler_reset;
    logic [1:0] sel;
    logic [WIDTH-1:0] comp_output;
    logic [WIDTH-1:0] shift_reg_output;
    logic [WIDTH-1:0] max_reg_op;
    logic [WIDTH-1:0] mux_out;
   
    pooler_control_unit #(M,p) log(     
	    clk,
	    external_reset,
	    ce,
	    sel,
	    reset_max_reg,
	    valid_output,
	    load_shift_reg,
	    pooler_reset,
	    end_op
      );
    
    comparator #(.WIDTH(WIDTH)) comp (
        ce,         
	    data_in,
	    mux_out,
	    comp_output
      );
  
    register #(.WIDTH(WIDTH)) max_register (
    	.clk(clk),
    	.ce(ce),
	    .d_in(comp_output),
	    .reg_reset(reset_max_reg),
	    .external_reset(external_reset),
	    .q_out(max_reg_op)
      );
 
    shift_register #(.WIDTH(WIDTH),.SIZE((M/p))) SR (
         .d(comp_output),                 
         .clk(clk),                 
         .ce(load_shift_reg),                 
         .reset(pooler_reset && external_reset),         
         .q(shift_reg_output)             
    );

   mux #(.N(WIDTH)) mux (shift_reg_output, max_reg_op, sel, mux_out);
    
   assign data_out = max_reg_op;

endmodule


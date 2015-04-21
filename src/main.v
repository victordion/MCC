// this is the MCC controller block
// Author: Jianwei Cui
// Date: 04/20/2015
// All Rights Reserved
//
//
`define DAC_BIT_WIDTH 32
`define ADC_BIT_WIDTH 32
`define MEMORY_ADDR_WIDTH 32
`define MEMORY_DATA_WIDTH 32
`define DATA_WIDTH 32 
`define CROSSBAR_SIZE 32
`define CROSSBAR_SIZE_BIN 5
`define STATE_WIDTH 5

module mcc(clk, rstn, ld_en, y_final_memaddr, y_final_rdy, sub_x_addr, sub_b_addr, sub_y_addr, mem_addr, mem_en, mem_rdy, 
            mem_data_in, mem_data_out, DAC_out, ADC_in, mux_sel);

    
    parameter ITER_MAX = 5;

    parameter IDLE           =  5'd0;
    parameter LOAD_SUB_X     =  5'd1;
    parameter LOAD_SUB_Y     =  5'd2;
    parameter LOAD_SUB_B     =  5'd3;
    parameter PROG_CROSSBAR  =  5'd4;
    parameter SENSE_CROSSBAR =  5'd5;
    parameter EVAL_CROSSBAR  =  5'd6;
    parameter MERGE_RESULT   =  5'd7;
        
    input clk;
    input rstn;

    // start signal from CPU
    input ld_en;
    output [`MEMORY_ADDR_WIDTH - 1 : 0] y_final_memaddr;
    output y_final_rdy;
    
    // telling MCC where to find the input X vector
    input [`DATA_WIDTH - 1 : 0]         sub_x_addr[0 : `CROSSBAR_SIZE - 1];
    input [`MEMORY_ADDR_WIDTH - 1 : 0]  sub_b_addr;
    input [`DATA_WIDTH - 1 : 0]         sub_y_addr[0 : `CROSSBAR_SIZE - 1];

    // interface to the main memory
    output [`MEMORY_ADDR_WIDTH - 1 : 0] mem_addr;
    output mem_en;
    input  mem_rdy;
    input [`MEMORY_DATA_WIDTH - 1 : 0] mem_data_in;
    output [`MEMORY_DATA_WIDTH - 1 : 0] mem_data_out;

    // interface to the memristor crossbar
    output [`DAC_BIT_WIDTH - 1 : 0] DAC_out[`CROSSBAR_SIZE_BIN - 1 : 0];
    output [`ADC_BIT_WIDTH - 1 : 0] ADC_in[`CROSSBAR_SIZE_BIN - 1 : 0];
    output [`CROSSBAR_SIZE_BIN - 1 : 0] mux_sel[`CROSSBAR_SIZE_BIN - 1 : 0];

    reg [`STATE_WIDTH - 1 : 0] state;
    reg [5:0] curr_iter_num;
    reg [`CROSSBAR_SIZE_BIN - 1 : 0] curr_prog_diag_idx;
    reg [`DAC_BIT_WIDTH - 1 : 0] target_resistance[`CROSSBAR_SIZE_BIN - 1 : 0];
    reg [`DATA_WIDTH - 1 : 0] sub_b[`CROSSBAR_SIZE_BIN - 1 : 0];
    reg [`CROSSBAR_SIZE_BIN - 1 : 0] sub_b_ld_count;

    
    wire [`DATA_WIDTH - 1 : 0] in_1;
    wire [`DATA_WIDTH - 1 : 0] in_2;
    wire [`DATA_WIDTH - 1 : 0] result;
    multiplier u_multiplier(in_1, in_2, result);


    always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
            state = IDLE;
        end
        else begin
            case(state)
                IDLE: begin
                    if(ld_en == 1'b1) begin
                        state <= LOAD_SUB_X;
                    end
                end

                LOAD_SUB_X: begin
                    state <= LOAD_SUB_Y;
                end
                
                LOAD_SUB_Y: begin
                    state <= LOAD_SUB_B;
                end
                
                LOAD_SUB_B: begin
                    if(sub_b_ld_count == 0) begin
                        state <= PROG_CROSSBAR;
                    end
                end
            
                PROG_CROSSBAR: begin
                    if(curr_iter_num == ITER_MAX) begin
                        state <= EVAL_CROSSBAR;
                    end
                end
            endcase
        end
    end

endmodule

module multiplier(clk, rstn, in_1, in_2, result);
    input clk;
    input rstn;
    input [`DATA_WIDTH - 1 : 0] in_1;
    input [`DATA_WIDTH - 1 : 0] in_2;
    output [`DATA_WIDTH - 1 : 0] result;
    
    reg [`DATA_WIDTH - 1 : 0] result;
    
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            result <= 0;
        end
        else begin
            result = in_1 * in_2;
        end
    end

endmodule

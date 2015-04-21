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
`define MUX_SEL_WIDTH 5
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
    input [`MEMORY_ADDR_WIDTH - 1 : 0]  sub_x_addr;
    input [`MEMORY_ADDR_WIDTH - 1 : 0]  sub_b_addr;
    input [`MEMORY_ADDR_WIDTH - 1 : 0]  sub_y_addr;

    // interface to the main memory
    output [`MEMORY_ADDR_WIDTH - 1 : 0] mem_addr;
    output mem_en;
    input  mem_rdy;
    input  [`MEMORY_DATA_WIDTH - 1 : 0] mem_data_in;
    output [`MEMORY_DATA_WIDTH - 1 : 0] mem_data_out;

    // interface to the memristor crossbar
    output [`DAC_BIT_WIDTH * `CROSSBAR_SIZE - 1 : 0] DAC_out;
    input  [`ADC_BIT_WIDTH * `CROSSBAR_SIZE - 1 : 0] ADC_in;
    output [`MUX_SEL_WIDTH * `CROSSBAR_SIZE - 1 : 0] mux_sel;

    reg [`STATE_WIDTH - 1 : 0] state;
    reg [5:0] curr_iter_num;
    reg [`CROSSBAR_SIZE_BIN - 1 : 0] curr_prog_diag_idx;
    reg [`DAC_BIT_WIDTH - 1 : 0] target_resistance[`CROSSBAR_SIZE_BIN - 1 : 0];
    reg [`DATA_WIDTH - 1 : 0] sub_b[`CROSSBAR_SIZE_BIN - 1 : 0];
    reg [`CROSSBAR_SIZE_BIN - 1 : 0] sub_b_ld_count;

    
    wire [`DATA_WIDTH - 1 : 0] m_in_1;
    wire [`DATA_WIDTH - 1 : 0] m_in_2;
    wire [`DATA_WIDTH - 1 : 0] m_result;
    wire [`DATA_WIDTH - 1 : 0] a_in_1;
    wire [`DATA_WIDTH - 1 : 0] a_in_2;
    wire [`DATA_WIDTH - 1 : 0] a_result;


    assign m_in_1 = mem_data_in;
    assign m_in_2 = ADC_in[`DATA_WIDTH - 1 : 0];
    assign DAC_out[`DATA_WIDTH - 1 : 0] = m_result;
    
    multiplier u_multiplier(clk, rstn, m_in_1, m_in_2, m_result);

    assign a_in_1 = mem_data_in;
    assign a_in_2 = ADC_in[`DATA_WIDTH - 1 : 0];
    assign DAC_out[2 * `DATA_WIDTH - 1 : `DATA_WIDTH] = a_result;
    
    adder u_adder(clk, rstn, a_in_1, a_in_2, a_result);

    always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
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



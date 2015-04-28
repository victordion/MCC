// this is the MCC controller block
// Author: Jianwei Cui
// Date: 04/20/2015
// All Rights Reserved
// Modified on: Fri Apr 24 14:33:00 EDT 2015
/*
`define DAC_BIT_WIDTH 32
`define ADC_BIT_WIDTH 32
`define MEMORY_ADDR_WIDTH 32
`define MEMORY_DATA_WIDTH 32
`define CROSSBAR_SIZE 32
`define CROSSBAR_SIZE_BIN 5
`define MUX_SEL_WIDTH 5
`define STATE_WIDTH 5
*/

`define XBAR_SIZE 32
`define XBAR_SIZE_BIN 5
`define DATA_WIDTH 8
`define TGT_MTX_ROWS 1024
`define TGT_MTX_COLS 1024
`define TGT_MTX_COLS_BIN 10
`define TGT_MTX_ROWS_BIN 10
module mcc(
   
 
    clk,
    rstn,
    x_values_in,
    x_values_valid_in,
    b_value_in,
    b_diag_in,
    b_offset_in,
    block_valid_in,
    new_diagonal,

    adc_in,
    adc_valid_in,
    dac_out,
    dac_valid_out,
    dac_en,
    
    x_value_idx_in,
    y_value_idx_in,

    y_value_request,
    y_values_out,
    y_values_valid,
    mux_sel
 );

    integer c;
    
    reg [`DATA_WIDTH - 1 : 0] internal_x[0 : `TGT_MTX_COLS - 1];
    reg [`DATA_WIDTH - 1 : 0] internal_y[0 : `TGT_MTX_ROWS - 1];
    reg [`TGT_MTX_COLS_BIN - 1 : 0] internal_x_offset;

    input clk;
    input rstn;
    input [`DATA_WIDTH - 1    : 0] x_values_in;
    input  x_values_valid_in;
    input [`DATA_WIDTH - 1 : 0]    b_value_in;
    input [`XBAR_SIZE_BIN - 1 : 0] b_diag_in;
    input [`XBAR_SIZE_BIN - 1 : 0] b_offset_in;
    input block_valid_in;
    input new_diagonal;
    input dac_en;

    input [0 : `XBAR_SIZE * `TGT_MTX_COLS_BIN - 1] x_value_idx_in;
    input [0 : `XBAR_SIZE * `TGT_MTX_ROWS_BIN - 1] y_value_idx_in;

    input [0 : `DATA_WIDTH * `XBAR_SIZE - 1] adc_in;
    input adc_valid_in;
    output [0 : `DATA_WIDTH * `XBAR_SIZE - 1] dac_out;
    output dac_valid_out;

    input y_value_request;
    output reg [`DATA_WIDTH - 1 : 0] y_values_out;
    output y_values_valid;

    output [`XBAR_SIZE_BIN * `XBAR_SIZE - 1 : 0] mux_sel;

    reg [`XBAR_SIZE * `DATA_WIDTH - 1 : 0] x_values_reg;
    
    reg [`DATA_WIDTH - 1 : 0] dac_data_reg [0: `XBAR_SIZE - 1];
    reg [`DATA_WIDTH - 1 : 0] adc_data_reg [0: `XBAR_SIZE - 1];

    reg [`TGT_MTX_COLS_BIN - 1 : 0] x_value_idx_reg[0 : `XBAR_SIZE - 1];
    reg [`TGT_MTX_ROWS_BIN - 1 : 0] y_value_idx_reg[0 : `XBAR_SIZE - 1];
    
 
  genvar j; 
  generate
  for(j = 0; j < `XBAR_SIZE; j = j + 1) begin:x_value_idx
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)
            x_value_idx_reg[j] <=0 ;
        else
            x_value_idx_reg[j] <= x_value_idx_in[j * `TGT_MTX_COLS_BIN : j * `TGT_MTX_COLS_BIN + `TGT_MTX_COLS_BIN - 1];
    end

  end
  endgenerate

 
  genvar j; 
  generate
  for(j = 0; j < `XBAR_SIZE; j = j + 1) begin:y_value_idx
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)
            y_value_idx_reg[j] <=0 ;
        else
            y_value_idx_reg[j] <= y_value_idx_in[j * `TGT_MTX_ROWS_BIN : j * `TGT_MTX_ROWS_BIN + `TGT_MTX_ROWS_BIN - 1];
    end

  end
  endgenerate



    always@(posedge clk or negedge rstn) begin
        if(rstn == 0)
            for(c = 0; c < `TGT_MTX_COLS; c = c + 1)
                internal_x[c] = 0;
        else
            if(x_values_valid_in == 1) begin
                internal_x[internal_x_offset] = x_values_in;
            end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn)
            internal_x_offset = 0;
        else
            if(x_values_valid_in == 1'b1)
                internal_x_offset = internal_x_offset + 1;
            else
                internal_x_offset = 0;
    end


    always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
                for( c = 0; c < `XBAR_SIZE; c = c + 1) begin
                    dac_data_reg[c] <= 0;
                end
        end
        else begin
            dac_data_reg[b_offset_in] <= b_value_in; 
        end
    end


    genvar i;
    generate
    for(i = 0; i < `XBAR_SIZE; i = i + 1) begin:m
        assign dac_out[i * `DATA_WIDTH : i * `DATA_WIDTH + `DATA_WIDTH - 1] = dac_en ? dac_data_reg[i] : 0;
    end
    endgenerate

    
    
  genvar j; 
  generate
  for(j = 0; j < `XBAR_SIZE; j = j + 1) begin:adc
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)
            adc_data_reg[j] <=0 ;
        else
            adc_data_reg[j] <= adc_in[j * `DATA_WIDTH : j * `DATA_WIDTH + `DATA_WIDTH - 1];
    end

  end
  endgenerate

  wire [`DATA_WIDTH - 1 : 0] sel_internal_y[0 : `XBAR_SIZE - 1];

  generate
  for(j = 0; j < `XBAR_SIZE; j = j + 1) begin:sel_internal_y_loop
      assign sel_internal_y[j] = internal_y[y_value_idx_reg[j]]; 
  end
  endgenerate
    
  reg [`DATA_WIDTH - 1 : 0] y_sub[0 : `XBAR_SIZE - 1];

  generate
  for(j = 0; j < `XBAR_SIZE; j = j + 1) begin:y_sub_loop
     always @ (posedge clk or negedge rstn) begin
         if(!rstn)
            y_sub[j] <= 0;
         else
            y_sub[j] <= adc_data_reg[j] + sel_internal_y[j];
     end
  end    
  endgenerate

  reg [`XBAR_SIZE_BIN - 1: 0] y_sub_counter;
  always @ (posedge clk or negedge rstn) begin
      if(!rstn)
          y_sub_counter = 0;
      else
          //if(write_back_en)
              y_sub_counter = y_sub_counter + 1;
  end

  always @ (posedge clk or negedge rstn) begin
      if(!rstn)
          
          internal_y[y_value_idx_reg[y_sub_counter]] = 0;
      else
          internal_y[y_value_idx_reg[y_sub_counter]] = y_sub[y_sub_counter];

  end
  /*
  genvar j;
  genvar k;
  generate
  for(j = 0; j < `TGT_MTX_ROWS; j = j + 1) begin:internal_y_loop
  always @ (posedge clk or negedge rstn) begin
      if(!rstn)
          internal_y[j] =  0;
      else
          generate
          
          internal_y[j] =  ;
      
  end
  end
  endgenerate
  */


  reg [`TGT_MTX_ROWS_BIN - 1 : 0]  mtx_y_value_out_count;
  always@(posedge clk or negedge rstn) begin
      if(!rstn)
          mtx_y_value_out_count <= 0;
      else
          if(y_value_request == 1'b1)
              mtx_y_value_out_count <= mtx_y_value_out_count + 1;
  end

 always@(posedge clk or negedge rstn) begin
      if(!rstn)
         y_values_out <= 0;
      else
         y_values_out <= internal_y[mtx_y_value_out_count];
  end



endmodule



/*
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
   


    reg [`STATE_WIDTH - 1 : 0] curr_state;
    reg [`STATE_WIDTH - 1 : 0] next_state;
    
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)     
            curr_state <= IDLE;  
        else     
            curr_state <= next_state;
    end

    always @ (curr_state) begin 
        case(curr_state)
            IDLE: begin
                if(ld_en == 1'b1) begin
                    next_state = LOAD_SUB_X;
                end
            end

            LOAD_SUB_X: begin
                next_state = LOAD_SUB_Y;
            end
            
            LOAD_SUB_Y: begin
                next_state = LOAD_SUB_B;
            end
            
            LOAD_SUB_B: begin
                if(sub_b_ld_count == 0) begin
                    next_state = PROG_CROSSBAR;
                end
            end
        
            PROG_CROSSBAR: begin
                if(curr_iter_num == ITER_MAX) begin
                    next_state = SENSE_CROSSBAR;
                end
            end
            
            SENSE_CROSSBAR: begin
                next_state = EVAL_CROSSBAR;
            end
            
            EVAL_CROSSBAR: begin
                next_state = MERGE_RESULT;
            end

            MERGE_RESULT: begin
                next_state = IDLE;
            end
        endcase
    end

    always @ (posedge clk or negedge rstn) begin
        if(!rstn)
             curr_prog_diag_idx = 0;
         else begin
             
             if(next_state == PROG_CROSSBAR && curr_prog_diag_idx < {`CROSSBAR_SIZE_BIN{1'b1}})
                 curr_prog_diag_idx = curr_prog_diag_idx + 1'b1;
         end
    end

endmodule

*/

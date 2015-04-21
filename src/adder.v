`define DATA_WIDTH 32

module adder(clk, rstn, in_1, in_2, result);
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
            result <= in_1 + in_2;
        end
    end

endmodule

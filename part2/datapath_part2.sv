module datapath_part2(
    input  logic                 clk,
    input  logic                 rst,
    input  logic signed  [13:0]  input_data,
    input  logic         [1:0]   addr_x,
    input  logic                 wr_en_x,
    input  logic         [3:0]   addr_w,
    input  logic                 wr_en_w,
    input  logic                 clear_acc,
    input  logic                 en_acc,
    output logic signed [27:0]   output_data
);

logic signed [13:0] data_x;
logic signed [13:0] data_w;

logic signed [27:0] mult_result;

logic signed [27:0] adder_result;
logic signed [27:0] reg_accum;

assign output_data = reg_accum;

//Memory X
memory#(
    .WIDTH(14),
    .SIZE(3)
) memory_x(
    .data_in(input_data),
    .data_out(data_x),
    .addr(addr_x),
    .clk(clk),
    .wr_en(wr_en_x)
);

//Memory W
memory#(
    .WIDTH(14),
    .SIZE(9)
) memory_w(
    .data_in(input_data),
    .data_out(data_w),
    .addr(addr_w),
    .clk(clk),
    .wr_en(wr_en_w)
);

//Multiplier
multiplier #(
    .WIDTH(14)
) mult(
    .A(data_x),
    .B(data_w),
    .S(mult_result)
);

adder_sat #(
    .WIDTH(28)
) adder(
    .A(mult_result),
    .B(reg_accum),
    .S(adder_result)
);

//Register accum
always_ff @(posedge clk) begin 
    if (clear_acc) begin 
        reg_accum <= 'b0;
    end else if (en_acc) begin 
        reg_accum <= adder_result;
    end
end


endmodule: datapath_part2
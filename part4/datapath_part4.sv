module datapath_part4(
    input  logic                 clk,
    input  logic                 rst,
    input  logic signed  [13:0]  input_data,
    input  logic         [2:0]   addr_x,
    input  logic                 wr_en_x,
    input  logic         [5:0]   addr_w,
    input  logic                 wr_en_w,
    input  logic                 clear_acc,
    input  logic                 en_acc,
    output logic signed [27:0]   output_data
);

logic signed [13:0] data_x;
logic signed [13:0] data_w;
logic signed [13:0] data_x_mem[8];
logic signed [13:0] data_w_mem[8];
logic wr_en_x_mem[8];
logic wr_en_w_mem[8];

logic signed [27:0] mult_result;

logic signed [27:0] adder_result;
logic signed [27:0] reg_accum;

logic [2:0] prev_addr_x;
logic [5:0] prev_addr_w;

assign output_data = reg_accum;

always_ff @(posedge clk) begin
    prev_addr_w <= addr_w;
    prev_addr_x <= addr_x;
end

//Memories X
generate
    for (genvar i=0; i<8; i++) begin : gen_x_memories

        assign wr_en_x_mem[i] = (wr_en_x && (addr_x==i));

        memory#(
            .WIDTH(14),
            .SIZE(1)
        ) memory_x (
            .data_in(input_data),
            .data_out(data_x_mem[i]),
            .addr(2'b0),
            .clk(clk),
            .wr_en(wr_en_x_mem[i])
        );
    end
endgenerate

assign data_x = data_x_mem[prev_addr_x];

//Memories W
generate
    for (genvar i=0; i<8; i++) begin : gen_w_memories

        assign wr_en_w_mem[i] = (wr_en_w && (addr_w[2:0]==i));

        memory#(
            .WIDTH(14),
            .SIZE(8)
        ) memory_w (
            .data_in(input_data),
            .data_out(data_w_mem[i]),
            .addr(addr_w[5:3]),
            .clk(clk),
            .wr_en(wr_en_w_mem[i])
        );

    end
endgenerate

assign data_w = data_w_mem[prev_addr_w[2:0]];

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


endmodule: datapath_part4
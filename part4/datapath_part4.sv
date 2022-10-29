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
    input  logic                 en_pipe,
    output logic signed [27:0]   output_data
);

logic signed [13:0] data_x_mem[8];
logic signed [13:0] data_w_mem[8];
logic wr_en_x_mem[8];
logic wr_en_w_mem[8];

logic signed [27:0] mult_results[8];
logic signed [27:0] mult_results_reg[8];
logic signed [27:0] mult_results_reg2[5:7];

logic signed [27:0] adder_results[7];
logic signed [27:0] adder_result_reg;
logic signed [27:0] reg_accum;


genvar i;

assign output_data = reg_accum;


//Memories X
generate
    for (i=0; i<8; i++) begin : gen_x_memories

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


//Memories W
generate
    for (i=0; i<8; i++) begin : gen_w_memories

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


//Multipliers
generate
    for (i=0; i<8; i++) begin : gen_multipliers
        
        multiplier #(
            .WIDTH(14)
        ) mult(
            .A(data_x_mem[i]),
            .B(data_w_mem[i]),
            .S(mult_results[i])
        );

    end
endgenerate

//Register Multiplieer result
always_ff @(posedge clk) begin
    if (en_pipe) begin
        mult_results_reg <= mult_results;
        mult_results_reg2 <= mult_results_reg[5:7];
    end
end

//Adders
generate
    //First adder
    adder_sat#(
        .WIDTH(28)
    ) adder_0(
        .A(mult_results_reg[0]),
        .B(mult_results_reg[1]),
        .S(adder_results[0])
    );
    //Adders 1-3
    for (i=0; i<3; i++) begin : gen_adders_1_3
        adder_sat #(
            .WIDTH(28)
        ) adder (
            .A(mult_results_reg[i+2]),
            .B(adder_results[i]),
            .S(adder_results[i+1])
        );
    end
    //Adderss 4-6 after register
    adder_sat#(
        .WIDTH(28)
    ) adder_4(
        .A(mult_results_reg2[5]),
        .B(adder_result_reg),
        .S(adder_results[4])
    );
    for (i=4; i<6; i++) begin : gen_adders_5_6
        adder_sat#(
        .WIDTH(28)
    ) adder_4(
        .A(mult_results_reg2[i+2]),
        .B(adder_results[i]),
        .S(adder_results[i+1])
    );
    end
endgenerate

//Register Adder
always_ff @(posedge clk) begin
    if (en_pipe) begin
        adder_result_reg <= adder_results[3];
    end
end


//Register accum
always_ff @(posedge clk) begin 
    if (clear_acc) begin 
        reg_accum <= 'b0;
    end else if (en_acc) begin 
        reg_accum <= adder_results[6];
    end
end


endmodule: datapath_part4
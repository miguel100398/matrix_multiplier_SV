module matvec3_part1(clk, reset, input_valid, input_ready,
                    input_data, output_valid, output_ready, output_data);

    input   logic clk, reset, input_valid, output_ready;
    input   logic signed [13:0] input_data;
    output  logic signed [27:0] output_data;
    output  logic output_valid, input_ready;

    logic [3:0] addr_w;
    logic [1:0] addr_x;
    logic wr_en_x;
    logic wr_en_w;
    logic clear_acc;
    logic en_acc;

    control_part1 control(
        .clk(clk),
        .rst(reset),
        .input_valid(input_valid),
        .output_ready(output_ready),
        .addr_x(addr_x),
        .wr_en_x(wr_en_x),
        .addr_w(addr_w),
        .wr_en_w(wr_en_w),
        .clear_acc(clear_acc),
        .en_acc(en_acc),
        .input_ready(input_ready),
        .output_valid(output_valid)
    );

    datapath_part1 datapath(
        .clk(clk),
        .rst(reset),
        .input_data(input_data),
        .addr_x(addr_x),
        .wr_en_x(wr_en_x),
        .addr_w(addr_w),
        .wr_en_w(wr_en_w),
        .clear_acc(clear_acc),
        .en_acc(en_acc),
        .output_data(output_data)
    );

endmodule: matvec3_part1
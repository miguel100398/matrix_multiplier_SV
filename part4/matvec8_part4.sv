module matvec8_part4(clk, reset, input_valid, input_ready,
input_data, new_matrix, output_valid, output_ready, output_data);

    input   logic clk, reset, input_valid, output_ready, new_matrix;
    input   logic signed [13:0] input_data;
    output  logic signed [27:0] output_data;
    output  logic output_valid, input_ready;

    logic [5:0] addr_w;
    logic [2:0] addr_x;
    logic wr_en_x;
    logic wr_en_w;
    logic clear_acc;
    logic en_acc;
    logic en_pipe;

    control_part4 control(
        .clk(clk),
        .rst(reset),
        .input_valid(input_valid),
        .output_ready(output_ready),
        .new_matrix(new_matrix),
        .addr_x(addr_x),
        .en_pipe(en_pipe),
        .wr_en_x(wr_en_x),
        .addr_w(addr_w),
        .wr_en_w(wr_en_w),
        .clear_acc(clear_acc),
        .en_acc(en_acc),
        .input_ready(input_ready),
        .output_valid(output_valid)
    );

    datapath_part4 datapath(
        .clk(clk),
        .rst(reset),
        .input_data(input_data),
        .addr_x(addr_x),
        .wr_en_x(wr_en_x),
        .addr_w(addr_w),
        .wr_en_w(wr_en_w),
        .clear_acc(clear_acc),
        .en_acc(en_acc),
        .output_data(output_data),
        .en_pipe(en_pipe)
    );

endmodule: matvec8_part4
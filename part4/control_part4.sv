module control_part4(
    input   logic           clk,
    input   logic           rst,
    input   logic           input_valid,
    input   logic           output_ready,
    input   logic           new_matrix,
    output  logic [2:0]     addr_x,
    output  logic           wr_en_x,
    output  logic [5:0]     addr_w,
    output  logic           wr_en_w,
    output  logic           clear_acc,
    output  logic           en_acc,
    output  logic           input_ready,
    output  logic           output_valid,
    output  logic           en_pipe
);

//TODO: Add more memories and multipliers to increase parallelism
//TODO: Add pipeline Mult 7 stages + adders

//State
typedef enum logic[2:0] {RST, WAIT_NEW_MATRIX, WAIT_W, WAIT_X, MULT, SEND_DATA, WAIT_RESULT} state_t;

state_t state, next_state;

logic[5:0] cntr1;
logic[2:0] cntr2;
logic[2:0] cntr3;
logic[2:0] cntr2_prev;

logic en_cntr1;
logic en_cntr2;

logic cntr1_done;
logic cntr2_done;
logic cntr3_done;

logic en_acc_q;

logic set_done_mult;
logic done_mult;
logic clear_done_mult;

logic waiting_output_ready;

logic output_valid_q[5];

genvar i;

assign cntr1_done = (cntr1 == 6'd63);
assign cntr2_done = (cntr2 == 3'd7);
assign cntr3_done = (cntr3 == 3'd7);


//FSM
always_ff @(posedge clk) begin 
    if (rst) begin 
        state <= RST;
    end else begin 
        state <= next_state;
    end
end

//Next state
always_comb begin 
    case(state)
        RST: begin 
            next_state = WAIT_NEW_MATRIX;
        end
        WAIT_NEW_MATRIX : begin
            if (input_valid) begin 
                if (new_matrix) begin 
                    next_state = WAIT_W;
                end else begin
                    next_state = WAIT_X;
                end
            end else begin 
                next_state = WAIT_NEW_MATRIX;
            end
        end 
        WAIT_W: begin 
            if (cntr1_done && input_valid) begin 
                next_state = WAIT_X;
            end else begin 
                next_state = WAIT_W;
            end
        end 
        WAIT_X: begin
            if (cntr2_done && input_valid) begin 
                next_state = MULT;
            end else begin 
                next_state = WAIT_X;
            end
        end
        MULT: begin 
            if (cntr3_done && ~waiting_output_ready) begin
                next_state = WAIT_NEW_MATRIX;
            end else begin
                next_state = MULT;
            end
        end
        WAIT_RESULT : begin
            next_state = SEND_DATA;
        end
        SEND_DATA: begin
            if (output_ready) begin 
                if (done_mult) begin 
                    next_state = WAIT_NEW_MATRIX;
                end else begin
                    next_state = MULT;
                end
            end else begin
                next_state = SEND_DATA;
            end
        end
        default: begin
            next_state = RST;
        end
    endcase
end

//Outputs
always_comb begin 
    addr_x  = 2'b0;
    wr_en_x = 1'b0;
    addr_w  = 3'b0;
    wr_en_w = 1'b0;
    clear_acc = 1'b0;
    en_acc  = 1'b0;
    input_ready = 1'b0;
    output_valid_q[4] = 1'b0;
    en_cntr1 = 1'b0;
    en_cntr2 = 1'b0;
    clear_done_mult = 1'b0;
    set_done_mult = 1'b0;
    output_valid = 1'b0;
    en_pipe = 1'b0;
    case(state)
        RST: begin
           clear_acc = 1'b1; 
           clear_done_mult = 1'b1;
        end
        WAIT_NEW_MATRIX: begin
            addr_w = cntr1;
            addr_x = cntr2;
            en_cntr1 = (input_valid && new_matrix);
            en_cntr2 = (input_valid && ~new_matrix);
            wr_en_w  = (input_valid && new_matrix);
            wr_en_x  = (input_valid && ~new_matrix);
            input_ready = 1'b1;
            clear_done_mult = 1'b1; 
        end
        WAIT_W: begin
            addr_w = cntr1;
            en_cntr1 = input_valid;
            wr_en_w = input_valid;
            input_ready = 1'b1; 
        end
        WAIT_X: begin
            addr_x = cntr2;
            en_cntr2 = input_valid;
            wr_en_x = input_valid;
            input_ready = 1'b1;
        end
        MULT: begin
            addr_w[5:3] = (~waiting_output_ready) ? cntr2 : cntr2_prev;
            addr_w[2:0] = 3'b0;
            addr_x = (~waiting_output_ready) ? cntr2 : cntr2_prev;
            en_acc = ~waiting_output_ready;
            en_cntr2 = ~waiting_output_ready;
            set_done_mult = (cntr2_done);
            output_valid_q[4] = 1'b1;
            output_valid = output_valid_q[0];
            en_pipe = (~waiting_output_ready);
        end
        SEND_DATA: begin
            clear_acc = output_ready;
        end
        default: begin
            addr_x  = 2'b0;
            wr_en_x = 1'b0;
            addr_w  = 3'b0;
            wr_en_w = 1'b0;
            clear_acc = 1'b0;
            en_acc  = 1'b0;
            input_ready = 1'b0;
            en_cntr1 = 1'b0;
            en_cntr2 = 1'b0;
        end
    endcase
end

//done_mult
always_ff @(posedge clk) begin
    if (set_done_mult) begin
        done_mult <= 1'b1;
    end else if (clear_done_mult) begin
        done_mult <= 1'b0;
    end
end

//Waiting output ready
assign waiting_output_ready = output_valid && ~output_ready;

//Delay output valid Depening on Pipe Stages
// READ_MEM + WRITE_ACC + WRITE_MULT + ADDERS + MULT_INT
// 1        +     1     +     1      +   1    +    1

generate
    for (i=0; i<4; i++) begin : gen_output_valid_delay
        always_ff @(posedge clk) begin
            output_valid_q[i] <= output_valid_q[i+1];
        end
    end
endgenerate

//Previous value of counter2
assign cntr2_prev = cntr2 - 1'b1;

///Counters
always_ff @(posedge clk) begin 
    if (rst) begin 
        cntr1 <= 6'b0;
    end else if (en_cntr1) begin 
        if (cntr1_done) begin 
            cntr1 <= 6'b0;
        end else begin 
            cntr1 <= cntr1 + 1'b1;
        end
    end
end

always_ff @(posedge clk) begin 
    if (rst) begin 
        cntr2 <= 3'b0;
    end else if (en_cntr2) begin 
        if (cntr2_done || (next_state == WAIT_NEW_MATRIX)) begin 
            cntr2 <= 3'b0;
        end else begin 
            cntr2 <= cntr2 + 1'b1;
        end
    end
end

always_ff @(posedge clk) begin 
    if (rst) begin 
        cntr3 <= 3'b0;
    end else if (cntr3_done && ~waiting_output_ready) begin 
        cntr3 <= 3'b0;
    end else if (output_valid && output_ready) begin 
        cntr3 <= cntr3 + 1'b1;
    end
end


endmodule: control_part4
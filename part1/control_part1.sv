module control_part1(
    input   logic           clk,
    input   logic           rst,
    input   logic           input_valid,
    input   logic           output_ready,
    output  logic [1:0]     addr_x,
    output  logic           wr_en_x,
    output  logic [3:0]     addr_w,
    output  logic           wr_en_w,
    output  logic           clear_acc,
    output  logic           en_acc,
    output  logic           input_ready,
    output  logic           output_valid
);

//State
typedef enum logic[2:0] {RST, WAIT_W, WAIT_X, MULT, SEND_DATA} state_t;

state_t state, next_state;

logic[3:0] cntr1;
logic[1:0] cntr2;

logic en_cntr1;
logic en_cntr2;

logic cntr1_done;
logic cntr2_done;

assign cntr1_done = (cntr1 == 4'd8);
assign cntr2_done = (cntr2 == 2'd2);

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
            next_state = WAIT_W;
        end 
        WAIT_W: begin 
            if (cntr1_done) begin 
                next_state = WAIT_X;
            end else begin 
                next_state = WAIT_W;
            end
        end 
        WAIT_X: begin
            if (cntr2_done) begin 
                next_state = MULT;
            end else begin 
                next_state = WAIT_X;
            end
        end
        MULT: begin 
            if (cntr2_done) begin 
                next_state = SEND_DATA;
            end else begin 
                next_state = MULT;
            end
        end
        SEND_DATA: begin
            if (output_ready) begin 
                if (cntr1_done) begin 
                    next_state = WAIT_W;
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
    output_valid = 1'b0;
    en_cntr1 = 1'b0;
    en_cntr2 = 1'b0;
    case(state)
        RST: begin
           clear_acc = 1'b1; 
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
            addr_w = cntr1;
            addr_x = cntr2;
            en_acc = 1'b1;
            en_cntr1 = 1'b1;
            en_cntr2 = 1'b1;
        end
        SEND_DATA: begin
            clear_acc = output_ready;
            output_valid = 1'b1; 
        end
        default: begin
            addr_x  = 2'b0;
            wr_en_x = 1'b0;
            addr_w  = 3'b0;
            wr_en_w = 1'b0;
            clear_acc = 1'b0;
            en_acc  = 1'b0;
            input_ready = 1'b0;
            output_valid = 1'b0;
            en_cntr1 = 1'b0;
            en_cntr2 = 1'b0;
        end
    endcase
end


///Counters
always_ff @(posedge clk) begin 
    if (rst) begin 
        cntr1 <= 4'b0;
    end else if (en_cntr1) begin 
        if (cntr1_done) begin 
            cntr1 <= 4'b0;
        end else begin 
            cntr1 <= cntr1 + 1'b1;
        end
    end
end

always_ff @(posedge clk) begin 
    if (rst) begin 
        cntr2 <= 2'b0;
    end else if (en_cntr2) begin 
        if (cntr2_done) begin 
            cntr2 <= 2'b0;
        end else begin 
            cntr2 <= cntr2 + 1'b1;
        end
    end
end


endmodule: control_part1
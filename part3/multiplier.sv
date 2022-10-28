module multiplier#(
    parameter WIDTH = 14
)(
    input  logic signed [WIDTH-1:0] A,
    input  logic signed [WIDTH-1:0] B,
    output logic signed [(WIDTH*2)-1:0] S
);

    assign S = $signed(A) * $signed(B);

endmodule: multiplier
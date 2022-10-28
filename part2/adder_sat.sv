module adder_sat#(
    parameter WIDTH = 14
)(
    input  logic signed [WIDTH-1:0] A,
    input  logic signed [WIDTH-1:0] B,
    output logic signed [WIDTH-1:0] S
);

localparam logic signed [WIDTH-1:0] MAX_VALUE = (2**(WIDTH-1)) - 1;
localparam logic signed [WIDTH-1:0] MIN_VALUE = -(2**(WIDTH-1));

logic signed [WIDTH:0] add_result;

assign add_result = $signed(A) + $signed(B);


//Saturate value
assign S = ($signed(add_result) >= $signed(MAX_VALUE))? $signed(MAX_VALUE) : ($signed(add_result) <= $signed(MIN_VALUE)) ? $signed(MIN_VALUE) : $signed(add_result[27:0]);

endmodule: adder_sat
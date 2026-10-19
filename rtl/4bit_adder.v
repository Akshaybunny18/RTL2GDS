module 4bit_adder(
    input wire [3:0] A, B,
    input wire Cin,
    output wire [3:0] Sum,
    output wire Cout
);
    wire [4:0] C;
    assign C[0] = Cin;
    assign Cout = C[4];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : FA
            full_adder U (
                A[i], B[i], C[i],
                Sum[i], C[i+1]
            );
        end
    endgenerate

endmodule
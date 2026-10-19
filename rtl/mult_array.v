module mult_array(
    input        clk,
    input        rst_n,
    input  [3:0] a,
    input  [3:0] b,
    output reg [7:0] p
);
    // Input registers (8 flip-flops)
    reg [3:0] a_r, b_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r <= 4'b0;
            b_r <= 4'b0;
        end else begin
            a_r <= a;
            b_r <= b;
        end
    end

    // Partial products: pp[i][j] = a_r[j] & b_r[i]  (16 AND gates)
    wire [3:0] pp [0:3];
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_pp
            for (j = 0; j < 4; j = j + 1) begin : g_bit
                assign pp[i][j] = a_r[j] & b_r[i];
            end
        end
    endgenerate

    // r[i]: 4 bits passed down from row i to row i+1
    wire [3:0] r [0:3];
    // s[i], c[i]: sums and carries of the full-adder row i (rows 1..3)
    wire [3:0] s [1:3];
    wire [4:0] c [1:3];

    // Row 0: AND gates only
    assign r[0] = {1'b0, pp[0][3], pp[0][2], pp[0][1]};

    // Rows 1..3: 4 full adders each (12 in total)
    generate
        for (i = 1; i < 4; i = i + 1) begin : g_row
            assign c[i][0] = 1'b0;
            for (j = 0; j < 4; j = j + 1) begin : g_fa
                full_adder fa (
                    .a   (pp[i][j]),
                    .b   (r[i-1][j]),
                    .cin (c[i][j]),
                    .sum (s[i][j]),
                    .cout(c[i][j+1])
                );
            end
            assign r[i] = {c[i][4], s[i][3], s[i][2], s[i][1]};
        end
    endgenerate

    // Product bits
    wire [7:0] prod;
    assign prod[0]   = pp[0][0];
    assign prod[1]   = s[1][0];
    assign prod[2]   = s[2][0];
    assign prod[3]   = s[3][0];
    assign prod[7:4] = r[3];

    // Output register (8 flip-flops)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) p <= 8'b0;
        else        p <= prod;
    end
endmodule

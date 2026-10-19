`timescale 1ns/1ps

module tb_mult;
    reg        clk;
    reg        rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;

    integer i, j;
    integer errors;
    reg [7:0] expected;

    mult_array dut (
        .clk  (clk),
        .rst_n(rst_n),
        .a    (a),
        .b    (b),
        .p    (p)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);
    end

    initial begin
        errors = 0;
        a = 4'd0;
        b = 4'd0;
        rst_n = 1'b0;

        // hold reset low for the first 2 cycles
        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;

        // apply all 256 combinations
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i[3:0];
                b = j[3:0];
                // 2-cycle latency: inputs captured at edge 1, product at edge 2
                repeat (2) @(posedge clk);
                #1;
                expected = a * b;
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d", a, b, expected, p);
                end
            end
        end

        if (errors == 0)
            $display("PASS: 256 vectors checked, 0 errors");
        else
            $display("FAIL: 256 vectors checked, %0d errors", errors);

        $finish;
    end
endmodule

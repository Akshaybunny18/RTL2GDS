module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    // assign sum = a ^ b; // this is for error injection deliverable
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

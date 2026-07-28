
module kogge_stone_adder(
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,
    output [7:0] SUM,
    output       Cout
);

    // Bitwise generate and propagate
    wire [7:0] G, P;
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin
            and g(G[i], A[i], B[i]);   // Generate
            xor p(P[i], A[i], B[i]);   // Propagate
        end
    endgenerate

    // Stage 1: distance 1
    wire [7:0] G1, P1;
    assign G1[0] = G[0]; assign P1[0] = P[0];
    generate
        for (i=1; i<8; i=i+1) begin : stage1
            wire tmp;
            and a(P1[i], P[i], P[i-1]);
            and b(tmp, P[i], G[i-1]);
            or  o(G1[i], G[i], tmp);
        end
    endgenerate

    // Stage 2: distance 2
    wire [7:0] G2, P2;
    assign G2[0]=G1[0]; assign G2[1]=G1[1];
    assign P2[0]=P1[0]; assign P2[1]=P1[1];
    generate
        for (i=2; i<8; i=i+1) begin : stage2
            wire tmp;
            and a(P2[i], P1[i], P1[i-2]);
            and b(tmp, P1[i], G1[i-2]);
            or  o(G2[i], G1[i], tmp);
        end
    endgenerate

    // Stage 3: distance 4
    wire [7:0] G3, P3;
    assign G3[0]=G2[0]; assign G3[1]=G2[1];
    assign G3[2]=G2[2]; assign G3[3]=G2[3];
    assign P3[0]=P2[0]; assign P3[1]=P2[1];
    assign P3[2]=P2[2]; assign P3[3]=P2[3];
    generate
        for (i=4; i<8; i=i+1) begin : stage3
            wire tmp;
            and a(P3[i], P2[i], P2[i-4]);
            and b(tmp, P2[i], G2[i-4]);
            or  o(G3[i], G2[i], tmp);
        end
    endgenerate

    // Carry signals
    wire [7:0] C;
    // C[0] = Cin
    assign C[0] = Cin;

    // C[1] = G[0] | (P[0] & Cin)
    wire c1tmp;
    and a1(c1tmp, P[0], Cin);
    or  o1(C[1], G[0], c1tmp);

    // C[2] = G1[1] | (P1[1] & Cin)
    wire c2tmp;
    and a2(c2tmp, P1[1], Cin);
    or  o2(C[2], G1[1], c2tmp);

    // C[3] = G2[2] | (P2[2] & Cin)
    wire c3tmp;
    and a3(c3tmp, P2[2], Cin);
    or  o3(C[3], G2[2], c3tmp);

    // C[4] = G3[3] | (P3[3] & Cin)
    wire c4tmp;
    and a4(c4tmp, P3[3], Cin);
    or  o4(C[4], G3[3], c4tmp);

    // C[5] = G3[4] | (P3[4] & Cin)
    wire c5tmp;
    and a5(c5tmp, P3[4], Cin);
    or  o5(C[5], G3[4], c5tmp);

    // C[6] = G3[5] | (P3[5] & Cin)
    wire c6tmp;
    and a6(c6tmp, P3[5], Cin);
    or  o6(C[6], G3[5], c6tmp);

    // C[7] = G3[6] | (P3[6] & Cin)
    wire c7tmp;
    and a7(c7tmp, P3[6], Cin);
    or  o7(C[7], G3[6], c7tmp);

    // Cout = G3[7] | (P3[7] & Cin)
    wire couttmp;
    and a8(couttmp, P3[7], Cin);
    or  o8(Cout, G3[7], couttmp);

    // Sum outputs
    generate
        for (i=0; i<8; i=i+1) begin : sum_stage
            xor s(SUM[i], P[i], C[i]);
        end
    endgenerate

endmodule


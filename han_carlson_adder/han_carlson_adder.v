
module han_carlson_adder(
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,
    output [7:0] SUM,
    output       Cout
);

    // Step 1: bitwise generate and propagate
    wire [7:0] G, P;
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin
            and g(G[i], A[i], B[i]);   // Generate
            xor p(P[i], A[i], B[i]);   // Propagate
        end
    endgenerate

    // Step 2: prefix tree (Han-Carlson structure)
    // Stage 1: sparse (like Brent-Kung, every other bit)
    wire G1_1, G1_3, G1_5, G1_7;
    wire P1_1, P1_3, P1_5, P1_7;

    and a11(P1_1, P[1], P[0]);
    or  o11(G1_1, G[1], (P[1] & G[0]));

    and a13(P1_3, P[3], P[2]);
    or  o13(G1_3, G[3], (P[3] & G[2]));

    and a15(P1_5, P[5], P[4]);
    or  o15(G1_5, G[5], (P[5] & G[4]));

    and a17(P1_7, P[7], P[6]);
    or  o17(G1_7, G[7], (P[7] & G[6]));

    // Stage 2: dense (like Kogge-Stone, distance 2)
    wire G2_2, G2_3, G2_6, G2_7;
    wire P2_2, P2_3, P2_6, P2_7;

    and a22(P2_2, P[2], P1_1);
    or  o22(G2_2, G[2], (P[2] & G1_1));

    and a23(P2_3, P1_3, P1_1);
    or  o23(G2_3, G1_3, (P1_3 & G1_1));

    and a26(P2_6, P[6], P1_5);
    or  o26(G2_6, G[6], (P[6] & G1_5));

    and a27(P2_7, P1_7, P1_5);
    or  o27(G2_7, G1_7, (P1_7 & G1_5));

    // Stage 3: sparse again (distance 4)
    wire G3_7, P3_7;
    and a37(P3_7, P2_7, P2_3);
    or  o37(G3_7, G2_7, (P2_7 & G2_3));

    // Step 3: compute carries
    wire [7:0] C;
    assign C[0] = Cin;

    // C[1] = G[0] | (P[0] & Cin)
    wire c1tmp;
    and a1(c1tmp, P[0], Cin);
    or  o1(C[1], G[0], c1tmp);

    // C[2] = G1_1 | (P1_1 & Cin)
    wire c2tmp;
    and a2(c2tmp, P1_1, Cin);
    or  o2(C[2], G1_1, c2tmp);

    // C[3] = G2_2 | (P2_2 & Cin)
    wire c3tmp;
    and a3(c3tmp, P2_2, Cin);
    or  o3(C[3], G2_2, c3tmp);

    // C[4] = G2_3 | (P2_3 & Cin)
    wire c4tmp;
    and a4(c4tmp, P2_3, Cin);
    or  o4(C[4], G2_3, c4tmp);

    // C[5] = G[4] | (P[4] & C[4])
    wire c5tmp;
    and a5(c5tmp, P[4], C[4]);
    or  o5(C[5], G[4], c5tmp);

    // C[6] = G2_6 | (P2_6 & C[4])
    wire c6tmp;
    and a6(c6tmp, P2_6, C[4]);
    or  o6(C[6], G2_6, c6tmp);

    // C[7] = G2_7 | (P2_7 & C[4])
    wire c7tmp;
    and a7(c7tmp, P2_7, C[4]);
    or  o7(C[7], G2_7, c7tmp);

    // Cout = G3_7 | (P3_7 & Cin)
    wire couttmp;
    and a8(couttmp, P3_7, Cin);
    or  o8(Cout, G3_7, couttmp);

    // Step 4: compute sums
    generate
        for (i=0; i<8; i=i+1) begin : sum_stage
            xor s(SUM[i], P[i], C[i]);
        end
    endgenerate

endmodule


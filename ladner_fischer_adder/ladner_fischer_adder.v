
module ladner_fischer_adder(
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

    // Step 2: Ladner-Fischer prefix tree
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

    // Stage 2: distance 2 (sparse connections)
    wire [7:0] G2, P2;
    assign G2[0]=G1[0]; assign G2[1]=G1[1];
    assign P2[0]=P1[0]; assign P2[1]=P1[1];
    generate
        for (i=2; i<8; i=i+2) begin : stage2
            wire tmp;
            and a(P2[i], P1[i], P1[i-2]);
            and b(tmp, P1[i], G1[i-2]);
            or  o(G2[i], G1[i], tmp);
            // Pass through odd indices
            assign G2[i+1] = G1[i+1];
            assign P2[i+1] = P1[i+1];
        end
    endgenerate

    // Stage 3: distance 4
    wire [7:0] G3, P3;
    assign G3[0]=G2[0]; assign G3[1]=G2[1];
    assign G3[2]=G2[2]; assign G3[3]=G2[3];
    assign P3[0]=P2[0]; assign P3[1]=P2[1];
    assign P3[2]=P2[2]; assign P3[3]=P2[3];
    generate
        for (i=4; i<8; i=i+4) begin : stage3
            wire tmp;
            and a(P3[i], P2[i], P2[i-4]);
            and b(tmp, P2[i], G2[i-4]);
            or  o(G3[i], G2[i], tmp);
            // Pass through next 3 indices
            assign G3[i+1] = G2[i+1];
            assign P3[i+1] = P2[i+1];
            assign G3[i+2] = G2[i+2];
            assign P3[i+2] = P2[i+2];
            assign G3[i+3] = G2[i+3];
            assign P3[i+3] = P2[i+3];
        end
    endgenerate

    // Step 3: compute carries
    wire [7:0] C;
    assign C[0] = Cin;

    // Carry equations (using prefix outputs)
    wire c1tmp; and a1(c1tmp, P[0], Cin); or o1(C[1], G[0], c1tmp);
    wire c2tmp; and a2(c2tmp, P1[1], Cin); or o2(C[2], G1[1], c2tmp);
    wire c3tmp; and a3(c3tmp, P2[2], Cin); or o3(C[3], G2[2], c3tmp);
    wire c4tmp; and a4(c4tmp, P3[3], Cin); or o4(C[4], G3[3], c4tmp);
    wire c5tmp; and a5(c5tmp, P[4], C[4]); or o5(C[5], G[4], c5tmp);
    wire c6tmp; and a6(c6tmp, P[5], C[5]); or o6(C[6], G[5], c6tmp);
    wire c7tmp; and a7(c7tmp, P[6], C[6]); or o7(C[7], G[6], c7tmp);

    // Final carry out
    wire couttmp; and a8(couttmp, P[7], C[7]); or o8(Cout, G[7], couttmp);

    // Step 4: compute sums
    generate
        for (i=0; i<8; i=i+1) begin : sum_stage
            xor s(SUM[i], P[i], C[i]);
        end
    endgenerate

endmodule


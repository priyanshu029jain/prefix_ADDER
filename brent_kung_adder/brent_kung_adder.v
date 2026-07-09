module brent_kung_adder (
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,
    output [7:0] S,
    output       Cout
  );

  // Step 1: bitwise generate and propagate
  wire [7:0] G, P;
  genvar i;
  generate
    for (i=0; i<8; i=i+1)
    begin : gen_gp
      and g(G[i], A[i], B[i]);
      xor p(P[i], A[i], B[i]);
    end
  endgenerate

  // Step 2: Brent–Kung prefix tree
  // Stage 1: pairwise
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

  // Stage 2: combine pairs into quads
  wire G2_3, G2_7;
  wire P2_3, P2_7;

  and a23(P2_3, P1_3, P1_1);
  or  o23(G2_3, G1_3, (P1_3 & G1_1));

  and a27(P2_7, P1_7, P1_5);
  or  o27(G2_7, G1_7, (P1_7 & G1_5));

  // Stage 3: combine halves
  wire G3_7;
  wire P3_7;

  and a37(P3_7, P2_7, P2_3);
  or  o37(G3_7, G2_7, (P2_7 & G2_3));

  // Step 3: compute carries
  wire [7:0] C;
  assign C[0] = Cin;

  // C[1] = G[0] | (P[0] & Cin)
  wire p0c;
  and a0(p0c, P[0], Cin);
  or  o0(C[1], G[0], p0c);

  // C[2] = G1_1 | (P1_1 & Cin)
  wire p11c;
  and a1(p11c, P1_1, Cin);
  or  o1(C[2], G1_1, p11c);

  // C[3] = G[2] | (P[2] & C[2])
  wire p2c2;
  and a2(p2c2, P[2], C[2]);
  or  o2(C[3], G[2], p2c2);

  // C[4] = G2_3 | (P2_3 & Cin)
  wire p23c;
  and a3(p23c, P2_3, Cin);
  or  o3(C[4], G2_3, p23c);

  // C[5] = G[4] | (P[4] & C[4])
  wire p4c4;
  and a4(p4c4, P[4], C[4]);
  or  o4(C[5], G[4], p4c4);

  // C[6] = G1_5 | (P1_5 & C[4])
  wire p15c4;
  and a5(p15c4, P1_5, C[4]);
  or  o5(C[6], G1_5, p15c4);

  // C[7] = G[6] | (P[6] & C[6])
  wire p6c6;
  and a6(p6c6, P[6], C[6]);
  or  o6(C[7], G[6], p6c6);

  // Cout = G3_7 | (P3_7 & Cin)
  wire p37c;
  and a7(p37c, P3_7, Cin);
  or  o7(Cout, G3_7, p37c);

  // Step 4: compute sums
  generate
    for (i=0; i<8; i=i+1)
    begin : final_sum
      xor s(S[i], P[i], C[i]);
    end
  endgenerate

endmodule

`timescale 1ns/1ps
// `include "/brent_kung_adder/brent_kung_adder.v"

module tb_BKA;

  reg  [7:0] A, B;
  reg        Cin;
  wire [7:0] S;
  wire       Cout;

  // Instantiate the DUT
  brent_kung_adder uut (
    .A(A),
    .B(B),
    .Cin(Cin),
    .S(S),
    .Cout(Cout)
  );

  initial begin
    $dumpfile("BKA.vcd");
    $dumpvars(0, tb_BKA);
  end

  initial begin
    $monitor("t=%0t | A=%b (%d) B=%b (%d) Cin=%b | Sum=%b (%d) Cout=%b",
              $time, A, A, B, B, Cin, S, S, Cout);

    // Directed test cases
    A = 8'h00; B = 8'h00; Cin = 0; #10;
    A = 8'h01; B = 8'h01; Cin = 0; #10;
    A = 8'h0F; B = 8'h01; Cin = 1; #10;
    A = 8'h55; B = 8'hAA; Cin = 0; #10;
    A = 8'hFF; B = 8'h01; Cin = 0; #10;
    A = 8'hFF; B = 8'hFF; Cin = 1; #10;

    // Randomized stress test
    repeat (10) begin
      A   = $random;
      B   = $random;
      Cin = $random % 2;
      #10;
    end

    $finish;
  end

endmodule

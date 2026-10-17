
# Entity: han_carlson_adder

- **File**: [han_carlson_adder.v](han_carlson_adder.v)
- **Type**: 8-bit parallel-prefix adder, purely combinational, structural Verilog (gate primitives)
- **Prefix tree**: Han-Carlson style hybrid (sparse Brent-Kung outer stages, dense Kogge-Stone middle stage)
- **Functional status**: ❌ **Fails.** 57,344 of 131,072 input combinations give a wrong result (see [Known issue](#known-issue-wrong-c6--c7)).

## Diagram

### Logisim schematic

![Han-Carlson adder Logisim schematic](HCA.jpg "Han-Carlson adder: Logisim schematic")

Source circuit: [HCA.circ](HCA.circ) (open with Logisim-evolution)

### Module symbol

![Diagram](han_carlson_adder.svg "Diagram")

## Ports

| Port name | Direction | Type  | Description |
| --------- | --------- | ----- | ----------- |
| A         | input     | [7:0] | First 8-bit operand |
| B         | input     | [7:0] | Second 8-bit operand |
| Cin       | input     |       | Carry-in into bit 0 |
| SUM       | output    | [7:0] | 8-bit sum, `SUM = (A + B + Cin) mod 256` |
| Cout      | output    |       | Carry-out of bit 7 |

## Signals

Notation: `G[i:j]` / `P[i:j]` are the group generate / propagate over bits *i* down to *j*. `C[i]` is the carry **into** bit *i*.

| Name    | Type       | Description |
| ------- | ---------- | ----------- |
| G       | wire [7:0] | Bitwise generate, `G[i] = A[i] & B[i]` |
| P       | wire [7:0] | Bitwise propagate, `P[i] = A[i] ^ B[i]` |
| G1_1    | wire       | Stage 1 (sparse) group generate `G[1:0]` |
| G1_3    | wire       | Stage 1 group generate `G[3:2]` |
| G1_5    | wire       | Stage 1 group generate `G[5:4]` |
| G1_7    | wire       | Stage 1 group generate `G[7:6]` |
| P1_1    | wire       | Stage 1 group propagate `P[1:0]` |
| P1_3    | wire       | Stage 1 group propagate `P[3:2]` |
| P1_5    | wire       | Stage 1 group propagate `P[5:4]` |
| P1_7    | wire       | Stage 1 group propagate `P[7:6]` |
| G2_2    | wire       | Stage 2 (dense) group generate `G[2:0]` = `G[2] ∘ G1_1` |
| G2_3    | wire       | Stage 2 group generate `G[3:0]` = `G1_3 ∘ G1_1` |
| G2_6    | wire       | Stage 2 group generate `G[6:4]` = `G[6] ∘ G1_5` |
| G2_7    | wire       | Stage 2 group generate `G[7:4]` = `G1_7 ∘ G1_5` |
| P2_2    | wire       | Stage 2 group propagate `P[2:0]` |
| P2_3    | wire       | Stage 2 group propagate `P[3:0]` |
| P2_6    | wire       | Stage 2 group propagate `P[6:4]` |
| P2_7    | wire       | Stage 2 group propagate `P[7:4]` |
| G3_7    | wire       | Stage 3 (sparse) group generate `G[7:0]` |
| P3_7    | wire       | Stage 3 group propagate `P[7:0]` |
| C       | wire [7:0] | Carry into each bit. `C[0] = Cin`. |
| c1tmp   | wire       | `P[0] & Cin`, used for `C[1]` |
| c2tmp   | wire       | `P1_1 & Cin`, used for `C[2]` |
| c3tmp   | wire       | `P2_2 & Cin`, used for `C[3]` |
| c4tmp   | wire       | `P2_3 & Cin`, used for `C[4]` |
| c5tmp   | wire       | `P[4] & C[4]`, used for `C[5]` |
| c6tmp   | wire       | `P2_6 & C[4]`, used for `C[6]` (**wrong group, see Known issue**) |
| c7tmp   | wire       | `P2_7 & C[4]`, used for `C[7]` (**wrong group, see Known issue**) |
| couttmp | wire       | `P3_7 & Cin`, used for `Cout` |

## Working

Each prefix cell (●) applies `(G_hi, P_hi) ∘ (G_lo, P_lo) = (G_hi | P_hi & G_lo,  P_hi & P_lo)`.

### 1. Pre-processing

`G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]` for all 8 bits.

### 2. Prefix tree

Han-Carlson mixes the two classic trees. The first and last stages are sparse like Brent-Kung, so there are few cells. The middle stage is dense like Kogge-Stone, which shortens depth.

```
bit:        7     6     5     4     3     2     1     0
            |     |     |     |     |     |     |     |
Stage 1:    ●─────┘     ●─────┘     ●─────┘     ●─────┘     sparse, distance 1  → G1_7 G1_5 G1_3 G1_1
            |     |     |           |     |     |
Stage 2:    ●─────┼─────┘           ●─────┼─────┘           dense, distance 2   → G2_7 = G[7:4], G2_3 = G[3:0]
            |     ●─────┘           |     ●─────┘                               → G2_6 = G[6:4], G2_2 = G[2:0]
            |                       |
Stage 3:    ●───────────────────────┘                       sparse, distance 4  → G3_7 = G[7:0]
```

That is 9 prefix cells in total: 4 + 4 + 1.

### 3. Carry computation and sum

| Carry | Equation in RTL | Correct? |
| :---- | :-------------- | :------- |
| `C[1]` | `G[0] \| P[0]·Cin` | ✅ |
| `C[2]` | `G1_1 \| P1_1·Cin` | ✅ (`G[1:0]`) |
| `C[3]` | `G2_2 \| P2_2·Cin` | ✅ (`G[2:0]`) |
| `C[4]` | `G2_3 \| P2_3·Cin` | ✅ (`G[3:0]`) |
| `C[5]` | `G[4] \| P[4]·C[4]` | ✅ |
| `C[6]` | `G2_6 \| P2_6·C[4]` | ❌ This is `G[6:0]`, which is actually `C[7]` |
| `C[7]` | `G2_7 \| P2_7·C[4]` | ❌ This is `G[7:0]`, which is actually `Cout` |
| `Cout` | `G3_7 \| P3_7·Cin` | ✅ (`G[7:0]`) |

Finally `SUM[i] = P[i] ^ C[i]`.

## Known issue: wrong `C[6]` / `C[7]`

`C[6]` and `C[7]` are each built from a group that is one bit too high. The carry into bit 6 must cover bits 5..0, but `G2_6` covers bits 6..4. As a result `SUM[6]` and `SUM[7]` are wrong whenever the carry into those bits differs from the carry out of them.

An exhaustive simulation against `A + B + Cin` gives **57,344 / 131,072 mismatches**. For example, `A = 1, B = 63, Cin = 0` returns 0 instead of 64.

**Fix:** use the groups that end one bit lower. This was checked with the same exhaustive test and gives 0 mismatches:

```verilog
// C[6] = G[5:4] | P[5:4] & C[4]
and a6(c6tmp, P1_5, C[4]);
or  o6(C[6], G1_5, c6tmp);

// C[7] = G[6:4] | P[6:4] & C[4]
and a7(c7tmp, P2_6, C[4]);
or  o7(C[7], G2_6, c7tmp);
```

After this fix `G2_7` only feeds `G3_7`. **All PPA numbers below come from the buggy netlist.** Re-run synthesis, STA and the FPGA flow after applying the fix.

## Synthesis results: ASIC (SkyWater SKY130, `sky130_fd_sc_hd`, tt / 25 °C / 1.80 V)

Flow: Yosys ([synth.tcl](synth.tcl)) → ABC mapping → OpenSTA ([sta.tcl](sta.tcl)). The design is timed against a 10 ns virtual clock with 0 ns input and output delays.

### Area: [area_report.txt](area_report.txt)

| Metric | Value |
| :--- | :--- |
| Total cells | **30** |
| Chip area | **228.97 µm²** (smallest of the five) |
| Sequential area | 0 µm² |
| Wires / wire bits | 26 / 47 |

| Cell | Count | Cell | Count |
| :--- | :---: | :--- | :---: |
| `xnor2_1` | 11 | `lpflow_inputiso1p_1` | 2 |
| `maj3_1` | 5 | `nor2_1` | 2 |
| `and2_0` | 2 | `a21oi_1`, `a31o_1`, `a31oi_1`, `nand2b_1`, `o21a_1`, `o221ai_1` | 1 each |
| `nand2_1` | 2 | | |

### Timing: [timing_report.txt](timing_report.txt)

Critical path **B[0] → SUM[7]**, 7 cells deep:

| Cell | Type | Incr (ns) | Arrival (ns) |
| :--- | :--- | :---: | :---: |
| `_31_` | maj3_1 | 0.373 | 0.373 |
| `_33_` | maj3_1 | 0.400 | 0.773 |
| `_35_` | maj3_1 | 0.400 | 1.173 |
| `_37_` | maj3_1 | 0.401 | 1.574 |
| `_38_` | maj3_1 | 0.412 | 1.985 |
| `_40_` | o221ai_1 | 0.210 | 2.196 |
| `_50_` | a31o_1 | 0.151 | **2.347** |

| Metric | Value |
| :--- | :--- |
| Critical delay | **2.347 ns** |
| Equivalent Fmax | **426.2 MHz** |
| Slack @ 10 ns | +7.653 ns (MET) |

### Power: [power_report.txt](power_report.txt)

| Component | Value |
| :--- | :--- |
| Switching power | 3.21 µW |
| Internal power | 0 (not modelled in this run) |
| Leakage power | 60.0 pW |
| **Total** | **3.21 µW** |

OpenSTA used its default input activity because no VCD/SAIF file was annotated. Use these numbers only to compare the adders with each other.

## Synthesis results: FPGA (Lattice iCE40 HX8K, Yosys `synth_ice40` + nextpnr)

Report: [fpga_report.txt](fpga_report.txt)

| Metric | Value |
| :--- | :--- |
| Logic cells (LUT4) | **28** / 7680 |
| I/O pins | 26 / 256 |
| Critical path | A[0] → SUM[4], **10.31 ns** (1.32 ns logic + 8.99 ns routing) |
| Equivalent Fmax | **97.0 MHz** |

## Findings

1. **The RTL is functionally wrong** at `C[6]` and `C[7]`, so the PPA numbers describe a broken circuit. A wrong carry can drop logic, so the small area (228.97 µm²) and low power (3.21 µW) may be partly caused by the bug.
2. **Almost identical to Brent-Kung after synthesis:** both have 30 cells, about 229–233 µm², and about 2.35 ns delay. At 8 bits, ABC removes most of the structural difference between the two trees.
3. **The extra Kogge-Stone stage does not buy speed here.** The critical path is a 5-deep `maj3` (full-adder-carry) chain created by ABC's area-oriented mapping, not the RTL tree. Delay-oriented mapping would be needed to see the benefit of the dense middle stage.
4. **On iCE40, routing dominates:** 87% of the 10.31 ns path is interconnect, the highest share of the five designs.
5. **This is not a textbook Han-Carlson.** A true Han-Carlson tree runs Kogge-Stone on the odd bits and fixes up the even bits in one final stage. This implementation is closer to a Brent-Kung tree with two extra stage 2 cells (`G2_2`, `G2_6`).

## Files

| File | Purpose |
| :--- | :--- |
| [han_carlson_adder.v](han_carlson_adder.v) | RTL |
| [han_carlson_mapped.v](han_carlson_mapped.v) | Gate-level netlist (SKY130) |
| [synth.tcl](synth.tcl) / [sta.tcl](sta.tcl) | Yosys synthesis and OpenSTA scripts |
| [HCA.circ](HCA.circ) / [HCA.jpg](HCA.jpg) | Logisim schematic |

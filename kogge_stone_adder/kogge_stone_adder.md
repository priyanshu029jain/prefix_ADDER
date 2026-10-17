
# Entity: kogge_stone_adder

- **File**: [kogge_stone_adder.v](kogge_stone_adder.v)
- **Type**: 8-bit parallel-prefix adder, purely combinational, structural Verilog (gate primitives)
- **Prefix tree**: Kogge-Stone (dense, minimum depth, fan-out 2)
- **Functional status**: ✅ Passes an exhaustive test of all 2¹⁷ = 131,072 `{Cin, A, B}` combinations

## Diagram

### Logisim schematic

![Kogge-Stone adder Logisim schematic](KSA.jpg "Kogge-Stone adder: Logisim schematic")

Source circuit: [KSA.circ](KSA.circ) (open with Logisim-evolution)

### Module symbol

![Diagram](kogge_stone_adder.svg "Diagram")

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
| G1      | wire [7:0] | Stage 1 (distance 1): `G1[i] = G[i:i-1]` for i ≥ 1. `G1[0] = G[0]` is passed through. |
| P1      | wire [7:0] | Stage 1 group propagate `P[i:i-1]` (`P1[0] = P[0]`) |
| G2      | wire [7:0] | Stage 2 (distance 2): `G2[i] = G[i:max(i-3,0)]`. Bits 0–1 are passed through from `G1`. |
| P2      | wire [7:0] | Stage 2 group propagate |
| G3      | wire [7:0] | Stage 3 (distance 4): `G3[i] = G[i:0]` for every bit, so all prefixes are complete. Bits 0–3 are passed through from `G2`. |
| P3      | wire [7:0] | Stage 3 group propagate `P[i:0]` |
| C       | wire [7:0] | Carry into each bit. `C[0] = Cin`. |
| c1tmp   | wire       | `P[0] & Cin`, used for `C[1]` |
| c2tmp   | wire       | `P1[1] & Cin`, used for `C[2]` |
| c3tmp   | wire       | `P2[2] & Cin`, used for `C[3]` |
| c4tmp   | wire       | `P3[3] & Cin`, used for `C[4]` |
| c5tmp   | wire       | `P3[4] & Cin`, used for `C[5]` |
| c6tmp   | wire       | `P3[5] & Cin`, used for `C[6]` |
| c7tmp   | wire       | `P3[6] & Cin`, used for `C[7]` |
| couttmp | wire       | `P3[7] & Cin`, used for `Cout` |

Inside each `generate` stage block there is a local `tmp` wire that holds `P[i] & G[i-d]` for the cell's OR gate.

## Working

Each prefix cell (●) applies `(G_hi, P_hi) ∘ (G_lo, P_lo) = (G_hi | P_hi & G_lo,  P_hi & P_lo)`.

### 1. Pre-processing

`G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]` for all 8 bits.

### 2. Prefix tree

At stage *k*, every bit *i* ≥ 2^(k-1) combines with bit *i − 2^(k-1)*. After log₂8 = 3 stages, every bit holds its full prefix `G[i:0]`.

```
bit:        7   6   5   4   3   2   1   0
Stage 1:    ●   ●   ●   ●   ●   ●   ●   |     distance 1  (7 cells)
Stage 2:    ●   ●   ●   ●   ●   ●   |   |     distance 2  (6 cells)
Stage 3:    ●   ●   ●   ●   |   |   |   |     distance 4  (4 cells)
```

That is 17 prefix cells in total. Every node drives at most 2 loads, but the number of long wires is the largest of any tree, about n/2 horizontal tracks in the last stage.

### 3. Carry computation and sum

Every carry comes straight from the tree in a single AND-OR step, with no ripple:

| Carry | Equation |
| :---- | :------- |
| `C[1]` | `G[0] \| P[0]·Cin` |
| `C[2]` | `G1[1] \| P1[1]·Cin` |
| `C[3]` | `G2[2] \| P2[2]·Cin` |
| `C[4]` … `C[7]` | `G3[i-1] \| P3[i-1]·Cin` |
| `Cout` | `G3[7] \| P3[7]·Cin` |

Finally `SUM[i] = P[i] ^ C[i]`.

**Logic depth:** 1 (G/P) + 3 (tree) + 1 (carry) + 1 (sum XOR) = **6 levels**. That is the minimum for an 8-bit prefix adder.

## Synthesis results: ASIC (SkyWater SKY130, `sky130_fd_sc_hd`, tt / 25 °C / 1.80 V)

Flow: Yosys ([synth.tcl](synth.tcl)) → ABC mapping → OpenSTA ([sta.tcl](sta.tcl)). The design is timed against a 10 ns virtual clock with 0 ns input and output delays.

### Area: [area_report.txt](area_report.txt)

| Metric | Value |
| :--- | :--- |
| Total cells | **41** (most of the five) |
| Chip area | **275.26 µm²** (largest of the five) |
| Sequential area | 0 µm² |
| Wires / wire bits | 37 / 58 |

| Cell | Count | Cell | Count |
| :--- | :---: | :--- | :---: |
| `xnor2_1` | 10 | `a311o_1` | 2 |
| `nand2_1` | 6 | `and2_0` | 2 |
| `a31oi_1` | 4 | `lpflow_inputiso1p_1` | 2 |
| `nor2_1` | 4 | `a21o_1`, `a21oi_1`, `a221o_1`, `maj3_1`, `nand3_1`, `o211ai_1`, `o21a_1`, `xor2_1` | 1 each |
| `nand2b_1` | 3 | | |

### Timing: [timing_report.txt](timing_report.txt)

Critical path **B[0] → SUM[7]**, 6 cells deep:

| Cell | Type | Incr (ns) | Arrival (ns) |
| :--- | :--- | :---: | :---: |
| `_44_` | maj3_1 | 0.385 | 0.385 |
| `_48_` | a221o_1 | 0.331 | 0.715 |
| `_51_` | o211ai_1 | 0.151 | 0.867 |
| `_67_` | a311o_1 | 0.212 | 1.079 |
| `_71_` | a31oi_1 | 0.096 | 1.175 |
| `_72_` | xnor2_1 | 0.126 | **1.302** |

| Metric | Value |
| :--- | :--- |
| Critical delay | **1.302 ns** (fastest) |
| Equivalent Fmax | **768.3 MHz** |
| Slack @ 10 ns | +8.699 ns (MET) |

### Power: [power_report.txt](power_report.txt)

| Component | Value |
| :--- | :--- |
| Switching power | 4.83 µW |
| Internal power | 0 (not modelled in this run) |
| Leakage power | 85.1 pW |
| **Total** | **4.83 µW** (highest) |

OpenSTA used its default input activity because no VCD/SAIF file was annotated. Use these numbers only to compare the adders with each other.

## Synthesis results: FPGA (Lattice iCE40 HX8K, Yosys `synth_ice40` + nextpnr)

Report: [fpga_report.txt](fpga_report.txt)

| Metric | Value |
| :--- | :--- |
| Logic cells (LUT4) | **35** / 7680 |
| I/O pins | 26 / 256 |
| Critical path | B[1] → SUM[4], **8.57 ns** (1.32 ns logic + 7.25 ns routing) |
| Equivalent Fmax | **116.7 MHz** (fastest) |

## Findings

1. **Fastest design in both flows.** On ASIC it runs at 1.302 ns, 44% faster than Brent-Kung (2.346 ns). On iCE40 it reaches 8.57 ns, 12% faster than Brent-Kung (9.72 ns).
2. **Speed costs area and power.** Kogge-Stone uses 18% more area than Brent-Kung (275.26 vs 232.72 µm²) and 28% more power (4.83 vs 3.78 µW). It also has the highest leakage, 85.1 pW. This is the classic dense-tree trade-off.
3. **ABC keeps the parallel structure.** The critical path has only 6 cells and one `maj3`. Brent-Kung, Han-Carlson and Ladner-Fischer collapse into 5–6-deep `maj3` ripple chains instead. The dense tree gives ABC no serial carry path to fold.
4. **On iCE40 the advantage is smaller:** 85% of the path is routing. More LUTs (35) also means more nets to route, which offsets part of the shallower logic depth.
5. The Sklansky module currently produces an **identical** netlist, because its RTL describes the same tree. See [../sklansky_adder/sklansky_adder.md](../sklansky_adder/sklansky_adder.md).

## Files

| File | Purpose |
| :--- | :--- |
| [kogge_stone_adder.v](kogge_stone_adder.v) | RTL |
| [kogge_stone_mapped.v](kogge_stone_mapped.v) | Gate-level netlist (SKY130) |
| [synth.tcl](synth.tcl) / [sta.tcl](sta.tcl) | Yosys synthesis and OpenSTA scripts |
| [KSA.circ](KSA.circ) / [KSA.jpg](KSA.jpg) | Logisim schematic |

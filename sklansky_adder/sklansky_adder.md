
# Entity: sklansky_adder

- **File**: [sklansky_adder.v](sklansky_adder.v)
- **Type**: 8-bit parallel-prefix adder, purely combinational, structural Verilog (gate primitives)
- **Prefix tree (intended)**: Sklansky (divide-and-conquer, minimum depth, high fan-out)
- **Prefix tree (as written)**: ⚠️ Kogge-Stone (see [Known issue](#known-issue-the-rtl-is-a-kogge-stone-tree))
- **Functional status**: ✅ Passes an exhaustive test of all 2¹⁷ = 131,072 `{Cin, A, B}` combinations

## Diagram

### Logisim schematic

![Sklansky adder Logisim schematic](SLA.jpg "Sklansky adder: Logisim schematic")

Source circuit: [SLA.circ](SLA.circ) (open with Logisim-evolution)

### Module symbol

![Diagram](sklansky_adder.svg "Diagram")

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
| G1      | wire [7:0] | Stage 1 (distance 1): `G1[i] = G[i:i-1]`, `G1[0] = G[0]` |
| P1      | wire [7:0] | Stage 1 group propagate `P[i:i-1]` |
| G2      | wire [7:0] | Stage 2 (distance 2): `G2[i] = G[i:max(i-3,0)]`. Bits 0–1 are passed through. |
| P2      | wire [7:0] | Stage 2 group propagate |
| G3      | wire [7:0] | Stage 3 (distance 4): `G3[i] = G[i:0]`, the complete prefix for every bit. Bits 0–3 are passed through. |
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

### 2. Prefix tree: what Sklansky should be

Sklansky works by divide-and-conquer. At stage *k*, each block of 2^k bits is split in half, and **every** bit of the upper half combines with the **single** most-significant prefix of the lower half:

```
bit:        7   6   5   4   3   2   1   0
Stage 1:    ●   |   ●   |   ●   |   ●   |     7←6, 5←4, 3←2, 1←0
Stage 2:    ●   ●   |   |   ●   ●   |   |     7,6 ← 5 ;  3,2 ← 1         (fan-out 2)
Stage 3:    ●   ●   ●   ●   |   |   |   |     7,6,5,4 ← 3                (fan-out 4)
```

That is 12 prefix cells (n/2 · log₂n) with depth log₂n = 3. The cost is fan-out that grows to n/2 = 4 on the node `G[3:0]`.

### 2. Prefix tree: what the RTL implements

The RTL uses **distance-1/2/4 connections on every bit**, which is the Kogge-Stone pattern:

```
bit:        7   6   5   4   3   2   1   0
Stage 1:    ●   ●   ●   ●   ●   ●   ●   |     i ← i-1   (7 cells)
Stage 2:    ●   ●   ●   ●   ●   ●   |   |     i ← i-2   (6 cells)
Stage 3:    ●   ●   ●   ●   |   |   |   |     i ← i-4   (4 cells)
```

That is 17 prefix cells with fan-out 2. The result is still a correct full prefix, so every `G3[i] = G[i:0]`.

### 3. Carry computation and sum

| Carry | Equation |
| :---- | :------- |
| `C[1]` | `G[0] \| P[0]·Cin` |
| `C[2]` | `G1[1] \| P1[1]·Cin` |
| `C[3]` | `G2[2] \| P2[2]·Cin` |
| `C[4]` … `C[7]` | `G3[i-1] \| P3[i-1]·Cin` |
| `Cout` | `G3[7] \| P3[7]·Cin` |

Finally `SUM[i] = P[i] ^ C[i]`. Logic depth: G/P + 3 tree levels + carry + sum XOR = **6 levels**.

## Known issue: the RTL is a Kogge-Stone tree

[sklansky_adder.v](sklansky_adder.v) is, apart from the module name, the same as [../kogge_stone_adder/kogge_stone_adder.v](../kogge_stone_adder/kogge_stone_adder.v). Yosys therefore produces the **same netlist**, and every report below matches the Kogge-Stone reports exactly. The circuit adds correctly, but its PPA numbers say nothing about a real Sklansky tree.

To implement a true Sklansky tree, replace the three `generate` stages with these cells:

| Stage | Cells (`hi ← lo`) |
| :--- | :--- |
| 1 | `1←0`, `3←2`, `5←4`, `7←6` |
| 2 | `2←[1:0]`, `3←[1:0]`, `6←[5:4]`, `7←[5:4]` |
| 3 | `4←[3:0]`, `5←[3:0]`, `6←[3:0]`, `7←[3:0]` |

Here bits 2, 4 and 6 combine their **bitwise** `(G, P)` with the lower block, and bits 5, 6 and 7 use their stage 2 or stage 1 group.

## Synthesis results: ASIC (SkyWater SKY130, `sky130_fd_sc_hd`, tt / 25 °C / 1.80 V)

Flow: Yosys ([synth.tcl](synth.tcl)) → ABC mapping → OpenSTA ([sta.tcl](sta.tcl)). The design is timed against a 10 ns virtual clock with 0 ns input and output delays.

### Area: [area_report.txt](area_report.txt)

| Metric | Value |
| :--- | :--- |
| Total cells | **41** |
| Chip area | **275.26 µm²** |
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
| Critical delay | **1.302 ns** |
| Equivalent Fmax | **768.3 MHz** |
| Slack @ 10 ns | +8.699 ns (MET) |

### Power: [power_report.txt](power_report.txt)

| Component | Value |
| :--- | :--- |
| Switching power | 4.83 µW |
| Internal power | 0 (not modelled in this run) |
| Leakage power | 85.1 pW |
| **Total** | **4.83 µW** |

OpenSTA used its default input activity because no VCD/SAIF file was annotated. Use these numbers only to compare the adders with each other.

## Synthesis results: FPGA (Lattice iCE40 HX8K, Yosys `synth_ice40` + nextpnr)

Report: [fpga_report.txt](fpga_report.txt)

| Metric | Value |
| :--- | :--- |
| Logic cells (LUT4) | **35** / 7680 |
| I/O pins | 26 / 256 |
| Critical path | B[1] → SUM[4], **8.57 ns** (1.32 ns logic + 7.25 ns routing) |
| Equivalent Fmax | **116.7 MHz** |

## Findings

1. **Correct adder, wrong architecture.** It passes the exhaustive test, but it is a Kogge-Stone tree, so every ASIC and FPGA number matches [Kogge-Stone](../kogge_stone_adder/kogge_stone_adder.md) to the last digit.
2. **Joint-fastest in the comparison** (1.302 ns ASIC, 8.57 ns iCE40). It is also joint-largest (275.26 µm², 41 cells) and has the joint-highest power (4.83 µW).
3. **Expected result for a real Sklansky tree:** the same depth (3 levels) with 12 instead of 17 prefix cells, so less area and power than Kogge-Stone. Delay would be slightly worse because of the fan-out-4 node `G[3:0]`, which would need buffering or upsized cells.
4. **On iCE40, routing dominates:** 85% of the 8.57 ns path is interconnect.

## Files

| File | Purpose |
| :--- | :--- |
| [sklansky_adder.v](sklansky_adder.v) | RTL |
| [sklansky_mapped.v](sklansky_mapped.v) | Gate-level netlist (SKY130) |
| [synth.tcl](synth.tcl) / [sta.tcl](sta.tcl) | Yosys synthesis and OpenSTA scripts |
| [SLA.circ](SLA.circ) / [SLA.jpg](SLA.jpg) | Logisim schematic |

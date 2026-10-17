
# Entity: ladner_fischer_adder

- **File**: [ladner_fischer_adder.v](ladner_fischer_adder.v)
- **Type**: 8-bit parallel-prefix adder, purely combinational, structural Verilog (gate primitives)
- **Prefix tree**: Ladner-Fischer style sparse tree. The lower nibble comes from the prefix tree; the upper nibble ripples from `C[4]`.
- **Functional status**: ❌ **Fails.** 12,288 of 131,072 input combinations give a wrong result (see [Known issue](#known-issue-wrong-c4)).

## Diagram

### Logisim schematic

![Ladner-Fischer adder Logisim schematic](LFA.jpg "Ladner-Fischer adder: Logisim schematic")

Source circuit: [LFA.circ](LFA.circ) (open with Logisim-evolution)

### Module symbol

![Diagram](ladner_fischer_adder.svg "Diagram")

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
| G1      | wire [7:0] | Stage 1 (distance 1, every bit): `G1[i] = G[i:i-1]`, `G1[0] = G[0]` |
| P1      | wire [7:0] | Stage 1 group propagate `P[i:i-1]` |
| G2      | wire [7:0] | Stage 2 (distance 2, **even bits only**): `G2[2] = G[2:0]`, `G2[4] = G[4:1]`, `G2[6] = G[6:3]`. Odd bits are passed through from `G1`. |
| P2      | wire [7:0] | Stage 2 group propagate (same pattern) |
| G3      | wire [7:0] | Stage 3 (distance 4, **bit 4 only**): `G3[4] = G[4:0]`. All other bits are passed through from `G2`. |
| P3      | wire [7:0] | Stage 3 group propagate (same pattern) |
| C       | wire [7:0] | Carry into each bit. `C[0] = Cin`. |
| c1tmp   | wire       | `P[0] & Cin`, used for `C[1]` |
| c2tmp   | wire       | `P1[1] & Cin`, used for `C[2]` |
| c3tmp   | wire       | `P2[2] & Cin`, used for `C[3]` |
| c4tmp   | wire       | `P3[3] & Cin`, used for `C[4]` (**wrong group, see Known issue**) |
| c5tmp   | wire       | `P[4] & C[4]`, used for `C[5]` (ripple) |
| c6tmp   | wire       | `P[5] & C[5]`, used for `C[6]` (ripple) |
| c7tmp   | wire       | `P[6] & C[6]`, used for `C[7]` (ripple) |
| couttmp | wire       | `P[7] & C[7]`, used for `Cout` (ripple) |

Inside each `generate` stage block there is a local `tmp` wire that holds `P[i] & G[i-d]` for the cell's OR gate.

## Working

Each prefix cell (●) applies `(G_hi, P_hi) ∘ (G_lo, P_lo) = (G_hi | P_hi & G_lo,  P_hi & P_lo)`.

### 1. Pre-processing

`G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]` for all 8 bits.

### 2. Prefix tree

Ladner-Fischer cuts cells compared with Sklansky or Kogge-Stone. It computes higher stages only at selected positions and fills the rest in later. In this RTL:

```
bit:        7   6   5   4   3   2   1   0
Stage 1:    ●   ●   ●   ●   ●   ●   ●   |     distance 1, all bits   (7 cells)
Stage 2:    |   ●   |   ●   |   ●   |   |     distance 2, even bits  (3 cells)
Stage 3:    |   |   |   ●   |   |   |   |     distance 4, bit 4 only (1 cell)
```

Only `G[0]`, `G1[1]`, `G2[2]` and `G3[3]` (which is just `G1[3]` passed through) are used by the carry logic. `G2[4]`, `G2[6]` and `G3[4]` are computed but never used, so synthesis removes them.

### 3. Carry computation and sum

| Carry | Equation in RTL | Correct? |
| :---- | :-------------- | :------- |
| `C[1]` | `G[0] \| P[0]·Cin` | ✅ |
| `C[2]` | `G1[1] \| P1[1]·Cin` | ✅ (`G[1:0]`) |
| `C[3]` | `G2[2] \| P2[2]·Cin` | ✅ (`G[2:0]`) |
| `C[4]` | `G3[3] \| P3[3]·Cin` | ❌ `G3[3] = G1[3] = G[3:2]`, so bits 1..0 are skipped |
| `C[5]` | `G[4] \| P[4]·C[4]` | ripple (correct only if `C[4]` is correct) |
| `C[6]` | `G[5] \| P[5]·C[5]` | ripple |
| `C[7]` | `G[6] \| P[6]·C[6]` | ripple |
| `Cout` | `G[7] \| P[7]·C[7]` | ripple |

Finally `SUM[i] = P[i] ^ C[i]`. The upper four carries form a ripple chain, so the effective logic depth is about log₂4 + 4 stages.

## Known issue: wrong `C[4]`

The stage 2 cells sit on the even bits, so no node ever holds `G[3:0]`. `C[4]` is built from `G[3:2]` and `P[3:2]·Cin`. A carry generated in bit 0 or 1 that should propagate through bits 2–3 is lost, and the error then ripples into `SUM[7:4]` and `Cout`.

An exhaustive simulation against `A + B + Cin` gives **12,288 / 131,072 mismatches**. For example, `A = 1, B = 15, Cin = 0` returns 0 instead of 16.

**Fix:** extend `C[2]` across the `[3:2]` group. This was checked with the same exhaustive test and gives 0 mismatches:

```verilog
// C[4] = G[3:2] | P[3:2] & C[2]
wire c4tmp; and a4(c4tmp, P1[3], C[2]); or o4(C[4], G1[3], c4tmp);
```

A cleaner Ladner-Fischer tree would place the stage 2 cells on the **odd** bits (3, 7) and the stage 3 cells on bits 5–7. That gives `G[3:0]` as a tree node and removes the upper ripple chain.

**All PPA numbers below come from the buggy netlist.** Re-run synthesis, STA and the FPGA flow after applying the fix.

## Synthesis results: ASIC (SkyWater SKY130, `sky130_fd_sc_hd`, tt / 25 °C / 1.80 V)

Flow: Yosys ([synth.tcl](synth.tcl)) → ABC mapping → OpenSTA ([sta.tcl](sta.tcl)). The design is timed against a 10 ns virtual clock with 0 ns input and output delays.

### Area: [area_report.txt](area_report.txt)

| Metric | Value |
| :--- | :--- |
| Total cells | **25** (fewest of the five) |
| Chip area | **230.22 µm²** |
| Sequential area | 0 µm² |
| Wires / wire bits | 21 / 42 |

| Cell | Count |
| :--- | :---: |
| `xnor2_1` | 16 |
| `maj3_1` | 9 |

The netlist is just XNOR gates and majority (full-adder carry) gates. Structurally it is a **ripple-carry adder**: ABC flattened the prefix logic completely.

### Timing: [timing_report.txt](timing_report.txt)

Critical path **B[2] → Cout**, a chain of 6 `maj3` cells:

| Cell | Type | Incr (ns) | Arrival (ns) |
| :--- | :--- | :---: | :---: |
| `_17_` | maj3_1 | 0.344 | 0.344 |
| `_18_` | maj3_1 | 0.393 | 0.737 |
| `_19_` | maj3_1 | 0.400 | 1.137 |
| `_21_` | maj3_1 | 0.400 | 1.537 |
| `_23_` | maj3_1 | 0.400 | 1.937 |
| `_25_` | maj3_1 | 0.340 | **2.278** |

| Metric | Value |
| :--- | :--- |
| Critical delay | **2.278 ns** |
| Equivalent Fmax | **439.0 MHz** |
| Slack @ 10 ns | +7.722 ns (MET) |

### Power: [power_report.txt](power_report.txt)

| Component | Value |
| :--- | :--- |
| Switching power | 3.02 µW |
| Internal power | 0 (not modelled in this run) |
| Leakage power | 51.9 pW (lowest) |
| **Total** | **3.02 µW** (lowest) |

OpenSTA used its default input activity because no VCD/SAIF file was annotated. Use these numbers only to compare the adders with each other.

## Synthesis results: FPGA (Lattice iCE40 HX8K, Yosys `synth_ice40` + nextpnr)

Report: [fpga_report.txt](fpga_report.txt)

| Metric | Value |
| :--- | :--- |
| Logic cells (LUT4) | **21** / 7680 (fewest) |
| I/O pins | 26 / 256 |
| Critical path | A[3] → SUM[7], **10.37 ns** (1.58 ns logic + 8.79 ns routing) |
| Equivalent Fmax | **96.4 MHz** (slowest) |

## Findings

1. **The RTL is functionally wrong** at `C[4]`. Its "best area and power" result (25 cells, 3.02 µW, 21 LCs) partly comes from the missing logic for `G[3:0]`, so it should not be compared with the correct adders until the fix is applied and the flow is re-run.
2. **The netlist is effectively a ripple-carry adder.** It has 9 `maj3` and 16 `xnor2` cells, and the critical path is a 6-deep `maj3` chain. Its delay (2.278 ns) is therefore close to Brent-Kung, not to Kogge-Stone.
3. **Lowest power and leakage** (3.02 µW, 51.9 pW) of the five designs, which follows directly from having the fewest cells.
4. **Slowest on iCE40** (10.37 ns), even though it uses the fewest LUTs (21). The serial upper-nibble carry chain plus 85% routing share make up the critical path.

## Files

| File | Purpose |
| :--- | :--- |
| [ladner_fischer_adder.v](ladner_fischer_adder.v) | RTL |
| [ladner_fischer_mapped.v](ladner_fischer_mapped.v) | Gate-level netlist (SKY130) |
| [synth.tcl](synth.tcl) / [sta.tcl](sta.tcl) | Yosys synthesis and OpenSTA scripts |
| [LFA.circ](LFA.circ) / [LFA.jpg](LFA.jpg) | Logisim schematic |

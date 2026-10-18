# Parallel-Prefix Adders: RTL to ASIC & FPGA PPA Comparison

Five 8-bit parallel-prefix adder architectures written in structural Verilog. Each one is synthesized to the **SkyWater SKY130** standard-cell library (Yosys + OpenSTA) and placed and routed on a **Lattice iCE40 HX8K** FPGA (Yosys + nextpnr). The project then compares them on **Power, Performance and Area (PPA)**.

| Adder | Folder | Logisim schematic |
| :--- | :--- | :--- |
| Brent-Kung (BKA) | [brent_kung_adder/](brent_kung_adder/) | [BKA.circ](brent_kung_adder/BKA.circ) |
| Han-Carlson (HCA) | [han_carlson_adder/](han_carlson_adder/) | [HCA.circ](han_carlson_adder/HCA.circ) |
| Kogge-Stone (KSA) | [kogge_stone_adder/](kogge_stone_adder/) | [KSA.circ](kogge_stone_adder/KSA.circ) |
| Ladner-Fischer (LFA) | [ladner_fischer_adder/](ladner_fischer_adder/) | [LFA.circ](ladner_fischer_adder/LFA.circ) |
| Sklansky (SLA) | [sklansky_adder/](sklansky_adder/) | [SLA.circ](sklansky_adder/SLA.circ) |

---

## Background

A ripple-carry adder computes each carry from the one before it, so its delay grows as **O(n)**. Parallel-prefix adders treat carry computation as a prefix problem and solve it with a tree, which brings the delay down to **O(log n)**.

Every adder here follows the same three-step flow:

1. **Pre-processing:** bitwise generate and propagate signals
   `G[i] = A[i] & B[i]`, `P[i] = A[i] ^ B[i]`
2. **Prefix tree:** combine (G, P) pairs with the associative operator
   `(G_hi, P_hi) ∘ (G_lo, P_lo) = (G_hi | P_hi & G_lo, P_hi & P_lo)`
3. **Post-processing:** compute the carries `C[i+1] = G[i:0] | P[i:0] & Cin` and the sums `S[i] = P[i] ^ C[i]`

The architectures differ only in step 2. Each tree trades off **logic depth**, **number of prefix cells (area)**, **fan-out**, and **wiring tracks** differently:

| Architecture | Depth (n = 8) | Characteristic |
| :--- | :---: | :--- |
| Kogge-Stone | log₂n = 3 | Dense tree: every bit is computed at every stage. Minimum depth and fan-out of 2, but the most cells and wires. |
| Sklansky | log₂n = 3 | Divide-and-conquer. Minimum depth with few cells, but fan-out grows to n/2. |
| Brent-Kung | 2·log₂n − 1 | Sparse tree with an up-sweep and a down-sweep. Fewest cells and low fan-out, but the deepest tree. |
| Han-Carlson | log₂n + 1 | Hybrid: Brent-Kung on the outer stages and Kogge-Stone in the middle. |
| Ladner-Fischer | log₂n + 1 | Sparse prefix tree with fewer cells than Sklansky, at the cost of extra depth. |

### Module interface

All modules share the same 8-bit interface:

```verilog
input  [7:0] A, B;
input        Cin;
output [7:0] SUM;   // named S in brent_kung_adder
output       Cout;
```

---

## Repository layout

```
prefix_ADDER/
├── compare_ppa.sh          # Prints the ASIC PPA table from every adder's reports
├── run_fpga.sh             # Runs iCE40 synth + P&R for all adders and prints the FPGA table
├── run.sh                  # (empty placeholder)
├── sky130.lib              # SKY130 liberty file (not tracked, see Prerequisites)
└── <adder>_adder/
    ├── <adder>_adder.v     # Structural RTL
    ├── <adder>_mapped.v    # Gate-level netlist mapped to sky130_fd_sc_hd cells
    ├── synth.tcl           # Yosys ASIC synthesis script
    ├── sta.tcl             # OpenSTA timing + power script
    ├── area_report.txt     # Yosys `stat` cell count and chip area
    ├── timing_report.txt   # OpenSTA worst-case path report
    ├── power_report.txt    # OpenSTA power report
    ├── fpga_report.txt     # nextpnr-ice40 log (utilisation + critical path)
    ├── *.circ / *.jpg      # Logisim-evolution schematic and image
```

The Brent-Kung folder also contains:
- [tb_BKA.v](brent_kung_adder/tb_BKA.v): testbench with directed and random tests
- [BKA_waveform.png](brent_kung_adder/BKA_waveform.png): simulation waveform
- [fpga.tcl](brent_kung_adder/fpga.tcl): Vivado flow for a Xilinx Artix-7
- [BKA.md](brent_kung_adder/BKA.md): Vivado post-route analysis report for Artix-7

---

## Results

### ASIC: SKY130 (`sky130_fd_sc_hd`, tt corner, 25 °C, 1.80 V)

Unconstrained combinational paths are timed against a 10 ns virtual clock, with input and output delays set to 0. Fmax = 1 / critical delay.

| Adder | Cells | Area (µm²) | Critical delay (ns) | Fmax (MHz) | Total power (µW) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Brent-Kung | 30 | 232.72 | 2.346 | 426.3 | 3.78 |
| Han-Carlson | 30 | 228.97 | 2.347 | 426.2 | 3.21 |
| Kogge-Stone | 41 | 275.26 | **1.302** | **768.3** | 4.83 |
| Ladner-Fischer | **25** | 230.22 | 2.278 | 439.0 | **3.02** |
| Sklansky* | 41 | 275.26 | 1.302 | 768.3 | 4.83 |

### FPGA: Lattice iCE40 HX8K (CT256), Yosys `synth_ice40` + nextpnr

| Adder | Logic cells | Logic delay (ns) | Routing delay (ns) | Critical path (ns) | Fmax (MHz) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Brent-Kung | 25 | 1.71 | 8.01 | 9.72 | 102.9 |
| Han-Carlson | 28 | 1.32 | 8.99 | 10.31 | 97.0 |
| Kogge-Stone | 35 | 1.32 | 7.25 | **8.57** | **116.7** |
| Ladner-Fischer | **21** | 1.58 | 8.79 | 10.37 | 96.4 |
| Sklansky* | 35 | 1.32 | 7.25 | 8.57 | 116.7 |

All designs use 26 I/O pins and no flip-flops (purely combinational).

### Observations

- **Kogge-Stone is the fastest.** It has about 44% less ASIC delay than Brent-Kung, but costs about 18% more area and 28% more power. That is the expected trade-off for a dense, minimum-depth tree.
- **Ladner-Fischer gives the best area and power** in both flows. Its carries for bits 5–7 ripple from `C[4]`, which keeps the cell count low.
- **Brent-Kung and Han-Carlson end up almost the same** after Yosys/ABC optimisation at 8 bits. Their structural differences mostly disappear at this small width.
- **On FPGA, routing dominates:** 75–87% of the critical path is interconnect. Every architecture fits easily inside 4-input LUTs, so the size of the prefix tree matters less than on an ASIC.

> **\* Known issue:** [sklansky_adder.v](sklansky_adder/sklansky_adder.v) currently implements the same dense distance-1/2/4 tree as Kogge-Stone, so its results are identical. A true Sklansky tree would combine each upper half with the single most-significant prefix of the lower half, giving high fan-out.

### Xilinx Artix-7 (Brent-Kung only)

In Vivado post-route on `xc7a35t`, the BKA uses **14 LUTs** (8 × LUT5, 3 × LUT6, 3 × LUT4) with a **2.449 ns** worst-case path. See [BKA.md](brent_kung_adder/BKA.md) for the full breakdown.

---

## Reproducing the results

### Prerequisites

| Tool | Purpose |
| :--- | :--- |
| [Yosys](https://github.com/YosysHQ/yosys) | ASIC and FPGA synthesis |
| [OpenSTA](https://github.com/The-OpenROAD-Project/OpenSTA) (`sta`) | Static timing and power analysis |
| [nextpnr-ice40](https://github.com/YosysHQ/nextpnr) | iCE40 place & route |
| [Icarus Verilog](https://github.com/steveicarus/iverilog) + GTKWave | Simulation and waveforms |
| [Logisim-evolution](https://github.com/logisim-evolution/logisim-evolution) | Opening the `.circ` schematics (optional) |
| Vivado (optional) | Artix-7 flow in `fpga.tcl` |

Put the SKY130 liberty file `sky130_fd_sc_hd__tt_025C_1v80.lib` in the repository root and name it **`sky130.lib`**. You can get it from the [SkyWater PDK](https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd).

Run all commands from the repository root, because the scripts use paths relative to it.

### Simulation

```bash
iverilog -o bka.vvp brent_kung_adder/tb_BKA.v
vvp bka.vvp
gtkwave *.vcd
```

### ASIC synthesis, STA and power (per adder)

```bash
yosys -c brent_kung_adder/synth.tcl   # -> area_report.txt, brent_kung_mapped.v
sta brent_kung_adder/sta.tcl          # -> timing_report.txt, power_report.txt
```

For the other adders, replace `brent_kung_adder` with the folder name.

### Comparison tables

```bash
./compare_ppa.sh   # ASIC table (reads existing reports)
./run_fpga.sh      # Runs iCE40 synth + P&R for all adders, then prints the FPGA table
```

---

## Notes and limitations

- The power numbers are OpenSTA estimates that use default switching activity, with no VCD annotation. Use them to compare the adders with each other, not as absolute values.
- Only one corner (tt, 25 °C, 1.80 V) is analysed, and no wire-load model or parasitics are applied to the ASIC flow.
- The FPGA flow has no PCF file, so nextpnr places the I/O pins automatically. This adds noise to the routing delays.
- At 8 bits, the differences between architectures are small. The asymptotic trade-offs show up much more clearly at 32 or 64 bits.

## Possible extensions

- Fix the Sklansky tree so it uses true divide-and-conquer fan-out.
- Parameterise the adders to N bits and sweep 8 / 16 / 32 / 64 bits.
- Add self-checking testbenches for all five adders, comparing against `A + B + Cin`.
- Add SDF back-annotated timing and VCD-based power from OpenROAD place & route.

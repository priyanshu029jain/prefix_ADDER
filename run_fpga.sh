#!/bin/bash

ADDERS=("brent_kung_adder" "han_carlson_adder" "kogge_stone_adder" "ladner_fischer_adder" "sklansky_adder")

echo "=========================================================================================================="
echo "                               PREFIX ADDERS FPGA (iCE40) PPA COMPARISON REPORT                           "
echo "=========================================================================================================="
printf "%-22s | %-18s | %-24s | %-12s\n" "Adder Architecture" "Logic Cells (LCs)" "Critical Path Delay (ns)" "Fmax (MHz)"
echo "----------------------------------------------------------------------------------------------------------"

for adder in "${ADDERS[@]}"; do
    VERILOG_FILE="${adder}/${adder}.v"
    
    # Check for Ladner-Fischer naming variations
    if [ ! -f "$VERILOG_FILE" ] && [ "$adder" == "lader_fischa_adder" ]; then
        VERILOG_FILE="lader_fischa_adder/ladner_fischer_adder.v"
    fi

    if [ ! -f "$VERILOG_FILE" ]; then
        continue
    fi

    # 1. Synthesize RTL
    yosys -q -p "synth_ice40 -top ${adder} -json ${adder}/fpga_netlist.json" "$VERILOG_FILE" > /dev/null 2>&1

    # 2. Place & Route
    nextpnr-ice40 --hx8k --package ct256 --json "${adder}/fpga_netlist.json" --asc "${adder}/fpga.asc" --log "${adder}/fpga_report.txt" > /dev/null 2>&1

    # 3. Direct Regex Parsing for Logic Cells
    LCS=$(grep "ICESTORM_LC:" "${adder}/fpga_report.txt" 2>/dev/null | grep -oE 'ICESTORM_LC:[[:space:]]+[0-9]+' | grep -oE '[0-9]+')
    if [ -z "$LCS" ]; then LCS="N/A"; fi

    # 4. Critical Path Delay
    DELAY=$(grep "ns logic," "${adder}/fpga_report.txt" 2>/dev/null | awk '{printf "%.2f", $2 + $5}')
    if [ -z "$DELAY" ] || [ "$DELAY" == "0.00" ]; then
        DELAY=$(grep -A 40 "Critical path report" "${adder}/fpga_report.txt" 2>/dev/null | grep -E "^Info:\s+[0-9]+\.[0-9]+" | tail -n 1 | awk '{print $3}')
    fi
    if [ -z "$DELAY" ]; then DELAY="N/A"; fi

    # 5. Compute Fmax
    if [[ "$DELAY" != "N/A" && "$DELAY" != "0" && "$DELAY" != "0.00" ]]; then
        FMAX=$(awk -v d="$DELAY" 'BEGIN {printf "%.2f", 1000 / d}')
    else
        FMAX="N/A"
    fi

    printf "%-22s | %-18s | %-24s | %-12s\n" "$adder" "$LCS" "$DELAY" "$FMAX"
done

echo "=========================================================================================================="
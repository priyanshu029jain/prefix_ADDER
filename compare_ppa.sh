#!/bin/bash

# Define all 5 adder folders
ADDERS=("brent_kung_adder" "han_carlson_adder" "kogge_stone_adder" "ladner_fischer_adder" "sklansky_adder")

echo "=========================================================================================================="
echo "                                   PREFIX ADDERS ASIC PPA COMPARISON REPORT                               "
echo "=========================================================================================================="
printf "%-22s | %-16s | %-18s | %-18s | %-12s\n" "Adder Architecture" "Chip Area (um^2)" "Critical Delay (ns)" "Total Power (W)" "Fmax (MHz)"
echo "----------------------------------------------------------------------------------------------------------"

for adder in "${ADDERS[@]}"; do
    # 1. Extract Area from area_report.txt or synth log
    AREA=$(grep "Chip area" ${adder}/area_report.txt 2>/dev/null | awk -F':' '{print $2}' | tr -d ' ')
    if [ -z "$AREA" ]; then AREA="N/A"; fi

  # 2. Critical Path Delay (Grab the line above "data arrival time" without negative sign)
    DELAY=$(grep -B 1 "data arrival time" ${adder}/timing_report.txt 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
    if [ -z "$DELAY" ]; then DELAY="N/A"; fi
    
    # 3. Calculate Fmax in MHz if delay is valid
    if [ "$DELAY" != "N/A" ]; then
        FMAX=$(awk -v d="$DELAY" 'BEGIN {printf "%.2f", 1000 / d}')
    else
        FMAX="N/A"
    fi

    # 4. Extract Total Power from power_report.txt
    POWER=$(grep "Total " ${adder}/power_report.txt 2>/dev/null | tail -n 1 | awk '{print $(NF-1)}')
    if [ -z "$POWER" ]; then POWER="N/A"; fi

    printf "%-22s | %-16s | %-18s | %-18s | %-12s\n" "$adder" "$AREA" "$DELAY" "$POWER" "$FMAX"
done

echo "=========================================================================================================="
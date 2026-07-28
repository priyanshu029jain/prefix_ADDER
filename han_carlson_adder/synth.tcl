# Read the Sky130 technology cell library from the root directory
read_liberty -lib sky130.lib

# Read your Han-Carlson Verilog file
read_verilog han_carlson_adder/han_carlson_adder.v

# Elaborate the top module
hierarchy -top han_carlson_adder

# High-level synthesis pass (process RTL constructs, optimize, map memories)
proc; opt; memory; opt

# Map design technology to Sky130 standard cells
techmap; opt
abc -liberty sky130.lib
opt_clean -purge

# Print Area & Gate Count report directly in terminal
tee -o han_carlson_adder/area_report.txt stat -liberty sky130.lib

# Save the synthesized gate-level netlist (used later for STA timing/power)
write_verilog han_carlson_adder/han_carlson_mapped.v
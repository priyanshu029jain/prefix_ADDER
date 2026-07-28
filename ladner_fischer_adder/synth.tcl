# Read the Sky130 technology cell library from the root directory
read_liberty -lib sky130.lib

# Read your Ladner-Fischer Verilog file
read_verilog ladner_fischer_adder/ladner_fischer_adder.v

# Elaborate the top module
hierarchy -top ladner_fischer_adder

# High-level synthesis pass (process RTL constructs, optimize, map memories)
proc; opt; memory; opt

# Map design technology to Sky130 standard cells
techmap; opt
abc -liberty sky130.lib
opt_clean -purge

# Print Area & Gate Count report directly in terminal
stat -liberty sky130.lib

# Save the synthesized gate-level netlist (used later for STA timing/power)
write_verilog ladner_fischer_adder/ladner_fischer_mapped.v
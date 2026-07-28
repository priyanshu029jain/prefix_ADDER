# Read the Sky130 technology cell library from the root directory
read_liberty -lib sky130.lib

# Read your Brent-Kung Verilog file
read_verilog brent_kung_adder/brent_kung_adder.v

# Elaborate the top module
hierarchy -top brent_kung_adder

# High-level synthesis pass (process RTL constructs, optimize, map memories)
proc; opt; memory; opt

# Map design technology to Sky130 standard cells
techmap; opt
abc -liberty sky130.lib
opt_clean -purge

# # Print Area & Gate Count report directly in terminal
# stat -liberty sky130.lib

# Redirect area & cell statistics directly to area_report.txt inside module folder
tee -o brent_kung_adder/area_report.txt stat -liberty sky130.lib

# Save the synthesized gate-level netlist (used later for STA timing/power)
write_verilog brent_kung_adder/brent_kung_mapped.v
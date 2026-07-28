# Specify top module and source file
set top_module "brent_kung_adder"
set verilog_file "brent_kung_adder/brent_kung_adder.v"
set out_dir "brent_kung_adder"
set part_number "xc7a35tcpg236-1" ;# Artix-7 target (e.g. Basys 3 board)
export PATH=$PATH:/mnt/c/Xilinx/Vivado/2023.1/bin
synth_design -top $top_module -part $part_number -flatten_hierarchy rebuilt

# 3. Apply virtual clock constraint for combinational path delay (100 MHz target)
create_clock -name clk -period 10.000 [get_ports *]

# 4. Run Optimization, Placement, and Routing
opt_design
place_design
route_design

# 5. Export Reports directly into brent_kung_adder/
report_utilization -file $out_dir/fpga_area_report.txt
report_timing_summary -file $out_dir/fpga_timing_report.txt
report_power -file $out_dir/fpga_power_report.txt

exit
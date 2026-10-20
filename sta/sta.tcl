# OpenSTA script for mult_array (typical corner tt_025C_1v80)
# Run from the repository root:  sta sta/sta.tcl
# Clock period T in ns; override with:  T=7.5 sta sta/sta.tcl

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

set T 10.0
if {[info exists ::env(T)]} { set T $::env(T) }

# 1. Read the cell timing library
read_liberty $lib

# 2. Read and link the netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# 3. Define the clock
create_clock -name clk -period $T [get_ports clk]

# 4. Input arrival time
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# 5. Output required time
set_output_delay 1.0 -clock clk [all_outputs]

# 6. Worst setup slack
report_worst_slack -max

# 7. Critical path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt

# 4-bit Array Multiplier: RTL to GDSII

Name: Chanda Akshay Kumar
Roll number: 2024102014

All commands are run in WSL (Ubuntu) from the repository root, with the SKY130 PDK installed (open_pdks revision `8afc8346a57fe1ab7934ba5a6056ea8b43078e71`, see Part D for how it was installed).

Parts B and C are run inside the LibreLane (Nix) environment, so that Parts B to D all use the same Yosys: Yosys 0.62 and OpenSTA 2.7.0, with Icarus Verilog 13.0 for the gate-level simulation. Part A is plain Icarus Verilog (the RTL simulation gives the same PASS with the apt Icarus Verilog 12.0 and with 13.0) and GTKWave 3.3.116 from apt for the waveforms. An earlier run of Parts B and C with the apt Yosys 0.33 and OpenSTA 3.1.0 gave 66 cells and T_min = 2.46 ns; it was redone with Yosys 0.62 because ABC maps the logic differently in each Yosys version.

```
cd ~/librelane
nix-shell
cd /mnt/c/Users/aksha/Desktop/M-26/DVD/4Bit_Mult_RTL_GDS/mult4_2024102014
export PDK_ROOT=$HOME/pdk PDK=sky130A
```

## Part A: RTL design and verification

```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Error-injection test (task 6): temporarily replace line 8 of `rtl/full_adder.v` (`assign sum = a ^ b ^ cin;`) with the commented line below it (`assign sum = a ^ b;`), run the same `iverilog` and `vvp sim` commands above, which print `FAIL: 256 vectors checked, 95 errors`, then undo the change.

## Part B: logic synthesis (Yosys)

```
yosys -c synth/synth.tcl > synth/run.txt
```

Gate-level simulation of the synthesized netlist (writes `synth.vcd` instead of `mult.vcd`):

```
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls +VCD=synth.vcd
```

## Part C: static timing analysis (OpenSTA)

The clock period `T` (in ns) is read from the environment by `sta/sta.tcl`.

```
T=10 sta -exit sta/sta.tcl
T=2.98 sta -exit sta/sta.tcl
```

## Part D: physical design (LibreLane)

LibreLane v3.0.16 (with OpenROAD, Yosys, Magic, KLayout and Netgen) is installed with Nix in WSL, and is started with `nix-shell` inside the LibreLane clone:

```
cd ~/librelane
nix-shell
```

The SKY130 PDK is the revision that this LibreLane version pins (`8afc8346a57fe1ab7934ba5a6056ea8b43078e71`, from `librelane/pdk_hashes.yaml`), installed with `ciel` into `~/pdk`:

```
ciel enable --pdk-family sky130 --pdk-root $HOME/pdk -l sky130_fd_sc_hd -l sky130_fd_io 8afc8346a57fe1ab7934ba5a6056ea8b43078e71
```

The flow was run in a copy of the repository on the WSL filesystem (`~/work/mult4`), because run folders with symlinks do not work reliably under `/mnt/c`. In that copy, inside the `pnr/` folder, for each clock period (the `CLOCK_PERIOD` in `config.json` was edited before each run):

```
cd ~/work/mult4/pnr
```

The starting period is `CLOCK_PERIOD` = 1.2 x T_min = 1.2 x 2.98 = 3.58, rounded up to the next 0.5 ns, which gives 4.0 ns. Each run that fails timing is repeated with `CLOCK_PERIOD` increased by 0.5 ns, after setting it in `config.json`.

Two earlier runs were made before Parts B and C were redone with Yosys 0.62, when T_min was still 2.46 ns (1.2 x 2.46 = 2.95, which gives 3.0 ns). They are recorded here because every attempt must be listed:

```
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A config.json                    # CLOCK_PERIOD = 3.0
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P3.5 config.json     # CLOCK_PERIOD = 3.5
```

Runs 1 to 5 (each after setting `CLOCK_PERIOD` in `config.json` to the period in the tag):

```
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P4.0 config.json
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P4.5 config.json
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P5.0 config.json
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P5.5 config.json
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P6.0 config.json
```

Run 6, the final run, with `CLOCK_PERIOD` = 6.5 in `config.json` (this is the `pnr/config.json` in the repository):

```
librelane --manual-pdk --pdk-root $HOME/pdk --pdk sky130A --run-tag P6.5 config.json
```

Every attempt. The setup slack is `timing__setup__ws` from `metrics.json`, which is the worst slack over all corners:

| Run | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC errors | LVS errors | Result |
|---|---|---|---|---|---|
| earlier | 3.0 | -2.254 | 0 | 0 | timing fails |
| earlier | 3.5 | -1.754 | 0 | 0 | timing fails |
| 1 | 4.0 | -1.254 | 0 | 0 | timing fails |
| 2 | 4.5 | -0.754 | 0 | 0 | timing fails |
| 3 | 5.0 | -0.254 | 0 | 0 | timing fails |
| 4 | 5.5 | -0.009 | 0 | 0 | timing fails |
| 5 | 6.0 | -0.001 | 0 | 0 | timing fails |
| 6 | 6.5 | +0.499 | 0 | 0 | passes |

Before run 1, two attempts stopped before the design was processed (the PDK files were incomplete, then the PDK revision did not match this LibreLane version). They produced no results and are not counted.

The files of the passing run (6.5 ns) were copied into `pnr/`:

```
cp runs/P6.5/final/metrics.json /mnt/c/Users/aksha/Desktop/M-26/DVD/4Bit_Mult_RTL_GDS/mult4_2024102014/pnr/metrics.json
cp runs/P6.5/final/gds/mult_array.gds /mnt/c/Users/aksha/Desktop/M-26/DVD/4Bit_Mult_RTL_GDS/mult4_2024102014/pnr/mult_array.gds
```

<!-- The run folders are in the WSL copy at `~/work/mult4/pnr/runs/` (the passing run is `runs/P6.5/`, the first run is `runs/RUN_2026-10-20_04-11-15/`). The `runs/` folder is not committed. -->

To view the layout in KLayout (for the two screenshots), from the repository root in WSL:

```
klayout pnr/mult_array.gds
```

# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/lstm.sv
VERILOG_SOURCES += $(PWD)/function_lookup.sv
VERILOG_SOURCES += $(PWD)/rom.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = lstm

# MODULE is the basename of the Python test file
MODULE = cocotb_lstm

# Add waveform tracing
EXTRA_ARGS += --trace --trace-structs

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

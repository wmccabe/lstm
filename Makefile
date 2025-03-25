# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/rtl/lstm_layers.v
VERILOG_SOURCES += $(PWD)/rtl/lstm.v
VERILOG_SOURCES += $(PWD)/rtl/function_lookup.v
VERILOG_SOURCES += $(PWD)/rtl/rom.v
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = lstm_layers

# MODULE is the basename of the Python test file
MODULE = cocotb_lstm_layers

# Add waveform tracing
EXTRA_ARGS += --trace --trace-structs

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

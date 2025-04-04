# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/rtl/version_package.sv
VERILOG_SOURCES += $(PWD)/rtl/axi4_lite_lstm_layers_wrapper.v
VERILOG_SOURCES += $(PWD)/rtl/axi4_lite_lstm_layers.sv
VERILOG_SOURCES += $(PWD)/rtl/axi4_lite_slave.sv
VERILOG_SOURCES += $(PWD)/rtl/ram_tdp_rf.sv
VERILOG_SOURCES += $(PWD)/rtl/lstm_layers.sv
VERILOG_SOURCES += $(PWD)/rtl/lstm.sv
VERILOG_SOURCES += $(PWD)/rtl/function_lookup.sv
VERILOG_SOURCES += $(PWD)/rtl/rom.sv
VERILOG_SOURCES += $(PWD)/rtl/axi_handshake.sv
VERILOG_SOURCES += $(PWD)/rtl/address_decoder.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = axi4_lite_lstm_layers_wrapper

# MODULE is the basename of the Python test file
MODULE = cocotb_axi4_lite_lstm

# Add waveform tracing
EXTRA_ARGS += --trace --trace-structs

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

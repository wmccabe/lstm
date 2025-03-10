# cocotb_lstm.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import lstm
from lstm import LSTM
import random
weights = 4
Epsilon = 5/256

async def test_lstm(dut, pylstm):
    """Pass in the device under test and the python model, randomize inputs and check outputs"""
    while (dut.x_ready.value != 1):
        await cocotb.triggers.RisingEdge(dut.clk)
    # randomize model values
    pylstm.rand()
    # assign random values to the dut
    dut.C_in.value = pylstm.fixed_C_prev 
    dut.h_in.value = pylstm.fixed_h_prev
    for i in range(weights):
        dut.weight_x[i].value = pylstm.fixed_Wx[i]
        dut.weight_h[i].value = pylstm.fixed_Wh[i]
        dut.bias_x[i].value = pylstm.fixed_bx[i]
        dut.bias_h[i].value = pylstm.fixed_bh[i]
    
    # create random input
    x = random.uniform(-5, 5)
    x_fixed = lstm.createFixedPoint(x, lstm.precision)
    dut.x_in.value = x_fixed
    
    # assert valid on the input
    await cocotb.triggers.RisingEdge(dut.clk)
    dut.x_valid.value = 1
    pylstm.process([x])
    await cocotb.triggers.RisingEdge(dut.clk)
    dut.x_valid.value = 0
    # wait for valid output
    await cocotb.triggers.RisingEdge(dut.y_valid)
    floating_point_error = abs(lstm.floatingPoint(int(dut.y_out.value), lstm.precision) - pylstm.h_prev)
    assert floating_point_error < Epsilon
    
    

@cocotb.test()
async def lstm_test_suite(dut):
    """Set up LSTM tests."""
    pylstm = LSTM() 
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, 'ns').start())
    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    for _ in range(10):
        await cocotb.triggers.RisingEdge(dut.clk)
        while (dut.x_ready.value != 1):
            await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(test_lstm(dut, pylstm))
        await cocotb.triggers.RisingEdge(dut.clk)

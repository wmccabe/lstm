# cocotb_lstm.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import lstm
from lstm import LSTM
import random
weights = 4
Epsilon = 16

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
    x = random.uniform(-256, 256)
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
    fixed_point_error = abs(dut.y_out.value - pylstm.fixed_h_prev)
    print(f"{fixed_point_error} = |{dut.y_out.value} - {pylstm.fixed_h_prev}|")
    
    

@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""
    pylstm = LSTM() 
    dut.C_in.value = 64 
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, 'ns').start())

    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    print("Reset asserted and cleared")    
    for _ in range(10):
        await cocotb.triggers.RisingEdge(dut.clk)
        while (dut.x_ready.value != 1):
            await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(test_lstm(dut, pylstm))
        await cocotb.triggers.FallingEdge(dut.clk)
        await cocotb.triggers.RisingEdge(dut.clk)
        

    await cocotb.triggers.Timer(40, units="ns")  # wait a bit
    
    

    dut._log.info("y_valid is %s", dut.y_valid.value)
    assert dut.y_valid.value != 1, "y_valid is not 1!"

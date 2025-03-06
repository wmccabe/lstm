# test_lstm.py (simple)

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""

    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, 'ns').start())

    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    await cocotb.triggers.RisingEdge(dut.clk)
    dut.x_valid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    dut.x_valid.value = 0
    await cocotb.triggers.Timer(40, units="ns")  # wait a bit
    
    

    dut._log.info("y_valid is %s", dut.y_valid.value)
    assert dut.y_valid.value != 1, "y_valid is not 1!"

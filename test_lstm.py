# test_lstm.py (simple)

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""

    for cycle in range(10):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

    dut._log.info("y_valid is %s", dut.y_valid.value)
    assert dut.y_valid.value != 1, "my_signal_2[0] is not 1!"

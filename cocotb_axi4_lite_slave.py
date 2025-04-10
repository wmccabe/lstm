# cocotb_axi4_lite_slave.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import cocotb_axi
import random


async def randomize_user_ready(dut):
    while True:
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.user_ready.value = random.randint(0, 1)


async def test_axi_lite(dut):
    addresses_data = [
        (i, int(random.uniform(0, 2**dut.AXI_WIDTH.value - 1)))
        for i in range(dut.AXI_DEPTH.value)
    ]
    random.shuffle(addresses_data)
    await cocotb.triggers.RisingEdge(dut.clk)
    # write data
    for ad in addresses_data:
        address, data = ad
        await cocotb.start_soon(cocotb_axi.write(dut, address, data))

    random.shuffle(addresses_data)
    # read data
    for ad in addresses_data:
        address, expected_read = ad
        actual_read = await cocotb.start_soon(cocotb_axi.read(dut, address))
        assert expected_read == actual_read


@cocotb.test()
async def axi_test_suite(dut):
    """Axi Test Suite"""
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, "ns").start())
    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    cocotb.start_soon(randomize_user_ready(dut))
    await cocotb.start_soon(test_axi_lite(dut))

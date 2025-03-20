# cocotb_axi4_lite_slave.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import random

async def write(dut, address, data):
    dut.awaddr.value = address
    dut.wdata.value = data
 
    # Write Address
    dut.awvalid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.awready.value:
        dut.awvalid.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.awready.value)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.awvalid.value = 0
    # Write Data
    dut.wvalid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.wready.value:
        dut.wvalid.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.wready.value)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.wvalid.value = 0
    # Acknowledge write response
    dut.bready.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.bvalid.value:
        dut.bready.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.bvalid.wready)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.bready.value = 0

async def read(dut, address):
        dut.araddr.value = address
        dut.arvalid.value = 1 
        await cocotb.triggers.RisingEdge(dut.clk)
        if dut.awready.value:
            dut.arvalid.value = 0
        else:
            await cocotb.triggers.RisingEdge(dut.arready.value)
            await cocotb.triggers.RisingEdge(dut.clk)
            dut.arvalid.value = 0
        dut.rready.value = 1
        if dut.rvalid.value:
            actual_read = dut.rdata.value
            await cocotb.triggers.RisingEdge(dut.clk)
        else:
            await cocotb.triggers.RisingEdge(dut.rvalid)
            actual_read = dut.rdata.value
            await cocotb.triggers.RisingEdge(dut.clk)
        dut.rready.value = 0
        return actual_read
         

async def test_axi_lite(dut):
    addresses_data = [(i, int(random.uniform(0, 2**dut.WIDTH.value - 1))) for i in range(dut.DEPTH.value)]
    random.shuffle(addresses_data)
    await cocotb.triggers.RisingEdge(dut.clk)
    # write data
    for ad in addresses_data:
        address, data = ad
        await cocotb.start_soon(write(dut, address, data))
    
    random.shuffle(addresses_data)
    # read data
    for ad in addresses_data:
        address, expected_read = ad
        actual_read = await cocotb.start_soon(read(dut, address))
        assert expected_read == actual_read

@cocotb.test()
async def axi_test_suite(dut):
    """Axi Test Suite"""
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, "ns").start())
    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    await cocotb.start_soon(test_axi_lite(dut))


import cocotb
import random

verbose = False


async def send_write_address(dut):
    # Write Address
    dut.awvalid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.awready.value:
        dut.awvalid.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.awready)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.awvalid.value = 0


async def send_write_data(dut):
    # Write Data
    dut.wvalid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.wready.value:
        dut.wvalid.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.wready)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.wvalid.value = 0


async def write(dut, address, data):
    dut.awaddr.value = address
    dut.wdata.value = data
    if verbose:
        print(f"Writing {data} -> {address}")

    # randomize if write address or data is sent first
    random_path = random.randint(0, 2)
    if random_path == 0:
        cocotb.start_soon(send_write_address(dut))
        for _ in range(random.randint(0, 5)):
            await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(send_write_data(dut))
    elif random_path == 1:
        cocotb.start_soon(send_write_data(dut))
        for _ in range(random.randint(0, 5)):
            await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(send_write_address(dut))
    else:
        cocotb.start_soon(send_write_data(dut))
        cocotb.start_soon(send_write_address(dut))

    # Acknowledge write response
    dut.bready.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.bvalid.value:
        dut.bready.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.bvalid)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.bready.value = 0


async def read(dut, address):
    dut.araddr.value = address
    dut.arvalid.value = 1
    await cocotb.triggers.RisingEdge(dut.clk)
    if dut.arready.value:
        dut.arvalid.value = 0
    else:
        await cocotb.triggers.RisingEdge(dut.arready.value)
        await cocotb.triggers.RisingEdge(dut.clk)
        dut.arvalid.value = 0
    dut.rready.value = 1
    if dut.rvalid.value:
        read_data = dut.rdata.value
        await cocotb.triggers.RisingEdge(dut.clk)
    else:
        await cocotb.triggers.RisingEdge(dut.rvalid)
        read_data = dut.rdata.value
        await cocotb.triggers.RisingEdge(dut.clk)

    if verbose:
        print(f"Reading {address} -> {read_data}")
    return read_data

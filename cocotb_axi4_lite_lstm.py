# cocotb_axi4_lite_lstm.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import cocotb_axi
import lstm
from lstm import LSTM
from lstm import LAYERED_LSTM
import random

verbose = False
Epsilon = 0.1


async def test_lstm(dut):
    """Pass in the device under test and the python model, randomize inputs and check outputs"""

    pylstms = LAYERED_LSTM(dut.LAYERS.value)
    pylstms.rand()
    await cocotb.triggers.RisingEdge(dut.clk)
    version_register = await cocotb.start_soon(cocotb_axi.read(dut, pylstms.version_address))
    ver_dec = []
    for i in range(4):
        ver_dec.append(version_register & 0xff)
        version_register >>= 8
    print(f"ID.Major.Minor.Patch = {ver_dec[3]}.{ver_dec[2]}.{ver_dec[1]}.{ver_dec[0]}")
    for lyr in range(dut.LAYERS.value):
        for i in range(lstm.gates):
            await cocotb.start_soon(
                cocotb_axi.write(
                    dut,
                    pylstms.weight_x_address[lyr][i],
                    pylstms.layer[lyr].fixed_Wx[i],
                )
            )
            await cocotb.start_soon(
                cocotb_axi.write(
                    dut,
                    pylstms.weight_h_address[lyr][i],
                    pylstms.layer[lyr].fixed_Wh[i],
                )
            )
            await cocotb.start_soon(
                cocotb_axi.write(
                    dut, pylstms.bias_x_address[lyr][i], pylstms.layer[lyr].fixed_bx[i]
                )
            )
            await cocotb.start_soon(
                cocotb_axi.write(
                    dut, pylstms.bias_h_address[lyr][i], pylstms.layer[lyr].fixed_bh[i]
                )
            )

        await cocotb.start_soon(
            cocotb_axi.write(
                dut, pylstms.C_prev_address[lyr], pylstms.layer[lyr].fixed_C_prev
            )
        )
        await cocotb.start_soon(
            cocotb_axi.write(
                dut, pylstms.h_prev_address[lyr], pylstms.layer[lyr].fixed_h_prev
            )
        )

    # create random x input
    x = [random.uniform(-5, 5) for i in range(int(random.uniform(1, 10)))]
    # run against python module
    pylstms.process(x)
    for xi in x:
        x_fixed = lstm.createFixedPoint(xi, lstm.precision)
        await cocotb.start_soon(cocotb_axi.write(dut, pylstms.x_in_address, x_fixed))

    await cocotb.triggers.Timer(200, units="ns")
    await cocotb.triggers.RisingEdge(dut.clk)

    # error checking
    y_out = await cocotb.start_soon(cocotb_axi.read(dut, pylstms.y_out_address))
    C_out = await cocotb.start_soon(cocotb_axi.read(dut, pylstms.C_out_address))

    floating_point_error = abs(
        lstm.floatingPoint(y_out, lstm.precision)
        - pylstms.layer[dut.LAYERS.value - 1].h_prev
    )
    floating_point_error_state = abs(
        lstm.floatingPoint(C_out, lstm.precision)
        - pylstms.layer[dut.LAYERS.value - 1].C_prev
    )
    if verbose:
        print("--------------------")
        print(lstm.createFixedPoint(x, lstm.precision))
        print(
            f"{floating_point_error:.5f} = |{lstm.floatingPoint(int(y_out), lstm.precision):.5f} - {pylstms.layer[dut.LAYERS.value - 1].h_prev}|"
        )
        print(
            f"{floating_point_error_state:.5f} = |{lstm.floatingPoint(int(C_out), lstm.precision):.5f} - {pylstms.layer[dut.LAYERS.value - 1].C_prev}|"
        )

    assert floating_point_error < Epsilon
    assert floating_point_error_state < Epsilon


@cocotb.test()
async def lstm_test_suite(dut):
    """Set up LSTM tests."""
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, "ns").start())
    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    for _ in range(10):
        await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(test_lstm(dut))
        await cocotb.triggers.RisingEdge(dut.clk)
